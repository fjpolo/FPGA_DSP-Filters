# !/bin/bash

# Test RTL
echo "[RTL] Testing..."
cd test_rtl/ && ./test_all_log.sh
if [ $? -ne 0 ]; then
    echo "[RTL] ERROR: Failed tests. Exiting script."
    exit 1
fi
echo "[RTL] PASS: Testing done!"