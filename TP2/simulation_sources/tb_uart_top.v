`timescale 1ns / 1ps

// Testbench del sistema completo: simula a la PC.
// Envía A, B y OP por la línea serie y espera el resultado por la línea serie.
module tb_uart_top;

    localparam NB_DATA    = 8;
    localparam NB_OP      = 6;
    localparam CLK_FREQ   = 100_000_000;
    localparam BAUD_RATE  = 19200;
    localparam BIT_PERIOD = 1_000_000_000 / BAUD_RATE;  // Duración de un bit en ns (como la PC real)
    localparam N_RANDOM   = 2;                   // Pruebas aleatorias por operación

    localparam ADD    = 6'b100000;
    localparam SUB    = 6'b100010;
    localparam AND_OP = 6'b100100;
    localparam OR_OP  = 6'b100101;
    localparam XOR_OP = 6'b100110;
    localparam SRA    = 6'b000011;
    localparam SRL    = 6'b000010;
    localparam NOR_OP = 6'b100111;

    reg                clk;
    reg                reset;
    reg                rx;          // Lo que "manda la PC"
    wire               tx;          // Lo que "recibe la PC"
    wire [NB_DATA-1:0] leds;

    reg  [NB_OP-1:0]   ops [0:7];
    reg  [NB_DATA-1:0] a, b, recibido, esperado;
    integer i, j;
    integer pruebas;
    integer errores;

    uart_top #(
        .CLK_FREQ (CLK_FREQ),
        .BAUD_RATE(BAUD_RATE),
        .NB_DATA  (NB_DATA),
        .NB_OP    (NB_OP)
    ) dut (
        .clk  (clk),
        .reset(reset),
        .rx   (rx),
        .tx   (tx),
        .leds (leds)
    );

    // Clock de 100 MHz
    initial clk = 0;
    always #5 clk = ~clk;

    // La PC manda un byte: start (0), 8 bits LSB primero, stop (1)
    task pc_enviar(input [NB_DATA-1:0] dato);
        integer k;
        begin
            rx = 0;
            #(BIT_PERIOD);
            for (k = 0; k < NB_DATA; k = k + 1) begin
                rx = dato[k];
                #(BIT_PERIOD);
            end
            rx = 1;
            #(BIT_PERIOD);
        end
    endtask

    // La PC recibe un byte: espera el start y muestrea en la mitad de cada bit
    task pc_recibir(output [NB_DATA-1:0] dato);
        integer k;
        begin
            @(negedge tx);
            #(BIT_PERIOD / 2);                 // Mitad del bit de start
            for (k = 0; k < NB_DATA; k = k + 1) begin
                #(BIT_PERIOD);
                dato[k] = tx;
            end
            #(BIT_PERIOD);                     // Mitad del bit de stop
            if (tx !== 1'b1)
                $display("ERROR: stop bit invalido");
        end
    endtask

    // Modelo de referencia (mismo comportamiento que la ALU del TP1)
    function [NB_DATA-1:0] modelo(input [NB_DATA-1:0] x, input [NB_DATA-1:0] y, input [NB_OP-1:0] op);
        case (op)
            ADD:     modelo = x + y;
            SUB:     modelo = x - y;
            AND_OP:  modelo = x & y;
            OR_OP:   modelo = x | y;
            XOR_OP:  modelo = x ^ y;
            SRA:     modelo = $signed(x) >>> y;
            SRL:     modelo = x >> y;
            NOR_OP:  modelo = ~(x | y);
            default: modelo = 0;
        endcase
    endfunction

    // Una operación completa: manda A, B, OP y en paralelo espera la respuesta
    task probar(input [NB_DATA-1:0] x, input [NB_DATA-1:0] y, input [NB_OP-1:0] op);
        begin
            esperado = modelo(x, y, op);
            fork
                begin
                    pc_enviar(x);
                    pc_enviar(y);
                    pc_enviar({2'b00, op});
                end
                pc_recibir(recibido);
            join
            pruebas = pruebas + 1;
            if (recibido !== esperado) begin
                $display("ERROR: A=%h B=%h OP=%b -> recibido %h, esperado %h", x, y, op, recibido, esperado);
                errores = errores + 1;
            end
            else
                $display("OK: A=%h B=%h OP=%b -> %h (LEDs=%h)", x, y, op, recibido, leds);
            #(BIT_PERIOD);   // Pausa entre operaciones
        end
    endtask

    initial begin
        ops[0] = ADD;    ops[1] = SUB;    ops[2] = AND_OP; ops[3] = OR_OP;
        ops[4] = XOR_OP; ops[5] = SRA;    ops[6] = SRL;    ops[7] = NOR_OP;

        pruebas = 0;
        errores = 0;
        rx      = 1;      // Línea en reposo

        reset = 1;
        repeat (10) @(posedge clk);
        reset = 0;
        #(BIT_PERIOD);

        // Caso fijo, el mismo del TP1: 15 + 10 = 25
        probar(8'd15, 8'd10, ADD);

        // Shifts con cantidades chicas, para que el resultado no sea siempre 0
        probar(8'b1000_0000, 8'd3, SRA);   // Esperado 1111_0000
        probar(8'b1000_0000, 8'd3, SRL);   // Esperado 0001_0000

        // Aleatorios para todas las operaciones
        for (i = 0; i < 8; i = i + 1)
            for (j = 0; j < N_RANDOM; j = j + 1) begin
                a = $random;
                b = $random;
                probar(a, b, ops[i]);
            end

        if (errores == 0)
            $display("UART TOP OK: %0d operaciones sin errores", pruebas);
        else
            $display("UART TOP FALLO: %0d errores en %0d operaciones", errores, pruebas);

        $finish;
    end

endmodule