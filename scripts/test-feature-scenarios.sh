#!/usr/bin/env bash

# Description: Run the autogenerated tests for the specified features

set -e
current_dir=$(pwd)
trap 'cd "$current_dir"' EXIT
cd "$(dirname "$0")/.." || exit 1

# Run the tests
if [ -n "$2" ]; then
  devcontainer features test --skip-autogenerated --skip-duplicated --log-level trace --features "$1" --filter "$2" | tee /dev/null
elif [ -n "$1" ]; then
  devcontainer features test --skip-autogenerated --skip-duplicated --log-level trace --features "$@" | tee /dev/null
else
  devcontainer features test --skip-autogenerated --skip-duplicated --log-level trace | tee /dev/null
fi
