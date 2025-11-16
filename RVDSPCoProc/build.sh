# /bin/bash
source ~/oss-cad-suite/environment; python3 assemble.py test.s program.hex; python3 hex_to_verilog_init.py program.hex imem_init.v