`timescale 1ns / 1ps

module uart_top
#(
    parameter CLK_FREQ  = 100_000_000,
    parameter BAUD_RATE = 19200,
    parameter NB_DATA   = 8,
    parameter NB_OP     = 6
)
(
    input  wire               clk,     // Clock de 100 MHz
    input  wire               reset,   // Botón central (BTNC)
    input  wire               rx,      // Serie desde la PC
    output wire               tx,      // Serie hacia la PC
    output wire [NB_DATA-1:0] leds     // Último resultado
);

    // Cables internos
    wire               tick;
    wire [NB_DATA-1:0] rx_data;
    wire               rx_done;
    wire [NB_DATA-1:0] tx_data;
    wire               tx_start;
    wire               tx_done;
    wire [NB_DATA-1:0] alu_a;
    wire [NB_DATA-1:0] alu_b;
    wire [NB_OP-1:0]   alu_op;
    wire [NB_DATA-1:0] alu_result;

    baud_rate_gen #(
        .CLK_FREQ (CLK_FREQ),
        .BAUD_RATE(BAUD_RATE)
    ) u_baud (
        .clk  (clk),
        .reset(reset),
        .tick (tick)
    );

    uart_rx #(
        .NB_DATA(NB_DATA),
        .SB_TICK(16)
    ) u_rx (
        .clk         (clk),
        .reset       (reset),
        .rx          (rx),
        .s_tick      (tick),
        .rx_done_tick(rx_done),
        .dout        (rx_data)
    );

    uart_tx #(
        .NB_DATA(NB_DATA),
        .SB_TICK(16)
    ) u_tx (
        .clk         (clk),
        .reset       (reset),
        .tx_start    (tx_start),
        .s_tick      (tick),
        .din         (tx_data),
        .tx_done_tick(tx_done),
        .tx          (tx)
    );

    alu_interface #(
        .NB_DATA(NB_DATA),
        .NB_OP  (NB_OP)
    ) u_intf (
        .clk        (clk),
        .reset      (reset),
        .rx_data    (rx_data),
        .rx_done    (rx_done),
        .tx_data    (tx_data),
        .tx_start   (tx_start),
        .tx_done    (tx_done),
        .alu_a      (alu_a),
        .alu_b      (alu_b),
        .alu_op     (alu_op),
        .alu_result (alu_result),
        .last_result(leds)
    );

    // ALU del TP1, sin modificaciones
    ALU #(
        .NB_DATA(NB_DATA),
        .NB_OP  (NB_OP)
    ) u_alu (
        .A  (alu_a),
        .B  (alu_b),
        .OP (alu_op),
        .RES(alu_result)
    );

endmodule