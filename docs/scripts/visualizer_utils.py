#!/usr/bin/env python3
"""
Shared utilities for CI-Action visualizers.
"""

import csv
from pathlib import Path
from typing import Dict, List, Tuple


def read_csv_data(input_file: Path) -> List[Dict]:
    """Read usage data from CSV file."""
    with open(input_file, 'r', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        usages = []
        for row in reader:
            # Convert empty string to None for source_url
            source_url = row['source_url'] if row['source_url'] else None
            usages.append({
                'ci_action_file': row['ci_action_file'],
                'source_url': source_url
            })
    return usages


def parse_github_url(url: str) -> Tuple[str, str, str]:
    """
    Parse GitHub URL and extract components.
    
    Args:
        url: GitHub URL in format https://github.com/{owner}/{repo}/blob/{branch}/{file}#L{line}
    
    Returns:
        Tuple of (repo_name, file_path, line_number)
        line_number will be empty string if not present
    """
    parts = url.split('/')
    repo_name = parts[4]
    file_part = '/'.join(parts[7:]).split('#')[0]
    line_number = url.split('#L')[1] if '#L' in url else ''
    return repo_name, file_part, line_number


def format_display_name(repo_name: str, file_path: str, line_number: str = '') -> str:
    """
    Format a display name for a file reference.
    
    Args:
        repo_name: Repository name
        file_path: File path (will strip .github/workflows/ prefix)
        line_number: Optional line number
    
    Returns:
        Formatted display name like "repo: file:line" or "repo: file"
    """
    # Strip .github/workflows/ prefix for display
    display_file = file_path.replace('.github/workflows/', '', 1)
    
    if line_number:
        return f"{repo_name}: {display_file}:{line_number}"
    return f"{repo_name}: {display_file}"


class NodeIdGenerator:
    """Generate unique node IDs for graph visualization."""
    
    def __init__(self, prefix: str = 'F'):
        self.prefix = prefix
        self.counter = 0
        self.node_map = {}
    
    def get_id(self, label: str) -> str:
        """Get or create a node ID for the given label."""
        if label in self.node_map:
            return self.node_map[label]
        self.counter += 1
        node_id = f"{self.prefix}{self.counter}"
        self.node_map[label] = node_id
        return node_id

