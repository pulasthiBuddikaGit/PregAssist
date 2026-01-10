# Intelligent Prenatal Care Assistant  
*(AI- and AR-Integrated Decision Support System for Pregnancy Care)*

---

## 1. Project Overview

Pregnancy is a complex and dynamic process that requires continuous monitoring of maternal physical health, mental wellbeing, and fetal condition to ensure safe outcomes for both the mother and the fetus. However, existing prenatal care practices are largely clinic-dependent, fragmented, and rely heavily on manual interpretation and clinical judgment, particularly in fetal health assessment using cardiotocography (CTG).

This project proposes an **intelligent prenatal care assistant** that integrates multiple components into a single platform. The system combines maternal physical health monitoring, mental health risk assessment, interactive educational support, and an explainable AI-based fetal health decision support system (DSS). The primary objective is to support pregnant mothers in daily care while assisting obstetricians and gynecologists in making accurate, transparent, and well-informed clinical decisions.

A key contribution of this project is the **fetal health DSS**, which uses machine learning to classify fetal health from CTG features and provides explainable outputs to strengthen clinical judgment rather than replace it. The solution follows a mobile-first design and is optimized for practical deployment in real-world healthcare environments.

---

## 2. System Architecture

The system follows a **modular and integrated architecture**, where each component addresses a specific prenatal care challenge while sharing a common application framework and data flow.

### Architectural Components

- **Maternal Physical Health Monitoring Module**  
  Collects and analyzes maternal parameters such as blood pressure, blood glucose, and heart rate to support early risk detection.

- **Mental Health Assessment Module**  
  Assesses maternal emotional wellbeing using multimodal inputs while prioritizing data privacy and adaptive intelligence.

- **Educational and AR-Based Guidance Module**  
  Provides interactive and personalized pregnancy education using AR-based 3D visualizations.

- **Fetal Health Decision Support System (DSS)**  
  Uses CTG-derived features to classify fetal health and provides explainable predictions to assist clinicians.

- **Mobile Application Layer**  
  Serves as the primary interface for pregnant mothers and healthcare professionals, integrating all system outputs.

### Architectural Diagram (Conceptual)





*(This diagram represents the conceptual data flow and system structure.)*

---

## 3. Dependencies and Technologies Used

### Programming Languages
- Python  
- Dart  

### Machine Learning & Data Science
- Scikit-learn  
- NumPy  
- Pandas  
- SHAP (SHapley Additive exPlanations)  
- Joblib  

### Mobile Application Development
- Flutter  
- Android SDK  

### Model Deployment & Optimization
- ONNX (planned)  
- On-device inference techniques  

### Visualization & Utilities
- Matplotlib  
- JSON  

### Development Tools
- Git & GitHub  
- VS Code / Android Studio  

---

## 4. Summary

This project presents a comprehensive intelligent prenatal care solution that integrates explainable AI, maternal mental health assessment, educational support, and fetal health decision support within a single mobile platform. The modular design ensures scalability, transparency, and clinical relevance, contributing to improved maternal and fetal health outcomes.
