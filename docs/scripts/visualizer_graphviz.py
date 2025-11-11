#!/usr/bin/env python3
"""
CI-Action Graphviz Visualizer

Reads the CSV data and generates a Graphviz DOT format visualization.
"""

import sys
from pathlib import Path
from typing import Dict, List

from visualizer_utils import read_csv_data, parse_github_url, NodeIdGenerator


def escape_label(s: str) -> str:
    """Escape special characters for Graphviz labels."""
    s = s.replace('\\', '\\\\')
    s = s.replace('"', '\\"')
    return s


def generate_graphviz_dot(usages: List[Dict]) -> str:
    """Generate Graphviz DOT format graph."""
    # Build usage map and collect all ci-action files
    usage_map = {}
    all_ci_files = set()
    for usage in usages:
        ci_file = usage['ci_action_file']
        all_ci_files.add(ci_file)
        if ci_file not in usage_map:
            usage_map[ci_file] = []
        usage_map[ci_file].append(usage)

    lines = []
    lines.append("digraph CIActionUsage {\n")
    lines.append("  rankdir=LR;\n")
    lines.append("  node [shape=box, style=rounded];\n")
    lines.append("  \n")

    # CI-Action files cluster
    lines.append("  // CI-Action files\n")
    lines.append("  subgraph cluster_ci_action {\n")
    lines.append('    label="ci-action repository";\n')
    lines.append("    style=filled;\n")
    lines.append("    color=lightblue;\n")
    lines.append("    \n")

    # Use shared node ID generator
    node_gen = NodeIdGenerator('n')

    # Define ci-action file nodes
    for ci_file in sorted(all_ci_files):
        node_id_str = node_gen.get_id(ci_file)
        label = escape_label(ci_file)

        # Check if file is used (has at least one non-null source_url)
        is_used = False
        if ci_file in usage_map:
            for usage in usage_map[ci_file]:
                if usage['source_url'] is not None:
                    is_used = True
                    break

        if not is_used:
            # Unused files - red
            lines.append(f'    {node_id_str} [label="{label}", color=red, style="rounded,filled", fillcolor=lightcoral];\n')
        else:
            # Used files - yellow
            lines.append(f'    {node_id_str} [label="{label}", style="rounded,filled", fillcolor=lightyellow];\n')

    lines.append("  }\n")
    lines.append("  \n")

    # Build repo map from URLs (skip null source_url)
    repo_map = {}
    for usage in usages:
        source_url = usage['source_url']
        # Skip null source_url (unused files)
        if source_url is None:
            continue
        # Extract repo name and file from URL
        repo_name, file_path = parse_github_url(source_url)
        target_key = f"{repo_name}/{file_path}"
        if repo_name not in repo_map:
            repo_map[repo_name] = []
        repo_map[repo_name].append(target_key)

    # Repository files clusters
    lines.append("  // Repository files\n")
    cluster_id = 0
    for repo_name in sorted(repo_map.keys()):
        cluster_id += 1
        lines.append(f"  subgraph cluster_repo_{cluster_id} {{\n")
        lines.append(f'    label="{escape_label(repo_name)}";\n')
        lines.append("    style=filled;\n")
        lines.append("    color=lightgreen;\n")
        lines.append("    \n")

        # Get unique files for this repo
        seen = set()
        for usage in usages:
            source_url = usage['source_url']
            # Skip null source_url (unused files)
            if source_url is None:
                continue
            # Extract repo name and file from URL
            url_repo_name, file_path = parse_github_url(source_url)

            if url_repo_name == repo_name:
                target_key = f"{repo_name}/{file_path}"
                if target_key not in seen:
                    node_id_str = node_gen.get_id(target_key)
                    label = escape_label(file_path)
                    lines.append(f'    {node_id_str} [label="{label}", style="rounded,filled", fillcolor=white];\n')
                    seen.add(target_key)

        lines.append("  }\n")
        lines.append("  \n")

    # Create edges
    lines.append("  // Edges\n")
    for usage in usages:
        source_url = usage['source_url']
        # Skip null source_url (unused files)
        if source_url is None:
            continue
        ci_action_id = node_gen.get_id(usage['ci_action_file'])
        # Extract repo name and file from URL
        repo_name, file_path = parse_github_url(source_url)
        target_key = f"{repo_name}/{file_path}"
        repo_file_id = node_gen.get_id(target_key)
        lines.append(f"  {repo_file_id} -> {ci_action_id};\n")

    lines.append("}\n")

    return ''.join(lines)


def main():
    """Main entry point."""
    if len(sys.argv) < 2:
        print(f"Usage: {sys.argv[0]} <input-csv-file> [output-dot-file]", file=sys.stderr)
        sys.exit(1)

    input_file = Path(sys.argv[1])
    output_file = Path(sys.argv[2]) if len(sys.argv) >= 3 else Path('ci-action-usages.dot')

    # Read input CSV
    try:
        usages = read_csv_data(input_file)
    except Exception as e:
        print(f"Error reading input file: {e}", file=sys.stderr)
        sys.exit(1)

    # Generate Graphviz DOT
    dot_graph = generate_graphviz_dot(usages)

    # Write output
    try:
        with open(output_file, 'w') as f:
            f.write(dot_graph)
    except Exception as e:
        print(f"Error writing dot file: {e}", file=sys.stderr)
        sys.exit(1)

    # Count unique ci-action files
    ci_files = set(u['ci_action_file'] for u in usages)
    print(f"Generated graphviz DOT with {len(ci_files)} files and {len(usages)} usages. Written to {output_file}")
    print("\nTo render the graph, run:")
    print(f"  dot -Tpng {output_file} -o ci-action-usages.png")
    print(f"  dot -Tsvg {output_file} -o ci-action-usages.svg")


if __name__ == '__main__':
    main()

