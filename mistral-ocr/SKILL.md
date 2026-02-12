---
name: mistral-ocr
description: Uses Mistral's OCR to batch convert PDF files to Markdown.
allowed-tools: [Bash]
---

# Mistral OCR Batch Converter

This skill converts PDFs to Markdown using Mistral's OCR.

## Usage

Run the PowerShell wrapper script. You do not need to activate any environments manually.

```powershell
powershell -ExecutionPolicy Bypass -File ~/.claude/skills/mistral-ocr/run.ps1 "path/to/pdfs"
