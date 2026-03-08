import pandas as pd
import numpy as np
import joblib
import shap
import matplotlib.pyplot as plt
import seaborn as sns
import json
from sklearn.model_selection import train_test_split
from sklearn.metrics import accuracy_score, confusion_matrix
from xgboost import XGBClassifier, plot_importance

# 1. LOAD DATA
try:
    df = pd.read_csv('maternal_health_data.csv')
    df.columns = df.columns.str.strip()
    print("Dataset loaded successfully!")
except Exception as e:
    print(f"Error loading CSV: {e}")

# 2. PRE-PROCESSING
risk_mapping_names = {0: 'low risk', 1: 'mid risk', 2: 'high risk'}
df['RiskLevel'] = df['RiskLevel'].map({'low risk': 0, 'mid risk': 1, 'high risk': 2})

feature_cols = ['Age', 'SystolicBP', 'DiastolicBP', 'BS', 'BodyTemp', 'HeartRate']
X = df[feature_cols]
y = df['RiskLevel']

# 3. TRAIN XGBOOST
X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)

rf_model = XGBClassifier(
    n_estimators=1200,
    learning_rate=0.05,
    max_depth=10,
    subsample=0.9,
    colsample_bytree=0.9,
    random_state=42,
    eval_metric='mlogloss'
)
rf_model.fit(X_train, y_train)

# 4. INITIALIZE SHAP
explainer = shap.TreeExplainer(rf_model)

# 5. CORE ANALYSIS FUNCTION (Updated with Trimester Logic)
def analyze_maternal_health(input_list, trimester=1):
    data_df = pd.DataFrame([input_list], columns=feature_cols)
    
    # Prediction
    risk_code = int(rf_model.predict(data_df)[0])
    risk_name = risk_mapping_names[risk_code]
    
    probs = rf_model.predict_proba(data_df)[0]
    confidence = float(np.max(probs) * 100)
    
    # SHAP logic
    shap_values = explainer.shap_values(data_df)
    if len(shap_values.shape) == 3:
        impacts = shap_values[0, :, risk_code]
    else:
        impacts = shap_values[0]
    shap_data = sorted(zip(feature_cols, impacts), key=lambda x: x[1], reverse=True)
    
    # --- DETAILED MEDICAL GUIDELINES ---
    age, sbp, dbp, bs, temp, hr = input_list
    advice = []

    # A. Trimester-Specific Context 
    if trimester == 1:
        advice.append("Trimester 1: Focus on Folic Acid intake and manage early fatigue with rest.")
    elif trimester == 2:
        advice.append("Trimester 2: Monitor for baby's movements and ensure calcium-rich nutrition.")
    elif trimester == 3:
        advice.append("Trimester 3: Practice kick counting and watch for sudden swelling in hands or face.")
    
    # B. Blood Pressure Check
    if sbp > 140 or dbp > 90: 
        if trimester == 3:
            advice.append("🚨 3rd Trimester Alert: High BP may indicate Pre-eclampsia. Please consult your doctor immediately.")
        else:
            advice.append("Hypertension detected: Reduce salt intake and rest on your left side.")
    elif sbp < 90 or dbp < 60:
        advice.append("Hypotension detected: Increase hydration and move slowly to avoid dizziness.")

    # C. Blood Sugar Check
    if bs > 7.8: 
        advice.append("Elevated Blood Sugar: Focus on low-glycemic foods and consistent walking.")
    elif bs < 3.9:
        advice.append("Hypoglycemia detected: Consume a small natural sugar snack immediately and rest.")

    # D. Body Temperature & Heart Rate
    if temp > 100.4: 
        advice.append("Fever Warning: This may indicate an infection; contact your clinic.")
    elif temp < 95.0:
        advice.append("Low Body Temperature: Keep warm and monitor for lethargy.")

    if hr > 100: 
        advice.append("Tachycardia: Avoid caffeine and practice deep breathing techniques.")
    elif hr < 60:
        advice.append("Bradycardia detected: If you feel dizzy, please consult your doctor.")

    # E. Age logic
    if age > 35: 
        advice.append("Advanced Maternal Age: Regular monitoring for gestational risks is advised.")
    elif age < 18:
        advice.append("Adolescent Pregnancy: Focus on high-calcium and iron-rich nutrition.")

    if not advice:
        advice.append("Vitals appear stable. Continue your routine prenatal checkups.")
    
    if risk_code == 2: 
        advice.append("🚨 EMERGENCY: High Risk detected. Seek immediate medical attention.")
    
    return {
        "risk_level": risk_code,
        "risk_name": risk_name,
        "percentage": round(confidence, 2),
        "top_contributor": shap_data[0][0],
        "importance": {k: float(v) for k, v in shap_data},
        "advice": advice
    }

# --- 6. TEST RUN ---
if __name__ == "__main__":
    # Performance Check
    y_pred = rf_model.predict(X_test)
    accuracy = accuracy_score(y_test, y_pred)
    print(f"\n--- MODEL PERFORMANCE ---")
    print(f"Total Accuracy: {accuracy * 100:.2f}%")

    # A. Confusion Matrix Graph (Accuracy Visual)
    plt.figure(figsize=(8, 6))
    cm = confusion_matrix(y_test, y_pred)
    sns.heatmap(cm, annot=True, fmt='d', cmap='RdPu', 
                xticklabels=['Low', 'Mid', 'High'], 
                yticklabels=['Low', 'Mid', 'High'])
    plt.title(f"Model Accuracy Visualization ({accuracy*100:.2f}%)")
    plt.ylabel('Actual Risk')
    plt.xlabel('Predicted Risk')
    plt.savefig('accuracy_confusion_matrix.png')
    plt.show()

    # B. Feature Importance Graph 
    plt.figure(figsize=(10, 6))
    plot_importance(rf_model, color='pink')
    plt.title("XGBoost: Maternal Risk Factor Importance")
    plt.savefig('feature_importance.png')
    plt.show()

    # C. Sample Test Run
    sample_patient = [25, 145, 95, 7.0, 98.6, 80] 
    print("\n--- TEST RUN OUTPUT (Trimester 3) ---")
    test_result = analyze_maternal_health(sample_patient, trimester=3)
    
    print(json.dumps(test_result, indent=4))

    # --- SHAP WATERFALL PLOT  ---

    sample_df = pd.DataFrame([sample_patient], columns=feature_cols)

    predicted_class = int(rf_model.predict(sample_df)[0])

    shap_values = explainer(sample_df)

    
    shap_exp = shap_values[0, :, predicted_class]

    shap.plots.waterfall(shap_exp)

    shap.plots.waterfall(shap_exp, show=False)
    plt.savefig("shap_waterfall_sample_patient.png", bbox_inches="tight")