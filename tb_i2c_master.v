/*
 * Test Bench for i2c master controller implementation.
 * Stimulation is based on table below for read/write.
 *
 * Copyright (c) 2015 Joel Fernandes <joel@linuxinternals.org>
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 */

`timescale 1ns / 1ps

/* Reads
time	clock	strobe	addr_data	i_cmd	en	io_sda
00	0	1	<addr>		1	0	x
10	1	1	<addr>		1	0	x
20	0	0	x		x	0	x
30	1	0	x		x	x	x // start condition
40	0	0	x		x	x	x // addr bit 6
50	1	0	x		x	x	x // addr bit 6
60	0	0	x		x	x	x // addr bit 5
70	1	0	x		x	x	x // addr bit 5
80	0	0	x		x	x	x // addr bit 4
90	1	0	x		x	x	x // addr bit 4
100	0	0	x		x	x	x // addr bit 3
110	1	0	x		x	x	x // addr bit 3
120	0	0	x		x	x	x // addr bit 2
130	1	0	x		x	x	x // addr bit 2
140	0	0	x		x	x	x // addr bit 1
150	1	0	x		x	x	x // addr bit 1
160	0	0	x		x	x	x // addr bit 0
170	1	0	x		x	x	x // addr bit 0
180	0	0	x		x	x	x // r/w bit
190	1	0	x		x	x	x // r/w bit
200	0					1	0 // Ack bit
210	1					1	0 // Ack bit
220	0	0	x		x	1	1 // data bit 7
240	0	0	x		x	1	1 // data bit 6
260	0	0	x		x	1	0 // data bit 5
280	0	0	x		x	1	1 // data bit 4
300	0	0	x		x	1	0 // data bit 3
320	0	0	x		x	1	0 // data bit 2
340	0	0	x		x	1	1 // data bit 1
360	0	0	x		x	1	0 // data bit 0
370	1
380	0					0	x // Ack
390	1					0	x // Ack
400	0					0	x // Prep stop
410	1					0	x // stop
420	0					0	x // Reset neg edge state
430	1					0	x // Reset Positive edge state -> now ready to receive next req on next p.edge

*/

/* Writes:
time	clock	strobe	addr_data	i_cmd	en	io_sda
10	0	1	<addr>		0	0	x
20	1	1	<addr>		0	0	x
30	0	1	<data>		0	0	x
40	1	1	<data>		0	0	x
50	0	0	x		x	0	x
60	1	0	x		x	x	x // start condition
70	0	0	x		x	x	x // addr bit 6
80	1	0	x		x	x	x // addr bit 6
90	0	0	x		x	x	x // addr bit 5
100	1	0	x		x	x	x // addr bit 5
110	0	0	x		x	x	x // addr bit 4
120	1	0	x		x	x	x // addr bit 4
130	0	0	x		x	x	x // addr bit 3
140	1	0	x		x	x	x // addr bit 3
150	0	0	x		x	x	x // addr bit 2
160	1	0	x		x	x	x // addr bit 2
170	0	0	x		x	x	x // addr bit 1
180	1	0	x		x	x	x // addr bit 1
190	0	0	x		x	x	x // addr bit 0
200	1	0	x		x	x	x // addr bit 0
210	0	0	x		x	x	x // r/w bit
220	1	0	x		x	x	x // r/w bit
230	0					1	0 // Ack bit
240	1					1	0 // Ack bit
250	0					0	x // data bit 8
260	1					0	x // data bit 8
..
390	0					0	x // data bit 1
400	1					0	x // data bit 1
410	0					1	0 // Ack
420	1					1	0 // Ack
430	0					0	0 // Prep stop
440	1					0	0 // stop
450	0					0	x // Reset neg edge state
460	1					0	x // Reset Positive edge state -> now ready to receive next req on next p.edge
*/

module tb_i2c_master;

	// Inputs
	reg [7:0] i_addr_data;
	reg i_cmd;
	reg i_strobe;
	reg i_clk;

	// Outputs
	wire io_scl;
	wire [7:0] o_data;
	wire [2:0] o_status;

	// Bidirs
	wire io_sda_w;
	reg io_sda;
	reg en = 0;
	assign io_sda_w = en ? io_sda : 1'bZ;
	
	/*
	initial
	$monitor($time, ": i_clk=%b i_addr_data=%b i_cmd=%b d_neg_count=%d d_state=%d d_pos_state=%d d_neg_state=%d d_wr_sda_pos=%b d_wr_sda_neg=%b d_reg_sda_pos=%b d_reg_sda_neg=%b o_data=%b o_status=%b io_sda_w=%b d_in_data=%b",
				i_clk,
				i_addr_data,
				i_cmd,
				d_neg_count,
				d_state,
				d_pos_state,
				d_neg_state,
				d_wr_sda_pos,
				d_wr_sda_neg,
				d_reg_sda_pos,
				d_reg_sda_neg,
				o_data,
				o_status,
				io_sda_w,
				d_in_data);
		*/

	// Instantiate the Unit Under Test (UUT)
	i2c_master uut (
		.i_addr_data(i_addr_data),
		.i_cmd(i_cmd),
		.i_strobe(i_strobe),
		.i_clk(i_clk),
		.io_sda(io_sda_w),
		.io_scl(io_scl),
		.o_data(o_data),
		.o_status(o_status)
	);
	
	initial
	begin
	#10
		forever
		#10 i_clk = !i_clk;
	end
	
	initial begin
		// Initialize Inputs
		i_addr_data = 0;
		i_cmd = 0;
		i_strobe = 0;
		i_clk = 0;

		// Wait 10 ns for global reset to finish
		// Write data 0xAB at address 0x65
		#10;
		i_addr_data = 8'h65;	
		i_strobe = 1;
		i_cmd = 0;				// write
		#20;
		i_addr_data = 8'hAB;
		i_strobe = 1;
		#20;						// do nothing, Start condition is done
		i_strobe = 0;
		#180;						// 8 clocks later, provide addr ack on falling edge
		io_sda = 0;
		en = 1;
		#20;
		en = 0;					// release bus by rising
		#160;					   // 8 data writes
		io_sda = 0;
		en = 1;
		#20;
		en = 0;
		#60;
		
		// Read data of 11010010 from address 0x65
		i_addr_data = 8'h65;	
		i_strobe 	= 1;
		i_cmd 		= 1;		// read
		#20;
		i_strobe		= 0;
		#180;						// start + addr bits
		io_sda		= 0;		// Ack
		en				= 1;
		#20;
		io_sda		= 1;		// data 7
		#20;
		io_sda		= 1;
		#20;
		io_sda		= 0;
		#20;
		io_sda		= 1;
		#20;
		io_sda		= 0;
		#20;
		io_sda		= 0;
		#20;
		io_sda		= 1;
		#20;
		io_sda		= 0;		// data 0
		#20;
		en				= 0;
		#60;
		
		$stop;
	end
      
endmodule

