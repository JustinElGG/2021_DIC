`timescale 1ns/10ps
`define LENGTH 	14'd16383
`define IDLE 	3'd0
`define LOAD 	3'd1
`define CONV 	3'd2
`define WRITE 	3'd3
`define DONE 	3'd4

module MFE(clk,reset,busy,ready,iaddr,idata,data_rd,data_wr,addr,wen);
	input				clk;
	input				reset;
	output reg			busy;	
	input				ready;	
	output	 	[13:0]	iaddr;
	input		[7:0]	idata;	
	input		[7:0]	data_rd;
	output reg 	[7:0]	data_wr;
	output reg 	[13:0]	addr;
	output reg			wen;
	
integer i, j;
reg  [2:0] c_state, n_state;
reg  [14:0] in_addr [0:8]; //to decide load which pixel to in_map
reg  [7:0]  in_map  [0:8];
//reg [7:0] out_map [0:`LENGTH];
reg  [13:0] global_count, load_count, write_count;
reg  [7:0] pre_sort [0:8];
reg  [7:0] temp;
wire [6:0] x_pos, y_pos;
reg [2:0] idx_head, idx_butt;
wire sort_valid;

assign iaddr = in_addr[load_count];
assign x_pos = global_count[6:0];
assign y_pos = global_count[13:7];
assign sort_valid = (idx_butt==3'b1);

// FSM
always@(posedge clk, posedge reset) begin
	if(reset) begin
		c_state <= `IDLE;
	end
	else begin
		c_state <= n_state;
	end
end

always@(*) begin
	case(c_state)
		`IDLE: begin
			if(ready)
				n_state = `LOAD;
			else
				n_state = c_state;
		end
		`LOAD: begin
			if(load_count == 14'd8)
				n_state = `CONV;
			else
				n_state = c_state;
		end
		`CONV: begin
			if(sort_valid == 1'd1)
				n_state = `WRITE;
			else
				n_state = `CONV;
		end
		`WRITE: begin
			if(global_count == `LENGTH)
				n_state = `DONE;
			else
				n_state = `LOAD;
		end
		`DONE: begin
			n_state = `IDLE;
		end
		default: begin
			n_state = `IDLE;
		end
	endcase
end

// counters' home~
always@(posedge clk, posedge reset) begin
	if(reset) begin
		global_count <= 14'b0;
		load_count   <= 14'b0;
	end
	else begin
		if(c_state == `WRITE) begin
			global_count <= global_count+14'b1;
			load_count   <= 14'b0;
		end
		else if(c_state == `LOAD) begin
			global_count <= global_count;
			load_count   <= load_count+14'b1;
		end
		else begin
			global_count <= global_count;
			load_count   <= 14'b0;
		end
	end
end

//load which pixel
always@(*) begin
	// define 8 special cases and 1 general case
	//// 4 corner
	if(x_pos == 7'd0 && y_pos == 7'd0) begin //kernel at 'upper left'
		in_addr[0] = {1'd1, 14'd0};
		in_addr[1] = {1'd1, 14'd0};
		in_addr[2] = {1'd1, 14'd0};
		in_addr[3] = {1'd1, 14'd0};
		in_addr[4] = {1'd0, global_count};
		in_addr[5] = {1'd0, global_count+14'd1};
		in_addr[6] = {1'd1, 14'd0};
		in_addr[7] = {1'd0, global_count+14'd128};
		in_addr[8] = {1'd0, global_count+14'd129};
	end
	else if(x_pos == 7'd127 && y_pos == 7'd0) begin //kernel at 'upper right'
		in_addr[0] = {1'd1, 14'd0};
		in_addr[1] = {1'd1, 14'd0};
		in_addr[2] = {1'd1, 14'd0};
		in_addr[3] = {1'd0, global_count-14'd1};
		in_addr[4] = {1'd0, global_count};
		in_addr[5] = {1'd1, 14'd0};
		in_addr[6] = {1'd0, global_count+14'd127};
		in_addr[7] = {1'd0, global_count+14'd128};
		in_addr[8] = {1'd1, 14'd0};
	end
	else if(x_pos == 7'd0 && y_pos == 7'd127) begin //kernel at 'button left'
		in_addr[0] = {1'd1, 14'd0};
		in_addr[1] = {1'd0, global_count-14'd128};
		in_addr[2] = {1'd0, global_count-14'd129};
		in_addr[3] = {1'd1, 14'd0};
		in_addr[4] = {1'd0, global_count};
		in_addr[5] = {1'd0, global_count+14'd1};
		in_addr[6] = {1'd1, 14'd0};
		in_addr[7] = {1'd1, 14'd0};
		in_addr[8] = {1'd1, 14'd0};
	end
	else if(x_pos == 7'd127 && y_pos == 7'd127) begin //kernel at 'button right'
		in_addr[0] = {1'd0, global_count-14'd129};
		in_addr[1] = {1'd0, global_count-14'd128};
		in_addr[2] = {1'd1, 14'd0};
		in_addr[3] = {1'd0, global_count-14'd1};
		in_addr[4] = {1'd0, global_count};
		in_addr[5] = {1'd1, 14'd0};
		in_addr[6] = {1'd1, 14'd0};
		in_addr[7] = {1'd1, 14'd0};
		in_addr[8] = {1'd1, 14'd0};
	end
	//// 4 side
	else if(x_pos == 7'd0) begin //kernel at 'left side'
		in_addr[0] = {1'd1, 14'd0};
		in_addr[1] = {1'd0, global_count-14'd128};
		in_addr[2] = {1'd0, global_count-14'd127};
		in_addr[3] = {1'd1, 14'd0};
		in_addr[4] = {1'd0, global_count};
		in_addr[5] = {1'd0, global_count+14'd1};
		in_addr[6] = {1'd1, 14'd0};
		in_addr[7] = {1'd0, global_count+14'd128};
		in_addr[8] = {1'd0, global_count+14'd129};
	end
	else if(x_pos == 7'd127) begin //kernel at 'right side'
		in_addr[0] = {1'd0, global_count-14'd129};
		in_addr[1] = {1'd0, global_count-14'd128};
		in_addr[2] = {1'd1, 14'd0};
		in_addr[3] = {1'd0, global_count-14'd1};
		in_addr[4] = {1'd0, global_count};
		in_addr[5] = {1'd1, 14'd0};
		in_addr[6] = {1'd0, global_count+14'd127};
		in_addr[7] = {1'd0, global_count+14'd128};
		in_addr[8] = {1'd1, 14'd0};
	end
	else if(y_pos == 7'd0) begin //kernel at 'upper side'
		in_addr[0] = {1'd1, 14'd0};
		in_addr[1] = {1'd1, 14'd0};
		in_addr[2] = {1'd1, 14'd0};
		in_addr[3] = {1'd0, global_count-14'd1};
		in_addr[4] = {1'd0, global_count};
		in_addr[5] = {1'd0, global_count+14'd1};
		in_addr[6] = {1'd0, global_count+14'd127};
		in_addr[7] = {1'd0, global_count+14'd128};
		in_addr[8] = {1'd0, global_count+14'd129};
	end
	else if(y_pos == 7'd127) begin //kernel at 'botton side'
		in_addr[0] = {1'd0, global_count-14'd129};
		in_addr[1] = {1'd0, global_count-14'd128};
		in_addr[2] = {1'd0, global_count-14'd127};
		in_addr[3] = {1'd0, global_count-14'd1};
		in_addr[4] = {1'd0, global_count};
		in_addr[5] = {1'd0, global_count+14'd1};
		in_addr[6] = {1'd1, 14'd0};
		in_addr[7] = {1'd1, 14'd0};
		in_addr[8] = {1'd1, 14'd0};
	end
	//// 1 general
	else begin
		in_addr[0] = {1'd0, global_count-14'd129};
		in_addr[1] = {1'd0, global_count-14'd128};
		in_addr[2] = {1'd0, global_count-14'd127};
		in_addr[3] = {1'd0, global_count-14'd1};
		in_addr[4] = {1'd0, global_count};
		in_addr[5] = {1'd0, global_count+14'd1};
		in_addr[6] = {1'd0, global_count+14'd127};
		in_addr[7] = {1'd0, global_count+14'd128};
		in_addr[8] = {1'd0, global_count+14'd129};
	end
end

//load data
always@(posedge clk) begin

	if(c_state == `LOAD) begin
		if(in_addr[load_count][14] == 1'b1)
			in_map[load_count] <= 14'd0;
		else
			in_map[load_count] <= idata;
	end
	else if(c_state == `CONV) begin
		if(in_map[idx_head] < in_map[idx_head+1]) begin
			in_map[idx_head]   <= in_map[idx_head+1];
			in_map[idx_head+1] <= in_map[idx_head];
		end
		else begin
			in_map[idx_head]   <= in_map[idx_head];
			in_map[idx_head+1] <= in_map[idx_head+1];
		end
	end
	else begin
		in_map[load_count] <= in_map[load_count];
	end

end

always@(posedge clk) begin
	if(reset) begin
		idx_head <= 3'b0;
		idx_butt <= 3'b0;
	end
	else begin	
		if(c_state == `CONV) begin
			if(idx_head == idx_butt) begin
				idx_head <= 3'b0;
				idx_butt <= idx_butt-3'b1;
			end
			else begin
				idx_head <= idx_head+3'b1;
				idx_butt <= idx_butt;
			end
		end
		else begin
			idx_head <= 3'b0;
			idx_butt <= 3'd7;
		end
	end
end


// main func
always@(*) begin
	case(c_state)
		`IDLE: begin
			busy = 1'b0;
			wen = 1'b0;
			addr = 14'd0;
			data_wr = 8'd0;
		end
		`LOAD: begin
			busy = 1'b1;
			wen = 1'b0;
			addr = 14'd0;
			data_wr = 8'd0;
		end
		`CONV: begin
			busy = 1'b1;
			wen = 1'b0;
			addr = 14'd0;
			data_wr = 8'd0;
		end
		`WRITE: begin
			busy = 1'b1;
			wen = 1'b1;
			addr = global_count;
			data_wr = in_map[4];
		end
		`DONE: begin
			busy = 1'b0;
			wen = 1'b0;
			addr = 14'd0;
			data_wr = 8'd0;
		end
		default: begin
			busy = 1'b0;
			wen = 1'b0;
			addr = 14'd0;
			data_wr = 8'd0;
		end
	endcase
end



endmodule
