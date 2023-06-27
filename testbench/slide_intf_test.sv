module slide_intf_test(clk, RST_n, NXT, SS_n, SCLK, MOSI, MISO, LEDs);
	input wire clk, RST_n, NXT, MISO;
	output wire [7:0] LEDs;
	output SS_n, SCLK, MOSI;

	wire inc, rst_n;
	PB_release pbr(.clk(clk), .rst_n(rst_n), .PB(NXT), .released(inc)); 
	rst_synch r(.clk(clk), .RST_n(RST_n), .rst_n(rst_n));
	logic [11:0] lp, b1, b2, b3, hp, vo, out;

	//counter
	reg [2:0] cnt;
	always @(posedge clk, negedge rst_n)
		if(!rst_n)
			cnt <= 0;
		else if(inc)
			cnt <= cnt == 3'd5 ? 0 : cnt+1;
	
	slide_intf intf(.SS_n(SS_n), .SCLK(SCLK), .MOSI(MOSI), .MISO(MISO), .clk(clk), .rst_n(rst_n), .POT_LP(lp), .POT_B1(b1), .POT_B2(b2), .POT_B3(b3), .POT_HP(hp), .VOLUME(vo));

	always_comb
		case(cnt)
		0: out = lp;
		1: out = b1;
		2: out = b2;
		3: out = b3;
		4: out = hp;
		5: out = vo;
		default: out = 0;
		endcase
	assign LEDs = out[11:4];
endmodule
