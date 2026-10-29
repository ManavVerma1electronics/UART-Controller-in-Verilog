sim:
	iverilog -o uart_sim rtl/uart_tx.v rtl/uart_rx.v rtl/uart_top.v tb/tb_uart.v
	vvp uart_sim
wave:
	gtkwave uart.vcd
clean:
	rm -f uart_sim uart.vcd
