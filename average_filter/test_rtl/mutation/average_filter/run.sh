#!/bin/bash

# Source the OSS CAD Suite environment
echo "        [MCY] Sourcing OSS CAD Suite environment..."
source ~/oss-cad-suite/environment
if [ $? -ne 0 ]; then
    echo "        [MCY] Failed to source OSS CAD Suite environment. Exiting script."
    exit 1
fi

# Copy testbench here
cp ${PWD}/../../simulation/icarus/average_filter/testbench.v .

# Copy original rtl here
cp ${PWD}/../../../rtl/average_filter.v .

# Move create scripts to $SCRIPTS
cp ${PWD}/../create_mutated_eq.sh ~/oss-cad-suite/share/mcy/scripts/
cp ${PWD}/../create_mutated_fm.sh ~/oss-cad-suite/share/mcy/scripts/

# Generate mutations using mcy
echo "        [MCY] Generating mutations using mcy..."
mcy purge; mcy init; mcy run -j8

# Remove testbench
rm testbench.v

# Copy original rtl here
rm average_filter.v