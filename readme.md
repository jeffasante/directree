# Directree - Directory Tree Generator

## Overview
`directree` is a command-line tool written in Go that generates a tree-like visualization of a directory structure. It supports options for limiting depth, excluding files or directories, using colored output, saving to files, and copying output to the clipboard.

## Features
- Colored output option for directories
- Configurable depth limit
- Custom exclusion patterns for files and directories
- Sorted output (directories first)
- Proper tree-like formatting
- Default exclusions for common directories/files (`.git`, `node_modules`, etc.)
- Supports saving output as markdown or text file
- Cross-platform clipboard support (Windows, macOS, Linux)

## Installation

1. **Build from source:**
   ```bash
   go build -o directree directree.go
   ```

2. **Make it executable:**
   ```bash
   chmod +x directree
   ```

## Usage

### Basic Usage
```bash
./directree
```

### Specify Directory
```bash
./directree /path/to/directory
```

### Enable Colored Output
```bash
./directree --color
```

### Limit Depth to 2 Levels
```bash
./directree --max-depth 2
```

### Exclude Directories
```bash
./directree --exclude .git --exclude node_modules
```

### Exclude Specific Files
```bash
./directree --exclude-file "*.log" --exclude-file "*.tmp"
```

### Save to a Markdown File
```bash
./directree -o output.md
```

### Save to a Text File
```bash
./directree -o output.txt
```

### Copy Output to Clipboard
```bash
./directree --clip
```

### Combine Multiple Options
```bash
./directree --color --max-depth 3 --exclude .git --exclude node_modules -o tree.md
```

---

## Bash Script Usage (`dirtree.sh`)
To use the Bash wrapper script:

1. Save it as `dirtree.sh`
2. Make it executable:
   ```bash
   chmod +x dirtree.sh
   ```
3. Use it in various ways:

```bash
# Basic usage (current directory)
./dirtree.sh

# Specific directory
./dirtree.sh /path/to/directory

# With colored output
./dirtree.sh -c

# Limit depth to 2 levels
./dirtree.sh -d 2

# Exclude additional directories
./dirtree.sh -e build -e dist

# Exclude additional files
./dirtree.sh -f "*.log" -f "*.tmp"

# Save output to a markdown file
./dirtree.sh -o output.md

# Save output to a text file
./dirtree.sh -o output.txt

# Copy to clipboard
./dirtree.sh --clip

# Combine multiple options
./dirtree.sh -c -d 3 -e build -f "*.log" /path/to/directory
```

## Clipboard Support

### Linux
For clipboard functionality on Linux, install either `xclip` or `xsel`:

```bash
# Ubuntu/Debian
sudo apt-get install xclip

# or for xsel
sudo apt-get install xsel
```

### Windows
On Windows, the clipboard functionality uses `clip.exe`, which is built into Windows. To copy output to the clipboard:

```powershell
.\directree.exe --clip
```

### macOS
On macOS, `pbcopy` is used:
```bash
./directree | pbcopy
```

## License
MIT License

