import os
from pathlib import Path

from cocotb.runner import get_runner


def test_my_design_runner():
    sim = os.getenv("SIM", "icarus")

    proj_path = Path(__file__).resolve().parent

    sources = [proj_path / "simpleFixedPointSignedLongDivision.v"]

    runner = get_runner(sim)
    runner.build(
        sources=sources,
        hdl_toplevel="simpleFixedPointSignedLongDivision",
    )

    runner.test(hdl_toplevel="simpleFixedPointSignedLongDivision", test_module="testbench,")


if __name__ == "__main__":
    test_my_design_runner()