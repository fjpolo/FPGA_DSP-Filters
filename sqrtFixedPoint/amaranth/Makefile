# Makefile for cocotb simulation

# Simulator selection (uncomment one)
# SIM ?= icarus
# SIM ?= ghdl
SIM ?= verilator
# SIM ?= vcs
# SIM ?= xcelium
# SIM ?= questa

TOPLEVEL_LANG ?= verilog
TOPLEVEL      ?= top # This must match the module name generated by Amaranth

# Tell cocotb where to find your test functions
MODULE := test_sqrtFixedPoint

# Suppress the WIDTHEXPAND warning
VERILATOR_FLAGS += -Wno-WIDTHEXPAND

# Path to your Amaranth-generated Verilog file
VERILOG_SOURCES += sqrtFixedPoint.v

# Path to your cocotb testbench file
PYTHON_SOURCES += test_sqrtFixedPoint.py

# Include cocotb's standard Makefile rules
include $(shell cocotb-config --makefiles)/Makefile.sim

# Rule to generate Verilog before running cocotb simulation
# This ensures that sqrtFixedPoint.v is up-to-date
all: simulate

simulate: sqrtFixedPoint.v
	$(MAKE) -C $(shell pwd) sim

sqrtFixedPoint.v:
	python sqrtFixedPoint.py # This will execute the "Conversion" section of your script

.PHONY: clean_all
clean_all:
	rm -rf results.xml sim_build *.vcd sqrtFixedPoint.v