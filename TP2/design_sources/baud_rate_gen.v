`timescale 1ns / 1ps

module baud_rate_gen
#(
    parameter CLK_FREQ  = 100_000_000,  // Frecuencia del clock de la placa (Hz)
    parameter BAUD_RATE = 19200         // Velocidad de la UART (bits por segundo)
)
(
    input  wire clk,    // Clock de 100 MHz de la Basys 3
    input  wire reset,  // Reset sincrónico
    output wire tick    // Pulso de 1 ciclo, 16 veces por bit
);

    // Cantidad de ciclos de clock entre dos ticks (redondeado al entero más cercano)
    localparam DIVISOR   = (CLK_FREQ + BAUD_RATE * 8) / (BAUD_RATE * 16);

    // Cantidad de bits necesarios para contar hasta DIVISOR-1
    localparam CNT_WIDTH = $clog2(DIVISOR);

    // Registro del contador
    reg [CNT_WIDTH-1:0] counter;

    // Contador módulo DIVISOR: cuenta de 0 a DIVISOR-1 y vuelve a 0
    always @(posedge clk) begin
        if (reset)
            counter <= 0;
        else if (counter == DIVISOR - 1)
            counter <= 0;
        else
            counter <= counter + 1;
    end

    // Tick: vale 1 solo durante el ciclo en que el contador está en su último valor
    assign tick = (counter == DIVISOR - 1);

endmodule