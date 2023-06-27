module band_scale_piped(
		input unsigned [11:0] POT,
		input signed [15:0] audio,
		output signed [15:0] scaled,
		input clk,
		input rst_n
		);
	logic [23:0] squred, squred_org;
	logic signed [15:0] audio_pipe;
	wire signed [12:0] tru_sq;
	wire signed [28:0] ful_pr;
	assign squred_org = POT*POT;

	always_ff @(posedge clk, negedge rst_n)
		if(!rst_n) begin
			squred <= 0;
		end
		else begin
			squred <= squred_org;
		end
	
	assign tru_sq = {1'b0, squred[23:12]};//in^2/4096
	assign ful_pr = audio * tru_sq;
	assign scaled = (ful_pr[28] != ful_pr[27] | ful_pr[28] != ful_pr[26] | ful_pr[28] != ful_pr[25]) ? {ful_pr[28], {15{~ful_pr[28]}}} : ful_pr[25:10];//if any bit above what we need is meaningful, need to saturate the res
endmodule
