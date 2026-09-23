`timescale 1ns / 1ps

module tb_baud_rate_gen;

    localparam CLK_FREQ  = 100_000_000;
    localparam BAUD_RATE = 19200;
    localparam EXPECTED  = (CLK_FREQ + BAUD_RATE * 8) / (BAUD_RATE * 16);  // 326
    localparam N_TICKS   = 20;   // Cantidad de intervalos a medir

    reg  clk;
    reg  reset;
    wire tick;

    integer ciclos;     // Ciclos contados desde el último tick
    integer medidos;    // Intervalos medidos
    integer errores;

    // Módulo bajo prueba
    baud_rate_gen #(
        .CLK_FREQ (CLK_FREQ),
        .BAUD_RATE(BAUD_RATE)
    ) dut (
        .clk  (clk),
        .reset(reset),
        .tick (tick)
    );

    // Clock de 100 MHz
    initial clk = 0;
    always #5 clk = ~clk;

    initial begin
        ciclos  = 0;
        medidos = 0;
        errores = 0;

        reset = 1;
        repeat (5) @(posedge clk);
        reset = 0;

        // Esperamos el primer tick para empezar a medir desde ahí
        @(posedge clk);
        while (!tick) @(posedge clk);

        while (medidos < N_TICKS) begin
            @(posedge clk);
            ciclos = ciclos + 1;
            if (tick) begin
                medidos = medidos + 1;
                if (ciclos != EXPECTED) begin
                    $display("ERROR: intervalo %0d = %0d ciclos (esperado %0d)", medidos, ciclos, EXPECTED);
                    errores = errores + 1;
                end
                else
                    $display("OK: intervalo %0d = %0d ciclos", medidos, ciclos);
                ciclos = 0;
            end
        end

        if (errores == 0)
            $display("BAUD RATE GEN OK: %0d intervalos de %0d ciclos", N_TICKS, EXPECTED);
        else
            $display("BAUD RATE GEN FALLO: %0d errores", errores);

        $finish;
    end

endmodule