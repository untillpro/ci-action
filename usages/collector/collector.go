package main

import (
	"bufio"
	"encoding/json"
	"fmt"
	"net/http"
	"os"
	"path/filepath"
	"regexp"
	"sort"
	"strings"
	"time"
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

type GitHubRepo struct {
	Name     string `json:"name"`
	Archived bool   `json:"archived"`
}

type GitHubContent struct {
	Name        string `json:"name"`
	Path        string `json:"path"`
	Type        string `json:"type"`
	DownloadURL string `json:"download_url"`
}

var (
	usesActionRegex   = regexp.MustCompile(`uses:\s+untillpro/ci-action@(\S+)`)
	usesWorkflowRegex = regexp.MustCompile(`uses:\s+untillpro/ci-action/(\.github/workflows/[^@]+)@(\S+)`)
	curlScriptRegex   = regexp.MustCompile(`https://raw\.githubusercontent\.com/untillpro/ci-action/(\S+?)/scripts/([^\s|]+)`)
	curlAnyRegex      = regexp.MustCompile(`https://raw\.githubusercontent\.com/untillpro/ci-action/(\S+?)/([^\s|]+)`)
	httpClient        = &http.Client{Timeout: 30 * time.Second}
)

const (
	githubAPIBase = "https://api.github.com"
	orgName       = "untillpro"
)

func main() {
	workDir, err := os.Getwd()
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error getting working directory: %v\n", err)
		os.Exit(1)
	}

	rootDir := filepath.Join(workDir, "..")
	ciActionPath := filepath.Join(rootDir, "ci-action")
	var allCIActionFiles []CIActionFile

	if _, err := os.Stat(ciActionPath); os.IsNotExist(err) {
		fmt.Println("Local ci-action folder not found, fetching from GitHub...")
		allCIActionFiles, err = getAllCIActionFilesFromGitHub()
		if err != nil {
			fmt.Fprintf(os.Stderr, "Error fetching ci-action files from GitHub: %v\n", err)
			os.Exit(1)
		}
	} else {
		allCIActionFiles = getAllCIActionFiles(ciActionPath)
	}

	outdatedReposFile := filepath.Join(rootDir, "outdated-repos.txt")
	outdatedRepos, err := loadOutdatedRepos(outdatedReposFile)
	if err != nil {
		outdatedRepos = make(map[string]bool)
	} else if len(outdatedRepos) > 0 {
		fmt.Printf("Loaded %d outdated repositories to skip\n", len(outdatedRepos))
	}

	fmt.Println("Fetching non-archived repositories from GitHub...")
	repos, err := fetchNonArchivedRepos()
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error fetching repositories: %v\n", err)
		os.Exit(1)
	}
	fmt.Printf("Found %d non-archived repositories\n", len(repos))

	var usages []Usage
	reposWithUsages := make(map[string]bool)
	skippedCount := 0

	for idx := range repos {
		repoName := repos[idx].Name
		fullRepoName := orgName + "/" + repoName

		if outdatedRepos[fullRepoName] || outdatedRepos[repoName] {
			skippedCount++
			continue
		}

		fmt.Printf("Scanning %s (%d/%d)...\n", repoName, idx+1, len(repos))

		repoUsages, err := scanRepositoryFromGitHub(repoName)
		if err != nil {
			fmt.Fprintf(os.Stderr, "Warning: Error scanning %s: %v\n", repoName, err)
			continue
		}

		if len(repoUsages) > 0 {
			usages = append(usages, repoUsages...)
			reposWithUsages[repoName] = true
		}
	}

	if skippedCount > 0 {
		fmt.Printf("Skipped %d outdated repositories\n", skippedCount)
	}

	data := CollectedData{
		AllCIActionFiles: allCIActionFiles,
		Usages:           usages,
	}

	jsonData, err := json.MarshalIndent(data, "", "  ")
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error marshaling JSON: %v\n", err)
		os.Exit(1)
	}

	outputFile := filepath.Join(rootDir, "ci-action-data.json")
	if err := os.WriteFile(outputFile, jsonData, 0644); err != nil {
		fmt.Fprintf(os.Stderr, "Error writing JSON file: %v\n", err)
		os.Exit(1)
	}

	fmt.Printf("\nCollected %d ci-action files and %d usages from %d repositories\n",
		len(allCIActionFiles), len(usages), len(reposWithUsages))
	fmt.Println("Data written to ci-action-data.json")
}

func loadOutdatedRepos(filename string) (map[string]bool, error) {
	file, err := os.Open(filename)
	if err != nil {
		return nil, err
	}
	defer file.Close()

	outdated := make(map[string]bool)
	scanner := bufio.NewScanner(file)

	for scanner.Scan() {
		line := strings.TrimSpace(scanner.Text())
		if line != "" && !strings.HasPrefix(line, "#") {
			outdated[line] = true
		}
	}

	if err := scanner.Err(); err != nil {
		return nil, err
	}

	return outdated, nil
}

func fetchNonArchivedRepos() ([]GitHubRepo, error) {
	var allRepos []GitHubRepo
	page := 1
	githubToken := os.Getenv("GITHUB_TOKEN")

	for {
		url := fmt.Sprintf("%s/orgs/%s/repos?per_page=100&page=%d&type=all", githubAPIBase, orgName, page)
		req, err := http.NewRequest("GET", url, nil)
		if err != nil {
			return nil, err
		}

		req.Header.Set("Accept", "application/vnd.github.v3+json")
		if githubToken != "" {
			req.Header.Set("Authorization", "Bearer "+githubToken)
		}

		resp, err := httpClient.Do(req)
		if err != nil {
			return nil, err
		}

		if resp.StatusCode != http.StatusOK {
			resp.Body.Close()
			return nil, fmt.Errorf("GitHub API returned status %d", resp.StatusCode)
		}

		var repos []GitHubRepo
		if err := json.NewDecoder(resp.Body).Decode(&repos); err != nil {
			resp.Body.Close()
			return nil, err
		}
		resp.Body.Close()

		if len(repos) == 0 {
			break
		}

		for idx := range repos {
			if !repos[idx].Archived {
				allRepos = append(allRepos, repos[idx])
			}
		}

		page++
		time.Sleep(100 * time.Millisecond)
	}

	return allRepos, nil
}

func scanRepositoryFromGitHub(repoName string) ([]Usage, error) {
	contents, err := fetchGitHubDirectoryContents(repoName, ".github")
	if err != nil {
		return nil, nil
	}

	var usages []Usage

	for idx := range contents {
		if contents[idx].Type == "file" {
			fileUsages, err := scanGitHubFile(repoName, contents[idx].Path, contents[idx].DownloadURL)
			if err != nil {
				continue
			}
			usages = append(usages, fileUsages...)
		} else if contents[idx].Type == "dir" {
			subUsages, err := scanGitHubDirectory(repoName, contents[idx].Path)
			if err != nil {
				continue
			}
			usages = append(usages, subUsages...)
		}
	}

	return usages, nil
}

func scanGitHubDirectory(repoName, dirPath string) ([]Usage, error) {
	contents, err := fetchGitHubDirectoryContents(repoName, dirPath)
	if err != nil {
		return nil, err
	}

	var usages []Usage

	for idx := range contents {
		if contents[idx].Type == "file" {
			fileUsages, err := scanGitHubFile(repoName, contents[idx].Path, contents[idx].DownloadURL)
			if err != nil {
				continue
			}
			usages = append(usages, fileUsages...)
		} else if contents[idx].Type == "dir" {
			subUsages, err := scanGitHubDirectory(repoName, contents[idx].Path)
			if err != nil {
				continue
			}
			usages = append(usages, subUsages...)
		}
	}

	return usages, nil
}

func fetchGitHubDirectoryContents(repoName, dirPath string) ([]GitHubContent, error) {
	url := fmt.Sprintf("%s/repos/%s/%s/contents/%s", githubAPIBase, orgName, repoName, dirPath)
	req, err := http.NewRequest("GET", url, nil)
	if err != nil {
		return nil, err
	}

	req.Header.Set("Accept", "application/vnd.github.v3+json")
	githubToken := os.Getenv("GITHUB_TOKEN")
	if githubToken != "" {
		req.Header.Set("Authorization", "Bearer "+githubToken)
	}

	resp, err := httpClient.Do(req)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	if resp.StatusCode == http.StatusNotFound {
		return nil, fmt.Errorf("directory not found")
	}

	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("GitHub API returned status %d", resp.StatusCode)
	}

	var contents []GitHubContent
	if err := json.NewDecoder(resp.Body).Decode(&contents); err != nil {
		return nil, err
	}

	time.Sleep(100 * time.Millisecond)

	return contents, nil
}

func scanGitHubFile(repoName, filePath, downloadURL string) ([]Usage, error) {
	resp, err := httpClient.Get(downloadURL)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("failed to download file")
	}

	var usages []Usage
	scanner := bufio.NewScanner(resp.Body)

	for scanner.Scan() {
		line := scanner.Text()
		fileUsages := extractUsagesFromLine(line, repoName, filePath)
		usages = append(usages, fileUsages...)
	}

	time.Sleep(50 * time.Millisecond)

	return usages, nil
}

func getAllCIActionFilesFromGitHub() ([]CIActionFile, error) {
	var files []CIActionFile
	githubToken := os.Getenv("GITHUB_TOKEN")

	if _, err := os.Stat(filepath.Join("ci-action", "action.yml")); err == nil {
		files = append(files, CIActionFile{Path: "action.yml"})
	}

	workflowsContents, err := fetchGitHubDirectoryContents("ci-action", ".github/workflows")
	if err == nil {
		for idx := range workflowsContents {
			if workflowsContents[idx].Type == "file" && strings.HasSuffix(workflowsContents[idx].Name, ".yml") {
				files = append(files, CIActionFile{Path: ".github/workflows/" + workflowsContents[idx].Name})
			}
		}
	}

	scriptsContents, err := fetchGitHubDirectoryContents("ci-action", "scripts")
	if err == nil {
		for idx := range scriptsContents {
			if scriptsContents[idx].Type == "file" && strings.HasSuffix(scriptsContents[idx].Name, ".sh") {
				files = append(files, CIActionFile{Path: "scripts/" + scriptsContents[idx].Name})
			}
		}
	}

	actionURL := fmt.Sprintf("%s/repos/%s/ci-action/contents/action.yml", githubAPIBase, orgName)
	req, err := http.NewRequest("GET", actionURL, nil)
	if err == nil {
		req.Header.Set("Accept", "application/vnd.github.v3+json")
		if githubToken != "" {
			req.Header.Set("Authorization", "Bearer "+githubToken)
		}
		resp, err := httpClient.Do(req)
		if err == nil && resp.StatusCode == http.StatusOK {
			resp.Body.Close()
			files = append(files, CIActionFile{Path: "action.yml"})
		} else if resp != nil {
			resp.Body.Close()
		}
	}

	sort.Slice(files, func(i, j int) bool {
		return files[i].Path < files[j].Path
	})

	uniqueFiles := make([]CIActionFile, 0)
	seen := make(map[string]bool)
	for idx := range files {
		if !seen[files[idx].Path] {
			uniqueFiles = append(uniqueFiles, files[idx])
			seen[files[idx].Path] = true
		}
	}

	return uniqueFiles, nil
}

func getAllCIActionFiles(ciActionPath string) []CIActionFile {
	var files []CIActionFile

	if _, err := os.Stat(filepath.Join(ciActionPath, "action.yml")); err == nil {
		files = append(files, CIActionFile{Path: "action.yml"})
	}

	workflowsPath := filepath.Join(ciActionPath, ".github", "workflows")
	if entries, err := os.ReadDir(workflowsPath); err == nil {
		for _, entry := range entries {
			if !entry.IsDir() && strings.HasSuffix(entry.Name(), ".yml") {
				files = append(files, CIActionFile{Path: ".github/workflows/" + entry.Name()})
			}
		}
	}

	scriptsPath := filepath.Join(ciActionPath, "scripts")
	if entries, err := os.ReadDir(scriptsPath); err == nil {
		for _, entry := range entries {
			if !entry.IsDir() && strings.HasSuffix(entry.Name(), ".sh") {
				files = append(files, CIActionFile{Path: "scripts/" + entry.Name()})
			}
		}
	}

	sort.Slice(files, func(i, j int) bool {
		return files[i].Path < files[j].Path
	})

	return files
}

func extractUsagesFromLine(line, repoName, relPath string) []Usage {
	var usages []Usage

	if matches := usesWorkflowRegex.FindStringSubmatch(line); matches != nil {
		workflowPath := matches[1]
		usages = append(usages, Usage{
			CIActionFile: workflowPath,
			RepoName:     repoName,
			RepoFile:     relPath,
		})
	}

	if matches := usesActionRegex.FindStringSubmatch(line); matches != nil {
		if !usesWorkflowRegex.MatchString(line) {
			usages = append(usages, Usage{
				CIActionFile: "action.yml",
				RepoName:     repoName,
				RepoFile:     relPath,
			})
		}
	}

	if matches := curlScriptRegex.FindStringSubmatch(line); matches != nil {
		scriptName := matches[2]
		usages = append(usages, Usage{
			CIActionFile: "scripts/" + scriptName,
			RepoName:     repoName,
			RepoFile:     relPath,
		})
	} else if matches := curlAnyRegex.FindStringSubmatch(line); matches != nil {
		if !strings.Contains(line, "/scripts/") {
			filePath := matches[2]
			usages = append(usages, Usage{
				CIActionFile: filePath,
				RepoName:     repoName,
				RepoFile:     relPath,
			})
		}
	}

	return usages
}
