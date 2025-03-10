#!/bin/bash
./test_all.sh | tee >(cat > test_log.txt)