// Spec v1.1
module tpumac
 #(parameter BITS_AB=8,
   parameter BITS_C=16)
  (
   input clk, rst_n, WrEn, en,
   input signed [BITS_AB-1:0] Ain,
   input signed [BITS_AB-1:0] Bin,
   input signed [BITS_C-1:0] Cin,
   output reg signed [BITS_AB-1:0] Aout,
   output reg signed [BITS_AB-1:0] Bout,
   output reg signed [BITS_C-1:0] Cout
  );
// Modelsim prefers "reg signed" over "signed reg"

	// AOUT REG
	always_ff @(posedge clk, negedge rst_n) begin
		if (!rst_n)
			Aout <= '0;
		else if (en)
			Aout <= Ain;
	end
	
	// BOUT REG
	always_ff @(posedge clk, negedge rst_n) begin
		if (!rst_n)
			Bout <= '0;
		else if (en)
			Bout <= Bin;
	end
	
	// COUT REG
	always_ff @(posedge clk, negedge rst_n) begin
		if (!rst_n)
			Cout <= '0;
		else if (WrEn)
			Cout <= Cin;
		else if (en)
			Cout <= (Ain * Bin) + Cout;
	end
	
endmodule