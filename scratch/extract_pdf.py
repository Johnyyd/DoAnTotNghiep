import fitz
import sys
import io

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

doc = fitz.open(r'd:\codes\Antigravity\DoAnTotNghiep\DOCS\CamScanner.pdf')
for i in range(min(3, len(doc))):
    text = doc[i].get_text()
    print(f"=== Page {i+1} ===")
    print(text)
    print()
