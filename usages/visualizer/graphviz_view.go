package main

import (
	"encoding/json"
	"fmt"
	"os"
	"strings"
)

type CIActionFile struct {
	Path string `json:"path"`
}

type Usage struct {
	CIActionFile string `json:"ci_action_file"`
	RepoName     string `json:"repo_name"`
	RepoFile     string `json:"repo_file"`
}

type CollectedData struct {
	AllCIActionFiles []CIActionFile `json:"all_ci_action_files"`
	Usages           []Usage        `json:"usages"`
}

func main() {
	if len(os.Args) < 2 {
		fmt.Fprintf(os.Stderr, "Usage: %s <input-json-file> [output-dot-file]\n", os.Args[0])
		os.Exit(1)
	}

	inputFile := os.Args[1]
	outputFile := "ci-action-usages.dot"
	if len(os.Args) >= 3 {
		outputFile = os.Args[2]
	}

	jsonData, err := os.ReadFile(inputFile)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error reading input file: %v\n", err)
		os.Exit(1)
	}

	var data CollectedData
	if err := json.Unmarshal(jsonData, &data); err != nil {
		fmt.Fprintf(os.Stderr, "Error parsing JSON: %v\n", err)
		os.Exit(1)
	}

	dotGraph := generateGraphvizDot(data.AllCIActionFiles, data.Usages)

	if err := os.WriteFile(outputFile, []byte(dotGraph), 0644); err != nil {
		fmt.Fprintf(os.Stderr, "Error writing dot file: %v\n", err)
		os.Exit(1)
	}

	fmt.Printf("Generated graphviz DOT with %d files and %d usages. Written to %s\n", len(data.AllCIActionFiles), len(data.Usages), outputFile)
	fmt.Printf("\nTo render the graph, run:\n")
	fmt.Printf("  dot -Tpng %s -o ci-action-usages.png\n", outputFile)
	fmt.Printf("  dot -Tsvg %s -o ci-action-usages.svg\n", outputFile)
}

func generateGraphvizDot(allFiles []CIActionFile, usages []Usage) string {
	usageMap := make(map[string][]Usage)
	for _, usage := range usages {
		usageMap[usage.CIActionFile] = append(usageMap[usage.CIActionFile], usage)
	}

	var sb strings.Builder
	sb.WriteString("digraph CIActionUsage {\n")
	sb.WriteString("  rankdir=LR;\n")
	sb.WriteString("  node [shape=box, style=rounded];\n")
	sb.WriteString("  \n")

	sb.WriteString("  // CI-Action files\n")
	sb.WriteString("  subgraph cluster_ci_action {\n")
	sb.WriteString("    label=\"ci-action repository\";\n")
	sb.WriteString("    style=filled;\n")
	sb.WriteString("    color=lightblue;\n")
	sb.WriteString("    \n")

	nodeMap := make(map[string]string)
	nodeID := 0

	getNodeID := func(label string) string {
		if id, exists := nodeMap[label]; exists {
			return id
		}
		nodeID++
		id := fmt.Sprintf("n%d", nodeID)
		nodeMap[label] = id
		return id
	}

	for _, ciFile := range allFiles {
		id := getNodeID(ciFile.Path)
		label := escapeLabel(ciFile.Path)

		if _, used := usageMap[ciFile.Path]; !used {
			sb.WriteString(fmt.Sprintf("    %s [label=\"%s\", color=red, style=\"rounded,filled\", fillcolor=lightcoral];\n", id, label))
		} else {
			sb.WriteString(fmt.Sprintf("    %s [label=\"%s\", style=\"rounded,filled\", fillcolor=lightyellow];\n", id, label))
		}
	}

	sb.WriteString("  }\n")
	sb.WriteString("  \n")

	repoMap := make(map[string][]string)
	for _, usage := range usages {
		targetKey := usage.RepoName + "/" + usage.RepoFile
		repoMap[usage.RepoName] = append(repoMap[usage.RepoName], targetKey)
	}

	sb.WriteString("  // Repository files\n")
	clusterID := 0
	for repoName := range repoMap {
		clusterID++
		sb.WriteString(fmt.Sprintf("  subgraph cluster_repo_%d {\n", clusterID))
		sb.WriteString(fmt.Sprintf("    label=\"%s\";\n", escapeLabel(repoName)))
		sb.WriteString("    style=filled;\n")
		sb.WriteString("    color=lightgreen;\n")
		sb.WriteString("    \n")

		seen := make(map[string]bool)
		for _, usage := range usages {
			if usage.RepoName == repoName {
				targetKey := usage.RepoName + "/" + usage.RepoFile
				if !seen[targetKey] {
					id := getNodeID(targetKey)
					label := escapeLabel(usage.RepoFile)
					sb.WriteString(fmt.Sprintf("    %s [label=\"%s\", style=\"rounded,filled\", fillcolor=white];\n", id, label))
					seen[targetKey] = true
				}
			}
		}

		sb.WriteString("  }\n")
		sb.WriteString("  \n")
	}

	sb.WriteString("  // Edges\n")
	for _, usage := range usages {
		ciActionID := getNodeID(usage.CIActionFile)
		targetKey := usage.RepoName + "/" + usage.RepoFile
		repoFileID := getNodeID(targetKey)
		sb.WriteString(fmt.Sprintf("  %s -> %s;\n", repoFileID, ciActionID))
	}

	sb.WriteString("}\n")

	return sb.String()
}

func escapeLabel(s string) string {
	s = strings.ReplaceAll(s, "\\", "\\\\")
	s = strings.ReplaceAll(s, "\"", "\\\"")
	return s
}
