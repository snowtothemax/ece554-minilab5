module systolic_array
#(
   parameter BITS_AB=8,
   parameter BITS_C=16,
   parameter DIM=8
   )
  (
   input clk,rst_n,WrEn,en,
   input signed [BITS_AB-1:0] A [DIM-1:0],
   input signed [BITS_AB-1:0] B [DIM-1:0],
   input signed [BITS_C-1:0]  Cin [DIM-1:0],
   input [$clog2(DIM)-1:0]    Crow,
   output signed [BITS_C-1:0] Cout [DIM-1:0]
   );
   
   // genvar for generating the systolic array
   genvar i;
   genvar j;
   genvar k;
   genvar l;
   
   // interconnect
   wire signed [BITS_AB-1:0] A_interconnect [DIM-1:0][DIM:0];
   wire signed [BITS_AB-1:0] B_interconnect [DIM:0][DIM-1:0];
   wire signed [BITS_C-1:0] Cout_interconnect [DIM-1:0][DIM-1:0];
   
   /************************************
   * Generate statement for the systolic array
   ************************************/
   generate
	// rows
	for(i = 0; i < DIM; i = i + 1) begin
		// columns
		for(j = 0; j < DIM; j = j + 1) begin
			tpumac iTPU(
			.clk(clk), 
			.rst_n(rst_n),
			.en(en),
			.WrEn(WrEn & Crow == i),
			.Ain(A_interconnect[i][j]), 
			.Bin(B_interconnect[i][j]),
			.Aout(A_interconnect[i][j+1]),
			.Bout(B_interconnect[i+1][j]),
			.Cin(Cin[j]),
			.Cout(Cout_interconnect[i][j])
			);
		end
	end
   endgenerate
   
   // assign interconnects
   generate
	for(l = 0; l < DIM; l = l + 1) begin
		assign A_interconnect[l][0] = A[l];
		assign B_interconnect[0][l] = B[l];
	end
   endgenerate
   
   // assign cout
   generate
	for(k = 0; k < DIM; k = k + 1) begin
		assign Cout[k] = Cout_interconnect[Crow][k];
	end
   endgenerate
endmodule