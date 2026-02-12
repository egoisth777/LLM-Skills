# LLM-Skills

A collection of custom skills for Claude Code that extend its capabilities with specialized workflows.

## Available Skills

### cover-letter

Generates professional, concise cover letters in LaTeX format based on your resume templates and the currently opened job description.

**Usage:** `/cover-letter`

**Features:**

- Automatically extracts personal information from resume templates
- Context-aware generation from job descriptions
- Interactive prompts for personalization
- Structured file naming: `{folder}-{jobID}-cv.tex`
- Clean LaTeX output ready for compilation

[Learn more](./cover-letter/README.md)

### mistral-ocr

Batch converts PDF files to Markdown using Mistral's OCR API.

**Usage:** Invoke via PowerShell wrapper script

**Features:**

- Batch processing of PDF files
- High-quality OCR conversion
- Markdown output

[Learn more](./mistral-ocr/SKILL.md)

## Installation

To use these skills with Claude Code:

1. Clone this repository to your local machine
2. Install skills using the installation scripts provided:
   - Windows: `.\install.ps1`
   - Linux/Mac: `./install.sh`

## Creating Your Own Skills

Each skill is a folder containing at minimum a `SKILL.md` file with frontmatter metadata:

```markdown
---
name: skill-name
description: Brief description of what the skill does
allowed-tools: [Tool1, Tool2]
---

# Skill instructions and documentation
```

See existing skills for examples.

## Contributing

Feel free to contribute new skills or improvements to existing ones via pull requests.
