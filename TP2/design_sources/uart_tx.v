`timescale 1ns / 1ps

module uart_tx
#(
    parameter NB_DATA = 8,   // Cantidad de bits de datos
    parameter SB_TICK = 16   // Ticks para el bit de stop (16 = 1 stop bit)
)
(
    input  wire               clk,
    input  wire               reset,
    input  wire               tx_start,      // Pulso: empezar a transmitir din
    input  wire               s_tick,        // Tick del Baud Rate Generator
    input  wire [NB_DATA-1:0] din,           // Byte a transmitir
    output reg                tx_done_tick,  // Pulso de 1 ciclo: byte enviado
    output wire               tx             // Línea serie de salida
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
    reg                       tx_reg, tx_next;  // Salida registrada (sin glitches)

    // Memoria: registros de estado y de datos
    always @(posedge clk) begin
        if (reset) begin
            state  <= IDLE;
            s_reg  <= 0;
            n_reg  <= 0;
            b_reg  <= 0;
            tx_reg <= 1'b1;                  // La línea en reposo está en 1
        end
        else begin
            state  <= next_state;
            s_reg  <= s_next;
            n_reg  <= n_next;
            b_reg  <= b_next;
            tx_reg <= tx_next;
        end
    end

    // Lógica de próximo estado y salidas
    always @(*) begin
        next_state   = state;
        s_next       = s_reg;
        n_next       = n_reg;
        b_next       = b_reg;
        tx_next      = tx_reg;
        tx_done_tick = 1'b0;

        case (state)
            IDLE: begin
                tx_next = 1'b1;
                if (tx_start) begin
                    next_state = START;
                    s_next     = 0;
                    b_next     = din;        // Copiamos el byte a enviar
                end
            end

            START: begin
                tx_next = 1'b0;              // Bit de start
                if (s_tick) begin
                    if (s_reg == 15) begin
                        next_state = DATA;
                        s_next     = 0;
                        n_next     = 0;
                    end
                    else
                        s_next = s_reg + 1;
                end
            end

            DATA: begin
                tx_next = b_reg[0];          // Sale el LSB primero
                if (s_tick) begin
                    if (s_reg == 15) begin
                        s_next = 0;
                        b_next = b_reg >> 1;
                        if (n_reg == NB_DATA - 1)
                            next_state = STOP;
                        else
                            n_next = n_reg + 1;
                    end
                    else
                        s_next = s_reg + 1;
                end
            end

            STOP: begin
                tx_next = 1'b1;              // Bit de stop
                if (s_tick) begin
                    if (s_reg == SB_TICK - 1) begin
                        next_state   = IDLE;
                        tx_done_tick = 1'b1;
                    end
                    else
                        s_next = s_reg + 1;
                end
            end

            default:
                next_state = IDLE;           // Fault recovery
        endcase
    end

    assign tx = tx_reg;

endmodule