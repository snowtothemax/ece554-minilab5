module memA
	#(
	parameter BITS_AB=8,
	parameter DIM=8
	)
	(
	input clk, rst_n, en, WrEn,
	input signed [BITS_AB-1:0] Ain [DIM-1:0],
	input [$clog2(DIM)-1:0] Arow,
	output signed [BITS_AB-1:0] Aout [DIM-1:0]
	);
	// genvar
	genvar i;
	
	logic signed [BITS_AB-1:0] interconnects [DIM-1:0];
	
	//////
	//// instantiate array
	//////
	generate
		for(i = 0; i < DIM; i++) begin
			// input transpose fifos
			transpose_fifo 
				#(.DEPTH(DIM), .BITS(BITS_AB))
				iTranspose_fifo	(
				.clk(clk),
				.rst_n(rst_n),
				.en(en),
				.WrEn(Arow == i & WrEn),
				.d(Ain[i]),
				.q(interconnects[i]),
				.rowIn(Ain)
				);
			// possibly might want two for loops
			if( i === 0 ) begin
				assign Aout[i] = interconnects[i];
			end
			else begin
				fifo 
				#(.DEPTH(i), .BITS(BITS_AB))
				iFifo (
				.clk(clk),
				.rst_n(rst_n),
				.en(en),
				.d(interconnects[i]),
				.q(Aout[i])
				);
			end
		end
	endgenerate
endmodule