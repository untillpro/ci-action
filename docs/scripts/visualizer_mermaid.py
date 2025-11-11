#!/usr/bin/env python3
"""
CI-Action Mermaid Visualizer

Reads the CSV data and generates a Mermaid graph visualization.
"""

import sys
from pathlib import Path
from typing import Dict, List

from visualizer_utils import read_csv_data, parse_github_url, format_display_name, NodeIdGenerator


def generate_incoming_calls(usage_map: Dict[str, List[Dict]]) -> str:
    """Generate incoming calls section showing which repos call each ci-action file."""
    lines = []
    lines.append("## Incoming calls\n\n")
    lines.append("Files in ci-action repository that are called by other repositories:\n\n")

    # Create sorted list of ci-action files that have usages (exclude null source_url)
    files_with_usages = []
    for file_path, usages in usage_map.items():
        # Filter out usages with null source_url
        real_usages = [u for u in usages if u['source_url'] is not None]
        if real_usages:
            files_with_usages.append({
                'file_path': file_path,
                'usages': real_usages
            })

    # Sort files alphabetically
    files_with_usages.sort(key=lambda x: x['file_path'])

    # Generate the list
    for file_with_usage in files_with_usages:
        file_path = file_with_usage['file_path']
        lines.append(f"- [{file_path}](https://github.com/untillpro/ci-action/blob/main/{file_path})\n")

        # Collect and sort callers by URL
        callers = []
        for usage in file_with_usage['usages']:
            callers.append(usage['source_url'])

        # Sort callers alphabetically
        callers.sort()

        # Write callers
        for source_url in callers:
            repo_name, file_path, line_number = parse_github_url(source_url)
            display_text = format_display_name(repo_name, file_path, line_number)
            lines.append(f"  - [{display_text}]({source_url})\n")

    return ''.join(lines)


def generate_outgoing_calls(usage_map: Dict[str, List[Dict]]) -> str:
    """Generate outgoing calls section showing which ci-action files each repo calls."""
    lines = []
    lines.append("## Outgoing calls\n\n")
    lines.append("Files in all repositories that call ci-action files:\n\n")

    # Build map: source_url -> list of ci-action files called from that line
    calls_by_source = {}

    for ci_file_path, usages in usage_map.items():
        for usage in usages:
            source_url = usage['source_url']
            # Skip entries with null source_url (unused files)
            if source_url is None:
                continue
            if source_url not in calls_by_source:
                calls_by_source[source_url] = []
            calls_by_source[source_url].append(ci_file_path)

    # Sort by source URL
    sorted_sources = sorted(calls_by_source.keys())

    # Generate the list
    for source_url in sorted_sources:
        repo_name, file_path, line_number = parse_github_url(source_url)
        display_text = format_display_name(repo_name, file_path, line_number)
        lines.append(f"- [{display_text}]({source_url})\n")

        # Write ci-action files called from this line
        for ci_file in sorted(calls_by_source[source_url]):
            lines.append(f"  - [{ci_file}](https://github.com/untillpro/ci-action/blob/main/{ci_file})\n")

    return ''.join(lines)


def generate_mermaid_graph(usages: List[Dict]) -> str:
    """Generate complete Mermaid graph visualization."""
    # Build usage map
    usage_map = {}
    all_ci_files = set()
    for usage in usages:
        ci_file = usage['ci_action_file']
        all_ci_files.add(ci_file)
        if ci_file not in usage_map:
            usage_map[ci_file] = []
        usage_map[ci_file].append(usage)

    lines = []
    lines.append("# CI-Action Usage Graph\n\n")
    lines.append("This graph shows which repositories are using files from the ci-action repository.\n\n")

    # Generate Incoming calls section
    lines.append(generate_incoming_calls(usage_map))
    lines.append("\n")

    # Generate Outgoing calls section
    lines.append(generate_outgoing_calls(usage_map))
    lines.append("\n")

    # Generate Mermaid visualization
    lines.append("## Mermaid Visualization\n\n")
    lines.append("```mermaid\n")
    lines.append("graph LR\n")

    # Use shared node ID generator
    node_gen = NodeIdGenerator('F')

    # Group left-side nodes by the ci-action files they call
    left_nodes_ordered = []
    left_nodes_seen = set()

    # Iterate through ci-action files and collect calling files in order
    for ci_file in sorted(all_ci_files):
        if ci_file in usage_map:
            for usage in usage_map[ci_file]:
                source_url = usage['source_url']
                # Skip null source_url (unused files)
                if source_url is None:
                    continue
                # Extract repo/file from URL for node key
                repo_name, file_path, _ = parse_github_url(source_url)
                key = f"{repo_name}/{file_path}"
                if key not in left_nodes_seen:
                    left_nodes_seen.add(key)
                    left_nodes_ordered.append(key)

    # Define left-side nodes (calling files) in grouped order
    for node_key in left_nodes_ordered:
        node_id_str = node_gen.get_id(node_key)
        lines.append(f'    {node_id_str}["{node_key}"]\n')

    # Define right-side nodes (ci-action files)
    for ci_file in sorted(all_ci_files):
        ci_node_id = node_gen.get_id(ci_file)
        lines.append(f'    {ci_node_id}["{ci_file}"]\n')

    # Create edges
    for ci_file in sorted(all_ci_files):
        ci_node_id = node_gen.get_id(ci_file)

        if ci_file in usage_map:
            for usage in usage_map[ci_file]:
                source_url = usage['source_url']
                # Skip null source_url (unused files)
                if source_url is None:
                    continue
                # Extract repo/file from URL for node key
                repo_name, file_path, _ = parse_github_url(source_url)
                target_key = f"{repo_name}/{file_path}"
                target_node_id = node_gen.get_id(target_key)
                lines.append(f"    {target_node_id} --> {ci_node_id}\n")

    lines.append("```\n")

    return ''.join(lines)


def main():
    """Main entry point."""
    if len(sys.argv) < 2:
        print(f"Usage: {sys.argv[0]} <input-csv-file> [output-md-file]", file=sys.stderr)
        sys.exit(1)

    input_file = Path(sys.argv[1])
    output_file = Path(sys.argv[2]) if len(sys.argv) >= 3 else Path('ci-action-usages.md')

    # Read input CSV
    try:
        usages = read_csv_data(input_file)
    except Exception as e:
        print(f"Error reading input file: {e}", file=sys.stderr)
        sys.exit(1)

    # Generate Mermaid graph
    mermaid_graph = generate_mermaid_graph(usages)

    # Write output
    try:
        with open(output_file, 'w') as f:
            f.write(mermaid_graph)
    except Exception as e:
        print(f"Error writing mermaid file: {e}", file=sys.stderr)
        sys.exit(1)

    # Count unique ci-action files
    ci_files = set(u['ci_action_file'] for u in usages)
    print(f"Generated mermaid graph with {len(ci_files)} files and {len(usages)} usages. Written to {output_file}")


if __name__ == '__main__':
    main()

