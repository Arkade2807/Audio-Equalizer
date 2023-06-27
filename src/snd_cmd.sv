module snd_cmd(
		input [4:0] cmd_start,
		input [3:0] cmd_len,
		input send,
		input clk,
		input rst_n,
		input RX,
		output TX,
		output resp_rcvd
		);
	typedef enum logic [1:0] {IDLE, RMEM, SEND, WAIT} state_t;
	state_t nxt_state, state;
	wire [7:0] dout, rx_data;
	reg inc_addr, trmt;
	wire last_byte, tx_done, rx_rdy;
	reg [4:0] eff_addr, last_addr;
	cmdROM crom(.clk(clk), .addr(eff_addr), .dout(dout));
	UART iuart(.clk(clk), .rst_n(rst_n), .RX(RX), .TX(TX), .rx_rdy(rx_rdy), .clr_rx_rdy(rx_rdy), .rx_data(rx_data), .trmt(trmt), .tx_data(dout), .tx_done(tx_done));
	assign resp_rcvd = rx_rdy & (rx_data == 8'h0A);
	//logic for eff_addr
	always_ff @(posedge clk, negedge rst_n) begin
		if(!rst_n)
			eff_addr <= 0;
		else if(send)
			eff_addr <= cmd_start;
		else if(inc_addr)
			eff_addr <= eff_addr + 1;
	end

	//logic for compare
	always_ff @(posedge clk, negedge rst_n) begin
		if(!rst_n)
			last_addr <= 0;
		else if(send)
			last_addr <= cmd_len + cmd_start;
	end
	assign last_byte = eff_addr === last_addr;

	//sm ff
	always_ff @(posedge clk, negedge rst_n)
		if(!rst_n)
			state <= IDLE;
		else
			state <= nxt_state;
	always_comb begin
		nxt_state = state;
		inc_addr = 0;
		trmt = 0;
		case(state) inside
		IDLE: if(send) nxt_state = RMEM; //wait for send
		RMEM: nxt_state = SEND; //wait for rom to read
		SEND: if(~last_byte) begin //send if not last_byte (start of next)
			trmt = 1;
			nxt_state = WAIT;
		end
		else nxt_state = IDLE; //otherwise back to idle
		WAIT: //finish send, inc addr and read rom
			if(tx_done)begin
				inc_addr = 1;
				nxt_state = RMEM;
			end
		endcase
	end
endmodule
