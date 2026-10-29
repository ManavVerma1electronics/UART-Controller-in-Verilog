// UART receiver: 8N1, samples each bit in the middle of the bit period
module uart_rx #(
    parameter CLKS_PER_BIT = 434
)(
    input  wire       clk,
    input  wire       rst,
    input  wire       rx,             // serial input
    output reg  [7:0] rx_data,
    output reg        rx_valid,       // 1-clock pulse when rx_data is valid
    output reg        frame_error     // stop bit was not 1
);
    localparam IDLE = 2'd0, START = 2'd1, DATA = 2'd2, STOP = 2'd3;

    // 2-flop synchronizer (rx is asynchronous to clk)
    reg rx_ff1, rx_ff2;
    always @(posedge clk) begin
        rx_ff1 <= rx;
        rx_ff2 <= rx_ff1;
    end

    reg [1:0]  state;
    reg [15:0] clk_cnt;
    reg [2:0]  bit_idx;
    reg [7:0]  shreg;

    always @(posedge clk) begin
        if (rst) begin
            state       <= IDLE;
            clk_cnt     <= 0;
            bit_idx     <= 0;
            shreg       <= 8'd0;
            rx_data     <= 8'd0;
            rx_valid    <= 1'b0;
            frame_error <= 1'b0;
        end else begin
            rx_valid <= 1'b0;
            case (state)
                IDLE: begin
                    clk_cnt <= 0;
                    bit_idx <= 0;
                    if (rx_ff2 == 1'b0) state <= START;   // falling edge = start bit
                end
                START: begin
                    // wait to the middle of the start bit and confirm it is still low
                    if (clk_cnt == (CLKS_PER_BIT-1)/2) begin
                        clk_cnt <= 0;
                        if (rx_ff2 == 1'b0) state <= DATA;
                        else                state <= IDLE;   // glitch
                    end else clk_cnt <= clk_cnt + 1;
                end
                DATA: begin
                    if (clk_cnt == CLKS_PER_BIT-1) begin
                        clk_cnt        <= 0;
                        shreg[bit_idx] <= rx_ff2;            // sample mid-bit, LSB first
                        if (bit_idx == 3'd7) state <= STOP;
                        else bit_idx <= bit_idx + 1;
                    end else clk_cnt <= clk_cnt + 1;
                end
                STOP: begin
                    if (clk_cnt == CLKS_PER_BIT-1) begin
                        clk_cnt     <= 0;
                        rx_data     <= shreg;
                        rx_valid    <= 1'b1;
                        frame_error <= (rx_ff2 != 1'b1);
                        state       <= IDLE;
                    end else clk_cnt <= clk_cnt + 1;
                end
            endcase
        end
    end
endmodule
