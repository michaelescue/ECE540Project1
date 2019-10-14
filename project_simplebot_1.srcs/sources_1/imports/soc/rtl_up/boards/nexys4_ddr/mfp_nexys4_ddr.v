// mfp_nexys4_ddr.v
// January 1, 2017
//
// Instantiate the mipsfpga system and rename signals to
// match the GPIO, LEDs and switches on Digilent's (Xilinx)
// Nexys4 DDR board

// Outputs:
// 16 LEDs (IO_LED) 
// Inputs:
// 16 Slide switches (IO_Switch),
// 5 Pushbuttons (IO_PB): {BTNU, BTND, BTNL, BTNC, BTNR}
//

`include "mfp_ahb_const.vh"

module mfp_nexys4_ddr( 
                        input                   CLK100MHZ,
                        input                   CPU_RESETN,
                        input                   BTNU, BTND, BTNL, BTNC, BTNR, 
                        input  [`MFP_N_SW-1 :0] SW,
                        output [`MFP_N_LED-1:0] LED,
                        //output [`MFP_N_SEG-1:0] SEG,
                        output CA, CB, CC, CD, CE, CF, CG, DP,
                        output [7:0] AN,
                        inout  [ 8          :1] JB,
                        input                   UART_TXD_IN);

  // Press btnCpuReset to reset the processor. 
        
  wire clk_out; 
  wire tck_in, tck;
  wire [7:0] io_wire;
  wire [5:0] pbtn_db;
  wire [`MFP_N_SW-1 :0] swtch_db;
  
  
  assign io_wire = {DP,CA,CB,CC,CD,CE,CF,CG};       
  
  clk_wiz_0 clk_wiz_0(.clk_in1(CLK100MHZ), .clk_out1(clk_out));
  IBUF IBUF1(.O(tck_in),.I(JB[4]));
  BUFG BUFG1(.O(tck), .I(tck_in));
  
  debounce debounce(.clk(clk_out), .pbtn_in({BTNU,BTND,BTNL,BTNC,BTNR,CPU_RESETN}), .switch_in(SW), .pbtn_db(pbtn_db), .swtch_db(swtch_db));

  mfp_sys mfp_sys(
			        .SI_Reset_N(pbtn_db[0]),
                    .SI_ClkIn(clk_out),
                    .HADDR(),
                    .HRDATA(),
                    .HWDATA(),
                    .HWRITE(),
					.HSIZE(),
                    .EJ_TRST_N_probe(JB[7]),
                    .EJ_TDI(JB[2]),
                    .EJ_TDO(JB[3]),
                    .EJ_TMS(JB[1]),
                    .EJ_TCK(tck),
                    .SI_ColdReset_N(JB[8]),
                    .EJ_DINT(1'b0),
                    .IO_Switch(swtch_db),
                    .IO_PB(pbtn_db[5:1]),
                    .IO_LED(LED),
                    .IO_7SEGEN_N(AN),
                    .IO_SEG_N(io_wire),
                    .UART_RX(UART_TXD_IN));
          
endmodule
