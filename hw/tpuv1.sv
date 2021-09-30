module tpuv1
  #(
    parameter BITS_AB=8,
    parameter BITS_C=16,
    parameter DIM=8,
    parameter ADDRW=16,
    parameter DATAW=64
    )
   (
    input clk, rst_n, r_w, // r_w=0 read, =1 write
    input [DATAW-1:0] dataIn,
    output [DATAW-1:0] dataOut,
    input [ADDRW-1:0] addr
   );
   
	localparam ROWBITS = $clog2(DIM);
	localparam COUNTER_BITS = $ceil($clog2(DIM*3 - 2));
	
	///////////////////////////////
	/// intermediate signals
	//////////////////////////////
	logic WrEn_SA, WrEn_A;
	logic [ROWBITS-1:0] Arow;
	logic [ROWBITS-1:0] Crow;
	logic signed [BITS_AB-1:0] A [DIM-1:0];
	logic signed [BITS_AB-1:0] B [DIM-1:0];
	logic signed [BITS_C-1:0] Cin [DIM-1:0];
	logic signed [BITS_C-1:0] Cout [DIM-1:0];

	logic signed [BITS_AB-1:0] Amem_int [DIM-1:0];
	logic signed [BITS_AB-1:0] Bmem_int [DIM-1:0];

	logic signed [BITS_AB-1:0] nextA [DIM-1:0];
	logic signed [BITS_AB-1:0] nextB [DIM-1:0];
	
	logic signed [COUNTER_BITS-1:0] countSA_cycles;
	
	logic signed [BITS_C-1:0] out_reg [DIM-1:0];
	
	genvar i;
	
	// control signals
	logic startCount_SA;
	logic countSA_done;
	logic en_SA, en_memA, en_memB;
	
	assign dataOut[15:0] = addr[3] ? out_reg[4] : out_reg[0];
	assign dataOut[31:16] = addr[3] ? out_reg[5] : out_reg[1];
	assign dataOut[47:32] = addr[3] ? out_reg[6] : out_reg[2];
	assign dataOut[63:48] = addr[3] ? out_reg[7] : out_reg[3];
	
	////////////////////////////////
	///// DUTS
	////////////////////////////////
	
	systolic_array #(
					.BITS_AB(BITS_AB),
                    .BITS_C(BITS_C),
                    .DIM(DIM))
                    systolic_array_DUT (.clk(clk),
                                        .rst_n(rst_n),
                                        .en(en_SA),
                                        .WrEn(WrEn_SA),
                                        .A(Amem_int),
                                        .B(Bmem_int),
                                        .Cin(Cin),
                                        .Crow(Crow),
                                        .Cout(Cout)
                                        );
	
	memA #(.BITS_AB(BITS_AB),
          .DIM(DIM))
          memA_DUT (.clk(clk),
                    .rst_n(rst_n),
                    .en(en_memA),
                    .WrEn(WrEn_A),
                    .Ain(A),
                    .Arow(Arow),
                    .Aout(Amem_int)
                    );
	
	memB #(.BITS_AB(BITS_AB),
          .DIM(DIM))
          memB_DUT (.clk(clk),
                    .rst_n(rst_n),
                    .en(en_memB),
                    .Bin(B),
                    .Bout(Bmem_int)
                    );
	
	/////////////////////////
	/// counter ff
	/////////////////////////
	
	// SA
	always_ff @(posedge clk, negedge rst_n) begin
		if (!rst_n) begin
			countSA_cycles <= (DIM*3);
			countSA_done <= 0;
      en_memA = 0;
			//en_memB = 0;
			en_SA = 0;

		end
		else if (startCount_SA && countSA_done) begin
			countSA_cycles <= countSA_cycles - 1;
			countSA_done <= 0;
      en_memA = 1;
			//en_memB = 1;
			en_SA = 1;

		end
		else if (countSA_cycles === 16'h0) begin
      countSA_cycles <= 16'h0;
			countSA_done <= 1;
      en_memA = 0;
			//en_memB = 0;
			en_SA = 0;
      
		end
    else begin
			countSA_cycles <= countSA_cycles - 1;
			countSA_done <= 0;
      en_memA = 1;
			//en_memB = 1;
			en_SA = 1;

		end
	end
	
	///////////////////////
	// case statement
	///////////////////////
	
	always_comb begin
		// set the input values to be 0
		for(int rowcol=0;rowcol<DIM;++rowcol) begin
		  A[rowcol] = {BITS_AB{1'b0}};
		  B[rowcol] = {BITS_AB{1'b0}};
		  out_reg[rowcol] = {BITS_C{1'b0}};
		end
		
		en_memB = 0;
		//en_memA = 0;
		//en_SA = 0;
		WrEn_A = 0;
		WrEn_SA = 0;
		startCount_SA = 0;
		case (addr[11:8])
			// write to A
			4'h1: begin
				WrEn_A = 1;
				Arow = addr[ROWBITS+2:ROWBITS];
				
				// assign dataIn to A
				// for(int rowcol=0;rowcol<DIM;++rowcol) begin
				  // A[rowcol] = dataIn[((rowcol+1)*BITS_AB)-1:(rowcol*BITS_AB)];
				// end
				A[0] = dataIn[7:0];
				A[1] = dataIn[15:8];
				A[2] = dataIn[23:16];
				A[3] = dataIn[31:24];
				A[4] = dataIn[39:32];
				A[5] = dataIn[47:40];
				A[6] = dataIn[55:48];
				A[7] = dataIn[63:56];
				
				
			end
			// write to B
			4'h2: begin
				en_memB = 1;
				
				// assign dataIn to B
				// for(int rowcol=0;rowcol<DIM;++rowcol) begin
				  // B[rowcol] = dataIn[((rowcol+1)*BITS_AB)-1:(rowcol*BITS_AB)];
				// end
				B[0] = dataIn[7:0];
				B[1] = dataIn[15:8];
				B[2] = dataIn[23:16];
				B[3] = dataIn[31:24];
				B[4] = dataIn[39:32];
				B[5] = dataIn[47:40];
				B[6] = dataIn[55:48];
				B[7] = dataIn[63:56];
			
      end
			// read / write to C
			4'h3: begin
				Crow = addr[ROWBITS+3:ROWBITS+1];
				
				if (!r_w) begin
					out_reg = Cout;
				end
				else begin
					WrEn_SA = 1;
					
					// assign dataIn to A
					// for(int rowcol=0;rowcol<DIM;++rowcol) begin
					  // Cin[DIM-rowcol] = dataIn[((rowcol+1)*BITS_AB)-1:(rowcol*BITS_AB)];
					// end
					if(addr[3]) begin
						Cin[0] = Cout[0];
						Cin[1] = Cout[1];
						Cin[2] = Cout[2];
						Cin[3] = Cout[3];
						Cin[4] = dataIn[15:0];
						Cin[5] = dataIn[31:16];
						Cin[6] = dataIn[47:32];
						Cin[7] = dataIn[63:48];
					end else begin
						Cin[0] = dataIn[15:0];
						Cin[1] = dataIn[31:16];
						Cin[2] = dataIn[47:32];
						Cin[3] = dataIn[63:48];
						Cin[4] = Cout[4];
						Cin[5] = Cout[5];
						Cin[6] = Cout[6];
						Cin[7] = Cout[7];
					end
				end
			end
			4'h4: begin
			    startCount_SA = 1;
			end
			default: begin
				// balls
        if (~countSA_done) begin
          en_memB = 1;
        end
			end
		endcase
	end
   
   
   
endmodule
