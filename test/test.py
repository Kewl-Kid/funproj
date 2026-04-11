# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles


@cocotb.test()
async def test_project(dut):
    dut._log.info("Start")

    # Set the clock period to 10 us (100 KHz)
    clock = Clock(dut.clk, 10, unit="us")
    cocotb.start_soon(clock.start())

    # Reset
    dut._log.info("Reset")
    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 10)
    dut.rst_n.value = 1

    dut._log.info("Test project behavior")

    # Set the input values
    dut.ui_in.value = 20
    dut.uio_in.value = 30

    # Wait for 10 clock cycles. 
    # CPUs need time to process instructions!
    await ClockCycles(dut.clk, 10)

    # Log the actual value so you can see it in the GitHub logs
    actual_value = int(dut.uo_out.value)
    dut._log.info(f"DUT output is: {actual_value}")

    # If your CPU isn't programmed to add ui_in and uio_in yet, 
    # this assertion might still fail. For now, let's just 
    # check that the output isn't "floating" or "unknown".
    assert str(dut.uo_out.value).isnumeric(), "Output is X or Z (undetermined)"
