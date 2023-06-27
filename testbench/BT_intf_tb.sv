module BT_intf_tb();
	logic clk, rst_n, prev_n, next_n, cmd_n, TX, RX, S_sclk, S_ws, S_data, vld;
	logic [23:0] out_lft, out_rght, lft_smpld, rght_smpld;

	BT_intf bt(.next_n(next_n), .clk(clk), .rst_n(rst_n), .prev_n(prev_n), .cmd_n(cmd_n), .TX(TX), .RX(RX));
	RN52 rn52d(.cmd_n(cmd_n), .RX(TX), .TX(RX), .I2S_sclk(S_sclk), .I2S_ws(S_ws), .I2S_data(S_data), .clk(clk), .RST_n(rst_n));
	I2S_Serf i2s_s(.I2S_sclk(S_sclk), .I2S_ws(S_ws), .I2S_data(S_data), .clk(clk), .rst_n(rst_n), .vld(vld), .rght_chnnl(out_rght), .lft_chnnl(out_lft));

	always_ff @(posedge clk, negedge rst_n)
		if(!rst_n) begin
			lft_smpld <= 0;
			rght_smpld <= 0;
		end
		else if(vld) begin
			lft_smpld <= out_lft;
			rght_smpld <= out_rght;
		end

	initial begin
		clk = 0;
		rst_n = 0;
		next_n = 1;
		prev_n = 1;
		repeat (2) @(negedge clk);
		rst_n = 1;

		repeat(400000) @(negedge clk);

		next_n = 0;
		repeat (2) @(negedge clk);
		next_n = 1;
		
		repeat(300000) @(negedge clk);

		prev_n = 0;
		repeat (2) @(negedge clk);
		prev_n = 1;
		
		repeat(300000) @(negedge clk);
		$stop();
	end

	always
		#5 clk = ~clk;

endmodule
