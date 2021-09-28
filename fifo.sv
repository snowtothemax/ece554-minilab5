// fifo.sv
// Implements delay buffer (fifo)
// On reset all entries are set to 0
// Shift causes fifo to shift out oldest entry to q, shift in d

module fifo
  #(
  parameter DEPTH=8,
  parameter BITS=64
  )
  (
  input clk,rst_n,en,
  input [BITS-1:0] d,
  output [BITS-1:0] q
  );
  
  logic signed [BITS-1:0] fifo_data [0:DEPTH-1];
  genvar i;
  
  assign q = fifo_data[DEPTH-1];
  
  // FLOP BUFFER
  // Form flop buffer //
	generate
		for (i = 0; i < DEPTH; i=i+1) begin
		   always_ff @(posedge clk, negedge rst_n) begin
		      if (!rst_n)
			     fifo_data[i] <= 0;
			  else if (en) begin
			     if (i == 0)
			        fifo_data[i] <= d;
				 else
			        fifo_data[i] <= fifo_data[i-1];
			  end
		   end
		end
	endgenerate
  
endmodule // fifo
