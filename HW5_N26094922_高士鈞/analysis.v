`define IDLE	3'd0
`define SORT	3'd1
`define OUT		3'd2
`define REST	3'd3


module analysis	(clk, rst, fft_valid,
				fft_d1, fft_d2, fft_d3, fft_d4, fft_d5, fft_d6, fft_d7, fft_d8,
				fft_d9, fft_d10, fft_d11, fft_d12, fft_d13, fft_d14, fft_d15, fft_d0,
				freq, done);

	input clk;
	input rst;
	input fft_valid;
	input [31:0] fft_d1, fft_d2, fft_d3, fft_d4, fft_d5, fft_d6, fft_d7, fft_d8;
	input [31:0] fft_d9, fft_d10, fft_d11, fft_d12, fft_d13, fft_d14, fft_d15, fft_d0;
	
	output reg [3:0] freq;
	output reg done;

reg [2:0] c_state, n_state;
reg [7:0] counter;
reg [3:0] max_idx;
reg signed [31:0] max_value;
wire [31:0] current_value;
wire signed [31:0] current_value_mux;


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
			if(fft_valid)
				n_state = `SORT;
			else
				n_state = c_state;
		end
		`SORT: begin
			if(counter == 12'd15)
				n_state = `OUT;
			else
				n_state = c_state;
		end
		`OUT: begin
			n_state = `REST;
		end
		`REST: begin
			n_state = c_state;
		end
		default: begin
			n_state = `IDLE;
		end
	endcase
end

always@(posedge clk, posedge rst) begin
	if(rst) begin
		counter <= 8'b0;
	end
	else begin
		if(c_state == `SORT) begin
			counter <= counter+1;
		end
	end
end



// SORTING~~~
assign current_value = 	(counter == 8'd0) ? fft_d0:
						(counter == 8'd1) ? fft_d1:
						(counter == 8'd2) ? fft_d2:
						(counter == 8'd3) ? fft_d3:
						(counter == 8'd4) ? fft_d4:
						(counter == 8'd5) ? fft_d5:
						(counter == 8'd6) ? fft_d6:
						(counter == 8'd7) ? fft_d7:
						(counter == 8'd8) ? fft_d8:
						(counter == 8'd9) ? fft_d9:
						(counter == 8'd10) ? fft_d10:
						(counter == 8'd11) ? fft_d11:
						(counter == 8'd12) ? fft_d12:
						(counter == 8'd13) ? fft_d13:
						(counter == 8'd14) ? fft_d14:
						fft_d15;
assign current_value_mux = (current_value[31:16]*current_value[31:16]) + (current_value[15:0]*current_value[15:0]);

always@(posedge clk, posedge rst) begin
	if(rst) begin
		max_idx <= 4'd0;
		max_value <= 32'hffff_ffff;
	end
	else begin
		if(c_state == `SORT) begin
			if(current_value_mux > max_value) begin
				max_idx <= counter[3:0];
				max_value <= current_value_mux;
			end
		end
	end
end

always@(*) begin
	if(c_state == `OUT) begin
		freq = max_idx;
		done = 1'd1;
	end
	else if(c_state == `REST) begin
		freq = max_idx;
		done = 1'd0;
	end
	else begin
		freq = 4'b0;
		done = 1'b0;
	end
end


endmodule