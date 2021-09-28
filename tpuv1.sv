module tpuv1
  #(
    parameter BITS_AB=8,
    parameter BITS_C=16,
    parameter DIM=8,
    parameter ADDRW=16;
    parameter DATAW=64;
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
	logic signed [BITS_C-1:0] Coutreg [DIM-1:0];

	logic signed [BITS_AB-1:0] Amem_int [DIM-1:0];
	logic signed [BITS_AB-1:0] Bmem_int [DIM-1:0];

	logic signed [BITS_AB-1:0] nextA [DIM-1:0];
	logic signed [BITS_AB-1:0] nextB [DIM-1:0];
	
	logic signed [COUNTER_BITS-1:0] countSA_cycles;
	logic signed [ROWBITS-1:0] countMemA_cycles, countMemB_cycles;
	
	// control signals
	logic startCount_memA, startCount_SA, startCount_memB;
	logic countMemA_done, countMemB_done, countSA_done;
	logic en_SA, en_memA, en_memB;
	
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
	
	// memA
	always_ff @(posedge clk, negedge rst_n) begin
		if (!rst_n) begin
			countMemA_cycles <= 0;
			countMemA_done <= 0;
		end
		else if (startCount_memA & countMemA_done) begin
			countMemA_cycles <= DIM;
			countMemA_done <= 0;
		end
		else if (en_memA && countMemA_cycles > 0)
			countMemA_cycles <= countMemA_cycles - 1;
		else
			countMemA_done <= 1;
	end
	
	// memB
	always_ff @(posedge clk, negedge rst_n) begin
		if (!rst_n) begin
			countMemB_cycles <= 0;
			countMemB_done <= 0;
		end
		else if (startCount_memB &  countMemB_done) begin
			countMemB_cycles <= DIM;
			countMemB_done <= 0;
		end
		else if (en_memB && countMemB_cycles > 0)
			countMemB_cycles <= countMemB_cycles - 1;
		else
			countMemB_done <= 1;
	end
	
	// SA
	always_ff @(posedge clk, negedge rst_n) begin
		if (!rst_n) begin
			curr_state <= INIT;
			next_state <= INIT;
		end
	end
	
	///////////////////////
	// case statement
	///////////////////////
	
	always_comb begin
		case (addr[11:8])
			4'h1: begin
			end
			4'h2: begin
			end
			4'h3: begin
			end
			4'h4: begin
			end
			default: begin
				// balls
			end
		endcase
	end
   
   
   
endmodule