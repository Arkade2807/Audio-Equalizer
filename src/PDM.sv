module PDM(
		input clk,
		input rst_n,
		input [15:0] duty,
		output reg PDM,
		output reg PDM_n
		);
	logic [15:0] duty_q, B;
	logic A_gt_B;
	//B-A
	assign A_gt_B = duty_q >= B;
	always_ff @(posedge clk, negedge rst_n)//async active low reset
		if(!rst_n)
			duty_q <= 0;
		else
			duty_q <= duty;
	always_ff @(posedge clk, negedge rst_n)//async active low reset
		if(!rst_n)
			B <= 0;
		else
			B <= B + ((A_gt_B ? 16'hffff : 16'h0000) - duty_q);
	
	always_ff @(posedge clk, negedge rst_n)//async active low reset
		if(!rst_n)
		begin
			PDM <= 1'b0;
			PDM_n <= 1'b1;
		end
		else
		begin
			PDM <= A_gt_B;
			PDM_n <= ~A_gt_B;
		end
endmodule
