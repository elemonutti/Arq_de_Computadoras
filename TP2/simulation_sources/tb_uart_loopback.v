`timescale 1ns / 1ps

// Loopback: la salida del Tx se conecta a la entrada del Rx.
// Se envían bytes y se verifica que el Rx reciba exactamente lo mismo.
module tb_uart_loopback;

    localparam NB_DATA = 8;
    localparam N_BYTES = 10;

    reg                clk;
    reg                reset;
    reg                tx_start;
    reg  [NB_DATA-1:0] tx_data;
    wire               tick;
    wire               serial;       // Cable que une Tx con Rx
    wire               tx_done;
    wire               rx_done;
    wire [NB_DATA-1:0] rx_data;

    integer i;
    integer errores;

    baud_rate_gen #(
        .CLK_FREQ (100_000_000),
        .BAUD_RATE(19200)
    ) u_baud (
        .clk  (clk),
        .reset(reset),
        .tick (tick)
    );

    uart_tx #(.NB_DATA(NB_DATA), .SB_TICK(16)) u_tx (
        .clk         (clk),
        .reset       (reset),
        .tx_start    (tx_start),
        .s_tick      (tick),
        .din         (tx_data),
        .tx_done_tick(tx_done),
        .tx          (serial)
    );

    uart_rx #(.NB_DATA(NB_DATA), .SB_TICK(16)) u_rx (
        .clk         (clk),
        .reset       (reset),
        .rx          (serial),
        .s_tick      (tick),
        .rx_done_tick(rx_done),
        .dout        (rx_data)
    );

    // Clock de 100 MHz
    initial clk = 0;
    always #5 clk = ~clk;

    // Envía un byte por el Tx y verifica lo que llega al Rx
    task enviar_y_verificar(input [NB_DATA-1:0] dato);
        begin
            @(posedge clk);
            tx_data  = dato;
            tx_start = 1;
            @(posedge clk);
            tx_start = 0;

            @(posedge rx_done);
            @(negedge clk);
            if (rx_data !== dato) begin
                $display("ERROR: enviado %h, recibido %h", dato, rx_data);
                errores = errores + 1;
            end
            else
                $display("OK: enviado %h, recibido %h", dato, rx_data);

            @(posedge tx_done);   // Esperamos que el Tx termine el stop bit
        end
    endtask

    initial begin
        errores  = 0;
        tx_start = 0;
        tx_data  = 0;

        reset = 1;
        repeat (5) @(posedge clk);
        reset = 0;

        // Casos borde
        enviar_y_verificar(8'h00);
        enviar_y_verificar(8'hFF);
        enviar_y_verificar(8'h55);   // 01010101
        enviar_y_verificar(8'hAA);   // 10101010

        // Casos aleatorios
        for (i = 0; i < N_BYTES; i = i + 1)
            enviar_y_verificar($random);

        if (errores == 0)
            $display("LOOPBACK OK: %0d bytes sin errores", N_BYTES + 4);
        else
            $display("LOOPBACK FALLO: %0d errores", errores);

        $finish;
    end

endmodule