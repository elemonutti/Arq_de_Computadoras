`timescale 1ns / 1ps

module alu_interface
#(
    parameter NB_DATA = 8,
    parameter NB_OP   = 6
)
(
    input  wire               clk,
    input  wire               reset,
    // Lado UART
    input  wire [NB_DATA-1:0] rx_data,     // Byte recibido por el Rx
    input  wire               rx_done,     // Pulso: llegó un byte
    output wire [NB_DATA-1:0] tx_data,     // Byte a enviar por el Tx
    output reg                tx_start,    // Pulso: empezar a enviar
    input  wire               tx_done,     // Pulso: terminó de enviar
    // Lado ALU
    output wire [NB_DATA-1:0] alu_a,
    output wire [NB_DATA-1:0] alu_b,
    output wire [NB_OP-1:0]   alu_op,
    input  wire [NB_DATA-1:0] alu_result,
    // Último resultado (para mostrar en los LEDs)
    output wire [NB_DATA-1:0] last_result
);

    // Estados de la FSM (one-hot)
    localparam [4:0] WAIT_A  = 5'b00001,
                     WAIT_B  = 5'b00010,
                     WAIT_OP = 5'b00100,
                     SEND    = 5'b01000,
                     WAIT_TX = 5'b10000;

    reg [4:0]         state,   next_state;
    reg [NB_DATA-1:0] a_reg,   a_next;
    reg [NB_DATA-1:0] b_reg,   b_next;
    reg [NB_OP-1:0]   op_reg,  op_next;
    reg [NB_DATA-1:0] res_reg, res_next;

    // Memoria
    always @(posedge clk) begin
        if (reset) begin
            state   <= WAIT_A;
            a_reg   <= 0;
            b_reg   <= 0;
            op_reg  <= 0;
            res_reg <= 0;
        end
        else begin
            state   <= next_state;
            a_reg   <= a_next;
            b_reg   <= b_next;
            op_reg  <= op_next;
            res_reg <= res_next;
        end
    end

    // Lógica de próximo estado y salidas
    always @(*) begin
        next_state = state;
        a_next     = a_reg;
        b_next     = b_reg;
        op_next    = op_reg;
        res_next   = res_reg;
        tx_start   = 1'b0;

        case (state)
            WAIT_A:
                if (rx_done) begin
                    a_next     = rx_data;
                    next_state = WAIT_B;
                end

            WAIT_B:
                if (rx_done) begin
                    b_next     = rx_data;
                    next_state = WAIT_OP;
                end

            WAIT_OP:
                if (rx_done) begin
                    op_next    = rx_data[NB_OP-1:0];  // Solo los 6 bits bajos
                    next_state = SEND;
                end

            SEND: begin
                tx_start   = 1'b1;           // El Tx copia tx_data en este ciclo
                res_next   = alu_result;
                next_state = WAIT_TX;
            end

            WAIT_TX:
                if (tx_done)
                    next_state = WAIT_A;

            default:
                next_state = WAIT_A;         // Fault recovery
        endcase
    end

    assign alu_a       = a_reg;
    assign alu_b       = b_reg;
    assign alu_op      = op_reg;
    assign tx_data     = alu_result;
    assign last_result = res_reg;

endmodule