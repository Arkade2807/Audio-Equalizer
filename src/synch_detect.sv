module synch_detect_pos(input asynch_sig_in,
		            input clk,
					input rst_n,
					output rise_edge);
	logic ff_q0, ff_sync, ff_input_sig, ff_input_sig_n;
	
	//sync
	dff sync_dff0(.D(asynch_sig_in), .clk(clk), .PRN(rst_n), .Q(ff_q0));
	dff sync_dff1(.D(ff_q0), .clk(clk), .PRN(rst_n), .Q(ff_sync));

	//rising edge detect
	dff input_ff(.D(ff_sync), .clk(clk), .PRN(rst_n), .Q(ff_input_sig));
	not (ff_input_sig_n, ff_input_sig);
	and (rise_edge, ff_sync, ff_input_sig_n);
endmodule
module synch_detect_neg(input asynch_sig_in,
		            input clk,
					input rst_n,
					output fall_edge);
	logic ff_q0, ff_sync, ff_input_sig, ff_input_sig_n;
	
	//sync
	dff sync_dff0(.D(asynch_sig_in), .clk(clk), .PRN(rst_n), .Q(ff_q0));
	dff sync_dff1(.D(ff_q0), .clk(clk), .PRN(rst_n), .Q(ff_sync));

	//edge detect
	dff input_ff(.D(ff_sync), .clk(clk), .PRN(rst_n), .Q(ff_input_sig));
	not (ff_input_sig_n, ff_sync);
	and (fall_edge, ff_input_sig, ff_input_sig_n);
endmodule
