# UART Controller in Verilog

A UART (8N1) transmitter and receiver written in Verilog, verified with a self-checking loopback testbench.

## Features
- 8 data bits, no parity, 1 stop bit, LSB first
- Parameterised baud rate: `CLKS_PER_BIT = clk_freq / baud` (default 434 = 50 MHz / 115200)
- Receiver samples in the middle of each bit and uses a 2-flop synchronizer on the `rx` input
- Frame error flag if the stop bit is not high

## Frame format
```
idle(1) | start(0) | D0 D1 D2 D3 D4 D5 D6 D7 | stop(1)
```

## Project structure
- `rtl/uart_tx.v` - transmitter (IDLE, START, DATA, STOP state machine)
- `rtl/uart_rx.v` - receiver (IDLE, START, DATA, STOP state machine)
- `rtl/uart_top.v` - top level with one TX and one RX
- `tb/tb_uart.v` - loopback testbench (TX wired to RX, 10 test bytes)

## Run
```
iverilog -o uart_sim rtl/uart_tx.v rtl/uart_rx.v rtl/uart_top.v tb/tb_uart.v
vvp uart_sim
gtkwave uart.vcd
```

## Results
10 bytes sent through loopback, 0 errors.

![Waveform](waveform.png)

## Tools
Icarus Verilog, GTKWave
