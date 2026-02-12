# Cover Letter Generator Skill

A Claude Code skill that generates concise, professional cover letters in LaTeX format based on your resume and the currently opened job description.

## Features

- Automatically extracts personal information from your resume templates
- Generates clean, professional LaTeX cover letters
- Uses context from the currently opened file (job descriptions, role requirements, etc.)
- Interactive prompts for personalization
- Automatic file naming with structured format: `{folder}-{jobID}-cv.tex`
- Concise output focused on key qualifications

## How It Works

The skill follows this workflow:

1. **Reads the job description** from your currently opened file
2. **Scans for resume templates** in your working directory (`.tex`, `.pdf` files)
3. **Extracts personal information** from your resume (name, contact, skills, experience)
4. **Prompts you** for company name, job ID, and specific points to emphasize
5. **Generates a tailored cover letter** combining job requirements with your background
6. **Saves the output** in the format: `{folder}-{jobID}-cv.tex`

## Usage

1. Navigate to your resume folder (where your resume templates are stored)
2. Open a job description or relevant document in your editor
3. Invoke the skill:

   ```bash
   /cover-letter
   ```

4. Answer the prompts for:

   - Company/folder name
   - Job ID or position identifier
   - Key points to emphasize for this specific role
   - Which skills or experiences to highlight

5. The skill will generate a LaTeX file ready for compilation

## Output Format

The generated cover letter will be saved as: `{folder}-{jobID}-cv.tex`

For example:

- `google-SWE2024-cv.tex`
- `microsoft-PM2024-cv.tex`
- `startup-fullstack-cv.tex`

## Compiling the LaTeX File

To generate a PDF from the LaTeX file:

```bash
pdflatex your-cover-letter.tex
```

Or use your preferred LaTeX editor (Overleaf, TeXShop, etc.)

## Tips

- Keep your job description open in the editor for best context
- Be specific about achievements and skills you want to highlight
- The generated letter is a starting point - review and personalize as needed
- Make sure your resume templates are in the working directory

## Requirements

- No additional dependencies (uses Claude's native capabilities)
- Resume templates (`.tex` or `.pdf` format) in your working directory
- LaTeX distribution for compiling the output (not required for generation)
