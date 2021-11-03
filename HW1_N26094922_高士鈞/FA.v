`timescale 10ns / 1ps
//`include "HA.v"

module FA(s, c_out, x, y, c_in);
input x, y, c_in;
output s, c_out;
wire s1, c1, c2;

HA ha1(s1, c1, x, y);
HA ha2(s, c2, c_in, s1);
or or1(c_out, c2, c1);

/*
xor xor1(s1, x, y);
and and1(c1, x, y);
xor xor2(s, s1, c_in);
and and2(c2, s1, c_in);
xor xor3(c_out, c2, c1);
*/
  
endmodule

