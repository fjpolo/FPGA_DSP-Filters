#!/bin/bash

# Define paths
TESTBENCH="testbench.v"
RTL_MODULE="${PWD}/../../../../rtl/average_filter.v"
OUTPUT="testbench"
WAVEFORM="dump.vcd"

# oss-cad-suite env
source ~/oss-cad-suite/environment

# Check if the RTL module exists
if [ ! -f "$RTL_MODULE" ]; then
  echo "Error: RTL module not found at $RTL_MODULE"
  exit 1
fi

# Compile the testbench and RTL module
echo "        [ICARUS] Compiling testbench and RTL module..."
iverilog -o "$OUTPUT" "$TESTBENCH" "$RTL_MODULE"

# Check if compilation was successful
if [ $? -ne 0 ]; then
  echo "        [ICARUS] Error: Compilation failed."
  exit 1
fi

# Run the simulation and generate waveform
echo "        [ICARUS] Running simulation and generating waveform..."
vvp "$OUTPUT" -lxt2

# Check if simulation was successful
if [ $? -ne 0 ]; then
  echo "        [ICARUS] Error: Simulation failed."
  exit 1
fi

# Rename the waveform file to the desired name
if [ -f "dump.vcd" ]; then
  mv "dump.vcd" "$WAVEFORM"
  echo "        [ICARUS] Waveform saved to $WAVEFORM"
else
  echo "        [ICARUS] Error: Waveform file not generated."
  exit 1
fi

echo "        [ICARUS] Simulation completed successfully."