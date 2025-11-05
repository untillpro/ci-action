package main

import (
	"encoding/json"
	"fmt"
	"os"
	"sort"
	"strings"

	"usage-analyzer/pkg/types"
)

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

	var data types.CollectedData
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

func generateMermaidGraph(allFiles []types.CIActionFile, usages []types.Usage) string {
	usageMap := make(map[string][]types.Usage)
	for _, usage := range usages {
		usageMap[usage.CIActionFile] = append(usageMap[usage.CIActionFile], usage)
	}

	var sb strings.Builder
	sb.WriteString("# CI-Action Usage Graph\n\n")
	sb.WriteString("This graph shows which repositories are using files from the ci-action repository.\n\n")

	// Generate Incoming calls section
	sb.WriteString(generateIncomingCalls(allFiles, usageMap))
	sb.WriteString("\n")

	// Generate Outgoing calls section
	sb.WriteString(generateOutgoingCalls(allFiles, usageMap))
	sb.WriteString("\n")

	sb.WriteString("## Mermaid Visualization\n\n")
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

	// Group left-side nodes by the ci-action files they call
	// This ensures that files calling the same ci-action file are grouped together
	leftNodesOrdered := []string{}
	leftNodesSeen := make(map[string]bool)

	// Iterate through ci-action files and collect calling files in order
	for _, ciFile := range allFiles {
		if usageList, used := usageMap[ciFile.Path]; used {
			for _, usage := range usageList {
				key := usage.RepoName + "/" + usage.RepoFile
				if !leftNodesSeen[key] {
					leftNodesSeen[key] = true
					leftNodesOrdered = append(leftNodesOrdered, key)
				}
			}
		}
	}

	// Define left-side nodes (calling files) in grouped order
	for _, nodeKey := range leftNodesOrdered {
		nodeID := getNodeID(nodeKey)
		sb.WriteString(fmt.Sprintf("    %s[\"%s\"]\n", nodeID, nodeKey))
	}

	// Define right-side nodes (ci-action files)
	for _, ciFile := range allFiles {
		ciNodeID := getNodeID(ciFile.Path)
		sb.WriteString(fmt.Sprintf("    %s[\"%s\"]\n", ciNodeID, ciFile.Path))
	}

	// Create edges
	for _, ciFile := range allFiles {
		ciNodeID := getNodeID(ciFile.Path)

		if usageList, used := usageMap[ciFile.Path]; used {
			for _, usage := range usageList {
				targetKey := usage.RepoName + "/" + usage.RepoFile
				targetNodeID := getNodeID(targetKey)
				sb.WriteString(fmt.Sprintf("    %s --> %s\n", targetNodeID, ciNodeID))
			}
		}
	}

	sb.WriteString("```\n")
	return sb.String()
}
func generateIncomingCalls(allFiles []types.CIActionFile, usageMap map[string][]types.Usage) string {
	var sb strings.Builder
	sb.WriteString("## Incoming calls\n\n")
	sb.WriteString("Files in ci-action repository that are called by other repositories:\n\n")

	// Create a sorted list of ci-action files that have usages
	type FileWithUsages struct {
		FilePath string
		Usages   []types.Usage
	}

	var filesWithUsages []FileWithUsages
	for _, ciFile := range allFiles {
		if usageList, used := usageMap[ciFile.Path]; used {
			filesWithUsages = append(filesWithUsages, FileWithUsages{
				FilePath: ciFile.Path,
				Usages:   usageList,
			})
		}
	}

	// Sort files alphabetically
	sort.Slice(filesWithUsages, func(i, j int) bool {
		return filesWithUsages[i].FilePath < filesWithUsages[j].FilePath
	})

	// Generate the list
	for _, fileWithUsage := range filesWithUsages {
		sb.WriteString(fmt.Sprintf("- [%s](https://github.com/untillpro/ci-action/blob/main/%s)\n", fileWithUsage.FilePath, fileWithUsage.FilePath))

		// Group usages by repo and file
		type CallerInfo struct {
			RepoName   string
			RepoFile   string
			RepoOwner  string
			RepoBranch string
		}
		var callers []CallerInfo
		for _, usage := range fileWithUsage.Usages {
			callers = append(callers, CallerInfo{
				RepoName:   usage.RepoName,
				RepoFile:   usage.RepoFile,
				RepoOwner:  usage.RepoOwner,
				RepoBranch: usage.RepoBranch,
			})
		}

		// Sort callers alphabetically
		sort.Slice(callers, func(i, j int) bool {
			if callers[i].RepoName != callers[j].RepoName {
				return callers[i].RepoName < callers[j].RepoName
			}
			return callers[i].RepoFile < callers[j].RepoFile
		})

		// Write callers
		for _, caller := range callers {
			repoOwner := caller.RepoOwner
			repoBranch := caller.RepoBranch
			if repoBranch == "" {
				repoBranch = "main"
			}
			// Strip .github/workflows/ prefix for display
			displayFileName := strings.TrimPrefix(caller.RepoFile, ".github/workflows/")
			sb.WriteString(fmt.Sprintf("  - [%s: %s](https://github.com/%s/%s/blob/%s/%s)\n",
				caller.RepoName, displayFileName, repoOwner, caller.RepoName, repoBranch, caller.RepoFile))
		}
	}

	return sb.String()
}

func generateOutgoingCalls(allFiles []types.CIActionFile, usageMap map[string][]types.Usage) string {
	var sb strings.Builder
	sb.WriteString("## Outgoing calls\n\n")
	sb.WriteString("Files in all repositories that call ci-action files:\n\n")

	// Build map: calling file -> list of ci-action files it calls
	type CallingFileInfo struct {
		RepoName   string
		RepoFile   string
		RepoOwner  string
		RepoBranch string
		Calls      map[string]bool
	}

	callingFiles := make(map[string]*CallingFileInfo)

	// For each ci-action file and its usages
	for ciFilePath, usages := range usageMap {
		for _, usage := range usages {
			// Create a unique key for the calling file
			key := usage.RepoName + "/" + usage.RepoFile

			if callingFiles[key] == nil {
				callingFiles[key] = &CallingFileInfo{
					RepoName:   usage.RepoName,
					RepoFile:   usage.RepoFile,
					RepoOwner:  usage.RepoOwner,
					RepoBranch: usage.RepoBranch,
					Calls:      make(map[string]bool),
				}
			}
			callingFiles[key].Calls[ciFilePath] = true
		}
	}

	// Create sorted list of calling files
	type FileWithCalls struct {
		RepoName   string
		RepoFile   string
		RepoOwner  string
		RepoBranch string
		Calls      []string
	}

	var filesWithCalls []FileWithCalls
	for _, info := range callingFiles {
		var callList []string
		for call := range info.Calls {
			callList = append(callList, call)
		}
		sort.Strings(callList)
		filesWithCalls = append(filesWithCalls, FileWithCalls{
			RepoName:   info.RepoName,
			RepoFile:   info.RepoFile,
			RepoOwner:  info.RepoOwner,
			RepoBranch: info.RepoBranch,
			Calls:      callList,
		})
	}

	// Sort files alphabetically by repo name, then by file name
	sort.Slice(filesWithCalls, func(i, j int) bool {
		if filesWithCalls[i].RepoName != filesWithCalls[j].RepoName {
			return filesWithCalls[i].RepoName < filesWithCalls[j].RepoName
		}
		return filesWithCalls[i].RepoFile < filesWithCalls[j].RepoFile
	})

	// Generate the list
	for _, fileWithCall := range filesWithCalls {
		repoOwner := fileWithCall.RepoOwner
		repoBranch := fileWithCall.RepoBranch
		if repoBranch == "" {
			repoBranch = "main"
		}

		// Strip .github/workflows/ prefix for display
		displayFileName := strings.TrimPrefix(fileWithCall.RepoFile, ".github/workflows/")

		sb.WriteString(fmt.Sprintf("- [%s: %s](https://github.com/%s/%s/blob/%s/%s)\n",
			fileWithCall.RepoName, displayFileName, repoOwner, fileWithCall.RepoName, repoBranch, fileWithCall.RepoFile))

		// Write calls (ci-action files being called)
		for _, call := range fileWithCall.Calls {
			sb.WriteString(fmt.Sprintf("  - [%s](https://github.com/untillpro/ci-action/blob/main/%s)\n", call, call))
		}
	}

	return sb.String()
}
