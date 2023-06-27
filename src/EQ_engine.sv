module EQ_engine(
	input [15:0] aud_in_lft,
	input [15:0] aud_in_rght,
	input vld,
	output [15:0] aud_out_lft,
	output [15:0] aud_out_rght,
	input [11:0] POT_LP,
	input [11:0] POT_HP,
	input [11:0] POT_B1,
	input [11:0] POT_B2,
	input [11:0] POT_B3,
	input [11:0] VOLUME,
	input rst_n,
	output seq_low,
	input clk
	);
	
	logic [15:0] hi_freq_l, hi_freq_r, lo_freq_l, lo_freq_r;
	logic [15:0] LP_l, LP_r, B1_l, B1_r, B2_l, B2_r, B3_l, B3_r, HP_l, HP_r;
	logic [15:0] scaled_LPL, scaled_LPR, scaled_B1L, scaled_B1R, scaled_B2L, scaled_B2R, scaled_B3L, scaled_B3R, scaled_HPL, scaled_HPR;
	logic signed [15:0] ff_scaled_LPL, ff_scaled_LPR, ff_scaled_B1L, ff_scaled_B1R, ff_scaled_B2L, ff_scaled_B2R, ff_scaled_B3L, ff_scaled_B3R, ff_scaled_HPL, ff_scaled_HPR;
	logic signed [15:0] ff_all_lft, ff_all_rght;
	logic signed [28:0] fin_out_l, fin_out_r;
	logic signed [12:0] signed_vol;
	logic hi_seq, lo_seq, lvld;

	assign seq_low = lo_seq;
	
	always @(posedge clk, negedge rst_n)
		if(!rst_n)
			lvld <= 0;
		else
			lvld <= lvld + vld;
	
	
	high_freq_queue iHQ(.clk(clk), .rst_n(rst_n), .lft_smpl(aud_in_lft), .rght_smpl(aud_in_lft), .wrt_smpl(vld), .lft_out(hi_freq_l), .rght_out(hi_freq_r), .sequencing(hi_seq));
	low_freq_queue iLQ(.clk(clk), .rst_n(rst_n), .lft_smpl(aud_in_lft), .rght_smpl(aud_in_lft), .wrt_smpl(vld & lvld), .lft_out(lo_freq_l), .rght_out(lo_freq_r), .sequencing(lo_seq));
	
	
	FIR_LP iFIR_LP(.clk(clk), .rst_n(rst_n), .lft_in(lo_freq_l), .sequencing(lo_seq), .rght_in(lo_freq_r), .lft_out(LP_l), .rght_out(LP_r));
	FIR_B1 iFIR_B1(.clk(clk), .rst_n(rst_n), .lft_in(lo_freq_l), .sequencing(lo_seq), .rght_in(lo_freq_r), .lft_out(B1_l), .rght_out(B1_r));
	FIR_B2 iFIR_B2(.clk(clk), .rst_n(rst_n), .lft_in(hi_freq_l), .sequencing(hi_seq), .rght_in(hi_freq_r), .lft_out(B2_l), .rght_out(B2_r));
	FIR_B3 iFIR_B3(.clk(clk), .rst_n(rst_n), .lft_in(hi_freq_l), .sequencing(hi_seq), .rght_in(hi_freq_r), .lft_out(B3_l), .rght_out(B3_r));
	FIR_HP iFIR_HP(.clk(clk), .rst_n(rst_n), .lft_in(hi_freq_l), .sequencing(hi_seq), .rght_in(hi_freq_r), .lft_out(HP_l), .rght_out(HP_r));
	
	
	band_scale_piped iSCALE_LPL(.clk(clk), .rst_n(rst_n), .POT(POT_LP), .audio(LP_l), .scaled(scaled_LPL));
	band_scale_piped iSCALE_LPR(.clk(clk), .rst_n(rst_n), .POT(POT_LP), .audio(LP_r), .scaled(scaled_LPR));
	
	band_scale_piped iSCALE_B1L(.clk(clk), .rst_n(rst_n), .POT(POT_B1), .audio(B1_l), .scaled(scaled_B1L));
	band_scale_piped iSCALE_B1R(.clk(clk), .rst_n(rst_n), .POT(POT_B1), .audio(B1_r), .scaled(scaled_B1R));
	
	band_scale_piped iSCALE_B2L(.clk(clk), .rst_n(rst_n), .POT(POT_B2), .audio(B2_l), .scaled(scaled_B2L));
	band_scale_piped iSCALE_B2R(.clk(clk), .rst_n(rst_n), .POT(POT_B2), .audio(B2_r), .scaled(scaled_B2R));
	
	band_scale_piped iSCALE_B3L(.clk(clk), .rst_n(rst_n), .POT(POT_B3), .audio(B3_l), .scaled(scaled_B3L));
	band_scale_piped iSCALE_B3R(.clk(clk), .rst_n(rst_n), .POT(POT_B3), .audio(B3_r), .scaled(scaled_B3R));
	
	band_scale_piped iSCALE_HPL(.clk(clk), .rst_n(rst_n), .POT(POT_HP), .audio(HP_l), .scaled(scaled_HPL));
	band_scale_piped iSCALE_HPR(.clk(clk), .rst_n(rst_n), .POT(POT_HP), .audio(HP_r), .scaled(scaled_HPR));
	
	always_ff @(posedge clk, negedge rst_n)
		if(!rst_n) begin
			ff_scaled_B1L <= 0;
			ff_scaled_B1R <= 0;
			ff_scaled_B2L <= 0;
			ff_scaled_B2R <= 0;
			ff_scaled_B3L <= 0;
			ff_scaled_B3R <= 0;
			ff_scaled_HPL <= 0;
			ff_scaled_HPR <= 0;
			ff_scaled_LPL <= 0;
			ff_scaled_LPR <= 0;
		end
		else begin
			if(vld & lvld) begin
				ff_scaled_B1L <= scaled_B1L;
				ff_scaled_B1R <= scaled_B1R;
				ff_scaled_LPL <= scaled_LPL;
				ff_scaled_LPR <= scaled_LPR;
			end
			if(vld) begin
				ff_scaled_B2L <= scaled_B2L;
				ff_scaled_B2R <= scaled_B2R;
				ff_scaled_B3L <= scaled_B3L;
				ff_scaled_B3R <= scaled_B3R;
				ff_scaled_HPL <= scaled_HPL;
				ff_scaled_HPR <= scaled_HPR;
			end
		end
	
	always_ff @(posedge clk, negedge rst_n)
		if(!rst_n) begin
			ff_all_lft <= 0;
			ff_all_rght <= 0;
		end
		else begin
			ff_all_lft <= ff_scaled_B1L + ff_scaled_B2L + ff_scaled_B3L + ff_scaled_HPL + ff_scaled_LPL;
			ff_all_rght <= ff_scaled_B1R + ff_scaled_B2R + ff_scaled_B3R + ff_scaled_HPR + ff_scaled_LPR;
		end
	
	assign signed_vol = {1'b0, VOLUME};
	assign fin_out_l = signed_vol * ff_all_lft;
	assign fin_out_r = signed_vol * ff_all_rght;
	
	assign aud_out_lft = fin_out_l[27:12];
	assign aud_out_rght = fin_out_r[27:12];
endmodule
	
