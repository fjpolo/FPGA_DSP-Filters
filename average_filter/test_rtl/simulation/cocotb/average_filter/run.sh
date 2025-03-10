# !/bin/bash

# Source the OSS CAD Suite environment
echo "        [COCOTB]Sourcing OSS CAD Suite environment..."
source ~/oss-cad-suite/environment
if [ $? -ne 0 ]; then
    echo "        [COCOTB] Failed to source OSS CAD Suite environment. Exiting script."
    exit 1
fi

# Copy original average_filter.v
cp ${PWD}/../../../../rtl/average_filter.v .

# Call cocoTB
python3 testrunner_icarus.py
if [ $? -ne 0 ]; then
    echo "        [COCOTB][ICARUS] Simulation failed. Exiting script."
    exit 1
fi
python3 testrunner_verilator.py
if [ $? -ne 0 ]; then
    echo "        [COCOTB][VERILATOR] Simulation failed. Exiting script."
    exit 1
fi

# Remove average_filter.-v
rm average_filter.v