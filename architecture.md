# untillpro/ci-action Architecture

The untillpro/ci-action is a GitHub Action designed to provide continuous integration capabilities for Go and Node.js projects. Its architecture consists of several key components working together to validate code, run tests, and publish releases.

---

## Core Components

### Main Action Entry Point

- **[index.js](./index.js)**: The primary entry point that orchestrates the entire CI process
- Uses `@actions/core` and `@actions/github` libraries to interact with GitHub Actions

### Core Functionality Modules

- **[checkSources.js](./checkSources.js)**: Validates source files for copyright notices and other requirements
- **[common.js](./common.js)**: Provides utility functions, particularly for executing commands
- **[publish.js](./publish.js)**: Handles release publishing functionality
- **[rejectHiddenFolders.js](./rejectHiddenFolders.js)**: Enforces rules against hidden directories

### Shell Scripts Collection

The scripts directory contains numerous bash scripts that perform specific CI operations:

- Code linting (e.g., [gbash.sh](./scripts/gbash.sh))
- Vulnerability checking (e.g., [vulncheck.sh](./scripts/vulncheck.sh), [execgovuln.sh](./scripts/execgovuln.sh))
- Testing (e.g., [test_subfolders.sh](./scripts/test_subfolders.sh))
- Release management (e.g., [git-release.sh](./scripts/git-release.sh))
- Configuration updates (e.g., [updateConfig.sh](./scripts/updateConfig.sh))

### Workflow Templates

The workflows directory contains reusable GitHub workflow templates:

- Language-specific workflows (e.g., [ci_reuse_go.yml](.github/workflows/ci_reuse_go.yml), [ci_reuse.yml](.github/workflows/ci_reuse.yml) for Node.js)
- Specialized workflows (e.g., [cp.yml](.github/workflows/cp.yml) for cherry-picking, [rc.yml](.github/workflows/rc.yml) for release candidates)

---

## `dist` folder

`dist` folder serves as the distribution or build output directory for the GitHub Action.

1. In the action.yml file, the entry point is specified as:
   ```yaml
   runs:
     using: 'node20'
     main: 'dist/index.js'
   ```
   This shows that the GitHub Action is configured to use the compiled JavaScript from the dist directory.

2. The package.json file contains a script to build the distribution:
   ```json
   "scripts": {
     "package": "ncc build index.js"
   }
   ```
   This uses `@vercel/ncc` (listed in devDependencies) to bundle the code into a single file.

3. The .gitignore file has `dist/*` entries (although commented out in one place), indicating it's a generated directory.

4. The .eslintignore file specifically excludes the dist directory from linting.

The dist folder is indeed built automatically as part of the development workflow. When contributors run `npm run package`, it compiles and bundles the action's JavaScript code into a single file in the dist folder. This bundling process is essential for GitHub Actions as it packages all dependencies, making the action self-contained and ready for execution in GitHub's environment.

When the action is used in workflows, GitHub executes the compiled code from this dist folder rather than running the source files directly.


---

## Execution Flow

1. **Input Processing**: Action reads inputs like `ignore`, `organization`, and `token`
2. **Environment Setup**: Configures necessary environment variables
3. **Source Validation**:
   - Rejects hidden folders
   - Checks copyright notices in source files
   - Validates go.mod for local replaces
4. **Language Detection**: Determines if the project is Go or Node.js
5. **Build & Test**:
   - For Go: Runs `go build`, `go test`, linters, and vulnerability checks
   - For Node.js: Runs `npm install`, `npm run build`, and `npm test`
6. **Optional Publishing**: If configured, creates GitHub releases

---

## Key Features

1. **Language Support**: Handles both Go and Node.js projects
2. **Private Repository Access**: Configures authentication for private dependencies
3. **Code Quality Enforcement**:
   - Copyright verification
   - Go linting via golangci-lint
   - Vulnerability scanning
4. **Release Automation**: Creates and manages GitHub releases
5. **Reusable Workflows**: Provides templates for common CI scenarios

The action is designed to be highly configurable through input parameters while providing sensible defaults, making it adaptable to various project requirements within the untillpro ecosystem.