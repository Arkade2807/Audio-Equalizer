module LED_tb();
	logic clk, rst_n;
	logic [15:0] lft;
	logic [15:0] rht;
	logic [7:0] LED;

	LED_drv iDUT(.clk(clk),.rst_n(rst_n),.lft(lft),.rht(rht),.LED(LED));

	initial begin
		clk = 0;
		rst_n = 0;

		lft = 16'hFFFF;
		rht = 16'hFFFF;
		@(posedge clk);
		@(negedge clk);
		rst_n = 1;
		repeat(10)@(posedge clk);

		lft = 16'h1FFE;
		rht = 16'h1FFE;
		@(posedge clk);
		@(negedge clk);
		repeat(10)@(posedge clk);
		
		lft = 16'h7FFF;
		rht = 16'h7FFF;
		@(posedge clk);
		@(negedge clk);
		repeat(10)@(posedge clk);

		lft = 16'h0000;
		rht = 16'h0000;
		@(posedge clk);
		@(negedge clk);
		repeat(10)@(posedge clk);

		lft = 16'h0001;
		rht = 16'h0001;
		@(posedge clk);
		@(negedge clk);
		repeat(10)@(posedge clk);

		lft = 16'h7FFF;
		rht = 16'h0000;
		@(posedge clk);
		@(negedge clk);
		repeat(10)@(posedge clk);

		lft = 16'h7FFF;
		rht = 16'h8000;
		@(posedge clk);
		@(negedge clk);
		repeat(10)@(posedge clk);

		$stop();
	end

	always
  		#5 clk = ~ clk;

endmodule
		