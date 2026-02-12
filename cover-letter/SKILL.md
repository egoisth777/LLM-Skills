---
name: cover-letter
description: Generates a concise LaTeX cover letter based on the currently opened file context.
allowed-tools: [Read, Write, AskUserQuestion]
---

# Cover Letter Generator

This skill generates a professional, concise cover letter in LaTeX format based on the context from the currently opened file in the editor.

## Instructions

When this skill is invoked:

1. **Read the context**: Look at the user's currently active file, the active file should be named as `job_descriptions.md`. This file contains the company and job information that you will need to generate the cover-letter.

2. **Read resume templates**: Look for the Resume files in `./Resumes/`, glob them all, and:
   - Search for common resume file patterns: `*.tex`
   - Read available resume templates to extract:
     - Personal information (name, contact details, email, phone)
     - Professional summary or objective
     - Key skills and technical competencies
     - Work experience and achievements
     - Education background
   - If multiple resume templates exist, prefer `.tex` files as they're easier to parse

3. **Gather additional information**: Ask the user for:
   - Company folder name (for organizing the output)
   - Job ID or position identifier
   - Any specific points they want to emphasize beyond what's in the resume
   - Which skills or experiences to highlight for this particular position

4. **Generate the cover letter**:
   - Keep it concise (aim for 3-4 paragraphs maximum), below 1 page.
   - Use a professional tone
   - Use the personal information extracted from the resume templates
   - Highlight relevant skills and experience based on both the job context and resume
   - Use the LaTeX `letter` document class or a modern CV template format
   - Include standard sections: opening, body paragraphs, and closing
   - Tailor the content to match the job description from the opened file

5. **File naming**: Save the cover letter as `{folder}-{jobID}-cv.tex` where:
   - `{folder}` is the company/organization folder name provided by the user
   - `{jobID}` is the job identifier provided by the user
   - Example: `acme-SWE2024-cv.tex`
   - Save in the current working directory or a subdirectory specified by the user

6. **LaTeX Format**: Use a clean, professional LaTeX format. Include:
   - Proper document class and packages
   - Contact information header
   - Date
   - Recipient address (if available)
   - Professional opening and closing
   - Well-formatted paragraphs

## Example Output Structure

```latex
\documentclass[11pt]{letter}
\usepackage[margin=1in]{geometry}
\usepackage{hyperref}

\signature{Your Name}
\address{Your Address \\ City, State ZIP \\ Email \\ Phone}

\begin{document}

\begin{letter}{Hiring Manager \\ Company Name \\ Company Address}

\opening{Dear Hiring Manager,}

[Concise paragraph expressing interest and highlighting key qualifications]

[Optional: Brief paragraph demonstrating knowledge of the company and fit]

[Closing paragraph with call to action]

\closing{Sincerely,}

\end{letter}
\end{document}
```

