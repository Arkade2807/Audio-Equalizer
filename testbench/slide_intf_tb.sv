`default_nettype none
module slide_intf_tb();
	logic [11:0] ans_lp, ans_b1, ans_b2, ans_b3, ans_hp, ans_vol, out_lp, out_b1, out_b2, out_b3, out_hp, out_vol;
	wire SS_n, SCLK, MOSI, MISO;
	logic clk, rst_n;
	A2D_with_Pots in(.LP(ans_lp), .B1(ans_b1), .B2(ans_b2), .B3(ans_b3), .HP(ans_hp), .VOL(ans_vol), .clk(clk), .rst_n(rst_n), .MISO(MISO), .MOSI(MOSI), .SCLK(SCLK), .SS_n(SS_n));
	slide_intf DUT(.SS_n(SS_n), .SCLK(SCLK), .MOSI(MOSI), .MISO(MISO), .rst_n(rst_n), .clk(clk), .POT_LP(out_lp), .POT_B1(out_b1), .POT_B2(out_b2), .POT_B3(out_b3), .POT_HP(out_hp), .VOLUME(out_vol));

	initial begin
		clk = 0;
		rst_n = 0;
		repeat(30) @(negedge clk);
		rst_n = 1;
		repeat(10) begin//10 random tests
			ans_lp = $random();
			ans_b1 = $random();
			ans_b2 = $random();
			ans_b3 = $random();
			ans_vol = $random();
			ans_hp = $random();

			repeat(10000) @(negedge clk);

			if(!(ans_lp === out_lp && ans_b1 === out_b1 && ans_b2 === out_b2 && ans_b3 === out_b3 && ans_vol === out_vol && ans_hp === out_hp))begin
				$display("ERROR!");
				$stop();
			end
		end
		$display("PASSED.");
		$stop();
	end
	always
		#5 clk = ~clk;
endmodule
