#!/bin/bash

# 1. Ensure the target directory exists
CLAUDE_SKILLS_DIR="$HOME/.claude/skills"
mkdir -p "$CLAUDE_SKILLS_DIR"

# 2. Get the directory where this script is located
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Linking skills from $REPO_DIR to $CLAUDE_SKILLS_DIR..."

# 3. Loop through subdirectories and symlink them
for skill in "$REPO_DIR"/*/; do
    skill_name=$(basename "$skill")
    target="$CLAUDE_SKILLS_DIR/$skill_name"

    # Remove existing link/folder if it exists to avoid conflicts
    if [ -e "$target" ] || [ -L "$target" ]; then
        echo "  - Replacing existing $skill_name..."
        rm -rf "$target"
    fi

    # Create the symlink
    ln -s "$skill" "$target"
    echo "  + Linked $skill_name"
done

echo "Done! Skills are installed."
