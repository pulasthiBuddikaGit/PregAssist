
try:
    with open('analysis_v2.txt', 'r', encoding='utf-16') as f:
        print(f.read())
except Exception as e:
    print(f"Error: {e}")
