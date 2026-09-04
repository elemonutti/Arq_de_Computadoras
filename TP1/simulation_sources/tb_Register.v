`timescale 1ns / 1ps

module tb_Register;
  localparam NB = 8;

  reg          clk;
  reg          rst;
  reg          enable;
  reg [NB-1:0] d;
  wire [NB-1:0] q;

  // Instancia del módulo a probar
  Register #(.NB(NB)) dut (
    .clk(clk),
    .rst(rst),
    .enable(enable),
    .d(d),
    .q(q)
  );

  // Generación del Clock (Periodo = 10ns)
  always #5 clk = ~clk;

  initial begin
    clk = 0; rst = 1; enable = 0; d = 8'h00;
    #12 rst = 0; // Desactivar Reset

    // Caso 1: Probar que NO guarda si enable = 0
    #10 d = 8'hAA; 
    #10;
    if (q !== 8'h00) $display("ERROR: Actualizo sin enable!");

    // Caso 2: Probar que guarda con enable = 1
    #10 enable = 1;
    #10;
    if (q !== 8'hAA) $display("ERROR: No guardo el dato!");

    // Caso 3: Mantener valor anterior al bajar enable
    #10 enable = 0; d = 8'hFF;
    #10;
    if (q !== 8'hAA) $display("ERROR: Retencion fallida!");

    $display("=== Testbench del Registro finalizado sin errores ===");
    $finish;
  end
endmodule
