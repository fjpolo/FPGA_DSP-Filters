#!/bin/bash

# Source the OSS CAD Suite environment
echo "    [MUTATION] Sourcing OSS CAD Suite environment..."
source ~/oss-cad-suite/environment
if [ $? -ne 0 ]; then
    echo "[MUTATION] FAIL: Failed to source OSS CAD Suite environment. Exiting script."
    exit 1
fi

# Loop through all directories in the current directory
for dir in */; do
  # Check if the directory contains a run.sh script
  if [ -f "$dir/run.sh" ]; then
    echo "    [MUTATION] Running $dir/run.sh..."

    # Run the run.sh script and capture the exit status
    (cd "$dir" && ./run.sh >> average_filter_log.txt)
    exit_status=$?

    # Check if the script failed
    if [ $exit_status -ne 0 ]; then
      echo "    [MUTATION] FAIL: average_filter failed!"
      echo "    [MUTATION] Please check ${PWD}/${dir}/average_filter_log.txt!"
    else
      echo "    [MUTATION] average_filter passed!"
      echo "    [MUTATION] Don't forget to check ${PWD}/${dir}/average_filter_log.txt!"
    fi
  else
    echo "    [MUTATION] No run.sh found in $dir"
  fi
done