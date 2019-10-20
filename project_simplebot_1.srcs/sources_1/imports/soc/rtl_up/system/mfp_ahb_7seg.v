// mfp_ahb_7seg.v
//
// Based off of: 
// General-purpose I/O module for Altera's DE2-115 and 
// Digilent's (Xilinx) Nexys4-DDR board
//
// Modified for use with on board Seven Segment Display


`include "mfp_ahb_const.vh"

module mfp_ahb_7seg(
    input                        HCLK,
    input                        HRESETn,
    input       [ 31          :0]HADDR,
    input       [ 31          :0]HWDATA,
    input                        HWRITE,
    input                        HSEL,

// memory-mapped I/O
    output reg [`MFP_N_SEG-1 :0] IO_7SEGEN_N,   // Lowest level output to the digit enable anode pins at the top level.
    output reg [`MFP_N_SEG-1 :0] IO_SEG_N       // Lowest level output to the segment enable cathode pins at the top level.
);

  reg [31:0]    HADDR_d;
  reg           HWRITE_d;
  reg           HSEL_d;
  reg [7:0]     DE, DP; // Digit enable and decimal point enable registers, respectively, to be addressed for writes.
  reg [31:0]    DVL, DVU; // Registers for Lower and Upper digit value, respectively, to be addressed for writes.
  wire        we;            // write enable. Asserted when HSEL[3] is asserted to select the seven segment display. 
  wire [`MFP_N_SEG-1 :0]io_7segen_n; // Output wire from the mf_seven_seg module to be clocked into the IO_7SEGEN_N output reg which ties into the top level anode pins.
  wire [`MFP_N_SEG-1 :0]io_seg_n; // Output wire from the mf_seven_seg module to be clocked into the IO_SEG_N output reg which ties into the top level cathode pins.

// mfp_seven_seg instance takes DE, DP, DVU, and DVL write input registers to decode output onto io_seg_n and io_7segen_n output nets.
mfp_ahb_sevensegtimer mfp_seven_seg(.clk(HCLK), .resetn(HRESETn), .EN(DE), .DIGITS({DVU,DVL}), .dp(DP), .DISPOUT(io_seg_n), .DISPENOUT(io_7segen_n));

  // delay HADDR, HWRITE, HSEL, and HTRANS to align with HWDATA for writing
  always @ (posedge HCLK) 
  begin
    HADDR_d  <= HADDR;
	HWRITE_d <= HWRITE;
	HSEL_d   <= HSEL;
  end
  
  // overall write enable signal
  assign we = HSEL_d & HWRITE_d;

    always @(posedge HCLK or negedge HRESETn)begin
       if (~HRESETn) begin
         IO_SEG_N <= `MFP_N_SEG'b0;
         IO_7SEGEN_N <= `MFP_N_SEG'b0;  
       end else if (we)
         case (HADDR_d)
           `H_SEG_ADDR_en:       DE <= HWDATA[7:0]; // Digit enable register written to when 32'h1F70_0000 is addressed.
           `H_SEG_ADDR_digit3_0: DVL <= HWDATA; // Lower segment digit value register written to when 32'h1F70_0008 is addressed.
           `H_SEG_ADDR_digit7_4: DVU <= HWDATA; // Upper segment digit value register written to when 32'h1F70_0004 is addressed.
           `H_SEG_ADDR_dp:       DP <= HWDATA[7:0]; // Decimal point enable register written to when 32'h1F70_000C is addressed. 
         endcase
         IO_SEG_N <= io_seg_n; // Clock into output register to be tied to top level anodes.
         IO_7SEGEN_N <= io_7segen_n; // Clock into outpu register to be tied to top level cathodes. 
         end
         
endmodule

