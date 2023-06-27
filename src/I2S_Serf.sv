module I2S_Serf(
		input clk,
		input rst_n,
		input I2S_sclk,
		input I2S_ws,
		input I2S_data,
		output [23:0] lft_chnnl,
		output [23:0] rght_chnnl,
		output reg vld
		);
	logic eq22, eq23, eq24, sclk_rise, ws_fall, clr_cnt;
	logic [4:0] bit_cntr;
	logic [47:0] shft_reg;
	//rise and fall edge detect
	synch_detect_pos pos(.asynch_sig_in(I2S_sclk), .clk(clk), .rst_n(rst_n), .rise_edge(sclk_rise));
	synch_detect_neg neg(.asynch_sig_in(I2S_ws), .clk(clk), .rst_n(rst_n), .fall_edge(ws_fall));

	//counter
	always_ff @(posedge clk, negedge rst_n)
		if(!rst_n)
			bit_cntr <= 0;
		else if(clr_cnt)
			bit_cntr <= 0;
		else if(sclk_rise)
			bit_cntr <= bit_cntr + 1; //increment occurs only on sclk rise
	assign eq22 = bit_cntr == 5'd22;
	assign eq23 = bit_cntr == 5'd23;
	assign eq24 = bit_cntr == 5'd24;

	//shift register
	always_ff @(posedge clk, negedge rst_n)
		if(!rst_n)
			shft_reg <= 0;
		else if(sclk_rise)
			shft_reg <= {shft_reg[46:0], I2S_data};//read a bit on sclk rise
	assign lft_chnnl = shft_reg[47:24];
	assign rght_chnnl = shft_reg[23:0];

	typedef enum logic [1:0] {WAIT_SYNC, DROP, SL, SR} state_t;
	state_t state, nxt_state;
	//state ff
	always_ff @(posedge clk, negedge rst_n)
		if(!rst_n)
			state <= WAIT_SYNC;
		else
			state <= nxt_state;
	//state comb
	always_comb begin
		clr_cnt = 1; //default clearing the counter
		vld = 0;
		nxt_state = state;
		case (state) inside
			WAIT_SYNC: if(ws_fall) nxt_state = DROP;//wait for begin
			DROP: if(sclk_rise) nxt_state = SL;//drop the first bit
			SL: if(!eq24)
					clr_cnt = 0;//read left chnnl, dont clear counter
				else
					nxt_state = SR;//all read, clear and next state
			SR: if((sclk_rise & eq22 & ~I2S_ws) | (sclk_rise & eq23 & I2S_ws)) // filling the current bit[22]/bit[23] and check if synced
					nxt_state = WAIT_SYNC;//out of sync
				else if(eq24) begin //finished with correct sync
					vld = 1; //set valid and switch to left chnnl
					nxt_state = SL;
				end
				else
					clr_cnt = 0;//read right chnnl, dont clear counter
		endcase
		
	end
endmodule
