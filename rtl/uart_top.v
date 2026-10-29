// Top level: one TX and one RX sharing the same baud setting
module uart_top #(
    parameter CLKS_PER_BIT = 434
)(
    input  wire       clk,
    input  wire       rst,
    input  wire       tx_start,
    input  wire [7:0] tx_data,
    output wire       tx,
    output wire       tx_busy,
    output wire       tx_done,
    input  wire       rx,
    output wire [7:0] rx_data,
    output wire       rx_valid,
    output wire       frame_error
);
    uart_tx #(.CLKS_PER_BIT(CLKS_PER_BIT)) u_tx (
        .clk(clk), .rst(rst), .tx_start(tx_start), .tx_data(tx_data),
        .tx(tx), .tx_busy(tx_busy), .tx_done(tx_done));

    uart_rx #(.CLKS_PER_BIT(CLKS_PER_BIT)) u_rx (
        .clk(clk), .rst(rst), .rx(rx),
        .rx_data(rx_data), .rx_valid(rx_valid), .frame_error(frame_error));
endmodule
