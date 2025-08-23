#!/bin/bash
set -euo pipefail

main() {
  {{__selection__}} || {
    echo "Error: Command failed" >&2
    exit 1
  }
}

main "$@"
