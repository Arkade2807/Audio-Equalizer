module bt_intf(
	input next_n,
	input prev_n,
	input RX,
	input clk,
	input rst_n,
	output TX,
	output reg cmd_n
	);
	logic [16:0] timer;
	typedef enum logic [1:0] {INT1, INT2, IDLE, WAIT} state_t;
	state_t state, nxt_state;
	logic [4:0] cmd_start;
	logic send, resp_rcvd;
	logic [3:0] cmd_len;
	logic timer_exp, prev, next;

	snd_cmd uart_intf(.cmd_start(cmd_start), .send(send), .cmd_len(cmd_len), .resp_rcvd(resp_rcvd), .clk(clk), .rst_n(rst_n), .TX(TX), .RX(RX));
	//17 bit timer
	assign timer_exp = ~(|timer);
	always_ff @(posedge clk, negedge rst_n)
		if(!rst_n)
			timer <= '1;
		else
			timer <= timer_exp ? timer : timer - 1;
	
	//sm ff
	always_ff @(posedge clk, negedge rst_n)
		if(!rst_n)
			state <= INT1;
		else 
			state <= nxt_state;
	//sm comb
	always_comb begin
		cmd_n = 0;
		cmd_start = 0;
		cmd_len = 0;
		send = 0;
		nxt_state = state;
		case (state)
		INT1: if(timer_exp & resp_rcvd)begin //timer expired and resp received
				nxt_state = INT2;
				cmd_start = 5'b0;
				cmd_len = 4'd6;
				send = 1;
		end
		else if(~timer_exp)cmd_n = 1; //timer not exp, set cmd_n
		INT2: if(resp_rcvd) begin//resp received, send next intit cmd
			nxt_state = WAIT;
			cmd_start = 5'b00110;
			cmd_len = 4'd10;
			send = 1;
		end
		WAIT: if(resp_rcvd) nxt_state = IDLE;
		IDLE: if(next) begin
			nxt_state = WAIT;
			cmd_start = 5'b10000;
			cmd_len = 4'd4;
			send = 1;
		end
		else if (prev) begin
			nxt_state = WAIT;
			cmd_start = 5'b10100;
			cmd_len = 4'd4;
			send = 1;
		end
		endcase
	end

	PB_release pb_next(.PB(next_n), .released(next), .clk(clk), .rst_n(rst_n));
	PB_release pb_prev(.PB(prev_n), .released(prev), .clk(clk), .rst_n(rst_n));
endmodule
