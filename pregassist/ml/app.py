from flask import Flask, request, jsonify
from flask_cors import CORS
# This imports the logic from your model.py file
from model_core import analyze_maternal_health, rf_model, X_test, y_test
from sklearn.metrics import accuracy_score

app = Flask(__name__)
CORS(app)

# --- PERFORMANCE CHECK ON STARTUP ---
print("\n--- MODEL PERFORMANCE ---")
y_pred = rf_model.predict(X_test)
accuracy = accuracy_score(y_test, y_pred)
print(f"Total Accuracy: {accuracy * 100:.2f}%")

# --- TEST RUN (Simulating a high-risk case with Trimester 3) ---
print("\n--- TEST RUN OUTPUT ---")
sample_vitals = [36, 150, 95, 8.5, 98.6, 105] 
# Now passing '3' as the trimester for the test run
print(analyze_maternal_health(sample_vitals, trimester=3))
print("-" * 30)

@app.route('/predict', methods=['POST'])
def predict():
    try:
        req_data = request.json
        
        # 1. Get Trimester from Flutter (Default to 1 if not provided)
        trimester = int(req_data.get('trimester', 1))
        
        # 2. Extract Vitals
        if 'vitals' in req_data:
            vitals_data = req_data['vitals']
        else:
            # Extract fields manually if sent as separate keys
            vitals_data = [
                float(req_data.get('Age')),
                float(req_data.get('SystolicBP')),
                float(req_data.get('DiastolicBP')),
                float(req_data.get('BS')),
                float(req_data.get('BodyTemp')),
                float(req_data.get('HeartRate'))
            ]
            
        # 3. Pass both vitals and trimester to the model
        result = analyze_maternal_health(vitals_data, trimester=trimester)
        return jsonify(result)

    except Exception as e:
        print(f"❌ Error: {e}")
        return jsonify({"error": str(e)}), 400

if __name__ == '__main__':
    # host='0.0.0.0' allows your Flutter app to connect
    app.run(host='0.0.0.0', port=5000, debug=True)