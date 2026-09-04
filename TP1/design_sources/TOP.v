`timescale 1ns / 1ps

module TOP
  #(
    parameter NB_DATA = 8,
    parameter NB_OP   = 6
  )
  (
    input  wire                 clk,
    input  wire                 rst,
    input  wire [NB_DATA-1:0]   switches, // Compartidos para A, B y OP
    input  wire                 btn_a,    // Enable para guardar A
    input  wire                 btn_b,    // Enable para guardar B
    input  wire                 btn_op,   // Enable para guardar OP
    output wire [NB_DATA-1:0]   leds      // Muestra el resultado de la ALU
  );

  // Cables de interconexión
  wire [NB_DATA-1:0] data_a;
  wire [NB_DATA-1:0] data_b;
  wire [NB_OP-1:0]   op_code;

  // Registro para Entrada A
  Register #(.NB(NB_DATA)) reg_A (
    .clk(clk),
    .rst(rst),
    .enable(btn_a),
    .d(switches),
    .q(data_a)
  );

  // Registro para Entrada B
  Register #(.NB(NB_DATA)) reg_B (
    .clk(clk),
    .rst(rst),
    .enable(btn_b),
    .d(switches),
    .q(data_b)
  );

  // Registro para Operación OP
  Register #(.NB(NB_OP)) reg_OP (
    .clk(clk),
    .rst(rst),
    .enable(btn_op),
    .d(switches[NB_OP-1:0]),
    .q(op_code)
  );

  // Instancia de la ALU combinacional
  ALU #(
    .NB_DATA(NB_DATA),
    .NB_OP(NB_OP)
  ) alu_inst (
    .A(data_a),
    .B(data_b),
    .OP(op_code),
    .RES(leds)
  );

endmodule
