#!/usr/bin/env bash
set -Eeuo pipefail

export GOWORK=off

if [ $# -eq 0 ]; then
    echo "Usage: $0 <output-format>"
    echo ""
    echo "Available formats:"
    echo "  mermaid    - Generate Mermaid graph"
    echo "  graphviz   - Generate Graphviz DOT format (and SVG if dot is available)"
    echo ""
    echo "Example: $0 mermaid"
    echo "Example: $0 graphviz"
    exit 1
fi

FORMAT=$1

case $FORMAT in
    mermaid)
        echo "Generating Mermaid graph visualization..."

        python visualizer_mermaid.py ci-action-data.csv ci-action-usages.md

        echo ""
        echo "Visualization complete!"
        echo "Output: ci-action-usages.md"
        ;;
    graphviz)
        echo "Generating Graphviz DOT visualization..."
        python visualizer_graphviz.py ci-action-data.csv ci-action-usages.dot
        echo ""
        if command -v dot &> /dev/null; then
            echo "Rendering SVG with Graphviz..."
            dot -Tsvg ci-action-usages.dot -o ci-action-usages.svg
            echo "SVG rendered successfully!"
            echo "Output: ci-action-usages.svg"
        else
            echo "Graphviz 'dot' command not found. Install Graphviz to render the graph."
            echo "Output: ci-action-usages.dot (DOT format only)"
        fi
        ;;
    *)
        echo "Error: Unknown format '$FORMAT'"
        echo "Available formats: mermaid, graphviz"
        exit 1
        ;;
esac

