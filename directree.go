// directree.go
package main

import (
	"flag"
	"fmt"
	"io/fs"
	"log"
	"os"
	"os/exec"
	"path/filepath"
	"sort"
	"strings"
)

const (
	colorBlue = "\033[0;34m"
	colorNone = "\033[0m"
)

var (
	maxDepth        int
	useColor        bool
	excludeDirs     arrayFlags
	excludeFiles    arrayFlags
	defaultDirs     = []string{".git", "__pycache__", "node_modules", ".idea", ".vscode"}
	defaultFiles    = []string{".DS_Store", ".gitignore"}
	excludeDirSet   = make(map[string]struct{})
	excludeFileSet  = make(map[string]struct{})
	outputFile      string
	clipToClipboard bool
)

type arrayFlags []string

func (i *arrayFlags) String() string { return strings.Join(*i, ", ") }
func (i *arrayFlags) Set(value string) error {
	*i = append(*i, value)
	return nil
}

func main() {
	setupFlags()
	dir := getTargetDirectory()
	initializeExclusions()
	tree := generateTree(dir, "", 0)
	printTree(tree)

	if clipToClipboard {
		copyTreeToClipboard(tree)
	}

	if outputFile != "" {
		saveToFile(tree, outputFile)
	}
}

func setupFlags() {
	flag.IntVar(&maxDepth, "max-depth", -1, "Maximum depth to traverse")
	flag.BoolVar(&useColor, "color", false, "Enable colored output")
	flag.Var(&excludeDirs, "exclude", "Directory to exclude")
	flag.Var(&excludeFiles, "exclude-file", "File to exclude")
	flag.StringVar(&outputFile, "o", "", "Output file (default: stdout)")
	flag.BoolVar(&clipToClipboard, "clip", false, "Copy output to clipboard")
	flag.Usage = customUsage
	flag.Parse()
}

func customUsage() {
	fmt.Fprintf(flag.CommandLine.Output(), "Usage: %s [OPTIONS] [DIRECTORY]\n", os.Args[0])
	fmt.Println("Generate a tree-like visualization of directory structure.")
	fmt.Println("Options:")
	flag.PrintDefaults()
	fmt.Printf("\nExample:\n  %s -max-depth 3 -color ~/projects\n", os.Args[0])
}

func getTargetDirectory() string {
	if flag.NArg() > 0 {
		return flag.Arg(0)
	}
	return "."
}

func initializeExclusions() {
	for _, d := range append(defaultDirs, excludeDirs...) {
		excludeDirSet[d] = struct{}{}
	}
	for _, f := range append(defaultFiles, excludeFiles...) {
		excludeFileSet[f] = struct{}{}
	}
}

func generateTree(path string, prefix string, depth int) string {
	if maxDepth != -1 && depth > maxDepth {
		return ""
	}

	entries := readSortedEntries(path)
	var tree strings.Builder
	for i, entry := range entries {
		isLast := i == len(entries)-1
		tree.WriteString(printEntry(entry, prefix, isLast))
		if entry.IsDir() {
			tree.WriteString(generateTree(
				filepath.Join(path, entry.Name()),
				getNextPrefix(prefix, isLast),
				depth+1,
			))
		}
	}
	return tree.String()
}

func printTree(tree string) {
	fmt.Println(tree)
}

func copyTreeToClipboard(tree string) {
	cmd := exec.Command("clip")
	cmd.Stdin = strings.NewReader(tree)
	if err := cmd.Run(); err != nil {
		log.Fatal(err)
	}
}

func saveToFile(tree string, outputFile string) {
	if err := os.WriteFile(outputFile, []byte(tree), 0644); err != nil {
		log.Fatal(err)
	}
}

func readSortedEntries(path string) []fs.DirEntry {
	entries, err := os.ReadDir(path)
	if err != nil {
		return nil
	}
	filtered := filterEntries(entries)
	sortEntries(filtered)
	return filtered
}

func filterEntries(entries []fs.DirEntry) []fs.DirEntry {
	var filtered []fs.DirEntry
	for _, entry := range entries {
		name := entry.Name()
		if name == "." || name == ".." {
			continue
		}
		if shouldExclude(entry) {
			continue
		}
		filtered = append(filtered, entry)
	}
	return filtered
}

func shouldExclude(entry fs.DirEntry) bool {
	name := entry.Name()
	if entry.IsDir() {
		_, excluded := excludeDirSet[name]
		return excluded
	}
	_, excluded := excludeFileSet[name]
	return excluded
}

func sortEntries(entries []fs.DirEntry) {
	sort.Slice(entries, func(i, j int) bool {
		if entries[i].IsDir() && !entries[j].IsDir() {
			return true
		}
		if !entries[i].IsDir() && entries[j].IsDir() {
			return false
		}
		return entries[i].Name() < entries[j].Name()
	})
}

func printEntry(entry fs.DirEntry, prefix string, isLast bool) string {
	linePrefix := "├── "
	if isLast {
		linePrefix = "└── "
	}

	name := entry.Name()
	if entry.IsDir() && useColor {
		name = colorBlue + name + colorNone
	}

	return fmt.Sprintf("%s%s%s\n", prefix, linePrefix, name)
}

func getNextPrefix(currentPrefix string, isLast bool) string {
	connector := "│   "
	if isLast {
		connector = "    "
	}
	return currentPrefix + connector
}

