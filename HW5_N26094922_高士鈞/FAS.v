//`include "FIR.v"
//`include "FFT.v"
//`include "analysis.v"

module FAS (data_valid, data, clk, rst, fir_d, fir_valid, fft_valid, done, freq,
			fft_d1, fft_d2, fft_d3, fft_d4, fft_d5, fft_d6, fft_d7, fft_d8,
			fft_d9, fft_d10, fft_d11, fft_d12, fft_d13, fft_d14, fft_d15, fft_d0);

	input clk, rst;
	input data_valid;
	input [15:0] data; 

	output fir_valid, fft_valid;
	output [15:0] fir_d;
	output [31:0] fft_d1, fft_d2, fft_d3, fft_d4, fft_d5, fft_d6, fft_d7, fft_d8;
	output [31:0] fft_d9, fft_d10, fft_d11, fft_d12, fft_d13, fft_d14, fft_d15, fft_d0;
	output done;
	output [3:0] freq;

FIR FIR_1(	.clk(clk), .rst(rst),
			.data(data), .data_valid(data_valid),
			.fir_out(fir_d), .fir_valid(fir_valid));
FFT	FFT_1(	.clk(clk), .rst(rst),
			.fir_d(fir_d), .fir_valid(fir_valid), .fft_valid(fft_valid),
			.fft_d1(fft_d1), .fft_d2(fft_d2), .fft_d3(fft_d3), .fft_d4(fft_d4),
			.fft_d5(fft_d5), .fft_d6(fft_d6), .fft_d7(fft_d7), .fft_d8(fft_d8),
			.fft_d9(fft_d9), .fft_d10(fft_d10), .fft_d11(fft_d11), .fft_d12(fft_d12),
			.fft_d13(fft_d13), .fft_d14(fft_d14), .fft_d15(fft_d15), .fft_d0(fft_d0));
analysis analysis_1(.clk(clk), .rst(rst),
					.fft_valid(fft_valid),
					.fft_d1(fft_d1), .fft_d2(fft_d2), .fft_d3(fft_d3), .fft_d4(fft_d4),
					.fft_d5(fft_d5), .fft_d6(fft_d6), .fft_d7(fft_d7), .fft_d8(fft_d8),
					.fft_d9(fft_d9), .fft_d10(fft_d10), .fft_d11(fft_d11), .fft_d12(fft_d12),
					.fft_d13(fft_d13), .fft_d14(fft_d14), .fft_d15(fft_d15), .fft_d0(fft_d0),
					.done(done),
					.freq(freq));

endmodule
