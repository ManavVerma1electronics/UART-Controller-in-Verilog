`timescale 1ns/1ps
// Loopback test: TX output is wired to RX input.
// Small CLKS_PER_BIT keeps the simulation fast; logic is identical for 434.
module tb_uart;
    localparam CLKS_PER_BIT = 16;
    localparam CLK_PERIOD   = 20;       // 50 MHz

    reg        clk = 0, rst = 1;
    reg        tx_start = 0;
    reg  [7:0] tx_data  = 0;
    wire       serial;
    wire       tx_busy, tx_done, rx_valid, frame_error;
    wire [7:0] rx_data;

    uart_top #(.CLKS_PER_BIT(CLKS_PER_BIT)) dut (
        .clk(clk), .rst(rst),
        .tx_start(tx_start), .tx_data(tx_data),
        .tx(serial), .tx_busy(tx_busy), .tx_done(tx_done),
        .rx(serial), .rx_data(rx_data), .rx_valid(rx_valid),
        .frame_error(frame_error));

    always #(CLK_PERIOD/2) clk = ~clk;

    integer errors = 0, sent = 0, i;
    reg [7:0] expected;
    reg [7:0] test_bytes [0:9];

    task send_byte(input [7:0] b);
        begin
            expected = b;
            @(posedge clk); tx_data <= b; tx_start <= 1'b1;
            @(posedge clk); tx_start <= 1'b0;
            wait (rx_valid);                 // wait for receiver
            @(posedge clk);
            sent = sent + 1;
            if (rx_data !== expected || frame_error) begin
                errors = errors + 1;
                $display("FAIL: sent 0x%02h, got 0x%02h, frame_error=%b", expected, rx_data, frame_error);
            end else
                $display("PASS: sent 0x%02h, got 0x%02h", expected, rx_data);
            wait (!tx_busy);
            repeat (4) @(posedge clk);
        end
    endtask

    initial begin
        $dumpfile("uart.vcd");
        $dumpvars(0, tb_uart);
        test_bytes[0]=8'h00; test_bytes[1]=8'hFF; test_bytes[2]=8'hA5; test_bytes[3]=8'h5A;
        test_bytes[4]=8'h01; test_bytes[5]=8'h80; test_bytes[6]=8'h41; test_bytes[7]=8'h42;
        test_bytes[8]=8'h7E; test_bytes[9]=8'hC3;
        repeat (5) @(posedge clk);
        rst = 0;
        repeat (5) @(posedge clk);

        for (i = 0; i < 10; i = i + 1) send_byte(test_bytes[i]);

        $display("----------------------------------------");
        $display("UART loopback: %0d bytes sent, %0d errors", sent, errors);
        if (errors == 0) $display("RESULT: PASS"); else $display("RESULT: FAIL");
        $finish;
    end

    // watchdog
    initial begin
        #5_000_000;
        $display("TIMEOUT");
        $finish;
    end
endmodule
