module slide_intf(
		input wire rst_n,
		input wire clk,
		input wire MISO,
		output wire MOSI,
		output wire SCLK,
		output wire SS_n,
		output reg[11:0] VOLUME,
		output reg[11:0] POT_LP,
		output reg[11:0] POT_B1,
		output reg[11:0] POT_B2,
		output reg[11:0] POT_B3,
		output reg[11:0] POT_HP
		);
	
	logic vo, lp, b1, b2, b3, hp;
	logic [2:0] chnnl, nxt_chnnl;
	logic [11:0] res;
	logic strt_cnv, cnv_cmplt;
	typedef enum logic [1:0]{IDLE, CONV1, CONV2} state_t;
	state_t state, nxt_state;
	A2D_intf a2d(.strt_cnv(strt_cnv), .clk(clk), .rst_n(rst_n), .chnnl(chnnl), .cnv_cmplt(cnv_cmplt), .res(res), .SS_n(SS_n), .SCLK(SCLK), .MOSI(MOSI), .MISO(MISO));
	//registers for outputs
	always_ff @(posedge clk, negedge rst_n)
		if(!rst_n) begin
			VOLUME <= 0;
			POT_LP <= 0;
			POT_B1 <= 0;
			POT_B2 <= 0;
			POT_B3 <= 0;
			POT_HP <= 0;
		end
		else if(vo) VOLUME <= res;
		else if(lp) POT_LP <= res;
		else if(b1) POT_B1 <= res;
		else if(b2) POT_B2 <= res;
		else if(b3) POT_B3 <= res;
		else if(hp) POT_HP <= res;
	
	//state ff
	always_ff @(posedge clk, negedge rst_n)
		if(!rst_n)begin
			state <= IDLE;
			chnnl <= 3'b111;
		end
		else begin
			state <= nxt_state;
			chnnl <= nxt_chnnl;
		end
	//state comb
	always_comb begin
		vo = 0;
		lp = 0;
		b1 = 0;
		b2 = 0;
		b3 = 0;
		hp = 0;
		nxt_state = state;
		nxt_chnnl = chnnl;
		strt_cnv = 0;
		case(state)
			IDLE: begin //call a conversion set chnnl
				strt_cnv = 1;
				nxt_state = CONV1;
			end
			CONV1: if(cnv_cmplt)begin // read data
				nxt_state = CONV2;
				strt_cnv = 1;
			end
			CONV2: if(cnv_cmplt)begin //wait for cmplt
				nxt_chnnl = chnnl == 3'b100 ? 3'b111 : chnnl + 1;//advance chnnl
				nxt_state = IDLE;
				vo = chnnl == 3'b111;
				lp = chnnl == 3'b001;
				b1 = chnnl == 3'b000;
				b2 = chnnl == 3'b100;
				b3 = chnnl == 3'b010;
				hp = chnnl == 3'b011;
			end
		endcase	
	end

endmodule
