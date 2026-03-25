import sys
import docx
import PyPDF2

with open("extracted_requirements.txt", "w", encoding="utf-8") as out:
    out.write("--- DOCX: TranThiVanAnh... ---\n")
    try:
        doc = docx.Document("TranThiVanAnh_xây dựng hệ thống quản lý quy trình chế biến thuốc theo tiêu chuẩn gmp-who.docx")
        for para in doc.paragraphs:
            if para.text.strip():
                out.write(para.text + "\n")
    except Exception as e:
        out.write(f"Error DOCX: {e}\n")
        
    out.write("\n--- PDF: CamScanner 4-2-2026 11.01.pdf ---\n")
    try:
        with open("CamScanner 4-2-2026 11.01.pdf", 'rb') as f:
            reader = PyPDF2.PdfReader(f)
            for page in reader.pages:
                text = page.extract_text()
                if text:
                    out.write(text + "\n")
    except Exception as e:
        out.write(f"Error PDF: {e}\n")

print("Extraction complete.")
