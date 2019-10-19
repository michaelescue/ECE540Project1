#
 # main.S - ECE 540 project #1 starter code for microAptiv_UP MIPS core
 # running on Nexys4 DDR FPGA target board
 #
 # Copyright Srivatsa Yogendra, 2017
 # 
 # Created By:		Srivatsa Yogendra
 # Last Modified:	01-Oct-2017 (RK)
 #
 # Description:
 # Reads the switches on the FPGA board and writes 
 # the values to the LEDs and the seven segment display
 #
 # Assumes the existance of an AHB-Lite peripheral for the 8 digit
 # 7-segment display on the Nexys4 DDR.  The peripheral has 4 memory
 # mapped I/O registers:
 #	PORT_SEVENSEG_EN - (8 bits) Individual enables for each digit. Set bit to 0 to enable digit
 #									Digit7 = bit[7], Digit6 = bit[6], Digit5 = bit[5], Digit4 = bit[4],
 #									Digit3 = bit[3], Digit2 = bit[2], Digit1 = bit[1], Digit0 = bit[0]
 #	PORT_SEVENSEG_HGH = (32 bits) Value of digit.  Each digit has the range of 31:0, top 3 bits ignored
 #									Digit7 = bits[31:24], Digit6 = bits[23:16],
 #									Digit5 = bits[15:8] , Digit4 = bits[7:0]
 #	PORT_SEVENSEG_LOW = (32 bits) Value of digit.  Each digit has the range of 31:0, top 3 bits ignored
 #									Digit3 = bits[31:24], Digit2 = bits[23:16],
 #									Digit1 = bits[15:8] , Digit0 = bits[7:0]
 #	PORT_SEVENSEG_DP - (8 bits) Individual decimal points for each digit. Set bit to 0 to turn on the decimal point
 #									DP7 = bit[7], DP6 = bit[6], DP5 = bit[5], DP4 = bit[4],
 #									DP3 = bit[3], DP2 = bit[2], DP1 = bit[1], DP0 = bit[0]
 #


# FOR PROJECT 1 , Change the below addresses to 
 # the addresses of your peripherals 
 #

PORT_SEVENSEG_EN 	= 0xbf700000		# (o) 7 Segment enable
PORT_SEVENSEG_HGH	= 0xbf700004		# (o) 7 Segment Higher Display
PORT_SEVENSEG_LOW	= 0xbf700008		# (o) 7 Segment Lower Display
PORT_SEVENSEG_DP	= 0xbf70000C		# (o) 7 segment Decimal Point Display
PORT_BTNS			= 0xbf800008		# BTNS

# Enable Values for each segment on digit 3
SEG_A	= 0x10000000		#Active high
SEG_B	= 0x11000000
SEG_C	= 0x12000000
SEG_D	= 0x13000000
SEG_E	= 0x14000000
SEG_F	= 0x15000000
SEG_G	= 0x16000000
BLANK	= 0xFF000000

# Dp enable values
DP3_SSEG_EN = 0x000000F8		#Active low
DP1_SSEG_EN = 0x000000F7


# Btn values
BTNU	= 0x10		#Active high
BTND	= 0x08
BTNL	= 0x04
BTNR	= 0x01

 
.globl main
main:
   li    $14, PORT_SEVENSEG_EN			# $14 = address of the 7 segment enable
   li 	 $15, PORT_SEVENSEG_HGH			# $15 = address of the higher 7 segment digits
   li 	 $16, PORT_SEVENSEG_LOW			# $16 = address of the lower 7 segment digits
   li 	 $17, PORT_SEVENSEG_DP			# $17 = address of the dp points in 7 segment digits
  
#Initiate Clk Counter. 50M 
   li	$20, 0x00000000	# $20 (s4)  is Flags register. One hot. bit 0 = 1hz, bit 1 = 5hz, bit 2 = 10hz.  
   li	$19, 0x00000000	# $19 (s3) is Counter register
   
# Initiate BCD counter register $18 (s2)
	li $18, 0x00000000	# $18 is the BCD counter.
	
# $21 (t5) is the current segment display.
	li $21, SEG_G
	
# $23 is the chase memory register (last segment0
	li $23, SEG_A
	
# $22 DP value register
	li $22, 0xF7
	

readIO:
	lui   $12, 0xbf80    				# $12 = address of LEDs (0xbf800000)
	addiu $12, $12, 8    				# $13 = address of PushButtons
	lw    $10, 0($12)    	# read btns: $10 = button values
	and   $11, $10, 0xFFFFF
	sw    $11, 0($12)    	# write switch values to leds
#	sw    $11, 0($16)    	# write switch values to lower 7 segment digits 
	li 	  $11, 0xf0			# enable only lower 4 digits.
	sw	  $11, 0($14)		# Enable all the displays 
	li 		$11, 0x0
	add 	  $11, $22, $11			# Enable the digit 3 decimal point.
	sw	  $11, 0($17)
	nop                  	# branch delay slot
	
	#Blink Decimal point
	# Check for 1hz enable signal
	li $11, 0x1
	li $12, 0x1
	
	# Mask bit 0, of $20 status reg for 1hz flag.
	and $11, $20, $11
	
	# If 1hz bit not enabled continue with decode
	bne $11, $12, decode
	
	# Test DP value if lowest DP is enabled.
	li $11, 0xF6
	bne $22, $11, blinkdp
	
	# So, if 1hz bit asserted enable seg_A
	li $22, 0xF7
	
	# Store to $17 DP enable reg
	sw $22, 0($17)

	# Jump to compass to update direction/counter
	beq   $0, $0, decode	

blinkdp:

	# 
	li $22, 0xF6
	
	# Store to $17 DP enable reg
	sw $22, 0($17)
	
decode:	
	# Decode pushbutton register to choose state.
	# $11 is test register

	# tr1x register value is = 0x04 or 0x08
	li $11, 0x04
	beq $11, $10, tr1x
	li $11, 0x08
	beq $11, $10, tr1x
	
	# tr2x	register value is = 0x0c
	li $11, 0x0c
	beq $11, $10, tr2x
	
	# tl1x register value is = 0x01 or 0x10
	li $11, 0x01
	beq $11, $10, tl1x
	li $11, 0x10
	beq $11, $10, tl1x
	
	# tl2x register value is = 0x11
	li $11, 0x11
	beq $11, $10, tl2x
	
	# forward register value is = 0x05
	li $11, 0x05
	beq $11, $10, forward
	
	# reverse register value is = 0x18
	li $11, 0x18
	beq $11, $10, reverse
	
	# Stop is everything else (no compare)

stop:	# Segment g on steady.
	
	#load mask into $11 (t3)
	li $11, 0x00FFFFFF
	
	#Clear digit 3 value
	and $21, $21, $11
	
	#load SEG_G into $11
	li $11, SEG_G

	#modify digit3 of current value register $21
	or $21, $21, $11
	
	#write to segment display
	#sw $21, 0($16)
	
	# Return to I/O read
	beq   $0, $0, decodecompass 	# repeat

tr1x: # Chase clockwise 5hz
	# Check for 5hz enable signal
	# $11's bit 1 mask
	# same value to test after the mask
	li $11, 0x2
	li $12, 0x2
	
	# Mask bit 1, of $20 status reg for 5hz flag.
	and $11, $20, $11
	
	# Continue to loop through compass/counter while in current state if not enabled.
	bne $11, $12, decodecompass

	# Load mask value for digit 3 bit select
	li $11, 0xFF000000
	
	# Select digit 3 bits for testing. $23 is unmodified.
	AND $12, $23, $11
	
	# Test value for segment F. 
	li $11, SEG_F
	
	# so, if digit 3 bits equal $11(SEG_F), branch to SEG_A in continuecw1x	
	beq $11, $12, continuecw1x
	
	# So, if not SEG_F, increment
	li $11, 0x01000000			# Increment Digit 3
	addu $23, $23, $11
	
	#clear digit 3 value
	li $11, 0x00FFFFFF
	and $21, $21, $11
	
	#set the digit 3 value
	or $21, $21, $23
	
	#update segment display
	#sw $21, 0($16)

	# Jump to compass to update direction
	beq   $0, $0, incrementcompass 
	
	continuecw1x:
	
		#load mask into $11 (t3)
		li $11, 0x00FFFFFF
		
		#Clear digit 3 value
		and $21, $21, $11
	
		#load SEG_A to enable.
		li $23, SEG_A
	
		#Update digit 3 value
		or $21, $21, $23
		
		#update segment display
		#sw $21, 0($16)

		# Jump to compass to update direction
		b incrementcompass 	
	
tr2x: # Chase clockwise 10hz

	# Check for 10hz enable signal
	li $11, 0x4
	li $12, 0x4
	
	# select bit 2, of $20 status reg for 10hz flag.
	and $11, $20, $11
	
	# Continue to loop through compass/counter while in current state if not enabled.
	bne $11, $12, decodecompass

	# Load mask value for digit 3 bit select
	li $11, 0xFF000000
	
	# Select digit 3 bits for testing. $23 is unmodified.
	AND $12, $23, $11
	
	# Test value for segment F. 
	li $11, SEG_F
	
	# so, if digit 3 bits equal $11(SEG_F), branch to SEG_A in continuecw2x	
	beq $11, $12, continuecw1x
	
	# So, if not SEG_F, increment
	li $11, 0x01000000			# Increment Digit 3
	addu $23, $23, $11
	
	#clear digit 3 value
	li $11, 0x00FFFFFF
	and $21, $21, $11
	
	#set the digit 3 value
	or $21, $21, $23
	
	#update segment display
	#sw $21, 0($16)

	# Jump to compass to update direction
	beq   $0, $0, incrementcompass  
	
	continuecw2x:
	
		#load mask into $11 (t3)
		li $11, 0x00FFFFFF
		
		#Clear digit 3 value
		and $21, $21, $11
	
		#load SEG_A to enable.
		li $23, SEG_A
	
		#Update digit 3 value
		or $21, $21, $23
		
		#update segment display
		#sw $21, 0($16)

		# Jump to compass to update direction
		b incrementcompass 			
		

tl1x: # Chase ccw 5hz
	# Check for 5hz enable signal
	li $11, 0x2
	li $12, 0x2
	
	# Mask bit 1, of $20 status reg for 5hz flag.
	and $11, $20, $11
	
	# Continue to loop through compass/counter while in current state if not enabled.
	bne $11, $12, decodecompass
	
	# Load mask value for digit 3 bit select
	li $11, 0xFF000000
	
	# Select digit 3 bits for testing. $21 is unmodified.
	AND $12, $23, $11
	
	# Test value for segment A. 
	li $11, SEG_A
	
	# so, if digit 3 bits equal $11(SEG_A), branch to SEG_F in continueccw1x	
	beq $11, $12, continueccw1x
	
	# So, if not SEG_A, decrement
	li $11, 0x01000000			# decrement Digit 3
	subu $23, $23, $11
	
	#clear digit 3 value
	li $11, 0x00FFFFFF
	and $21, $21, $11
	
	#set the digit 3 value
	or $21, $21, $23
	
	#update segment display
	#sw $21, 0($16)

	# Jump to compass to update direction
	beq   $0, $0, decrementcompass 

	continueccw1x:
	
		#load mask into $11 (t3)
		li $11, 0x00FFFFFF
		
		#Clear digit 3 value
		and $21, $21, $11
	
		#load SEG_F to enable bits.
		li $23, SEG_F
	
		#Update digit 3 value
		or $21, $21, $23
		
		#update segment display
		#sw $21, 0($16)

		# Jump to compass to update direction
		b decrementcompass 

tl2x: # Chase ccw 10hz
	# Check for 10hz enable signal
	li $11, 0x4
	li $12, 0x4
	
	# Mask bit 2, of $20 status reg for 10hz flag.
	and $11, $20, $11
	
	# Continue to loop through compass/counter while in current state if not enabled.
	bne $11, $12, counter

	# Load mask value for digit 3 bit select
	li $11, 0xFF000000
	
	# Select digit 3 bits for testing. $21 is unmodified.
	AND $12, $23, $11
	
	# Test value for segment A. 
	li $11, SEG_A
	
	# so, if digit 3 bits equal $11(SEG_A), branch to SEG_F in continueccw1x	
	beq $11, $12, continueccw1x
	
	# So, if not SEG_A, decrement
	li $11, 0x01000000			# decrement Digit 3
	subu $23, $23, $11
	
	#clear digit 3 value
	li $11, 0x00FFFFFF
	and $21, $21, $11
	
	#set the digit 3 value
	or $21, $21, $23
	
	#update segment display
	#sw $21, 0($16)

	# Jump to compass to update direction
	beq   $0, $0, decrementcompass  
	
	continueccw2x:
	
		#load mask into $11 (t3)
		li $11, 0x00FFFFFF
		
		#Clear digit 3 value
		and $21, $21, $11
	
		#load SEG_F to enable bits.
		li $23, SEG_F
	
		#Update digit 3 value
		or $21, $21, $23
		
		#update segment display
		#sw $21, 0($16)

		# Jump to compass to update direction
		b decrementcompass	

forward: # Segment a blinks at 1hz
	# Check for 1hz enable signal
	li $11, 0x1
	li $12, 0x1
	
	# Mask bit 0, of $20 status reg for 1hz flag.
	and $11, $20, $11
	
	# So, if 1hz bit is asserted, enable seg_A
	bne $11, $12, decodecompass
	
	# Check if digit 3 value is SEG_A
	li $11, 0xFF000000
	and $11, $21, $11
	
	#load test value into $12 for SEG_A
	li $12, SEG_A
	
	#test to see if current digit 3 value is SEG_A
	bne $12, $11, blinka
	
	# So, if 1hz bit asserted enable seg_A
	li $11, 0x00FFFFFF
	and $11, $21, $11
	
	#load blank enable value
	li $11, BLANK
	
	#update current value register
	or $21, $21, $11

	# Jump to compass to update direction/counter
	beq   $0, $0, decodecompass 	
	
blinka: #Turn on SEG_A

	# So, if 1hz bit asserted enable seg_A
	li $11, 0x00FFFFFF
	and $21, $21, $11
	
	#load SEG_A enable value
	li $11, SEG_A
	
	#update current value register
	or $21, $21, $11

	# Jump to compass to update direction/counter
	beq   $0, $0, decodecompass 	
	

reverse: # Segment d blinks at 1hz
	# Check for 1hz enable signal
	li $11, 0x1
	li $12, 0x1
	
	# Mask bit 0, of $20 status reg for 1hz flag.
	and $11, $20, $11
	
	# So, if 1hz bit is asserted, enable seg_A
	bne $11, $12, decodecompass
	
	# Check if digit 3 value is SEG_A
	li $11, 0xFF000000
	and $11, $21, $11
	
	#load test value into $12 for SEG_A
	li $12, SEG_D
	
	#test to see if current digit 3 value is SEG_A
	bne $12, $11, blinkd
	
	# So, if 1hz bit asserted enable seg_A
	li $11, 0x00FFFFFF
	and $11, $21, $11
	
	#load blank enable value
	li $11, BLANK
	
	#update current value register
	or $21, $21, $11

	# Jump to compass to update direction/counter
	beq   $0, $0, decodecompass	

blinkd:

	# So, if 1hz bit asserted enable seg_A
	li $11, 0x00FFFFFF
	and $21, $21, $11
	
	#load SEG_A enable value
	li $11, SEG_D
	
	#update current value register
	or $21, $21, $11

	# Jump to compass to update direction/counter
	beq   $0, $0, decodecompass 

incrementcompass: #$18 is the BCD counter to check boundary values.
	#Compare $18 with 0x00000359	
	li $11, 0x359

	bne $11, $18, inccompare
	
	# So, if so set to 0x00000000!
	
	li $18, 0x0
	b decodecompass
	
	inccompare:
		#AND COMPARE $18 with 0x00000009 (ones)
		andi $11, $18, 0x0F
		li $12, 0x9
		bne $11, $12, addones
		
		# So, if equal, clear ones.
		li $11, 0xFFFFFFF0
		and $18, $18, $11
		
		#AND COMPARE $18 with 0x00000090 (tens)  
		andi $11, $18, 0xF0
		li $12, 0x90
		bne $11, $12, addtens
		
		# So, if equal, clear ones.
		li $11, 0xFFFFFF0F
		and $18, $18, $11
		
		#add 0x00000100 (hundereds)
		addi $18, 0x100

		b decodecompass
	
	addtens:
		#Add tens bits 0x00000010
		addi $18, 0x10
		
		b decodecompass

	
	addones:
		#Add ones bits 0x00000001
		addi $18, 0x1
		
		b decodecompass

decrementcompass: #$18 is the BCD counter to check boundary values.
	#Compare $18 with 0x00000000, if so set to 0x00000359!
	#AND $18 with 0x00000009 (ones), if equal to 0, set to 0x9, sub 0x00000010 (tens)
	#AND $18 with 0x00000090 (tens), if equal to 0, set to 0x9, sub 0x00000100 (hundereds)

	#CHECK IF ZERO
	li $11, 0
	beq $18, $11, wrap

	#AND COMPARE $18 with 0x00000009 (ones)
	li $11, 0xF
	and $11, $18, $11
	li $12, 0x0
	bne $11, $12, subones
	
	
	#AND COMPARE $18 with 0x00000090 (tens)  
	li $11, 0xF0
	and $11, $18, $11
	li $12, 0x0
	bne $11, $12, subtens
	
	#AND COMPARE $18 with 0x300
	li $11, 0xF00
	and $11, $18, $11
	li $12, 0x0
	bne $11, $12, subhundereds
	
wrap:
	# So, if so set to 0x00000359!
	#clear lower 24 bits.
	li $11, 0xFF000000
	and $21, $21, $11
	
	#Set BCD value 
	li $18, 0x359
	
	b decodecompass

subhundereds:
	#sub hundereds bits 0x00000100
	li $12, 0x100
	sub $18, $18, $12
	
	#Set tens bits
	li $12, 0x90
	li $11, 0xFFFFFF0F
	and $18, $18, $11
	or $18, $18, $12
	
	#Set ones bits
	li $12, 0x9
	or $18, $18, $12
	
	b decodecompass


subtens:
	#sub tens bits 0x00000010
	li $12, 0x10
	sub $18, $18, $12
	
	#Set ones bits
	li $12, 0x9
	or $18, $18, $12
	
	b decodecompass


subones:
	#sub ones bits 0x00000001
	li $12,0x1
	sub $18, $18,$12
	
	b decodecompass


decodecompass:	#$18 holds the current BCD value., $11 hold temporary write value.

	#Digit 2 (hundereds) is valid between bit 20-16
	andi $12, $18, 0xF00
	SLL $12, $12, 8
	andi $11, $11, 0x0
	add $11, $12, $11
	
	#Digit 1 (tens) is valid between bit 12-8
	andi $12, $18, 0xF0
	SLL $12, $12, 4
	add $11, $12, $11
	
	#Digit 0 (ones) is valid between bit 4-0
	andi $12, $18, 0xF
	add $11, $12, $11
	
	#Clear lower 24 bits of current value register
	li $12, 0xFF000000
	and $21, $21, $12
	
	# add with current segment value reg $21
	add $21, $11, $21
	
	#update SSEG display
	sw $21, 0($16)
	

counter:	# Generates "clock". 26 bits required. 50M = 0x0?2FAF080
	
	#Check value for 1z flag toggle and wrap around.
	#li	$11, 50000000 # FPGA clock
	li	$11, 476190 # BusBlaster clock
	beq $19, $11, onehz
	
	#Is counter ($19) equal to 40M ($11)?
	#li	$11, 0x2625A00 # FPGA clock
	li	$11, 95238 # BusBlaster clock
	beq $19, $11, fivehz

	#Is counter ($19) equal to 30M ($11)?
	#li	$11, 0x1C9C380 # FPGA clock
	li	$11, 190476 # BusBlaster clock
	beq $19, $11, fivehz
	
	#Is counter ($19) equal to 20M ($11)?
	#li	$11, 0x1312D00 # FPGA clock
	li	$11, 285714 # BusBlaster clock
	beq $19, $11, fivehz
	
	#Is counter ($19) equal to 10M ($11)?
	#li	$11, 0x989680 # FPGA clock
	li	$11, 380952 # BusBlaster clock
	beq $19, $11, fivehz 
	
	#Is counter ($19) equal to 45M ($11)?
	#li	$11, 0x2AEA540 # FPGA clock
	li	$11, 238095 # BusBlaster clock
	beq $19, $11, tenhz 
	
	#Is counter ($19) equal to 35M ($11)?
	#li	$11, 0x2160EC0 # FPGA clock
	li	$11, 285714 # BusBlaster clock
	beq $19, $11, tenhz 
	
	#Is counter ($19) equal to 25M ($11)?
	#li	$11, 0x17D7840 # FPGA clock
	li	$11, 333333 # BusBlaster clock
	beq $19, $11, tenhz 
	
	#Is counter ($19) equal to 15M ($11)?
	#li	$11, 0xE4E1C0 # FPGA clock
	li	$11, 380952 # BusBlaster clock
	beq $19, $11, tenhz 
	
	#Is counter ($19) equal to 5M ($11)?
	#li	$11, 0x4C4B40 # FPGA clock
	li	$11, 428571 # BusBlaster clock
	beq $19, $11, tenhz 
	
	#clear flags
	li $20, 0x0

	# Branch to increment if no matches.
	b increment	
	
onehz:
	# Wrap counter to 0.
	li $19, 0x00000000
	
	# Toggle all bits (all are even multiples) $20 is Flags register, 
	xori $20, 0x1
	
	#fivehz and tenhz are multiples of 1hz, fall through to set bit.
	
fivehz:
	# Toggle 5 Hz bit 1, $20 is Flags register, 
	xori $20, 0x2
		
tenhz:
	# Toggle 5 Hz bit 2, $20 is Flags register, 
	xori $20, 0x4
	
	#fivehz is multiple of tenhz, fall through to set bit.

increment:
	#Increment counter register $19
	addi $19, $19, 0x01
	
	#Back to port read.

repeat:
	beq   $0, $0, readIO 	# repeat
