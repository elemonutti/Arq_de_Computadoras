`timescale 1ns / 1ps

module uart_rx
#(
    parameter NB_DATA = 8,   // Cantidad de bits de datos
    parameter SB_TICK = 16   // Ticks para el bit de stop (16 = 1 stop bit)
)
(
    input  wire               clk,
    input  wire               reset,
    input  wire               rx,            // Línea serie de entrada
    input  wire               s_tick,        // Tick del Baud Rate Generator
    output reg                rx_done_tick,  // Pulso de 1 ciclo: byte recibido
    output wire [NB_DATA-1:0] dout           // Byte recibido
);

    // Estados de la FSM
    localparam [1:0] IDLE  = 2'b00,
                     START = 2'b01,
                     DATA  = 2'b10,
                     STOP  = 2'b11;

    reg [1:0]                 state,  next_state;
    reg [3:0]                 s_reg,  s_next;   // Contador de ticks (0 a 15)
    reg [$clog2(NB_DATA)-1:0] n_reg,  n_next;   // Contador de bits de datos
    reg [NB_DATA-1:0]         b_reg,  b_next;   // Shift register con los datos

    // Sincronizador de 2 flip-flops: rx viene de afuera (asincrónica al clock)
    reg rx_meta, rx_sync;
    always @(posedge clk) begin
        if (reset) begin
            rx_meta <= 1'b1;
            rx_sync <= 1'b1;
        end
        else begin
            rx_meta <= rx;
            rx_sync <= rx_meta;
        end
    end

    // Memoria: registros de estado y de datos
    always @(posedge clk) begin
        if (reset) begin
            state <= IDLE;
            s_reg <= 0;
            n_reg <= 0;
            b_reg <= 0;
        end
        else begin
            state <= next_state;
            s_reg <= s_next;
            n_reg <= n_next;
            b_reg <= b_next;
        end
    end

    // Lógica de próximo estado y salidas
    always @(*) begin
        next_state   = state;
        s_next       = s_reg;
        n_next       = n_reg;
        b_next       = b_reg;
        rx_done_tick = 1'b0;

        case (state)
            IDLE:
                if (~rx_sync) begin          // Flanco de bajada: empieza el bit de start
                    next_state = START;
                    s_next     = 0;
                end

            START:
                if (s_tick) begin
                    if (s_reg == 7) begin    // Mitad del bit de start
                        if (~rx_sync) begin  // Sigue en 0: start válido
                            next_state = DATA;
                            s_next     = 0;
                            n_next     = 0;
                        end
                        else                 // Era un glitch: volvemos a esperar
                            next_state = IDLE;
                    end
                    else
                        s_next = s_reg + 1;
                end

            DATA:
                if (s_tick) begin
                    if (s_reg == 15) begin   // Mitad de un bit de datos
                        s_next = 0;
                        b_next = {rx_sync, b_reg[NB_DATA-1:1]};  // Entra por la izquierda (LSB primero)
                        if (n_reg == NB_DATA - 1)
                            next_state = STOP;
                        else
                            n_next = n_reg + 1;
                    end
                    else
                        s_next = s_reg + 1;
                end

            STOP:
                if (s_tick) begin
                    if (s_reg == SB_TICK - 1) begin
                        next_state   = IDLE;
                        rx_done_tick = 1'b1;
                    end
                    else
                        s_next = s_reg + 1;
                end

            default:
                next_state = IDLE;          // Fault recovery
        endcase
    end

    assign dout = b_reg;

endmodule