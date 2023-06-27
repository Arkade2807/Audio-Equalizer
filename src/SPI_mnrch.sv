module SPI_mnrch(
		input wire snd,
		input wire [15:0] cmd,
		input wire MISO,
		input wire clk,
		input wire rst_n,
		output reg done,
		output wire [15:0] resp,
		output reg SS_n,
		output wire SCLK,
		output wire MOSI
		);
	logic ld_SCLK, full, init, done16, set_done;
	//5-bit counter producing SCLK
	logic [4:0] clk_counter;
	assign SCLK = clk_counter[4];
	assign full = &clk_counter;
	always_ff @(posedge clk)
		clk_counter <= ld_SCLK ? 5'b10111 : clk_counter + 1;
	//shift register
	logic [15:0] shift_reg;
	logic en_shift;
	assign en_shift = clk_counter == 5'b10001;
	assign resp = shift_reg;
	assign MOSI = shift_reg[15];
	always @(posedge clk, negedge rst_n)
		if(!rst_n)
			shift_reg <= 0;
		else if(init)
			shift_reg <= cmd;
		else if(en_shift)
			shift_reg <= {shift_reg[14:0], MISO};//shift in
	//count number of bits send
	logic [4:0] bit_cntr;
	assign done16 = bit_cntr[4];
	always_ff @(posedge clk)
		if(init)
			bit_cntr <= 5'b00000;
		else if(en_shift)
			bit_cntr <= bit_cntr + 1;
		
	always @(posedge clk, negedge rst_n) begin//flop for output
		if(!rst_n) begin
			SS_n <= 1'b1;
			done <= 1'b0;
		end
		else begin if(init) begin
			SS_n <= 1'b0;
			done <= 1'b0;
		end else
		if(set_done) begin
			SS_n <= 1'b1;
			done <= 1'b1;
		end
		end
	end
	//state machine
	typedef enum logic [1:0] {IDLE, WAIT, DONE} state;
	state cur_state, next_state;//state register
	always_ff @(posedge clk, negedge rst_n)
		if(!rst_n) cur_state <= IDLE;
		else cur_state <= next_state;
	always_comb begin//initial value
		init = 1'b0;
		set_done = 1'b0;
		ld_SCLK = 1'b0;
		next_state = cur_state;
		case (cur_state)
			IDLE: if(~snd) ld_SCLK = 1'b1;
			else begin
				ld_SCLK = 1'b1;
				init = 1'b1;
				next_state = WAIT;
			end
			WAIT: if(done16) next_state = DONE;
			DONE: if(full) begin
				set_done = 1'b1;
				ld_SCLK = 1'b1;
				next_state = IDLE;
			end
			default: next_state = IDLE;
		endcase
	end
endmodule
