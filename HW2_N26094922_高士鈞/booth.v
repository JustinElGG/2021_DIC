`timescale 1ns / 10ps
module booth(out, in1, in2);

parameter width = 6;

input  	[width-1:0]   in1; //multiplicand
input  	[width-1:0]   in2; //multiplier
output  [2*width-1:0] out; //product

/*write your code here*/

reg [2*width:0]  P; 
reg [3:0]   i;

assign out = P[2*width:1];

always@(*)begin
    P = (in2 << 1) + 13'b0;
    for(i = 0; i< width; i = i+1)begin
		case(P[1:0])
			2'b00:begin 
				P = $signed(P) >>> 1 ;
			end
			2'b01:begin
				P = $signed({P[2*width:width+1]+in1, P[width:0]}) >>> 1;
			end
			2'b10:begin
				P = $signed({P[2*width:width+1]-in1, P[width:0]}) >>> 1;
			end
			2'b11:begin
				P = $signed(P) >>> 1;
			end
			default:begin
			end
		endcase
    end
end




endmodule
