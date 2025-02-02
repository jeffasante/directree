#!/bin/bash

# Default values for excluded directories and files
DEFAULT_EXCLUDE_DIRS=".git __pycache__ node_modules .idea .vscode"
DEFAULT_EXCLUDE_FILES=".DS_Store .gitignore"

# ANSI colors for optional colored output
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Help message
show_help() {
    echo "Usage: $0 [OPTIONS] [DIRECTORY]"
    echo "Generate a tree-like visualization of directory structure."
    echo ""
    echo "Options:"
    echo "  -h, --help           Show this help message"
    echo "  -d, --max-depth N    Maximum depth to traverse (default: unlimited)"
    echo "  -c, --color          Enable colored output"
    echo "  -e, --exclude DIR    Additional directory to exclude (can be used multiple times)"
    echo "  -f, --exclude-file F Additional file to exclude (can be used multiple times)"
    echo "  -o, --output FILE    Save output to a file (Markdown or text)"
    echo "  --clip               Copy output to clipboard"
    echo ""
    echo "Example:"
    echo "  $0 -d 3 -c -o tree.md --clip ~/projects"
    exit 0
}

# Initialize variables
MAX_DEPTH=""
USE_COLOR=0
ADDITIONAL_EXCLUDES=""
ADDITIONAL_EXCLUDE_FILES=""
OUTPUT_FILE=""
CLIPBOARD=0

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            ;;
        -d|--max-depth)
            MAX_DEPTH="$2"
            shift 2
            ;;
        -c|--color)
            USE_COLOR=1
            shift
            ;;
        -e|--exclude)
            ADDITIONAL_EXCLUDES="$ADDITIONAL_EXCLUDES|$2"
            shift 2
            ;;
        -f|--exclude-file)
            ADDITIONAL_EXCLUDE_FILES="$ADDITIONAL_EXCLUDE_FILES|$2"
            shift 2
            ;;
        -o|--output)
            OUTPUT_FILE="$2"
            shift 2
            ;;
        --clip)
            CLIPBOARD=1
            shift
            ;;
        *)
            DIRECTORY="$1"
            shift
            ;;
    esac
done

# Set default directory to current if not specified
DIRECTORY="${DIRECTORY:-.}"

# Function to check if a directory should be excluded
should_exclude() {
    local dir="$1"
    local basename=$(basename "$dir")
    for excl in $DEFAULT_EXCLUDE_DIRS; do
        [[ "$basename" == "$excl" ]] && return 0
    done
    [[ -n "$ADDITIONAL_EXCLUDES" ]] && echo "$basename" | grep -qE "${ADDITIONAL_EXCLUDES#|}" && return 0
    return 1
}

# Function to check if a file should be excluded
should_exclude_file() {
    local file="$1"
    local basename=$(basename "$file")
    for excl in $DEFAULT_EXCLUDE_FILES; do
        [[ "$basename" == "$excl" ]] && return 0
    done
    [[ -n "$ADDITIONAL_EXCLUDE_FILES" ]] && echo "$basename" | grep -qE "${ADDITIONAL_EXCLUDE_FILES#|}" && return 0
    return 1
}

# Function to generate tree
generate_tree() {
    local dir="$1"
    local prefix="$2"
    local depth="$3"
    local max_depth="$4"

    # Check max depth
    if [[ -n "$max_depth" ]] && (( depth > max_depth )); then
        return
    fi

    # Get list of files and directories, sorted with directories first
    local items=($(ls -1a "$dir" | grep -v '^\.\{1,2\}$'))
    local total=${#items[@]}
    local count=0

    for item in "${items[@]}"; do
        ((count++))
        local path="$dir/$item"
        local is_last=$([[ $count -eq $total ]] && echo 1 || echo 0)
        local current_prefix=$([[ $is_last -eq 1 ]] && echo "└── " || echo "├── ")
        local next_prefix=$([[ $is_last -eq 1 ]] && echo "    " || echo "│   ")

        # Skip excluded directories and files
        if [[ -d "$path" ]]; then
            should_exclude "$path" && continue
        else
            should_exclude_file "$path" && continue
        fi

        # Print item
        if [[ $USE_COLOR -eq 1 && -d "$path" ]]; then
            echo -e "$prefix$current_prefix${BLUE}$item${NC}"
        else
            echo "$prefix$current_prefix$item"
        fi

        # Recurse into directories
        if [[ -d "$path" ]]; then
            generate_tree "$path" "$prefix$next_prefix" $((depth + 1)) "$max_depth"
        fi
    done
}

# Capture output
TREE_OUTPUT=$(generate_tree "$DIRECTORY" "" 0 "$MAX_DEPTH")

# Save to file if requested
if [[ -n "$OUTPUT_FILE" ]]; then
    echo "$TREE_OUTPUT" > "$OUTPUT_FILE"
    echo "Saved to $OUTPUT_FILE"
fi

# Copy to clipboard if requested
if [[ $CLIPBOARD -eq 1 ]]; then
    if command -v pbcopy &> /dev/null; then
        echo "$TREE_OUTPUT" | pbcopy  # macOS
    elif command -v xclip &> /dev/null; then
        echo "$TREE_OUTPUT" | xclip -selection clipboard  # Linux
    elif command -v clip.exe &> /dev/null; then
        echo "$TREE_OUTPUT" | clip.exe  # Windows (Git Bash, WSL)
    else
        echo "Clipboard support not found. Install 'xclip' (Linux) or use 'pbcopy' (macOS)."
    fi
fi

# Print output
echo "$TREE_OUTPUT"
