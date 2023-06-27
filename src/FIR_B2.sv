module FIR_B2(
		input clk,
		input rst_n,
		input wire signed [15:0] lft_in,
		input wire signed [15:0] rght_in,
		input sequencing,
		output [15:0] lft_out,
		output [15:0] rght_out
		);
	typedef enum logic [1:0] {IDLE, WAIT, CONV} state_t;
	state_t state, nxt_state;
	logic clear, incr, accum;
	logic [9:0] coeff_addr;
	wire signed [15:0] coeff;
	reg signed [31:0] lft_val, rght_val;
	//addr for rom
	always @(posedge clk, negedge rst_n)
		if(!rst_n)
			coeff_addr <= 0;
		else if(clear)
			coeff_addr <= 0;
		else if(incr)
			coeff_addr <= coeff_addr + 1;
	ROM_B2 rom(.clk(clk), .addr(coeff_addr), .dout(coeff));
	
	//sm ff
	always_ff @(posedge clk, negedge rst_n)
		if(!rst_n)
			state <= IDLE;
		else state <= nxt_state;
	
	//sm comb
	always_comb begin
		nxt_state = state;
		clear = 0;
		incr = 0;
		accum = 0;
		case(state)
		IDLE:if(sequencing) begin
			clear = 1;//clear regs
			nxt_state = WAIT;
		end
		WAIT: begin //wait for coeff ready
			incr = 1;
			nxt_state = CONV;
		end
		CONV:if(sequencing) begin
			incr = 1;
			accum = 1; //start the convolution
		end
		else nxt_state = IDLE;
		default:nxt_state = IDLE;
		endcase
	end
	//multiply and accum
	always @(posedge clk, negedge rst_n)
		if(!rst_n) begin
			lft_val <= 0;
			rght_val <= 0;
		end
		else if(clear) begin
			lft_val <= 0;
			rght_val <= 0;
		end
		else if(accum) begin
			lft_val <= lft_val + lft_in * coeff;
			rght_val <= rght_val + rght_in * coeff;
		end
	assign lft_out = lft_val[30:15];
	assign rght_out = rght_val[30:15];
endmodule
