`timescale 1ns / 1ps

module tb_ALU;

  localparam NB_DATA = 8;
  localparam NB_OP   = 6;

  localparam ADD    = 6'b100000;
  localparam SUB    = 6'b100010;
  localparam AND_OP = 6'b100100;
  localparam OR_OP  = 6'b100101;
  localparam XOR_OP = 6'b100110;
  localparam SRA    = 6'b000011;
  localparam SRL    = 6'b000010;
  localparam NOR_OP = 6'b100111;

  reg  [NB_DATA-1:0] A, B;
  reg  [NB_OP-1:0]   OP;
  wire [NB_DATA-1:0] RES;

  integer i;
  integer errores = 0;
  integer total   = 0;
  reg [NB_DATA-1:0] esperado;

  ALU #(.NB_DATA(NB_DATA), .NB_OP(NB_OP)) dut (
    .A(A), .B(B), .OP(OP), .RES(RES)
  );

  function [NB_DATA-1:0] modelo_esperado;
    input [NB_DATA-1:0] a, b;
    input [NB_OP-1:0]   op;
    begin
      case (op)
        ADD:     modelo_esperado = a + b;
        SUB:     modelo_esperado = a - b;
        AND_OP:  modelo_esperado = a & b;
        OR_OP:   modelo_esperado = a | b;
        XOR_OP:  modelo_esperado = a ^ b;
        SRA:     modelo_esperado = $signed(a) >>> b;
        SRL:     modelo_esperado = a >> b;
        NOR_OP:  modelo_esperado = ~(a | b);
        default: modelo_esperado = {NB_DATA{1'b0}};
      endcase
    end
  endfunction

  task aplicar_y_chequear;
    input [NB_DATA-1:0] a_in, b_in;
    input [NB_OP-1:0]   op_in;
    begin
      A = a_in; B = b_in; OP = op_in;
      #10;
      esperado = modelo_esperado(a_in, b_in, op_in);
      total = total + 1;
      if (RES !== esperado) begin
        errores = errores + 1;
        $display("FALLO  #%0d | OP=%b A=%0d B=%0d -> RES=%0d (esperado=%0d)",
                   total, op_in, a_in, b_in, RES, esperado);
      end else begin
        $display("OK     #%0d | OP=%b A=%0d B=%0d -> RES=%0d",
                   total, op_in, a_in, b_in, RES);
      end
    end
  endtask

  reg [NB_OP-1:0] ops [0:7];

  initial begin
    $dumpfile("dump.vcd");
    $dumpvars(0, tb_ALU);

    ops[0]=ADD; ops[1]=SUB; ops[2]=AND_OP; ops[3]=OR_OP;
    ops[4]=XOR_OP; ops[5]=SRA; ops[6]=SRL; ops[7]=NOR_OP;

    $display("=== Empieza el testbench de la ALU ===");
    for (i = 0; i < 8; i = i + 1) begin
      aplicar_y_chequear($random, $random, ops[i]);
      aplicar_y_chequear($random, $random, ops[i]);
      aplicar_y_chequear($random, $random, ops[i]);
    end

    $display("=== Resumen ===");
    $display("Total de casos: %0d | Errores: %0d", total, errores);
    if (errores == 0) $display(">>> TODOS LOS TESTS PASARON <<<");
    else $display(">>> HAY %0d TESTS QUE FALLARON <<<", errores);

    $finish;
  end

endmodule
