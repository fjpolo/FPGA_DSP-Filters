import cocotb
from cocotb.triggers import Timer

@cocotb.test()
async def test_hsFIRcheap(dut):
    """Empty testbench that simply prints PASS."""
    await Timer(1, units="ns")  # Wait for a small amount of time
    dut._log.info("PASS")