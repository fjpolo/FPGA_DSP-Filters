#!/bin/bash

# No sourcing of OSS CAD Suite environment as we're not using it.
echo "           [COCOTB] Using system-installed tools."

# Remove any LD_LIBRARY_PATH or LD_PRELOAD manipulations
# as they are no longer needed (and were causing conflicts).
unset LD_LIBRARY_PATH
unset LD_PRELOAD

# Ensure system tools are found by explicitly adding /usr/bin to PATH if necessary.
# Usually, /usr/bin is already in PATH by default, so this might not be needed.
# export PATH="/usr/bin:$PATH" # Uncomment if 'iverilog' or 'vvp' are not found

# Copy original simpleLongDivision.v
cp "${PWD}/../../../../rtl/simpleLongDivision.v" .

# Call cocoTB for Icarus
echo "         [COCOTB][ICARUS] Running testbench..."
# Explicitly use the system's python3.
# This will automatically find the system-installed iverilog and vvp.
/usr/bin/python3 testrunner_icarus.py
if [ $? -ne 0 ]; then
    echo "           [COCOTB][ICARUS] FAIL: Simulation failed. Exiting script."
    exit 1
fi
echo "         [COCOTB][ICARUS] PASS: CocoTB simulation passed!"

# Call cocoTB for Verilator (assuming you have verilator also installed via system package manager)
echo "         [COCOTB][VERILATOR] Running testbench..."
/usr/bin/python3 testrunner_verilator.py
if [ $? -ne 0 ]; then
    echo "           [COCOTB][VERILATOR] FAIL: Simulation failed. Exiting script."
    exit 1
fi
echo "         [COCOTB][VERILATOR] PASS: CocoTB simulation passed!"

# Remove simpleLongDivision.v
rm simpleLongDivision.v

echo "Simulation script finished."