module LED_drv(clk, rst_n, lft, rht, LED);
	input clk, rst_n;			// system clock and active low reset
	input signed [15:0] lft;		// left channel
	input signed [15:0] rht;		// right channel
	output logic [7:0] LED;			// LED signal
	
	// define internal signals
	logic unsigned [15:0] abs_lft, abs_rht;	// absolute value of signed lft and rht input
	logic unsigned [11:0] intensity;	// average intensity of lft and rht signal
	logic [7:0] LED_temp;			// LED signal before ff
	
	// taking absolute value
	always_ff @(posedge clk, negedge rst_n)
		if (!rst_n)
			abs_lft <= 16'h0000;
		else if (lft[15])
			abs_lft <= -lft;
		else
			abs_lft <= lft;

	always_ff @(posedge clk, negedge rst_n)
		if (!rst_n)
			abs_rht <= 16'h0000;
		else if (rht[15])
			abs_rht <= -rht;
		else
			abs_rht <= rht;
			
	// calculating intensity
	assign intensity = (sqrt(abs_lft) + sqrt(abs_rht)) >> 1;
	
	// show corresponding LED number
	assign LED_temp = (intensity == 0)    ? 8'b00000000 :
			(intensity < 12'd23)  ? 8'b00000001 :
			(intensity < 12'd45)  ? 8'b00000011 :
			(intensity < 12'd68)  ? 8'b00000111 :
			(intensity < 12'd91)  ? 8'b00001111 :
			(intensity < 12'd113) ? 8'b00011111 :
			(intensity < 12'd136) ? 8'b00111111 :
			(intensity < 12'd158) ? 8'b01111111 :
						8'b11111111;

	// output
	always_ff @(posedge clk, negedge rst_n)
		if (!rst_n)
			LED <= 8'h00;
		else
			LED <= LED_temp;


	// function to find square root of a 16-bit number.
	// output is 8-bit.
	function [7:0] sqrt;
 		input [15:0] num;
 		// internal signals
 		reg [15:0] a;
 		reg [15:0] q;
 		reg [9:0] left,right,r;    
 		integer i;
		begin
			// initialize
			a = num;
			q = 0;
			i = 0;
			left = 0;   // input to adder/sub
			right = 0;  // input to adder/sub
			r = 0;  // remainder
			// run the calculations for 8 iterations.
			for(i = 0; i < 8; i = i + 1) begin 
 				right = {q, r[9], 1'b1};
				left = {r[7:0, a[15:14]};
 				a = {a[13:0], 2'b00};    // left shift by 2 bits.
 				if (r[9] == 1) // add if r is negative
					r = left + right;
				else    // subtract if r is positive
					r = left - right;
				q = {q[7:0], !r[9]};       
			end
			sqrt = q;   // final assignment of output.
		end
	endfunction // end of Function
	
endmodule
