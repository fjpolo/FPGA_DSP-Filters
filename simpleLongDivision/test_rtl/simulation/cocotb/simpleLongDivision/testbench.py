## Project F Library - simpleLongDivision Test Bench (cocotb)
## (C)2023 Will Green, open source software released under the MIT License
## Learn more at https://projectf.io/verilog-lib/

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer

async def reset_dut(dut):
    await RisingEdge(dut.i_clk)
    dut.i_rst.value = 0
    await RisingEdge(dut.i_clk)
    dut.i_rst.value = 1
    await RisingEdge(dut.i_clk)
    dut.i_rst.value = 0
    await RisingEdge(dut.i_clk)

async def test_dut_divide(dut, i_operandA, i_operandB, log=True):
    cocotb.start_soon(Clock(dut.i_clk, 1, units="ns").start())
    await reset_dut(dut)

    await RisingEdge(dut.i_clk)
    dut.i_operandA.value = i_operandA
    dut.i_operandB.value = i_operandB
    dut.i_start.value = 1

    await RisingEdge(dut.i_clk)
    dut.i_start.value = 0

    # wait for calculation to complete
    while not dut.o_done.value:
        await RisingEdge(dut.i_clk)

    # model division
    model_c = i_operandA // i_operandB
    model_r = i_operandA % i_operandB

    # log numberical signals (note width formatting of model answers)
    if (log):
        dut._log.info('dut i_operandA:     ' + dut.i_operandA.value.binstr)
        dut._log.info('dut i_operandB:     ' + dut.i_operandB.value.binstr)
        dut._log.info('dut o_result_quotient:   ' + dut.o_result_quotient.value.binstr)
        dut._log.info('dut o_result_remainder:   ' + dut.o_result_remainder.value.binstr)
        dut._log.info('model o_result_quotient: ' + '{0:08b}'.format(model_c))
        dut._log.info('model o_result_remainder: ' + '{0:08b}'.format(model_r))

    # check output signals on 'o_done'
    assert dut.o_busy.value == 0, "o_busy is not 0!"
    assert dut.o_done.value == 1, "o_done is not 1!"
    assert dut.o_valid.value == 1, "o_valid is not 1!"
    assert dut.o_dbz.value == 0, "o_dbz is not 0!"
    assert dut.o_result_quotient.value == model_c, "dut o_result_quotient doesn't match model o_result_quotient"
    assert dut.o_result_remainder.value == model_r, "dut o_result_remainder doesn't match model o_result_remainder"

    # check 'o_done' is high for one tick
    await RisingEdge(dut.i_clk)
    assert dut.o_done.value == 0, "o_done is not 0!"


# simple division tests (no remainder)
@cocotb.test()
async def simple_1(dut):
    """Test 1/1"""
    await test_dut_divide(dut=dut, i_operandA=1, i_operandB=1)

@cocotb.test()
async def simple_2(dut):
    """Test 0/2"""
    await test_dut_divide(dut=dut, i_operandA=0, i_operandB=2)

@cocotb.test()
async def simple_3(dut):
    """Test 6/2"""
    await test_dut_divide(dut=dut, i_operandA=6, i_operandB=2)

@cocotb.test()
async def simple_4(dut):
    """Test 15/3"""
    await test_dut_divide(dut=dut, i_operandA=15, i_operandB=3)

@cocotb.test()
async def simple_5(dut):
    """Test 15/5"""
    await test_dut_divide(dut=dut, i_operandA=15, i_operandB=5)


# remainder tests
@cocotb.test()
async def rem_1(dut):
    """Test 7/2"""
    await test_dut_divide(dut=dut, i_operandA=7, i_operandB=2)

@cocotb.test()
async def rem_2(dut):
    """Test 2/7"""
    await test_dut_divide(dut=dut, i_operandA=2, i_operandB=7)

@cocotb.test()
async def rem_3(dut):
    """Test 97/13"""
    await test_dut_divide(dut=dut, i_operandA=97, i_operandB=13)


# edge tests
@cocotb.test()
async def edge_1(dut):
    """Test 255/16"""
    await test_dut_divide(dut=dut, i_operandA=255, i_operandB=16)

@cocotb.test()
async def edge_2(dut):
    """Test 255/255"""
    await test_dut_divide(dut=dut, i_operandA=255, i_operandB=255)

@cocotb.test()
async def edge_3(dut):
    """Test 255/254"""
    await test_dut_divide(dut=dut, i_operandA=255, i_operandB=254)

@cocotb.test()
async def edge_4(dut):
    """Test 254/255"""
    await test_dut_divide(dut=dut, i_operandA=254, i_operandB=255)


# divide by zero tests
@cocotb.test()
async def dbz_1(dut):
    """Test 2/0 [div by zero]"""
    cocotb.start_soon(Clock(dut.i_clk, 1, units="ns").start())
    await reset_dut(dut)

    await RisingEdge(dut.i_clk)
    i_operandA = 2
    i_operandB = 0
    dut.i_operandA.value = i_operandA
    dut.i_operandB.value = i_operandB
    dut.i_start.value = 1

    await RisingEdge(dut.i_clk)
    dut.i_start.value = 0
    # wait for calculation to complete
    while not dut.o_done.value:
        await RisingEdge(dut.i_clk)

    # check output signals on 'o_done'
    assert dut.o_busy.value == 0, "o_busy is not 0!"
    assert dut.o_done.value == 1, "o_done is not 1!"
    assert dut.o_valid.value == 0, "o_valid is not 0!"
    assert dut.o_dbz.value == 1, "o_dbz is not 1!"

    # check 'o_done' is high for one tick
    await RisingEdge(dut.i_clk)
    assert dut.o_done.value == 0, "o_done is not 0!"

@cocotb.test()
async def dbz_2(dut):
    """Test 251/13 [after o_dbz]"""
    await test_dut_divide(dut=dut, i_operandA=251, i_operandB=13)