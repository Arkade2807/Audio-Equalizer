`timescale 1ns/1ps
module Equalizer_tb();

reg clk,RST_n;
reg next_n,prev_n,Flt_n;
reg [11:0] LP,B1,B2,B3,HP,VOL;
logic signed [15:0] rev_left, rev_right;
logic debug;

wire [7:0] LED;
wire ADC_SS_n,ADC_MOSI,ADC_MISO,ADC_SCLK;
wire I2S_data,I2S_ws,I2S_sclk;
wire cmd_n,RX_TX,TX_RX;
wire lft_PDM,rght_PDM;
wire lft_PDM_n,rght_PDM_n;

//////////////////////
// Instantiate DUT //
////////////////////
Equalizer iDUT(.clk(clk),.RST_n(RST_n),.LED(LED),.ADC_SS_n(ADC_SS_n),
                .ADC_MOSI(ADC_MOSI),.ADC_SCLK(ADC_SCLK),.ADC_MISO(ADC_MISO),
                .I2S_data(I2S_data),.I2S_ws(I2S_ws),.I2S_sclk(I2S_sclk),.cmd_n(cmd_n),
				.sht_dwn(sht_dwn),.lft_PDM(lft_PDM),.rght_PDM(rght_PDM),
				.lft_PDM_n(lft_PDM_n),.rght_PDM_n(rght_PDM_n),.Flt_n(Flt_n),
				.next_n(next_n),.prev_n(prev_n),.RX(RX_TX),.TX(TX_RX));
	
	
//////////////////////////////////////////
// Instantiate model of RN52 BT Module //
////////////////////////////////////////	
RN52 iRN52(.clk(clk),.RST_n(RST_n),.cmd_n(cmd_n),.RX(TX_RX),.TX(RX_TX),.I2S_sclk(I2S_sclk),
           .I2S_data(I2S_data),.I2S_ws(I2S_ws));

//////////////////////////////////////////////
// Instantiate model of A2D and Slide Pots //
////////////////////////////////////////////		   
A2D_with_Pots iPOTs(.clk(clk),.rst_n(rst_n),.SS_n(ADC_SS_n),.SCLK(ADC_SCLK),.MISO(ADC_MISO),
                    .MOSI(ADC_MOSI),.LP(LP),.B1(B1),.B2(B2),.B3(B3),.HP(HP),.VOL(VOL));

task init_sim();
	begin
		clk = 0;
		next_n = 1;
		prev_n = 1;
		LP = 0;
		B1 = 0;
		B2 = 0;
		B3 = 0;
		HP = 0;
		VOL = 0;
		RST_n = 0;
		#42 RST_n = 1;
	end
endtask

task switch_song();
	logic rbit;
	begin
		rbit = $random();
		if(rbit)
			prev_n = 0;
		else
			next_n = 0;
		repeat(2) @(negedge clk);

		next_n = 1;
		prev_n = 1;
	end
endtask

task automatic set_pot_and_check(ref [11:0] POT, ref signed [15:0] aud, input [15:0] freq, input [11:0] test_pot);
	int signed min_time = 0, max_time = 0;
	logic err;
	int ptr = 0, temp, POT_backup, acutal_amp, ref_amp;
	int signed max = 0;
	int signed min = 0;
	int period = 1e9/freq, count=0; //period in ns
	real rat;
	int signed time_diff=0;
	
	begin
	//	VOL = 0;
	//	do begin
	//		VOL = (VOL << 2 + 3); //change master vol
			POT = test_pot;
			err = 0;
			fork
				begin: wait_res 
					repeat(5_000_000) @(posedge clk) if(err) break;
					if(err)
						$display("Error!");
					else $display("Timeout");
					$stop();
				end

				begin
					repeat(600_000)@(posedge clk); //wait for stablize
					debug = 1;
					while(count * 20 < period) begin
						@(posedge clk);
						if(aud > max) begin
							max = aud;
							max_time = $time;
						end
						if(aud < min)begin
							min = aud;
							min_time = $time;
						end
						count++;
					end
					debug = 0;
					
					time_diff = max_time-min_time;
					if(time_diff<0)begin
						time_diff = -time_diff; 			// absolute of time diff 
					end
						
					temp = freq -(1e9/time_diff/2);
					$display("period: %d, ctr_time: %d Expected: %d, actual: %d, max_t: %d, min_t: %d", period, count*10, freq, 0.5/(time_diff)*1e9, max_time, min_time);
					if((temp >= 0 && temp <= freq*0.7) || (temp < 0 && -temp <= freq*0.7))
						$display("Freq match.");
					else err = 1;

					acutal_amp = max;

					//test reference vol
					POT_backup = POT;
					POT = 2048;

					count = 0;
					max = 0;
					min = 0;
					repeat(600_000)@(posedge clk);
					debug = 1;
					while(count * 20 < period) begin
						@(posedge clk);
						if(aud > max) begin
							max = aud;
							max_time = $time;
						end
						if(aud < min)begin
							min = aud;
							min_time = $time;
						end
						count++;
					end
					debug = 0;
					ref_amp = max;


					rat = (acutal_amp/(0.0+ref_amp)) / ((POT_backup/2048.0)*(POT_backup/2048.0)); //ratio of amp should be (pot/2048)^2
					$display("%f", rat);
					if(rat >= 0 && (rat-1 <= 15e-2 && rat-1 >= -15e-2) || (rat < 0 && (rat+1 >= -15e-2 && rat+1 <= 15e-2)))
						$display("Amp test passed.");
					else
						err = 1;
					disable wait_res;
				end
			join
			POT = 0;
	end
endtask


logic [11:0] testpot;
initial begin
	init_sim();
	VOL   = 2048;

	repeat(300_000) @(posedge clk);
	switch_song();

	repeat(1_700_000) @(posedge clk);

	repeat(3) begin
		testpot = $random;
		while(testpot < 1900) testpot = $random();
		$display("###POT value used: %d \n", testpot);

		@(posedge clk);
		set_pot_and_check(LP, rev_left, 60, testpot);
		set_pot_and_check(B1, rev_left, 100, testpot);
		set_pot_and_check(B2, rev_left, 500, testpot);
		switch_song();
		set_pot_and_check(B3, rev_left, 2000, testpot);
		set_pot_and_check(HP, rev_left, 5000, testpot);
	end

	$display("ALL Tests passed.");
	$stop();
end

always
  #10 clk = ~ clk;

//conver PDM
logic [16:0] ctr;
logic signed [15:0] rev_l_t, rev_r_t, avg_l[4], avg_r[4];
always @(posedge clk, negedge RST_n) begin
	if(!RST_n) begin
		rev_left = 0;
		rev_right = 0;
		rev_l_t = 0;
		rev_r_t = 0;
		ctr = 0;
		{avg_l[0], avg_l[1], avg_l[2], avg_l[3], avg_r[0], avg_r[1], avg_r[2], avg_r[3]} = 0;
	end else if(ctr === 12'd2048) begin //do average of previos 2
		avg_l[0] = avg_l[1];
		avg_l[1] = (rev_l_t - (2048/2));
		rev_left = 32*(avg_l[0] + avg_l[1])/2; //counted max is 1/32 max amp
		
		avg_r[0] = avg_r[1];
		avg_r[1] = (rev_r_t - (2048/2));
		rev_right = 32*(avg_l[0] + avg_l[1])/2;

		rev_l_t = 0;
		rev_r_t = 0;
		ctr = 0;
	end else begin //add every clk
		ctr = ctr+1;
		rev_l_t += lft_PDM;
		rev_r_t += rght_PDM;
	end
end
  
endmodule	  
