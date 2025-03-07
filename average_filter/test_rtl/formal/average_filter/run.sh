#!/bin/bash

# Source the OSS CAD Suite environment
echo "Sourcing OSS CAD Suite environment..."
source ~/oss-cad-suite/environment
if [ $? -ne 0 ]; then
    echo "Failed to source OSS CAD Suite environment. Exiting script."
    exit 1
fi

# Input files
ORIGINAL_FILE="${PWD}/../../../rtl/average_filter.v"
FORMAL_FILE="properties.v"
CONFIG_FILE="average_filter.sby"

# Generate a timestamp for the temporary file
TEMP_FILE="average_filter_formal.v"
echo -n > $TEMP_FILE

# Check if required files exist
echo "Checking if required files exist..."
for FILE in "$ORIGINAL_FILE" "$FORMAL_FILE"; do
    if [ ! -f "$FILE" ]; then
        echo "Error: File $FILE not found. Exiting script."
        exit 1
    fi
done

# Insert formal properties into the original master.v before `endmodule`
gsed "/endmodule/e cat $FORMAL_FILE" "$ORIGINAL_FILE" > "$TEMP_FILE"


# Verify the original master.v with formal properties
# Run SymbiYosys (sby) on the temporary file
echo "Verifying $ORIGINAL_FILE with formal properties..."
CONFIG_FILE="average_filter.sby"
sby -f $CONFIG_FILE

# Check if sby succeeded
if [ $? -ne 0 ]; then
    echo "sby failed for $ORIGINAL_FILE. Exiting script."
    rm $TEMP_FILE
    exit 1
fi

# Clean up the temporary file for the original master.v
rm $TEMP_FILE

