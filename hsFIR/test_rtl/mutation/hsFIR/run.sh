    #!/bin/bash

    # Source the OSS CAD Suite environment
    echo "        [MCY] Sourcing OSS CAD Suite environment..."
    source ~/oss-cad-suite/environment
    if [ $? -ne 0 ]; then
        echo "        [MCY] FAIL: Failed to source OSS CAD Suite environment. Exiting script."
        exit 1
    fi

    # Copy original rtl here
    cp ${PWD}/../../../rtl/hsFIR.v .

    # Append `define MCY after `timescale 1ps/1ps
    sed '/\`timescale 1ps\/1ps/a \
    \`define MCY' hsFIR.v > hsFIR_temp.v

    #replace the orginal testbench file with the temp file.
    mv hsFIR_temp.v hsFIR.v

    # Copy hsFIR here
    cp ${PWD}/../../simulation/icarus/hsFIR/testbench.v .

    # Append `define MCY after `timescale 1ps/1ps
    sed '/\`timescale 1ps\/1ps/a \
    \`define MCY' testbench.v > testbench_temp.v

    #replace the orginal testbench file with the temp file.
    mv testbench_temp.v testbench.v

    # Move create scripts to $SCRIPTS
    cp ${PWD}/../create_mutated_eq.sh ~/oss-cad-suite/share/mcy/scripts/
    cp ${PWD}/../create_mutated_fm.sh ~/oss-cad-suite/share/mcy/scripts/

    # Generate mutations using mcy
    echo "        [MCY] Generating mutations using mcy..."
    mcy purge; mcy init; mcy run -j8
    if [ $? -ne 0 ]; then
        echo "        [MCY] FAIL: mcy process failed. Exiting script."
        exit 1
    fi
    echo "        [MCY] PASS: mcy process passed"

    # Remove testbench
    rm testbench.v

    # Copy original rtl here
    rm hsFIR.v