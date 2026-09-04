`timescale 1ns / 1ps

module ALU
  #(
    parameter NB_DATA = 8,
    parameter NB_OP   = 6
  )
  (
    input  wire [NB_DATA-1:0] A,
    input  wire [NB_DATA-1:0] B,
    input  wire [NB_OP-1:0]   OP,
    output wire [NB_DATA-1:0] RES
  );

  localparam ADD    = 6'b100000;
  localparam SUB    = 6'b100010;
  localparam AND_OP = 6'b100100;
  localparam OR_OP  = 6'b100101;
  localparam XOR_OP = 6'b100110;
  localparam SRA    = 6'b000011;
  localparam SRL    = 6'b000010;
  localparam NOR_OP = 6'b100111;

  reg [NB_DATA-1:0] resultado;

  always @(*) begin
    case (OP)
      ADD:     resultado = A + B;
      SUB:     resultado = A - B;
      AND_OP:  resultado = A & B;
      OR_OP:   resultado = A | B;
      XOR_OP:  resultado = A ^ B;
      SRA:     resultado = $signed(A) >>> B;
      SRL:     resultado = A >> B;
      NOR_OP:  resultado = ~(A | B);
      default: resultado = {NB_DATA{1'b0}};
    endcase
  end

  assign RES = resultado;

endmodule
