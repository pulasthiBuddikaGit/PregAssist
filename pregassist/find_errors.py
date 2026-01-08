
try:
    with open('analysis_v2.txt', 'r', encoding='utf-16') as f:
        for line in f:
            if 'error' in line.lower():
                print(line.strip())
except Exception as e:
    print(f"Error: {e}")
