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
                        output                  CA, CB, CC, CD, CE, CF, CG, DP, // Active low output into the cathode (and decimal point) pins- 
                                                                                // for enabling individual segments. 
                        output [ 7          :0] AN, // Active low output into the AN pins for enabling SSEG digits.
                        inout  [ 8          :1] JB,
                        input                   UART_TXD_IN);

  // Press btnCpuReset to reset the processor. 
        
  wire clk_out; 
  wire tck_in, tck;
  wire [7:0] io_wire; // Used to bundle cathode signals into single bus from mfp_sys output IO_7SEG_N.
  wire [5:0] pbtn_db; // Used for debounced signal of push button input from the debounce module.
  wire [`MFP_N_SW-1 :0] swtch_db; // Used for debounced signal from switch input of the debounce module.
  
  
  assign io_wire = {DP,CA,CB,CC,CD,CE,CF,CG};       
  
  clk_wiz_0 clk_wiz_0(.clk_in1(CLK100MHZ), .clk_out1(clk_out));
  IBUF IBUF1(.O(tck_in),.I(JB[4]));
  BUFG BUFG1(.O(tck), .I(tck_in));
  
  // The debounce module accepts the pushbutton and switch inputs, then outputs debounced signals pbtn_db and switch_db for use in submodules.
  debounce debounce(.clk(clk_out), .pbtn_in({BTNU,BTND,BTNL,BTNC,BTNR,CPU_RESETN}), .switch_in(SW), .pbtn_db(pbtn_db), .swtch_db(swtch_db));

  mfp_sys mfp_sys(
			        .SI_Reset_N(pbtn_db[0]), // Input is the debounced reset push button from the debounce module.
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
                    .IO_Switch(swtch_db), // Input is the debounced switch signal from the debounce module.
                    .IO_PB(pbtn_db[5:1]), // Input is the debounced push button signals for up, down, left, and right from the debounce module.
                    .IO_LED(LED),
                    .IO_7SEGEN_N(AN), // Output into the AN pins to enable SSEG digits which are set at the mfp_ahb_sevensegtimer submodule.
                    .IO_SEG_N(io_wire), // Output into the net connecting all cathodes at the top level which are set at the mfp_ahb_sevensegtimer submodule.
                    .UART_RX(UART_TXD_IN));
          
endmodule
