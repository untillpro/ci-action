package types

// CIActionFile represents a file in the ci-action repository
type CIActionFile struct {
	Path string `json:"path"`
}

// Usage represents a usage of a ci-action file in a repository
type Usage struct {
	CIActionFile string `json:"ci_action_file"`
	RepoName     string `json:"repo_name"`
	RepoFile     string `json:"repo_file"`
}

// CollectedData contains all collected ci-action files and their usages
type CollectedData struct {
	AllCIActionFiles []CIActionFile `json:"all_ci_action_files"`
	Usages           []Usage        `json:"usages"`
}

