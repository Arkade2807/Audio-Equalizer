module EQ_engine_tb();
	parameter one = 12'd2048;
	parameter zero = 12'd0;
	wire I2S_sclk, I2S_data, I2S_ws, vld;
	wire [23:0] lft_chnnl, rght_chnnl;
	wire [15:0] lfout, rfout;
	logic rst_n, clk;
	logic [11:0] l, h, b1, b2, b3;
	RN52_t rn52d(.cmd_n(1'b1), .RX(1'b1), .TX(), .I2S_sclk(I2S_sclk), .I2S_ws(I2S_ws), .I2S_data(I2S_data), .clk(clk), .RST_n(rst_n));
	I2S_Serf i2s_s(.I2S_sclk(I2S_sclk), .I2S_ws(I2S_ws), .I2S_data(I2S_data), .clk(clk), .rst_n(rst_n), .vld(vld), .rght_chnnl(rght_chnnl), .lft_chnnl(lft_chnnl));

	EQ_engine iEQ(.aud_in_lft(lft_chnnl[23:8]), .aud_in_rght(rght_chnnl[23:8]), .vld(vld), .aud_out_lft(lfout), .aud_out_rght(rfout), .POT_LP(l), .POT_HP(h), .POT_B1(b1), .POT_B2(b2), .POT_B3(b3), .VOLUME(12'd2048), .rst_n(rst_n), .clk(clk));

	initial begin
		clk = 0;
		rst_n = 0;
		l = one;
		h = 0;
		b1 = 0;
		b2 = 0;
		b3 = 0;
		repeat(2)@(negedge clk);
		rst_n = 1;

		repeat(3_100_000) @(posedge clk); //fill both queue
		l = zero;
		b1 = one;
		repeat (100_000) @(posedge clk);
		b1 = zero;
		b2 = one;
		repeat (100_000) @(posedge clk);
		b2 = zero;
		b3 = one;
		repeat (100_000) @(posedge clk);
		b3 = zero;
		h = one;
		repeat (100_000) @(posedge clk);
		$stop();

	end

	always #5 clk = ~clk;
endmodule
