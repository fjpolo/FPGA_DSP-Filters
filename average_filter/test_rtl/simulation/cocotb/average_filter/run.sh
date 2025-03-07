# !/bin/bash

# Source the OSS CAD Suite environment
echo "[SIMULATION][COCOTB]Sourcing OSS CAD Suite environment..."
source ~/oss-cad-suite/environment
if [ $? -ne 0 ]; then
    echo "[SIMULATION][COCOTB] Failed to source OSS CAD Suite environment. Exiting script."
    exit 1
fi

# Copy original average_filter.v
cp ${PWD}/../../../../rtl/average_filter.v .

# Call cocoTB
python3 testrunner_icarus.py
if [ $? -ne 0 ]; then
    echo "[SIMULATION][COCOTB][ICARUS] Simulation failed. Exiting script."
    exit 1
fi
python3 testrunner_verilator.py
if [ $? -ne 0 ]; then
    echo "[SIMULATION][COCOTB][VERILATOR] Simulation failed. Exiting script."
    exit 1
fi

# Remove average_filter.-v
rm average_filter.v