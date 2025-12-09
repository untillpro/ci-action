#!/usr/bin/env python3
"""
CI-Action Usage Collector

Scans all non-archived repositories from GitHub and collects raw usage data.
"""

import csv
import json
import os
import re
import sys
import time
from pathlib import Path
from typing import Dict, List, Optional
from urllib.request import Request, urlopen
from urllib.error import HTTPError, URLError


# Regular expressions for detecting ci-action usage
USES_ACTION_REGEX = re.compile(r'uses:\s+untillpro/ci-action@(\S+)')
USES_WORKFLOW_REGEX = re.compile(r'uses:\s+untillpro/ci-action/(\.github/workflows/[^@]+)@(\S+)')
CURL_SCRIPT_REGEX = re.compile(r'https://raw\.githubusercontent\.com/untillpro/ci-action/(\S+?)/scripts/([^\s|]+)')
CURL_ANY_REGEX = re.compile(r'https://raw\.githubusercontent\.com/untillpro/ci-action/(\S+?)/([^\s|]+)')
# Match $GITHUB_ACTION_PATH/../scripts/script.sh pattern (with or without quotes)
ACTION_PATH_SCRIPT_REGEX = re.compile(r'\$GITHUB_ACTION_PATH/\.\./scripts/([^\s"\']+)')

# Constants
GITHUB_API_BASE = "https://api.github.com"
ORG_NAME = "untillpro"
REQUEST_TIMEOUT = 30

# Repositories to skip
SKIP_REPOS = {"untillpro/voedger"}

# Additional repositories to scan (outside untillpro org)
ADDITIONAL_REPOS = [
    {"name": "voedger", "owner": "voedger", "default_branch": "main"}
]


class GitHubClient:
    """GitHub API client with authentication and rate limiting."""

    def __init__(self, token: Optional[str] = None):
        self.token = token or os.getenv("GITHUB_TOKEN")

    def get(self, url: str) -> Dict:
        """Make GET request with error handling."""
        req = Request(url)
        req.add_header("Accept", "application/vnd.github.v3+json")
        if self.token:
            req.add_header("Authorization", f"Bearer {self.token}")

        try:
            with urlopen(req, timeout=REQUEST_TIMEOUT) as response:
                return {
                    'status_code': response.status,
                    'data': json.loads(response.read().decode('utf-8'))
                }
        except HTTPError as e:
            return {
                'status_code': e.code,
                'data': None
            }
        except URLError:
            return {
                'status_code': 0,
                'data': None
            }


def load_outdated_repos(filename: str) -> set:
    """Load list of outdated repositories to skip."""
    outdated = set()
    try:
        with open(filename, 'r') as f:
            for line in f:
                line = line.strip()
                if line and not line.startswith('#'):
                    outdated.add(line)
    except FileNotFoundError:
        pass
    return outdated


def fetch_non_archived_repos(client: GitHubClient) -> List[Dict]:
    """Fetch all non-archived repositories from the organization."""
    all_repos = []
    page = 1

    while True:
        url = f"{GITHUB_API_BASE}/orgs/{ORG_NAME}/repos?per_page=100&page={page}&type=all"
        response = client.get(url)

        if response['status_code'] != 200:
            raise Exception(f"GitHub API returned status {response['status_code']}")

        repos = response['data']
        if not repos:
            break

        for repo in repos:
            if not repo.get('archived', False):
                all_repos.append({
                    'name': repo['name'],
                    'owner': repo['owner']['login'],
                    'default_branch': repo.get('default_branch', 'main')
                })

        page += 1
        time.sleep(0.1)  # Rate limiting

    return all_repos


def fetch_github_directory_contents(client: GitHubClient, owner: str, repo_name: str, dir_path: str) -> Optional[List[Dict]]:
    """Fetch contents of a directory from GitHub."""
    url = f"{GITHUB_API_BASE}/repos/{owner}/{repo_name}/contents/{dir_path}"
    response = client.get(url)

    if response['status_code'] == 404:
        return None

    if response['status_code'] != 200:
        return None

    time.sleep(0.1)  # Rate limiting
    return response['data']


def extract_usages_from_line(line: str, repo_info: Dict, file_path: str, line_number: int) -> List[Dict]:
    """Extract ci-action usages from a single line of text."""
    usages = []

    # Build the source URL once
    source_url = f"https://github.com/{repo_info['owner']}/{repo_info['name']}/blob/{repo_info['default_branch'] or 'main'}/{file_path}#L{line_number}"

    # Check for workflow usage (most specific pattern first)
    workflow_match = USES_WORKFLOW_REGEX.search(line)
    if workflow_match:
        usages.append({
            'ci_action_file': workflow_match.group(1),
            'source_url': source_url
        })
    # Check for action usage (only if not a workflow usage)
    elif USES_ACTION_REGEX.search(line):
        usages.append({
            'ci_action_file': 'action.yml',
            'source_url': source_url
        })

    # Check for script curl usage
    script_match = CURL_SCRIPT_REGEX.search(line)
    if script_match:
        usages.append({
            'ci_action_file': f'scripts/{script_match.group(2)}',
            'source_url': source_url
        })
    # Check for any other curl usage (only if no script match)
    elif '/scripts/' not in line:
        any_match = CURL_ANY_REGEX.search(line)
        if any_match:
            usages.append({
                'ci_action_file': any_match.group(2),
                'source_url': source_url
            })

    # Check for $GITHUB_ACTION_PATH/../scripts/ usage
    action_path_match = ACTION_PATH_SCRIPT_REGEX.search(line)
    if action_path_match:
        usages.append({
            'ci_action_file': f'scripts/{action_path_match.group(1)}',
            'source_url': source_url
        })

    return usages


def scan_github_file(client: GitHubClient, repo_info: Dict, file_path: str, download_url: str) -> List[Dict]:
    """Scan a GitHub file for ci-action usages."""
    try:
        req = Request(download_url)
        with urlopen(req, timeout=REQUEST_TIMEOUT) as response:
            if response.status != 200:
                return []

            content = response.read().decode('utf-8')
            usages = []
            for line_number, line in enumerate(content.splitlines(), start=1):
                usages.extend(extract_usages_from_line(line, repo_info, file_path, line_number))

            time.sleep(0.05)  # Rate limiting
            return usages
    except Exception:
        return []


def scan_github_directory(client: GitHubClient, repo_info: Dict, dir_path: str) -> List[Dict]:
    """Recursively scan a GitHub directory for ci-action usages."""
    contents = fetch_github_directory_contents(client, repo_info['owner'], repo_info['name'], dir_path)
    if not contents:
        return []

    usages = []
    for item in contents:
        if item['type'] == 'file':
            # Skip markdown files
            if item['name'].endswith('.md'):
                continue
            file_usages = scan_github_file(client, repo_info, item['path'], item['download_url'])
            usages.extend(file_usages)
        elif item['type'] == 'dir':
            sub_usages = scan_github_directory(client, repo_info, item['path'])
            usages.extend(sub_usages)

    return usages


def scan_repository_from_github(client: GitHubClient, repo_info: Dict) -> List[Dict]:
    """Scan a repository for ci-action usages."""
    return scan_github_directory(client, repo_info, '.github')


def get_all_ci_action_files_from_github(client: GitHubClient) -> List[Dict]:
    """Get all ci-action files from the ci-action repository."""
    files = {}  # Use dict to automatically handle duplicates

    # Check for checkout-and-setup-go/action.yml
    url = f"{GITHUB_API_BASE}/repos/{ORG_NAME}/ci-action/contents/checkout-and-setup-go/action.yml"
    response = client.get(url)
    if response['status_code'] == 200:
        files['checkout-and-setup-go/action.yml'] = {'path': 'checkout-and-setup-go/action.yml'}

    # Get workflow files
    workflows = fetch_github_directory_contents(client, ORG_NAME, 'ci-action', '.github/workflows')
    if workflows:
        for item in workflows:
            if item['type'] == 'file' and item['name'].endswith('.yml'):
                path = f".github/workflows/{item['name']}"
                files[path] = {'path': path}

    # Get script files
    scripts = fetch_github_directory_contents(client, ORG_NAME, 'ci-action', 'scripts')
    if scripts:
        for item in scripts:
            if item['type'] == 'file' and item['name'].endswith('.sh'):
                path = f"scripts/{item['name']}"
                files[path] = {'path': path}

    # Return sorted list
    return sorted(files.values(), key=lambda x: x['path'])


def get_all_ci_action_files_local(ci_action_path: Path) -> List[Dict]:
    """Get all ci-action files from local ci-action repository."""
    files = []

    # Check for checkout-and-setup-go/action.yml
    if (ci_action_path / 'checkout-and-setup-go' / 'action.yml').exists():
        files.append({'path': 'checkout-and-setup-go/action.yml'})

    # Get workflow files
    workflows_path = ci_action_path / '.github' / 'workflows'
    if workflows_path.exists():
        for file in workflows_path.glob('*.yml'):
            files.append({'path': f'.github/workflows/{file.name}'})

    # Get script files
    scripts_path = ci_action_path / 'scripts'
    if scripts_path.exists():
        for file in scripts_path.glob('*.sh'):
            files.append({'path': f'scripts/{file.name}'})

    return sorted(files, key=lambda x: x['path'])


def scan_ci_action_internal_usages_local(ci_action_path: Path) -> List[Dict]:
    """Scan ci-action's own files for internal script usages."""
    usages = []
    repo_info = {'owner': ORG_NAME, 'name': 'ci-action', 'default_branch': 'main'}

    # Scan checkout-and-setup-go/action.yml
    action_file = ci_action_path / 'checkout-and-setup-go' / 'action.yml'
    if action_file.exists():
        content = action_file.read_text(encoding='utf-8')
        for line_number, line in enumerate(content.splitlines(), start=1):
            line_usages = extract_usages_from_line(line, repo_info, 'checkout-and-setup-go/action.yml', line_number)
            usages.extend(line_usages)

    return usages


def scan_ci_action_internal_usages_github(client: GitHubClient) -> List[Dict]:
    """Scan ci-action's own files for internal script usages from GitHub."""
    usages = []
    repo_info = {'owner': ORG_NAME, 'name': 'ci-action', 'default_branch': 'main'}

    # Scan checkout-and-setup-go/action.yml
    url = f"{GITHUB_API_BASE}/repos/{ORG_NAME}/ci-action/contents/checkout-and-setup-go/action.yml"
    response = client.get(url)
    if response['status_code'] == 200:
        import base64
        content = base64.b64decode(response['data']['content']).decode('utf-8')
        for line_number, line in enumerate(content.splitlines(), start=1):
            line_usages = extract_usages_from_line(line, repo_info, 'checkout-and-setup-go/action.yml', line_number)
            usages.extend(line_usages)

    return usages


def main():
    """Main entry point."""
    work_dir = Path.cwd()
    ci_action_path = work_dir.parent

    # Initialize GitHub client
    client = GitHubClient()

    # Get all ci-action files and scan for internal usages
    if (ci_action_path / 'checkout-and-setup-go' / 'action.yml').exists():
        print("Using local ci-action folder...")
        all_ci_action_files = get_all_ci_action_files_local(ci_action_path)
        internal_usages = scan_ci_action_internal_usages_local(ci_action_path)
    else:
        print("Local ci-action folder not found, fetching from GitHub...")
        all_ci_action_files = get_all_ci_action_files_from_github(client)
        internal_usages = scan_ci_action_internal_usages_github(client)

    # Load outdated repos
    outdated_repos_file = work_dir / 'outdated-repos.txt'
    outdated_repos = load_outdated_repos(str(outdated_repos_file))
    if outdated_repos:
        print(f"Loaded {len(outdated_repos)} outdated repositories to skip")

    # Fetch repositories
    print("Fetching non-archived repositories from GitHub...")
    repos = fetch_non_archived_repos(client)
    print(f"Found {len(repos)} non-archived repositories")

    # Scan repositories
    usages = list(internal_usages)  # Start with internal ci-action usages
    repos_with_usages = set()
    skipped_count = 0

    for idx, repo in enumerate(repos, 1):
        repo_name = repo['name']
        full_repo_name = f"{repo['owner']}/{repo_name}"

        if repo_name in outdated_repos or full_repo_name in outdated_repos:
            skipped_count += 1
            continue

        if full_repo_name in SKIP_REPOS:
            skipped_count += 1
            continue

        print(f"Scanning {full_repo_name} ({idx}/{len(repos)})...")

        try:
            repo_usages = scan_repository_from_github(client, repo)
            if repo_usages:
                usages.extend(repo_usages)
                repos_with_usages.add(full_repo_name)
        except Exception as e:
            print(f"Warning: Error scanning {full_repo_name}: {e}", file=sys.stderr)

    if skipped_count > 0:
        print(f"Skipped {skipped_count} outdated repositories")

    # Scan additional repositories
    for repo in ADDITIONAL_REPOS:
        full_repo_name = f"{repo['owner']}/{repo['name']}"
        print(f"Scanning additional repo {full_repo_name}...")
        try:
            repo_usages = scan_repository_from_github(client, repo)
            if repo_usages:
                usages.extend(repo_usages)
                repos_with_usages.add(full_repo_name)
        except Exception as e:
            print(f"Warning: Error scanning {full_repo_name}: {e}", file=sys.stderr)

    # Find unused ci-action files and add them to usages with source_url=null
    used_files = set()
    for usage in usages:
        used_files.add(usage['ci_action_file'])

    for ci_file in all_ci_action_files:
        if ci_file['path'] not in used_files:
            usages.append({
                'ci_action_file': ci_file['path'],
                'source_url': None
            })

    # Write CSV output
    output_file = work_dir / 'ci-action-data.csv'
    with open(output_file, 'w', newline='', encoding='utf-8') as f:
        writer = csv.DictWriter(f, fieldnames=['ci_action_file', 'source_url'])
        writer.writeheader()
        writer.writerows(usages)

    print(f"\nCollected {len(all_ci_action_files)} ci-action files and {len(usages)} usages from {len(repos_with_usages)} repositories")
    print("Data written to ci-action-data.csv")


if __name__ == '__main__':
    main()

