#!/usr/bin/env python3
"""
CI-Action Graphviz Visualizer

Reads the JSON data and generates a Graphviz DOT format visualization.
"""

import json
import sys
from pathlib import Path
from typing import Dict, List


def escape_label(s: str) -> str:
    """Escape special characters for Graphviz labels."""
    s = s.replace('\\', '\\\\')
    s = s.replace('"', '\\"')
    return s


def generate_graphviz_dot(all_files: List[Dict], usages: List[Dict]) -> str:
    """Generate Graphviz DOT format graph."""
    # Build usage map
    usage_map = {}
    for usage in usages:
        ci_file = usage['ci_action_file']
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
    
    node_map = {}
    node_id = 0
    
    def get_node_id(label: str) -> str:
        nonlocal node_id
        if label in node_map:
            return node_map[label]
        node_id += 1
        node_id_str = f"n{node_id}"
        node_map[label] = node_id_str
        return node_id_str
    
    # Define ci-action file nodes
    for ci_file in all_files:
        file_path = ci_file['path']
        node_id_str = get_node_id(file_path)
        label = escape_label(file_path)
        
        if file_path not in usage_map:
            # Unused files - red
            lines.append(f'    {node_id_str} [label="{label}", color=red, style="rounded,filled", fillcolor=lightcoral];\n')
        else:
            # Used files - yellow
            lines.append(f'    {node_id_str} [label="{label}", style="rounded,filled", fillcolor=lightyellow];\n')
    
    lines.append("  }\n")
    lines.append("  \n")
    
    # Build repo map
    repo_map = {}
    for usage in usages:
        repo_name = usage['repo_name']
        target_key = f"{repo_name}/{usage['repo_file']}"
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
            if usage['repo_name'] == repo_name:
                target_key = f"{repo_name}/{usage['repo_file']}"
                if target_key not in seen:
                    node_id_str = get_node_id(target_key)
                    label = escape_label(usage['repo_file'])
                    lines.append(f'    {node_id_str} [label="{label}", style="rounded,filled", fillcolor=white];\n')
                    seen.add(target_key)
        
        lines.append("  }\n")
        lines.append("  \n")
    
    # Create edges
    lines.append("  // Edges\n")
    for usage in usages:
        ci_action_id = get_node_id(usage['ci_action_file'])
        target_key = f"{usage['repo_name']}/{usage['repo_file']}"
        repo_file_id = get_node_id(target_key)
        lines.append(f"  {repo_file_id} -> {ci_action_id};\n")
    
    lines.append("}\n")
    
    return ''.join(lines)


def main():
    """Main entry point."""
    if len(sys.argv) < 2:
        print(f"Usage: {sys.argv[0]} <input-json-file> [output-dot-file]", file=sys.stderr)
        sys.exit(1)
    
    input_file = Path(sys.argv[1])
    output_file = Path(sys.argv[2]) if len(sys.argv) >= 3 else Path('ci-action-usages.dot')
    
    # Read input JSON
    try:
        with open(input_file, 'r') as f:
            data = json.load(f)
    except Exception as e:
        print(f"Error reading input file: {e}", file=sys.stderr)
        sys.exit(1)
    
    all_files = data.get('all_ci_action_files', [])
    usages = data.get('usages', [])
    
    # Generate Graphviz DOT
    dot_graph = generate_graphviz_dot(all_files, usages)
    
    # Write output
    try:
        with open(output_file, 'w') as f:
            f.write(dot_graph)
    except Exception as e:
        print(f"Error writing dot file: {e}", file=sys.stderr)
        sys.exit(1)
    
    print(f"Generated graphviz DOT with {len(all_files)} files and {len(usages)} usages. Written to {output_file}")
    print("\nTo render the graph, run:")
    print(f"  dot -Tpng {output_file} -o ci-action-usages.png")
    print(f"  dot -Tsvg {output_file} -o ci-action-usages.svg")


if __name__ == '__main__':
    main()

