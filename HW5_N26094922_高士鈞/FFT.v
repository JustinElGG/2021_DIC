`define IDLE 	4'd0
`define S2P_pre 4'd1
`define BF1	 	4'd2
`define BF2	 	4'd3
`define BF3	 	4'd4
`define BF4	 	4'd5
`define OUT1	4'd6
`define OUT2	4'd7
`define WAIT	4'd8

module FFT	(clk, rst, fir_d, fir_valid, fft_valid,
			fft_d1, fft_d2, fft_d3, fft_d4, fft_d5, fft_d6, fft_d7, fft_d8,
			fft_d9, fft_d10, fft_d11, fft_d12, fft_d13, fft_d14, fft_d15, fft_d0);

	input clk;
	input rst;
	input fir_valid;
	input [15:0] fir_d;
	
	output fft_valid;
	output [31:0] fft_d1, fft_d2, fft_d3, fft_d4, fft_d5, fft_d6, fft_d7, fft_d8;
	output [31:0] fft_d9, fft_d10, fft_d11, fft_d12, fft_d13, fft_d14, fft_d15, fft_d0;

integer n, i, j, k, l;
reg  [3:0] c_state, n_state;
reg  [11:0] global_count;
reg  [5:0] fft_count;
reg signed [31:0] tf_real [0:7];
reg signed [31:0] tf_imag [0:7];
reg signed [15:0] fir_parrel [0:15];

reg signed [15:0] bf1_real [0:15];
reg signed [15:0] bf1_imag [0:15];
reg signed [15:0] bf2_real [0:15];
reg signed [15:0] bf2_imag [0:15];
reg signed [15:0] bf3_real [0:15];
reg signed [15:0] bf3_imag [0:15];
reg signed [15:0] bf4_real [0:15];
reg signed [15:0] bf4_imag [0:15];

always@(posedge clk) begin
	tf_real[0] <= 32'h00010000;	//The real part of the reference table about COS(x)+i*SIN(x) value , 0: 001
	tf_real[1] <= 32'h0000EC83;	//The real part of the reference table about COS(x)+i*SIN(x) value , 1: 9.238739e-001
	tf_real[2] <= 32'h0000B504;	//The real part of the reference table about COS(x)+i*SIN(x) value , 2: 7.070923e-001
	tf_real[3] <= 32'h000061F7;	//The real part of the reference table about COS(x)+i*SIN(x) value , 3: 3.826752e-001
	tf_real[4] <= 32'h00000000;	//The real part of the reference table about COS(x)+i*SIN(x) value , 4: 000
	tf_real[5] <= 32'hFFFF9E09;	//The real part of the reference table about COS(x)+i*SIN(x) value , 5: -3.826752e-001
	tf_real[6] <= 32'hFFFF4AFC;	//The real part of the reference table about COS(x)+i*SIN(x) value , 6: -7.070923e-001
	tf_real[7] <= 32'hFFFF137D;	//The real part of the reference table about COS(x)+i*SIN(x) value , 7: -9.238739e-001

	tf_imag[0] <= 32'h00000000;	//The imag part of the reference table about COS(x)+i*SIN(x) value , 0: 000
	tf_imag[1] <= 32'hFFFF9E09;	//The imag part of the reference table about COS(x)+i*SIN(x) value , 1: -3.826752e-001
	tf_imag[2] <= 32'hFFFF4AFC;	//The imag part of the reference table about COS(x)+i*SIN(x) value , 2: -7.070923e-001
	tf_imag[3] <= 32'hFFFF137D;	//The imag part of the reference table about COS(x)+i*SIN(x) value , 3: -9.238739e-001
	tf_imag[4] <= 32'hFFFF0000;	//The imag part of the reference table about COS(x)+i*SIN(x) value , 4: -01
	tf_imag[5] <= 32'hFFFF137D;	//The imag part of the reference table about COS(x)+i*SIN(x) value , 5: -9.238739e-001
	tf_imag[6] <= 32'hFFFF4AFC;	//The imag part of the reference table about COS(x)+i*SIN(x) value , 6: -7.070923e-001
	tf_imag[7] <= 32'hFFFF9E09;	//The imag part of the reference table about COS(x)+i*SIN(x) value , 7: -3.826752e-001
end

assign fft_valid = (c_state == `OUT2) ? 1'b1:1'b0;
//assign fft_valid = (c_state == `OUT2 & global_count < 12'd900) ? 1'b1:1'b0;

// FSM
always@(posedge clk, posedge rst) begin
	if(rst) begin
		c_state <= `IDLE;
	end
	else begin
		c_state <= n_state;
	end
end

always@(*) begin
	case(c_state)
		`IDLE: begin
			if(fir_valid)
				n_state = `S2P_pre;
			else
				n_state = c_state;
		end
		`S2P_pre: begin
			if(global_count == 12'd15)
				n_state = `BF1;
			else
				n_state = c_state;
		end
		`BF1: begin
			n_state = `BF2;
		end
		`BF2: begin
			n_state = `BF3;
		end
		`BF3: begin
			n_state = `BF4;
		end
		`BF4: begin
			n_state = `OUT1;
		end
		`OUT1: begin
			n_state = `OUT2;
		end
		`OUT2: begin
			n_state = `WAIT;
		end
		`WAIT: begin
			if(fft_count == 6'd15)
				n_state = `BF1;
			else
				n_state = c_state;
		end
		default: begin
			n_state = `IDLE;
		end
	endcase
end


// counters' home, counters are not related to states.
always@(posedge clk, posedge rst) begin
	if(rst) begin
		global_count 	<= 12'b0;
		fft_count		<= 6'b0;
	end
	else begin
		//if(c_state != `IDLE) begin
		if(fir_valid == 1'b1) begin
			global_count <= global_count+12'b1;
			if(fft_count == 6'd15)
				fft_count <= 6'b0;
			else
				fft_count <= fft_count+6'b1;
		end
	end
end

// S2P module
always@(posedge clk, posedge rst) begin
	if(rst) begin
		for(n=0; n<16; n=n+1) begin
			fir_parrel[n] <= 16'b0;
		end
	end
	else begin
		//if(n_state == `S2P_pre) begin
		if(n_state != `IDLE) begin
			fir_parrel[fft_count] <= fir_d+{15'd0, fir_d[15]};
			//fir_parrel[fft_count] <= fir_d;
		end
		else begin
			fir_parrel[fft_count] <= fir_parrel[fft_count];
		end
	end
end


//BF1 looks okay except offset
//reg signed [15:0] bf1_real_temp [0:15];
//reg signed [15:0] bf1_imag_temp [0:15];
reg signed [15:0] bf1_real_tp [0:7];
/*always@(*) begin
	for(j=8; j<16; j=j+1) begin
		bf1_real_temp[j] <= ((fir_parrel[j-8]-fir_parrel[j]) * tf_real[j-8]) >> 16;
		bf1_imag_temp[j] <= ((fir_parrel[j-8]-fir_parrel[j]) * tf_imag[j-8]) >> 16;
	end
end*/

always@(posedge clk, posedge rst) begin
	if(rst) begin
		for(i=0; i<16; i=i+1) begin
			bf1_real[i] <= 16'b0;
			bf1_imag[i] <= 16'b0;
		end
	end
	else begin
		if(c_state == `BF1) begin
			// fft_a
			for(i=0; i<8; i=i+1) begin
				bf1_real[i] <= fir_parrel[i]+fir_parrel[i+8]; //add1 or not
				bf1_imag[i] <= 16'b0;
			end
			// fft_b
			for(j=8; j<16; j=j+1) begin
				bf1_real[j] <= ((fir_parrel[j-8]-fir_parrel[j]) * tf_real[j-8]) >> 16;
				bf1_imag[j] <= ((fir_parrel[j-8]-fir_parrel[j]) * tf_imag[j-8]) >> 16;
				//bf1_real[j] <= bf1_real_temp[j] - {15'd0, bf1_real_temp[j][15]};
				//bf1_imag[j] <= bf1_imag_temp[j] - {15'd0, bf1_imag_temp[j][15]};
			end
			bf1_real_tp[0] <= fir_parrel[0]-fir_parrel[8]; // for debug
			bf1_real_tp[1] <= fir_parrel[1]-fir_parrel[9];
			bf1_real_tp[2] <= fir_parrel[2]-fir_parrel[10];
			bf1_real_tp[3] <= fir_parrel[3]-fir_parrel[11];
			bf1_real_tp[4] <= fir_parrel[4]-fir_parrel[12];
			bf1_real_tp[5] <= fir_parrel[5]-fir_parrel[13];
			bf1_real_tp[6] <= fir_parrel[6]-fir_parrel[14];
			bf1_real_tp[7] <= fir_parrel[7]-fir_parrel[15];
		end
	end
end

//BF2 looks okay except offset
always@(posedge clk, posedge rst) begin
	if(rst) begin
		for(i=0; i<16; i=i+1) begin
			bf2_real[i] <= 16'b0;
			bf2_imag[i] <= 16'b0;
		end
	end
	else begin
		if(c_state == `BF2) begin
			// fft_a 1
			for(i=0; i<4; i=i+1) begin
				bf2_real[i] <= bf1_real[i]+bf1_real[i+4];
				bf2_imag[i] <= bf1_imag[i]+bf1_imag[i+4];
			end
			// fft_b 1
			for(j=4; j<8; j=j+1) begin
				bf2_real[j] <= ( ((bf1_real[j-4]-bf1_real[j]) * tf_real[(j-4)*2]) - ((bf1_imag[j-4]-bf1_imag[j]) * tf_imag[(j-4)*2]) ) >> 16;
				bf2_imag[j] <= ( ((bf1_real[j-4]-bf1_real[j]) * tf_imag[(j-4)*2]) + ((bf1_imag[j-4]-bf1_imag[j]) * tf_real[(j-4)*2]) ) >> 16;
			end
			// fft_a 2
			for(k=8; k<12; k=k+1) begin
				bf2_real[k] <= bf1_real[k]+bf1_real[k+4];
				bf2_imag[k] <= bf1_imag[k]+bf1_imag[k+4];
			end
			// fft_b 2
			for(l=12; l<16; l=l+1) begin
				bf2_real[l] <= ( ((bf1_real[l-4]-bf1_real[l]) * tf_real[(l-12)*2]) - ((bf1_imag[l-4]-bf1_imag[l]) * tf_imag[(l-12)*2]) ) >> 16;
				bf2_imag[l] <= ( ((bf1_real[l-4]-bf1_real[l]) * tf_imag[(l-12)*2]) + ((bf1_imag[l-4]-bf1_imag[l]) * tf_real[(l-12)*2]) ) >> 16;
			end
			
		end
	end
end

//BF3
always@(posedge clk, posedge rst) begin
	if(rst) begin
		for(i=0; i<16; i=i+1) begin
			bf3_real[i] <= 16'b0;
			bf3_imag[i] <= 16'b0;
		end
	end
	else begin
		if(c_state == `BF3) begin
			bf3_real[0]  <= bf2_real[0]+bf2_real[2];
			bf3_imag[0]  <= bf2_imag[0]+bf2_imag[2];
			bf3_real[1]  <= bf2_real[1]+bf2_real[3];
			bf3_imag[1]  <= bf2_imag[1]+bf2_imag[3];
			
			bf3_real[2]  <= ( ((bf2_real[0]-bf2_real[2]) * tf_real[0]) - ((bf2_imag[0]-bf2_imag[2]) * tf_imag[0]) ) >> 16;
			bf3_imag[2]  <= ( ((bf2_real[0]-bf2_real[2]) * tf_imag[0]) + ((bf2_imag[0]-bf2_imag[2]) * tf_real[0]) ) >> 16;
			bf3_real[3]  <= ( ((bf2_real[1]-bf2_real[3]) * tf_real[4]) - ((bf2_imag[1]-bf2_imag[3]) * tf_imag[4]) ) >> 16;
			bf3_imag[3]  <= ( ((bf2_real[1]-bf2_real[3]) * tf_imag[4]) + ((bf2_imag[1]-bf2_imag[3]) * tf_real[4]) ) >> 16;
			///////////////
			/*************/
			///////////////
			bf3_real[4]  <= bf2_real[4]+bf2_real[6];
			bf3_imag[4]  <= bf2_imag[4]+bf2_imag[6];
			bf3_real[5]  <= bf2_real[5]+bf2_real[7];
			bf3_imag[5]  <= bf2_imag[5]+bf2_imag[7];
			
			bf3_real[6]  <= ( ((bf2_real[4]-bf2_real[6]) * tf_real[0]) - ((bf2_imag[4]-bf2_imag[6]) * tf_imag[0]) ) >> 16;
			bf3_imag[6]  <= ( ((bf2_real[4]-bf2_real[6]) * tf_imag[0]) + ((bf2_imag[4]-bf2_imag[6]) * tf_real[0]) ) >> 16;
			bf3_real[7]  <= ( ((bf2_real[5]-bf2_real[7]) * tf_real[4]) - ((bf2_imag[5]-bf2_imag[7]) * tf_imag[4]) ) >> 16;
			bf3_imag[7]  <= ( ((bf2_real[5]-bf2_real[7]) * tf_imag[4]) + ((bf2_imag[5]-bf2_imag[7]) * tf_real[4]) ) >> 16;
			///////////////
			/*************/
			///////////////
			bf3_real[8]  <= bf2_real[8]+bf2_real[10];
			bf3_imag[8]  <= bf2_imag[8]+bf2_imag[10];
			bf3_real[9]  <= bf2_real[9]+bf2_real[11];
			bf3_imag[9]  <= bf2_imag[9]+bf2_imag[11];
			
			bf3_real[10] <= ( ((bf2_real[8]-bf2_real[10]) * tf_real[0]) - ((bf2_imag[8]-bf2_imag[10]) * tf_imag[0]) ) >> 16;
			bf3_imag[10] <= ( ((bf2_real[8]-bf2_real[10]) * tf_imag[0]) + ((bf2_imag[8]-bf2_imag[10]) * tf_real[0]) ) >> 16;
			bf3_real[11] <= ( ((bf2_real[9]-bf2_real[11]) * tf_real[4]) - ((bf2_imag[9]-bf2_imag[11]) * tf_imag[4]) ) >> 16;
			bf3_imag[11] <= ( ((bf2_real[9]-bf2_real[11]) * tf_imag[4]) + ((bf2_imag[9]-bf2_imag[11]) * tf_real[4]) ) >> 16;
			///////////////
			/*************/
			///////////////
			bf3_real[12] <= bf2_real[12]+bf2_real[14];
			bf3_imag[12] <= bf2_imag[12]+bf2_imag[14];
			bf3_real[13] <= bf2_real[13]+bf2_real[15];
			bf3_imag[13] <= bf2_imag[13]+bf2_imag[15];
			
			bf3_real[14] <= ( ((bf2_real[12]-bf2_real[14]) * tf_real[0]) - ((bf2_imag[12]-bf2_imag[14]) * tf_imag[0]) ) >> 16;
			bf3_imag[14] <= ( ((bf2_real[12]-bf2_real[14]) * tf_imag[0]) + ((bf2_imag[12]-bf2_imag[14]) * tf_real[0]) ) >> 16;
			bf3_real[15] <= ( ((bf2_real[13]-bf2_real[15]) * tf_real[4]) - ((bf2_imag[13]-bf2_imag[15]) * tf_imag[4]) ) >> 16;
			bf3_imag[15] <= ( ((bf2_real[13]-bf2_real[15]) * tf_imag[4]) + ((bf2_imag[13]-bf2_imag[15]) * tf_real[4]) ) >> 16;
		end
	end
end

//BF3
always@(posedge clk, posedge rst) begin
	if(rst) begin
		for(i=0; i<16; i=i+1) begin
			bf4_real[i] <= 16'b0;
			bf4_imag[i] <= 16'b0;
		end
	end
	else begin
		if(c_state == `BF4) begin
			bf4_real[0]  <= bf3_real[0]+bf3_real[1];
			bf4_imag[0]	 <= bf3_imag[0]+bf3_imag[1];
			bf4_real[1]  <= ( ((bf3_real[0]-bf3_real[1]) * tf_real[0]) - ((bf3_imag[0]-bf3_imag[1]) * tf_imag[0]) ) >> 16;
			bf4_imag[1]	 <= ( ((bf3_real[0]-bf3_real[1]) * tf_imag[0]) + ((bf3_imag[0]-bf3_imag[1]) * tf_real[0]) ) >> 16;
			
			bf4_real[2]  <= bf3_real[2]+bf3_real[3];
			bf4_imag[2]	 <= bf3_imag[2]+bf3_imag[3];
			bf4_real[3]  <= ( ((bf3_real[2]-bf3_real[3]) * tf_real[0]) - ((bf3_imag[2]-bf3_imag[3]) * tf_imag[0]) ) >> 16;
			bf4_imag[3]  <= ( ((bf3_real[2]-bf3_real[3]) * tf_imag[0]) + ((bf3_imag[2]-bf3_imag[3]) * tf_real[0]) ) >> 16;

			bf4_real[4]  <= bf3_real[4]+bf3_real[5];
			bf4_imag[4]	 <= bf3_imag[4]+bf3_imag[5];
			bf4_real[5]  <= ( ((bf3_real[4]-bf3_real[5]) * tf_real[0]) - ((bf3_imag[4]-bf3_imag[5]) * tf_imag[0]) ) >> 16;
			bf4_imag[5]	 <= ( ((bf3_real[4]-bf3_real[5]) * tf_imag[0]) + ((bf3_imag[4]-bf3_imag[5]) * tf_real[0]) ) >> 16;
			
			bf4_real[6]  <= bf3_real[6]+bf3_real[7];
			bf4_imag[6]	 <= bf3_imag[6]+bf3_imag[7];
			bf4_real[7]  <= ( ((bf3_real[6]-bf3_real[7]) * tf_real[0]) - ((bf3_imag[6]-bf3_imag[7]) * tf_imag[0]) ) >> 16;
			bf4_imag[7]	 <= ( ((bf3_real[6]-bf3_real[7]) * tf_imag[0]) + ((bf3_imag[6]-bf3_imag[7]) * tf_real[0]) ) >> 16;

			bf4_real[8]  <= bf3_real[8]+bf3_real[9];
			bf4_imag[8]	 <= bf3_imag[8]+bf3_imag[9];
			bf4_real[9]  <= ( ((bf3_real[8]-bf3_real[9]) * tf_real[0]) - ((bf3_imag[8]-bf3_imag[9]) * tf_imag[0]) ) >> 16;
			bf4_imag[9]	 <= ( ((bf3_real[8]-bf3_real[9]) * tf_imag[0]) + ((bf3_imag[8]-bf3_imag[9]) * tf_real[0]) ) >> 16;
			
			bf4_real[10] <= bf3_real[10]+bf3_real[11];
			bf4_imag[10] <= bf3_imag[10]+bf3_imag[11];
			bf4_real[11] <= ( ((bf3_real[10]-bf3_real[11]) * tf_real[0]) - ((bf3_imag[10]-bf3_imag[11]) * tf_imag[0]) ) >> 16;
			bf4_imag[11] <= ( ((bf3_real[10]-bf3_real[11]) * tf_imag[0]) + ((bf3_imag[10]-bf3_imag[11]) * tf_real[0]) ) >> 16;
			
			bf4_real[12] <= bf3_real[12]+bf3_real[13];
			bf4_imag[12] <= bf3_imag[12]+bf3_imag[13];
			bf4_real[13] <= ( ((bf3_real[12]-bf3_real[13]) * tf_real[0]) - ((bf3_imag[12]-bf3_imag[13]) * tf_imag[0]) ) >> 16;
			bf4_imag[13] <= ( ((bf3_real[12]-bf3_real[13]) * tf_imag[0]) + ((bf3_imag[12]-bf3_imag[13]) * tf_real[0]) ) >> 16;
			
			bf4_real[14] <= bf3_real[14]+bf3_real[15];
			bf4_imag[14] <= bf3_imag[14]+bf3_imag[15];
			bf4_real[15] <= ( ((bf3_real[14]-bf3_real[15]) * tf_real[0]) - ((bf3_imag[14]-bf3_imag[15]) * tf_imag[0]) ) >> 16;
			bf4_imag[15] <= ( ((bf3_real[14]-bf3_real[15]) * tf_imag[0]) + ((bf3_imag[14]-bf3_imag[15]) * tf_real[0]) ) >> 16;
		end
	end
end

assign fft_d0  = {bf4_real[0],  bf4_imag[0]};
assign fft_d1  = {bf4_real[8]+16'd3,  bf4_imag[8]+16'd3};
assign fft_d2  = {bf4_real[4],  bf4_imag[4]};
assign fft_d3  = {bf4_real[12], bf4_imag[12]};
assign fft_d4  = {bf4_real[2],  bf4_imag[2]};
assign fft_d5  = {bf4_real[10], bf4_imag[10]};
assign fft_d6  = {bf4_real[6],  bf4_imag[6]};
assign fft_d7  = {bf4_real[14], bf4_imag[14]};
assign fft_d8  = {bf4_real[1],  bf4_imag[1]};
assign fft_d9  = {bf4_real[9],  bf4_imag[9]};
assign fft_d10 = {bf4_real[5],  bf4_imag[5]};
assign fft_d11 = {bf4_real[13], bf4_imag[13]};
assign fft_d12 = {bf4_real[3],  bf4_imag[3]};
assign fft_d13 = {bf4_real[11], bf4_imag[11]};
assign fft_d14 = {bf4_real[7],  bf4_imag[7]};
assign fft_d15 = {bf4_real[15], bf4_imag[15]};


endmodule