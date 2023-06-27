module A2D_intf(
		input clk,
		input rst_n,
		input strt_cnv,
		input [2:0] chnnl,
		input MISO,
		output MOSI,
		output SCLK,
		output SS_n,
		output reg cnv_cmplt,
		output [11:0] res
		);
	logic finish, snd, done;
	logic [15:0] cmd, resp;
	typedef enum logic [1:0] {IDLE, SETC, WAIT, RECV} state_t;
	state_t state, nxt_state;
	
	//flop for cnv_cmplt
	always_ff @(posedge clk, negedge rst_n)
		if(!rst_n)
			cnv_cmplt = 0;
		else if(strt_cnv)
			cnv_cmplt = 0;
		else if(finish)
			cnv_cmplt = 1;
	
	//flop for SM
	always_ff @(posedge clk, negedge rst_n)
		if(!rst_n)
			state = IDLE;
		else
			state = nxt_state;
	//comb for SM
	always_comb begin
		nxt_state = state;
		snd = 0;
		finish = 0;
		case(state)
			IDLE: if(strt_cnv) begin
				snd = 1;
				nxt_state = SETC;
			end
			SETC: if(done) nxt_state = WAIT;
			WAIT: nxt_state = RECV;
			RECV: if(done) begin
				finish = 1;
				nxt_state = IDLE;
			end
		endcase
	end
	
	//SPI module
	SPI_mnrch spi_driver(.rst_n(rst_n), .clk(clk), .cmd(cmd), .snd(snd), .done(done), .resp(resp), .SS_n(SS_n), .SCLK(SCLK), .MOSI(MOSI), .MISO(MISO));
	assign res = resp[11:0];
	assign cmd = {2'b00, chnnl, 11'd0};
endmodule
