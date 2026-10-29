// UART transmitter: 8 data bits, no parity, 1 stop bit (8N1)
module uart_tx #(
    parameter CLKS_PER_BIT = 434      // clk_freq / baud_rate (50 MHz / 115200)
)(
    input  wire       clk,
    input  wire       rst,            // synchronous, active high
    input  wire       tx_start,       // pulse for 1 clock to send tx_data
    input  wire [7:0] tx_data,
    output reg        tx,             // serial output (idles high)
    output reg        tx_busy,
    output reg        tx_done         // 1-clock pulse when frame is finished
);
    localparam IDLE = 2'd0, START = 2'd1, DATA = 2'd2, STOP = 2'd3;

    reg [1:0]  state;
    reg [15:0] clk_cnt;
    reg [2:0]  bit_idx;
    reg [7:0]  shreg;

    always @(posedge clk) begin
        if (rst) begin
            state   <= IDLE;
            tx      <= 1'b1;
            tx_busy <= 1'b0;
            tx_done <= 1'b0;
            clk_cnt <= 0;
            bit_idx <= 0;
            shreg   <= 8'd0;
        end else begin
            tx_done <= 1'b0;
            case (state)
                IDLE: begin
                    tx      <= 1'b1;
                    clk_cnt <= 0;
                    bit_idx <= 0;
                    if (tx_start) begin
                        shreg   <= tx_data;
                        tx_busy <= 1'b1;
                        state   <= START;
                    end
                end
                START: begin
                    tx <= 1'b0;                       // start bit
                    if (clk_cnt == CLKS_PER_BIT-1) begin
                        clk_cnt <= 0;
                        state   <= DATA;
                    end else clk_cnt <= clk_cnt + 1;
                end
                DATA: begin
                    tx <= shreg[bit_idx];             // LSB first
                    if (clk_cnt == CLKS_PER_BIT-1) begin
                        clk_cnt <= 0;
                        if (bit_idx == 3'd7) state <= STOP;
                        else bit_idx <= bit_idx + 1;
                    end else clk_cnt <= clk_cnt + 1;
                end
                STOP: begin
                    tx <= 1'b1;                       // stop bit
                    if (clk_cnt == CLKS_PER_BIT-1) begin
                        clk_cnt <= 0;
                        tx_done <= 1'b1;
                        tx_busy <= 1'b0;
                        state   <= IDLE;
                    end else clk_cnt <= clk_cnt + 1;
                end
            endcase
        end
    end
endmodule
