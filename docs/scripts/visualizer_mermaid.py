#!/usr/bin/env python3
"""
CI-Action Mermaid Visualizer

Reads the JSON data and generates a Mermaid graph visualization.
"""

import json
import sys
from pathlib import Path
from typing import Dict, List


def generate_incoming_calls(all_files: List[Dict], usage_map: Dict[str, List[Dict]]) -> str:
    """Generate incoming calls section showing which repos call each ci-action file."""
    lines = []
    lines.append("## Incoming calls\n\n")
    lines.append("Files in ci-action repository that are called by other repositories:\n\n")

    # Create sorted list of ci-action files that have usages
    files_with_usages = []
    for ci_file in all_files:
        file_path = ci_file['path']
        if file_path in usage_map:
            files_with_usages.append({
                'file_path': file_path,
                'usages': usage_map[file_path]
            })

    # Sort files alphabetically
    files_with_usages.sort(key=lambda x: x['file_path'])

    # Generate the list
    for file_with_usage in files_with_usages:
        file_path = file_with_usage['file_path']
        lines.append(f"- [{file_path}](https://github.com/untillpro/ci-action/blob/main/{file_path})\n")

        # Group usages by repo and file
        callers = []
        for usage in file_with_usage['usages']:
            callers.append({
                'repo_name': usage['repo_name'],
                'repo_file': usage['repo_file'],
                'repo_owner': usage['repo_owner'],
                'repo_branch': usage['repo_branch'],
                'line_number': usage.get('line_number')
            })

        # Sort callers alphabetically
        callers.sort(key=lambda x: (x['repo_name'], x['repo_file'], x['line_number'] or 0))

        # Write callers
        for caller in callers:
            repo_owner = caller['repo_owner']
            repo_branch = caller['repo_branch'] or 'main'
            line_number = caller['line_number']

            # Strip .github/workflows/ prefix for display
            display_file_name = caller['repo_file'].replace('.github/workflows/', '', 1)

            # Build the link with line number if available
            if line_number:
                link = f"https://github.com/{repo_owner}/{caller['repo_name']}/blob/{repo_branch}/{caller['repo_file']}#L{line_number}"
                lines.append(f"  - [{caller['repo_name']}: {display_file_name}:{line_number}]({link})\n")
            else:
                link = f"https://github.com/{repo_owner}/{caller['repo_name']}/blob/{repo_branch}/{caller['repo_file']}"
                lines.append(f"  - [{caller['repo_name']}: {display_file_name}]({link})\n")

    return ''.join(lines)


def generate_outgoing_calls(all_files: List[Dict], usage_map: Dict[str, List[Dict]]) -> str:
    """Generate outgoing calls section showing which ci-action files each repo calls."""
    lines = []
    lines.append("## Outgoing calls\n\n")
    lines.append("Files in all repositories that call ci-action files:\n\n")

    # Build map: calling file -> list of ci-action files it calls with details
    calling_files = {}

    for ci_file_path, usages in usage_map.items():
        for usage in usages:
            key = f"{usage['repo_name']}/{usage['repo_file']}"

            if key not in calling_files:
                calling_files[key] = {
                    'repo_name': usage['repo_name'],
                    'repo_file': usage['repo_file'],
                    'repo_owner': usage['repo_owner'],
                    'repo_branch': usage['repo_branch'],
                    'calls': []
                }
            calling_files[key]['calls'].append({
                'ci_file': ci_file_path,
                'line_number': usage.get('line_number')
            })

    # Create sorted list of calling files
    files_with_calls = []
    for info in calling_files.values():
        # Sort calls by ci_file and line_number
        call_list = sorted(info['calls'], key=lambda x: (x['ci_file'], x['line_number'] or 0))
        files_with_calls.append({
            'repo_name': info['repo_name'],
            'repo_file': info['repo_file'],
            'repo_owner': info['repo_owner'],
            'repo_branch': info['repo_branch'],
            'calls': call_list
        })

    # Sort files alphabetically by repo name, then by file name
    files_with_calls.sort(key=lambda x: (x['repo_name'], x['repo_file']))

    # Generate the list - group calls by unique line numbers
    for file_with_call in files_with_calls:
        repo_owner = file_with_call['repo_owner']
        repo_branch = file_with_call['repo_branch'] or 'main'
        repo_file = file_with_call['repo_file']

        # Strip .github/workflows/ prefix for display
        display_file_name = repo_file.replace('.github/workflows/', '', 1)

        # Group calls by line number to show each source line separately
        calls_by_line = {}
        for call in file_with_call['calls']:
            line_num = call['line_number']
            if line_num not in calls_by_line:
                calls_by_line[line_num] = []
            calls_by_line[line_num].append(call['ci_file'])

        # Sort by line number
        for line_number in sorted(calls_by_line.keys(), key=lambda x: x or 0):
            # Build the source file link with line number
            if line_number:
                source_link = f"https://github.com/{repo_owner}/{file_with_call['repo_name']}/blob/{repo_branch}/{repo_file}#L{line_number}"
                source_display = f"{file_with_call['repo_name']}: {display_file_name}:{line_number}"
            else:
                source_link = f"https://github.com/{repo_owner}/{file_with_call['repo_name']}/blob/{repo_branch}/{repo_file}"
                source_display = f"{file_with_call['repo_name']}: {display_file_name}"

            lines.append(f"- [{source_display}]({source_link})\n")

            # Write ci-action files called from this line
            for ci_file in calls_by_line[line_number]:
                lines.append(f"  - [{ci_file}](https://github.com/untillpro/ci-action/blob/main/{ci_file})\n")

    return ''.join(lines)


def generate_mermaid_graph(all_files: List[Dict], usages: List[Dict]) -> str:
    """Generate complete Mermaid graph visualization."""
    # Build usage map
    usage_map = {}
    for usage in usages:
        ci_file = usage['ci_action_file']
        if ci_file not in usage_map:
            usage_map[ci_file] = []
        usage_map[ci_file].append(usage)

    lines = []
    lines.append("# CI-Action Usage Graph\n\n")
    lines.append("This graph shows which repositories are using files from the ci-action repository.\n\n")

    # Generate Incoming calls section
    lines.append(generate_incoming_calls(all_files, usage_map))
    lines.append("\n")

    # Generate Outgoing calls section
    lines.append(generate_outgoing_calls(all_files, usage_map))
    lines.append("\n")

    # Generate Mermaid visualization
    lines.append("## Mermaid Visualization\n\n")
    lines.append("```mermaid\n")
    lines.append("graph LR\n")

    node_id = 0
    file_to_node = {}

    def get_node_id(file: str) -> str:
        nonlocal node_id
        if file in file_to_node:
            return file_to_node[file]
        node_id += 1
        node_id_str = f"F{node_id}"
        file_to_node[file] = node_id_str
        return node_id_str

    # Group left-side nodes by the ci-action files they call
    left_nodes_ordered = []
    left_nodes_seen = set()

    # Iterate through ci-action files and collect calling files in order
    for ci_file in all_files:
        ci_path = ci_file['path']
        if ci_path in usage_map:
            for usage in usage_map[ci_path]:
                key = f"{usage['repo_name']}/{usage['repo_file']}"
                if key not in left_nodes_seen:
                    left_nodes_seen.add(key)
                    left_nodes_ordered.append(key)

    # Define left-side nodes (calling files) in grouped order
    for node_key in left_nodes_ordered:
        node_id_str = get_node_id(node_key)
        lines.append(f'    {node_id_str}["{node_key}"]\n')

    # Define right-side nodes (ci-action files)
    for ci_file in all_files:
        ci_node_id = get_node_id(ci_file['path'])
        lines.append(f'    {ci_node_id}["{ci_file["path"]}"]\n')

    # Create edges
    for ci_file in all_files:
        ci_path = ci_file['path']
        ci_node_id = get_node_id(ci_path)

        if ci_path in usage_map:
            for usage in usage_map[ci_path]:
                target_key = f"{usage['repo_name']}/{usage['repo_file']}"
                target_node_id = get_node_id(target_key)
                lines.append(f"    {target_node_id} --> {ci_node_id}\n")

    lines.append("```\n")

    return ''.join(lines)


def main():
    """Main entry point."""
    if len(sys.argv) < 2:
        print(f"Usage: {sys.argv[0]} <input-json-file> [output-md-file]", file=sys.stderr)
        sys.exit(1)

    input_file = Path(sys.argv[1])
    output_file = Path(sys.argv[2]) if len(sys.argv) >= 3 else Path('ci-action-usages.md')

    # Read input JSON
    try:
        with open(input_file, 'r') as f:
            data = json.load(f)
    except Exception as e:
        print(f"Error reading input file: {e}", file=sys.stderr)
        sys.exit(1)

    all_files = data.get('all_ci_action_files', [])
    usages = data.get('usages', [])

    # Generate Mermaid graph
    mermaid_graph = generate_mermaid_graph(all_files, usages)

    # Write output
    try:
        with open(output_file, 'w') as f:
            f.write(mermaid_graph)
    except Exception as e:
        print(f"Error writing mermaid file: {e}", file=sys.stderr)
        sys.exit(1)

    print(f"Generated mermaid graph with {len(all_files)} files and {len(usages)} usages. Written to {output_file}")


if __name__ == '__main__':
    main()

