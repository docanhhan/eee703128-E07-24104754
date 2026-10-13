import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles


async def khoi_dong(dut):
    clock = Clock(dut.clk, 10, "us")
    cocotb.start_soon(clock.start())
    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 5)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 2)


async def nap(dut, d, mode):
    dut.ui_in.value = d
    dut.uio_in.value = (mode << 1) | 1
    await ClockCycles(dut.clk, 1)
    dut.uio_in.value = 0
    await ClockCycles(dut.clk, 1)
    return int(dut.uo_out.value)


def dao_bit(d):
    return int(f"{d:08b}"[::-1], 2)


def dao_nibble(d):
    return ((d & 0x0F) << 4) | (d >> 4)


@cocotb.test()
async def test_ca_de_bai(dut):
    await khoi_dong(dut)
    assert await nap(dut, 0x01, 0) == 0x80
    assert await nap(dut, 0xFF, 0) == 0xFF
    assert await nap(dut, 0xA5, 0) == 0xA5
    assert await nap(dut, 0x01, 1) == 0x10
    assert await nap(dut, 0xFF, 1) == 0xFF
    assert await nap(dut, 0xA5, 1) == 0x5A


@cocotb.test()
async def test_giu_gia_tri(dut):
    await khoi_dong(dut)
    assert await nap(dut, 0x01, 0) == 0x80
    dut.ui_in.value = 0x3C
    await ClockCycles(dut.clk, 3)
    assert int(dut.uo_out.value) == 0x80


@cocotb.test()
async def test_quet_256(dut):
    await khoi_dong(dut)
    for d in range(256):
        assert await nap(dut, d, 0) == dao_bit(d)
        assert await nap(dut, d, 1) == dao_nibble(d)
