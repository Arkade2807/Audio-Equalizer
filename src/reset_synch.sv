module rst_synch(
		input RST_n,
		input clk,
		output reg rst_n
		);
	reg mid_v;
	always @(negedge clk, negedge RST_n)
	begin
		if(~RST_n)
		begin
			mid_v <= 0;
			rst_n <= 0;
		end
		else
		begin
			mid_v <= 1'b1;
			rst_n <= mid_v;
		end
	end
endmodule
