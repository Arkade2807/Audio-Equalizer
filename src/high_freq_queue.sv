module high_freq_queue(
		input clk,
		input rst_n,
		input [15:0] lft_smpl,
		input [15:0] rght_smpl,
		input wrt_smpl,
		output [15:0] lft_out,
		output [15:0] rght_out,
		output reg sequencing);
	parameter queue_size = 1531;
	parameter real_len = 1021;
	parameter t_size = 1536 - 1;

	typedef enum logic {IDLE, READ} state_t;
	state_t state, nxt_state;
	logic queue_full, incr_read;
	logic [10:0] old_ptr, new_ptr, read_ptr, ctr;
	//left queue
	dualPort1536x16 lram(.clk(clk), .we(wrt_smpl), .waddr(new_ptr), .raddr(read_ptr), .wdata(lft_smpl), .rdata(lft_out));
	//right queue
	dualPort1536x16 rram(.clk(clk), .we(wrt_smpl), .waddr(new_ptr), .raddr(read_ptr), .wdata(rght_smpl), .rdata(rght_out));
	//generate queue_full
	always_ff @(posedge clk, negedge rst_n)
		if(!rst_n)
			queue_full <= 0;
		else if(new_ptr == queue_size) //new - old, old = 0
			queue_full <= 1;
	//old_new addr
	always @(posedge clk, negedge rst_n)begin
		if(!rst_n) begin
			old_ptr <= 0;
			new_ptr <= 0;
		end
		else if(wrt_smpl & queue_full) begin
			new_ptr <= new_ptr == t_size ? 0 : new_ptr + 1; //wrapping
			old_ptr <= old_ptr == t_size ? 0 : old_ptr + 1;
		end
		else if(wrt_smpl)
			new_ptr <= new_ptr + 1;
	end

	//increment read_addr, ctr
	always @(posedge clk, negedge rst_n)
		if(!rst_n)begin
			read_ptr <= 0;
			ctr <= 0;
		end
		else if(incr_read)begin
			read_ptr <= read_ptr == t_size ? 0 : read_ptr + 1; //wrap over
			ctr <= ctr + 1;
		end
		else begin
			read_ptr <= old_ptr;
			ctr <= 0;
		end

	//state sm
	always_ff @(posedge clk, negedge rst_n)
		if(!rst_n)
			state <= IDLE;
		else
			state <= nxt_state;
	
	always_comb begin
		incr_read = 0;
		nxt_state = state;
		sequencing = 0;
		case(state)
			IDLE: if(queue_full & wrt_smpl) begin //read out condition
				nxt_state = READ;
			end
			READ: if(ctr == real_len) begin //alawys assert seq in this state, if number of read achieved, exit
				sequencing = 1;
				nxt_state = IDLE;
			end
			else begin
				sequencing = 1;
				incr_read = 1; //incr ptr and ctr
			end
		endcase
	end
endmodule
