`define IDLE 2'b00
`define LOAD 2'b01
`define SORT 2'b10
`define OUT  2'b11

module PSE(clk,reset,Xin,Yin,point_num,valid,Xout,Yout);
input clk;
input reset;
input [9:0] Xin;
input [9:0] Yin;
input [2:0] point_num;
output valid;
output reg [9:0] Xout;
output reg [9:0] Yout;

reg [1:0] c_state, n_state;
reg [2:0] counter_in, counter_out;
reg [9:0] x[5:0];
reg [9:0] y[5:0];

reg [2:0] idx_head, idx_butt;
wire [31:0] vector1, vector2, swap_p;
wire swap, sort_valid;

assign valid = (c_state == `OUT);
always@(posedge clk, posedge reset) begin
	if(reset) begin
		c_state <= `LOAD;
	end
	else begin
		c_state <= n_state;
	end
end

always@(posedge clk, posedge reset) begin //counters for counting input data
	if(reset) begin
		counter_in  <= 3'b0;
		counter_out <= 3'b0;
	end
	else begin
		if(c_state == `LOAD) begin
			counter_in  <= counter_in + 3'b1;
			counter_out <= 3'b0;
		end
		else if(c_state == `SORT) begin
			counter_in  <= 3'b0;
			counter_out <= 3'b0;
		end
		else if(c_state == `OUT) begin
			counter_in  <= 3'b0;
			counter_out <= counter_out + 3'b1;
		end
		else begin
			counter_in  <= 3'b0;
			counter_out <= 3'b0;
		end
	end
end

always@(*) begin //FSM
	case(c_state)
		`IDLE: n_state = `LOAD;
		`LOAD: begin
			if(counter_in == point_num-1)
				n_state = `SORT;
			else
				n_state = c_state;
		end
		`SORT: begin
			if(sort_valid) begin
				n_state = `OUT;
			end
			else begin
				n_state = `SORT;
			end
		end
		`OUT: begin
			if(counter_out == point_num-1)
				n_state = `LOAD;
			else
				n_state = c_state;
		end
		default: n_state = c_state;
	endcase
end
/*
always@(posedge clk) begin //read data in
	if(c_state == `LOAD) begin
		x[counter_in] <= Xin;
		y[counter_in] <= Yin;
	end
	else begin
		x[counter_in] <= x[counter_in];
		y[counter_in] <= y[counter_in];
	end
end
*/
always@(*) begin //dump data out
	if(c_state == `OUT) begin
		Xout = x[counter_out];
		Yout = y[counter_out];
	end
	else begin
		Xout = 10'b0;
		Yout = 10'b0;
	end
end

assign vector1 = (x[idx_head]-x[0])*(y[idx_head+1]-y[0]);
assign vector2 = (x[idx_head+1]-x[0])*(y[idx_head]-y[0]);
assign swap_p = (vector1-vector2);
assign swap = ~swap_p[31];
assign sort_valid = (idx_butt==3'b1);
//
always@(posedge clk) begin
	if(c_state == `SORT) begin
		if(swap) begin
			x[idx_head] <= x[idx_head+1];
			y[idx_head] <= y[idx_head+1];
			x[idx_head+1] <= x[idx_head];
			y[idx_head+1] <= y[idx_head];
		end
		else begin
			x[idx_head] <= x[idx_head];
			y[idx_head] <= y[idx_head];
			x[idx_head+1] <= x[idx_head+1];
			y[idx_head+1] <= y[idx_head+1];
		end
	end
	else if(c_state == `LOAD) begin
		x[counter_in] <= Xin;
		y[counter_in] <= Yin;
	end
end

always@(posedge clk) begin
	if(c_state == `SORT) begin
		if(idx_head == idx_butt) begin
			idx_head <= 3'b1;
			idx_butt <= idx_butt-3'b1;
		end
		else begin
			idx_head <= idx_head+3'b1;
			idx_butt <= idx_butt;
		end
	end
	else begin
		idx_head <= 3'b1;
		idx_butt <= point_num-3'd2;
	end
end
//
/*
always@(posedge clk, posedge reset) begin
	if(c_state == `SORT) begin
		if(swap) begin
			x[idx_head] <= x[idx_head+1];
			y[idx_head] <= y[idx_head+1];
			x[idx_head+1] <= x[idx_head];
			y[idx_head+1] <= y[idx_head];
		end
		else begin
			x[idx_head] <= x[idx_head];
			y[idx_head] <= y[idx_head];
			x[idx_head+1] <= x[idx_head+1];
			y[idx_head+1] <= y[idx_head+1];
		end
		
		if(idx_head == idx_butt) begin
			idx_head <= 3'b1;
			idx_butt <= idx_butt-3'b1;
		end
		else begin
			idx_head <= idx_head+3'b1;
			idx_butt <= idx_butt;
		end
	end
	else begin
		idx_head <= 3'b1;
		idx_butt <= point_num-3'd2;
	end
end
*/
endmodule

