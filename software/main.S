/*
 * main.S - ECE 540 project #1 starter code for microAptiv_UP MIPS core
 * running on Nexys4 DDR FPGA target board
 *
 * Copyright Srivatsa Yogendra, 2017
 * 
 * Created By:		Srivatsa Yogendra
 * Last Modified:	01-Oct-2017 (RK)
 *
 * Description:
 * Reads the switches on the FPGA board and writes 
 * the values to the LEDs and the seven segment display
 *
 * Assumes the existance of an AHB-Lite peripheral for the 8 digit
 * 7-segment display on the Nexys4 DDR.  The peripheral has 4 memory
 * mapped I/O registers:
 *	PORT_SEVENSEG_EN - (8 bits) Individual enables for each digit. Set bit to 0 to enable digit
 *									Digit7 = bit[7], Digit6 = bit[6], Digit5 = bit[5], Digit4 = bit[4],
 *									Digit3 = bit[3], Digit2 = bit[2], Digit1 = bit[1], Digit0 = bit[0]
 *	PORT_SEVENSEG_HGH = (32 bits) Value of digit.  Each digit has the range of 31:0, top 3 bits ignored
 *									Digit7 = bits[31:24], Digit6 = bits[23:16],
 *									Digit5 = bits[15:8] , Digit4 = bits[7:0]
 *	PORT_SEVENSEG_LOW = (32 bits) Value of digit.  Each digit has the range of 31:0, top 3 bits ignored
 *									Digit3 = bits[31:24], Digit2 = bits[23:16],
 *									Digit1 = bits[15:8] , Digit0 = bits[7:0]
 *	PORT_SEVENSEG_DP - (8 bits) Individual decimal points for each digit. Set bit to 0 to turn on the decimal point
 *									DP7 = bit[7], DP6 = bit[6], DP5 = bit[5], DP4 = bit[4],
 *									DP3 = bit[3], DP2 = bit[2], DP1 = bit[1], DP0 = bit[0]
 */


/* FOR PROJECT 1 , Change the below addresses to 
 * the addresses of your peripherals 
 */

PORT_SEVENSEG_EN 	= 0xbf700000		# (o) 7 Segment enable
PORT_SEVENSEG_HGH	= 0xbf700004		# (o) 7 Segment Higher Display
PORT_SEVENSEG_LOW	= 0xbf700008		# (o) 7 Segment Lower Display
PORT_SEVENSEG_DP	= 0xbf70000C		# (o) 7 segment Decimal Point Display
PORT_BTNS			= 0xbf800008		# BTNS

// Enable Values for each segment
SEG_A	= 0x10		//Active high
SEG_B	= 0x11
SEG_C	= 0x12
SEG_D	= 0x13
SEG_E	= 0x14
SEG_F	= 0x15
SEG_G	= 0x16

// Dp enable values
DP3_SSEG_EN = 0x000000F8		//Active low
DP1_SSEG_EN = 0x000000F7


// Btn values
BTNU	= 0x10		//Active high
BTND	= 0x8
BTNL	= 0x4
BTNR	= 0x1


// Counter value @ 50hz that euates to 5hz & 10hz

 
.globl main
main:
   lui   $12, 0xbf80    				# $12 = address of LEDs (0xbf800000)
  // addiu $13, $12, 4    				# $13 = address of switches
   addiu $12, $12, 8    				# $13 = address of PushButtons
   li    $14, PORT_SEVENSEG_EN			# $14 = address of the 7 segment enable
   li 	 $15, PORT_SEVENSEG_HGH			# $15 = address of the higher 7 segment digits
   li 	 $16, PORT_SEVENSEG_LOW			# $16 = address of the lower 7 segment digits
   li 	 $17, PORT_SEVENSEG_DP			# $17 = address of the dp points in 7 segment digits
   
  // Initiate BCD.


readIO: 	
	lw    $10, 0($12)    	# read btns: $10 = button values
	and   $11, $10, 0xFFFFF
	sw    $11, 0($12)    	# write switch values to leds
	sw    $11, 0($16)    	# write switch values to lower 7 segment digits 
	li 	  $11, 0x00
	sw	  $11, 0($14)		# Enable all the displays 
	li 	  $11, 0xFF			# Turn off all of the decimal points
	sw	  $11, 0($17)

	// beq   $0, $0, readIO 	# repeat #Moved to bottom of routine to loop back.
	nop                  	# branch delay slot

decode:	// Decode pushbutton register to choose state.
	// $11 is test register

	// tr1x register value is = 0x04 or 0x08
	li $11, 0x04
	beq $11, $10, tr1x
	li $11, 0x08
	beq $11, $10, tr1x
	// tr2x	register value is = 0x0c
	li $11, 0x0c
	beq $11, $10, tr2x
	// tl1x register value is = 0x01 or 0x10
	li $11, 0x01
	beq $11, $10, tl1x
	li $11, 0x10
	beq $11, $10, tl1x
	// tl2x register value is = 0x11
	li $11, 0x11
	beq $11, $10, tl2x
	// forward register value is = 0x05
	li $11, 0x05
	beq $11, $10, forward
	// reverse register value is = 0x18
	li $11, 0x18
	beq $11, $10, reverse
	// Stop is everything else (no compare)

stop:	// Segment g on steady.
	// Update $11 with g segment binary equivalent
	// Store $11 to Seveng segment enable register
	// Branch to
	beq   $0, $0, readIO 	# repeat

tr1x: // Chase clockwise 5hz

	beq   $0, $0, readIO 	# repeat


tr2x: // Chase clockwise 10hz

	beq   $0, $0, readIO 	# repeat

tl1x: // Chase ccw 5hz

	beq   $0, $0, readIO 	# repeat

tl2x: // Chase ccw 10hz

	beq   $0, $0, readIO 	# repeat

forward: // Segment a blinks at 1hz

	beq   $0, $0, readIO 	# repeat
	b counterupdate
reverse: // Segment d blinks at 1hz
	beq   $0, $0, readIO 	# repeat

compassupdate:	// BCD counter.

	inc:
	// If BCD is equal to 11_0101_1001 (359 BCD), set to 0 if equal
	// If BCD is xx_xxxx_1001, set to zero, add by tens digit.
	// if BCD is xx_1001_xxxx, set to zro, add by hundereds digit.


	dec:
	// If BCD is equal to 0 (000 BCD), set to 359 (11_0101_1001)


counterupdate:	// Generates


repeat:
	beq   $0, $0, readIO 	# repeat
