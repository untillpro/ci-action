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
		fmt.Fprintf(os.Stderr, "Usage: %s <input-json-file> [output-md-file]\n", os.Args[0])
		os.Exit(1)
	}

	inputFile := os.Args[1]
	outputFile := "ci-action-usages.md"
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

	mermaidGraph := generateMermaidGraph(data.AllCIActionFiles, data.Usages)

	if err := os.WriteFile(outputFile, []byte(mermaidGraph), 0644); err != nil {
		fmt.Fprintf(os.Stderr, "Error writing mermaid file: %v\n", err)
		os.Exit(1)
	}

	fmt.Printf("Generated mermaid graph with %d files and %d usages. Written to %s\n", len(data.AllCIActionFiles), len(data.Usages), outputFile)
}

func generateMermaidGraph(allFiles []CIActionFile, usages []Usage) string {
	usageMap := make(map[string][]Usage)
	for _, usage := range usages {
		usageMap[usage.CIActionFile] = append(usageMap[usage.CIActionFile], usage)
	}

	var sb strings.Builder
	sb.WriteString("# CI-Action Usage Graph\n\n")
	sb.WriteString("This graph shows which repositories are using files from the ci-action repository.\n\n")
	sb.WriteString("```mermaid\n")
	sb.WriteString("graph LR\n")

	nodeID := 0
	fileToNode := make(map[string]string)

	getNodeID := func(file string) string {
		if id, exists := fileToNode[file]; exists {
			return id
		}
		nodeID++
		id := fmt.Sprintf("F%d", nodeID)
		fileToNode[file] = id
		return id
	}

	for _, ciFile := range allFiles {
		ciNodeID := getNodeID(ciFile.Path)
		sb.WriteString(fmt.Sprintf("    %s[\"%s\"]\n", ciNodeID, ciFile.Path))

		if usageList, used := usageMap[ciFile.Path]; used {
			for _, usage := range usageList {
				targetKey := usage.RepoName + "/" + usage.RepoFile
				targetNodeID := getNodeID(targetKey)
				sb.WriteString(fmt.Sprintf("    %s[\"%s\"]\n", targetNodeID, targetKey))
				sb.WriteString(fmt.Sprintf("    %s --> %s\n", targetNodeID, ciNodeID))
			}
		} else {
			notUsedID := getNodeID("NOT_USED")
			sb.WriteString(fmt.Sprintf("    %s[\"NOT_USED\"]\n", notUsedID))
			sb.WriteString(fmt.Sprintf("    %s --> %s\n", notUsedID, ciNodeID))
		}
	}

	sb.WriteString("```\n")
	return sb.String()
}
