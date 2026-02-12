import sys
import os
import time
from pathlib import Path
from mistralai import Mistral

def convert_pdf(file_path, client):
    """Uploads, processes, and extracts markdown from a single PDF."""
    try:
        file_path = Path(file_path)
        print(f"1. Uploading {file_path.name}...")
        
        # 1. Upload the file to Mistral's temp storage
        with open(file_path, "rb") as f:
            uploaded_file = client.files.upload(
                file={
                    "file_name": file_path.name,
                    "content": f,
                },
                purpose="ocr" 
            )

        # 2. Get a signed URL (required for the OCR engine to access the file)
        signed_url = client.files.get_signed_url(file_id=uploaded_file.id)

        print(f"2. Processing {file_path.name} with mistral-ocr-latest...")
        # 3. Call the OCR model
        pdf_response = client.ocr.process(
            document={
                "type": "document_url",
                "document_url": signed_url.url,
            },
            model="mistral-ocr-latest",
            include_image_base64=False  # Set True if you want images embedded
        )
        
        # 4. Combine all pages into one Markdown string
        full_markdown = ""
        for page in pdf_response.pages:
            full_markdown += page.markdown + "\n\n"
            
        return full_markdown

    except Exception as e:
        print(f"Error processing {file_path.name}: {e}")
        return None

def main():
    if len(sys.argv) < 2:
        print("Usage: python mistral_convert.py <path_to_pdf_or_folder>")
        sys.exit(1)

    api_key = os.environ.get("MISTRAL_API_KEY")
    if not api_key:
        print("Error: MISTRAL_API_KEY environment variable not set.")
        sys.exit(1)

    client = Mistral(api_key=api_key)
    input_path = Path(sys.argv[1])
    
    # Determine list of files to process
    files = list(input_path.glob("*.pdf")) if input_path.is_dir() else [input_path]
    
    print(f"Found {len(files)} PDF(s) to process with Mistral OCR.")

    for i, pdf_file in enumerate(files):
        print(f"\n--- File {i+1}/{len(files)}: {pdf_file.name} ---")
        
        md_content = convert_pdf(pdf_file, client)
        
        if md_content:
            output_file = pdf_file.with_suffix(".md")
            output_file.write_text(md_content, encoding="utf-8")
            print(f"✅ Success! Saved to: {output_file.name}")
        else:
            print(f"❌ Failed to convert {pdf_file.name}")

if __name__ == "__main__":
    main()
