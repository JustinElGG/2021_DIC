`timescale 10ns / 1ps
//`include "FA.v"

module RCA(s, c_out, x, y, c_in);
input  [3:0] x, y;
output [3:0] s;
input  c_in;
output c_out;

wire carry0, carry1, carry2;


FA a0(s[0], carry0, x[0], y[0], c_in);
FA a1(s[1], carry1, x[1], y[1], carry0);
FA a2(s[2], carry2, x[2], y[2], carry1);
FA a3(s[3], c_out,  x[3], y[3], carry2);

endmodule
