`timescale 1ns / 1ps

module tb_TOP;
  localparam NB_DATA = 8;
  localparam NB_OP   = 6;

  reg                 clk;
  reg                 rst;
  reg [NB_DATA-1:0]   switches;
  reg                 btn_a;
  reg                 btn_b;
  reg                 btn_op;
  wire [NB_DATA-1:0]  leds;

  // Instancia del sistema completo
  TOP #(
    .NB_DATA(NB_DATA),
    .NB_OP(NB_OP)
  ) dut (
    .clk(clk),
    .rst(rst),
    .switches(switches),
    .btn_a(btn_a),
    .btn_b(btn_b),
    .btn_op(btn_op),
    .leds(leds)
  );

  // Generador de reloj
  always #5 clk = ~clk;

  // Tarea que simula el estímulo de presionar un botón de la FPGA
  task pulsar_boton_a(input [NB_DATA-1:0] dato);
    begin
      switches = dato;
      #10 btn_a = 1;
      #10 btn_a = 0;
      #10;
    end
  endtask

  task pulsar_boton_b(input [NB_DATA-1:0] dato);
    begin
      switches = dato;
      #10 btn_b = 1;
      #10 btn_b = 0;
      #10;
    end
  endtask

  task pulsar_boton_op(input [NB_OP-1:0] op);
    begin
      switches = { {(NB_DATA-NB_OP){1'b0}}, op };
      #10 btn_op = 1;
      #10 btn_op = 0;
      #10;
    end
  endtask

  initial begin
    clk = 0; rst = 1;
    switches = 0; btn_a = 0; btn_b = 0; btn_op = 0;
    #20 rst = 0;

    // Estímulos de interacción estilo FPGA
    pulsar_boton_a(8'd15);        // A = 15
    pulsar_boton_b(8'd10);        // B = 10
    pulsar_boton_op(6'b100000);   // OP = ADD

    #20;
    if (leds === 8'd25) 
      $display("INTEGRACION OK: ADD 15 + 10 = %0d", leds);
    else 
      $display("INTEGRACION ERROR: Salida=%0d (Esperado 25)", leds);

    $finish;
  end
endmodule
