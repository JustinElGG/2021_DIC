//*********************//
//  fir_out would face precision problem, after sample pt.900
//*********************//
module FIR	(clk, rst, data, data_valid, fir_out, fir_valid);
	input clk;
	input rst;
	input [15:0] data;
	input data_valid;
	output reg [15:0] fir_out;
	output fir_valid;

//16-bit floating point
parameter signed [19:0] FIR_C00 = 20'hFFF9E ;     //The FIR_coefficient value 0: -1.495361e-003
parameter signed [19:0] FIR_C01 = 20'hFFF86 ;     //The FIR_coefficient value 1: -1.861572e-003
parameter signed [19:0] FIR_C02 = 20'hFFFA7 ;     //The FIR_coefficient value 2: -1.358032e-003
parameter signed [19:0] FIR_C03 = 20'h0003B ;    //The FIR_coefficient value 3: 9.002686e-004
parameter signed [19:0] FIR_C04 = 20'h0014B ;    //The FIR_coefficient value 4: 5.050659e-003
parameter signed [19:0] FIR_C05 = 20'h0024A ;    //The FIR_coefficient value 5: 8.941650e-003
parameter signed [19:0] FIR_C06 = 20'h00222 ;    //The FIR_coefficient value 6: 8.331299e-003
parameter signed [19:0] FIR_C07 = 20'hFFFE4 ;     //The FIR_coefficient value 7: -4.272461e-004
parameter signed [19:0] FIR_C08 = 20'hFFBC5 ;     //The FIR_coefficient value 8: -1.652527e-002
parameter signed [19:0] FIR_C09 = 20'hFF7CA ;     //The FIR_coefficient value 9: -3.207397e-002
parameter signed [19:0] FIR_C10 = 20'hFF74E ;     //The FIR_coefficient value 10: -3.396606e-002
parameter signed [19:0] FIR_C11 = 20'hFFD74 ;     //The FIR_coefficient value 11: -9.948730e-003
parameter signed [19:0] FIR_C12 = 20'h00B1A ;    //The FIR_coefficient value 12: 4.336548e-002
parameter signed [19:0] FIR_C13 = 20'h01DAC ;    //The FIR_coefficient value 13: 1.159058e-001
parameter signed [19:0] FIR_C14 = 20'h02F9E ;    //The FIR_coefficient value 14: 1.860046e-001
parameter signed [19:0] FIR_C15 = 20'h03AA9 ;    //The FIR_coefficient value 15: 2.291412e-001
parameter signed [19:0] FIR_C16 = 20'h03AA9 ;    //The FIR_coefficient value 16: 2.291412e-001
parameter signed [19:0] FIR_C17 = 20'h02F9E ;    //The FIR_coefficient value 17: 1.860046e-001
parameter signed [19:0] FIR_C18 = 20'h01DAC ;    //The FIR_coefficient value 18: 1.159058e-001
parameter signed [19:0] FIR_C19 = 20'h00B1A ;    //The FIR_coefficient value 19: 4.336548e-002
parameter signed [19:0] FIR_C20 = 20'hFFD74 ;     //The FIR_coefficient value 20: -9.948730e-003
parameter signed [19:0] FIR_C21 = 20'hFF74E ;     //The FIR_coefficient value 21: -3.396606e-002
parameter signed [19:0] FIR_C22 = 20'hFF7CA ;     //The FIR_coefficient value 22: -3.207397e-002
parameter signed [19:0] FIR_C23 = 20'hFFBC5 ;     //The FIR_coefficient value 23: -1.652527e-002
parameter signed [19:0] FIR_C24 = 20'hFFFE4 ;     //The FIR_coefficient value 24: -4.272461e-004
parameter signed [19:0] FIR_C25 = 20'h00222 ;    //The FIR_coefficient value 25: 8.331299e-003
parameter signed [19:0] FIR_C26 = 20'h0024A ;    //The FIR_coefficient value 26: 8.941650e-003
parameter signed [19:0] FIR_C27 = 20'h0014B ;    //The FIR_coefficient value 27: 5.050659e-003
parameter signed [19:0] FIR_C28 = 20'h0003B ;    //The FIR_coefficient value 28: 9.002686e-004
parameter signed [19:0] FIR_C29 = 20'hFFFA7 ;     //The FIR_coefficient value 29: -1.358032e-003
parameter signed [19:0] FIR_C30 = 20'hFFF86 ;     //The FIR_coefficient value 30: -1.861572e-003
parameter signed [19:0] FIR_C31 = 20'hFFF9E ;     //The FIR_coefficient value 31: -1.495361e-003

integer i, j;
reg  signed [15:0] buffer [0:31];
reg  signed [35:0] acc [0:31];
reg  [10:0] fir_counter; //11bit counter(1024 samples)



assign fir_valid = (fir_counter > 11'd33 & fir_counter < 11'd1056) ? 1'd1:1'd0;
always@(posedge clk, posedge rst) begin //fir_valid counter
	if(rst) begin
		fir_counter <= 16'b0;
	end
	else begin
		if(data_valid) begin
			fir_counter <= fir_counter+1;
		end
	end
end

always@(posedge clk, posedge rst) begin
	if(rst) begin
		for(i=0; i<32; i=i+1) begin
			buffer[i] <= 16'b0;
		end
	end
	else begin
		if(data_valid == 1'b1) begin
			buffer[0] <= data;
			for(i=0; i<31; i=i+1) begin //1<-0 ~ 31<-30
				buffer[i+1] <= buffer[i];
			end
		end
	end
end

always@(posedge clk, posedge rst) begin
	if(rst) begin
		for(j=0; j<32; j=j+1) begin
			acc[j] <= 16'b0;
		end
	end
	else begin
		if(data_valid == 1'b1) begin
			//acc[j] <= h[j] * buffer[j];
			acc[0]  <= FIR_C00 * buffer[0];
			acc[1]  <= FIR_C01 * buffer[1];
			acc[2]  <= FIR_C02 * buffer[2];
			acc[3]  <= FIR_C03 * buffer[3];
			acc[4]  <= FIR_C04 * buffer[4];
			acc[5]  <= FIR_C05 * buffer[5];
			acc[6]  <= FIR_C06 * buffer[6];
			acc[7]  <= FIR_C07 * buffer[7];
			acc[8]  <= FIR_C08 * buffer[8];
			acc[9]  <= FIR_C09 * buffer[9];
			acc[10] <= FIR_C10 * buffer[10];
			acc[11] <= FIR_C11 * buffer[11];
			acc[12] <= FIR_C12 * buffer[12];
			acc[13] <= FIR_C13 * buffer[13];
			acc[14] <= FIR_C14 * buffer[14];
			acc[15] <= FIR_C15 * buffer[15];
			acc[16] <= FIR_C16 * buffer[16];
			acc[17] <= FIR_C17 * buffer[17];
			acc[18] <= FIR_C18 * buffer[18];
			acc[19] <= FIR_C19 * buffer[19];
			acc[20] <= FIR_C20 * buffer[20];
			acc[21] <= FIR_C21 * buffer[21];
			acc[22] <= FIR_C22 * buffer[22];
			acc[23] <= FIR_C23 * buffer[23];
			acc[24] <= FIR_C24 * buffer[24];
			acc[25] <= FIR_C25 * buffer[25];
			acc[26] <= FIR_C26 * buffer[26];
			acc[27] <= FIR_C27 * buffer[27];
			acc[28] <= FIR_C28 * buffer[28];
			acc[29] <= FIR_C29 * buffer[29];
			acc[30] <= FIR_C30 * buffer[30];
			acc[31] <= FIR_C31 * buffer[31];
		end
	end
end

always@(posedge clk) begin
	if(data_valid == 1'b1) begin
		fir_out <=(acc[0] +acc[1] +acc[2] +acc[3] +acc[4] +acc[5] +acc[6] +acc[7] +
				   acc[8] +acc[9] +acc[10]+acc[11]+acc[12]+acc[13]+acc[14]+acc[15]+
				   acc[16]+acc[17]+acc[18]+acc[19]+acc[20]+acc[21]+acc[22]+acc[23]+
				   acc[24]+acc[25]+acc[26]+acc[27]+acc[28]+acc[29]+acc[30]+acc[31])>>16;
	end
end


endmodule