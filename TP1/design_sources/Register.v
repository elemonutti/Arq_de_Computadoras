`timescale 1ns / 1ps

module Register
  #(
    parameter NB = 8
  )
  (
    input  wire          clk,
    input  wire          rst,
    input  wire          enable,
    input  wire [NB-1:0] d,
    output reg  [NB-1:0] q
  );

  always @(posedge clk or posedge rst) begin
    if (rst) begin
      q <= {NB{1'b0}};
    end else if (enable) begin
      q <= d;
    end
  end

endmodule
