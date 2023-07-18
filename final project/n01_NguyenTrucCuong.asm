#HEXA KEYBOARD
.eqv IN_ADRESS_HEXA_KEYBOARD 0xFFFF0012
.eqv OUT_ADRESS_HEXA_KEYBOARD 0xFFFF0014

#KEYBOARD
.eqv KEY_CODE 0xFFFF0004 # ASCII code from keyboard, 1 byte
.eqv KEY_READY 0xFFFF0000 # =1 if has a new keycode, otherwise 0

#MARSBOT
.eqv HEADING 0xFFFF8010  # 0  up, 90 right, 180 down, 270, left
.eqv MOVING 0xFFFF8050 # 1 1 move, 0 stop
.eqv LEAVETRACK 0xFFFF8020 # 1 draw, 0 not draw

.data
clear_msg : .asciiz	  "\n reset successfully, please enter new command: \n"
.text
main:	li $t0, HEADING
		li $at, 180 #default direction is down
		sw $at, 0($t0)
		li $t1, IN_ADRESS_HEXA_KEYBOARD
 		li $t2, OUT_ADRESS_HEXA_KEYBOARD
 		li $k0, KEY_CODE
 		li $k1, KEY_READY
 		li $t3, 0x80 # bit 7 of = 1 to enable interrupt 
 		sb $t3, 0($t1)
 		add $fp, $zero, $sp #setup for marsbot memory
 setup:	jal SETUP
 		nop
Loop: 	nop
 		nop
 		nop
 		nop
 		nop
 		b Loop # Wait for interrupt
 		nop
 		b Loop # Wait for interrupt
 		nop
end_main:

SETUP:
	#go diagonal
	li $at, HEADING # change HEADING port
	li $a0, 135
 	sw $a0, 0($at) # to rotate robot
 	nop
 	#go
	li $at, MOVING # change MOVING port
 	addi $a0, $zero,1 # to logic 1,
 	sb $a0, 0($at) # to start running
 	#wait 5s
 	li $a0, 15000
 	li $v0, 32
 	syscall
 	nop
 	#stop
	li $at, MOVING # change MOVING port to 0
 	sb $zero, 0($at) # to stop
 	nop
	#go right
	li $at, HEADING # change HEADING port
	li $a0, 90
 	sw $a0, 0($at) # to rotate robot
 	nop
 	#go
 	jr $ra

# GENERAL INTERRUPT SERVED ROUTINE for all interrupts
.ktext 0x80000180
IntSR: 	lw $s6, MOVING #store initital state
 		beq $s6, $zero, skip_stop#if already stopped then skip
 			jal STOP #temporarily stop for easier control
 		skip_stop:	li $t4, 0x10
restart_cmd:
 		li $t5, 0 #number of keys pressed
 		li $s3, 0 #MARSBOT action code
reset: 	li $t3, 0x01 
 		
polling: 	beq	$t3, $t4, reset #no printing if there is no key pressed
		sb 	$t3, 0($t1 ) # must reassign expected row
 		lbu 	$a0, 0($t2) # read scan code of key button
 		bne $a0, $zero, print
 		sll	$t3, $t3, 1 	
 		
 		
 		
sleep10: 	li $a0, 10 # sleep 10ms
 		li $v0, 32
 		syscall
 		j polling
 		
 print: 	addi $t5, $t5, 1 #increase the key_pressed_count
 		jal keycode_to_hex #v0 now is the hex value of the key pressed
 		add $s0, $zero, $v0 #save the hex output
 		
 		add $a0, $s0, $zero
 		jal single_hex_to_char
 		#print the hex character to the output
 		add $a0, $zero, $v0
 		li $v0, 11 
 		syscall	
 process_cmd:		li $t6, 3 #maximum 3 print
 					sub $s1, $t6, $t5 #s1 = 3 - t5, t5 in {1, 2, 3} therefore s1 in {2, 1, 0}
 					sll $s1, $s1, 2 #multiply $s1 by 4, si now in {8, 4, 0}
 					sllv $s2, $s0, $s1 #shift hex number by 0, 1 or 2 digit based on s1
 					or $s3, $s3, $s2 #add the new hex number to the marsbot code
 		 
 		
 		
 sleep1500:	li $a0, 1500 # sleep 1.5s
 			li $v0, 32
 			syscall
 		bne $t5, $t6, polling #not reached 3 key then polling
 		
		
 		WaitForKey: 	lw $t8, 0($k1) # KEY_READY
 					beq $t8, $zero, WaitForKey # if = 0 then Polling
 		lw $t9, 0($k0)  #t9 = KEY_CODE
 	
 		li $t7, 0xa #ascii value for ENTER key
 		beq $t9, $t7, Enter #if ENTER then calling 
 		
 		li $t7, 0x7f #ascii value for DEL key
 		beq $t9, $t7, Del #if ENTER then calling marsbot
 		j WaitForKey
 		
 		Enter:	add $a0, $zero, $s3 #input marsbot code
 				jal call_marsbot
 				j end_Intr
 		
 		Del:	li $v0, 4
 			la $a0, clear_msg
 			syscall
 			j restart_cmd
 			nop
 		end_Intr:
 		li $a0, 10#print newline
 		li $v0, 11
 		syscall
 		li $t3, 0x80 # bit 7 of = 1 to enable interrupt 
 		sb $t3, 0($t1)
#epc + 4		
next_pc:	mfc0 $at, $14 # $at <= Coproc0.$14 = Coproc0.epc
 		addi $at, $at, 4 # $at = $at + 4 (next instruction)
 		mtc0 $at, $14 # Coproc0.$14 = Coproc0.epc <= $at
 		
return: 	eret # Return from exception 
 
keycode_to_hex:
	li $t6, -1 #column (from 0 to 3)
	li $t7, -1 #row (from 0 to 3)
	li $t9, 0x1 #start checking the lower 4 bits
	loop_row: 
		addi $t7, $t7, 1 
		and $t8, $a0, $t9 #check if there is a bit 1
		sll $t9, $t9, 1
		beq $t8, $zero, loop_row #if not continue to check

	li $t9, 0x10 #start checking the higher 4 bits
	loop_col:
		addi $t6, $t6, 1
		and $t8, $a0, $t9 #check if there is a bit 1
		sll $t9, $t9, 1
		beq $t8, $zero, loop_col #if not continue to check
	
		#result = 4*(row_coord) + col_coord
		sll $t7, $t7, 2 #mult by 4
		add $v0, $t7, $t6 #return value
		
		jr $ra
		nop

single_hex_to_char:
	slti $at, $a0, 0xa #check if the hex value is less than 0xa
	beq $at, $zero, letter
	number:
		addi $v0, $a0, 48 #convert to ascii value of number
		j end_single_hex_to_char
	letter:
		addi $v0, $a0, 87 #a_hex = 10_int -> 10 + 87 = 97 (ascii for 'a')
	end_single_hex_to_char:
	jr $ra
	nop
	
#MARS BOT'S FUNCTIONS
call_marsbot:
	#$a0 is the hex value of the input call code
	add $s7, $zero, $ra #store the return address for other subprocesses
	#compare the two number using xor
	cmd0:	xori $s5, $a0, 0x1b4
			beq $s5, $zero, go_call
			j cmd1
	go_call: 		li $s6, 1 #bypass state restoration		
				j end_call 
	#########################
	cmd1:	xori $s5, $a0, 0xc68
			beq $s5, $zero, stop_call
			j cmd2
	stop_call: 	li $s6, 0 #bypass state restoration
			 	j end_call 
	#########################
	cmd2:	xori $s5, $a0, 0x444
			beq $s5, $zero, left_call
			j cmd3
	left_call: 		addi $sp, $sp, -8
				sw $a0, 0($sp) #store call code in stack
				sw $zero, 4($sp) #changing direction has 0 time interval
				lw $a0, HEADING
				addi $a0, $a0, -90 # relative left = counter-clockwise
				jal ROTATE
			 	j end_call 
	#########################
	cmd3:	xori $s5, $a0, 0x666
			beq $s5, $zero, right_call
			j cmd4
	right_call: 	addi $sp, $sp, -8
				sw $a0, 0($sp) #store call code in stack
				sw $zero, 4($sp) #changing direction has 0 time interval
				lw $a0, HEADING
				addi $a0, $a0, 90 # relative right = clockwise
				jal ROTATE
			 	j end_call
	#########################
	cmd4:	xori $s5, $a0, 0xdad
			beq $s5, $zero, track_call
			j cmd5
	track_call: 	jal TRACK
			 	j end_call 
	#########################
	cmd5:	xori $s5, $a0, 0xcbc
			beq $s5, $zero, untrack_call
			j cmd6
	untrack_call: 	jal UNTRACK
			 	j end_call 
	######################### 
	cmd6:	xori $s5, $a0, 0x999
			beq $s5, $zero, retrace_call
			j end_call
	retrace_call: 	jal RETRACE
	##########################
	end_call:	beq $s6, $zero, stay_stopped #s6 is the initital state(can be overwritten by GO or STOP)
				jal GO #if s6 is 1 then continue moving
	stay_stopped:	add $ra, $zero, $s7 #restore the return address
	jr $ra
	nop

RETRACE:	add $t6, $zero, $ra #store return address
			lw $a0, HEADING
			addi $a0, $a0, 180 #rotate back
			jal ROTATE
			jal UNTRACK #stop tracking
	
	check:	beq $sp, $fp, end_check
			lw $a0, 0($sp) #load past command from stack
			lw $a1, 4($sp) #load interval from stack
			addi $sp, $sp, 8 #pop stack
			#################################
			xori $s5, $a0, 0x1b4
			beq $s5, $zero, go_return
			#################################
			xori $s5, $a0, 0x444 #left rotate code
			beq $s5, $zero, right_return
			#################################
			xori $s5, $a0, 0x666 #right rotate code
			beq $s5, $zero, left_return
			#################################
	go_return:	jal GO_NO_MEM
				j finish_return
				nop
	#################################
	right_return:	lw $a0, HEADING
				addi $a0, $a0, 90 # relative right = clockwise
				jal ROTATE
				j finish_return
				nop
	#################################
	left_return:	lw $a0, HEADING
				addi $a0, $a0, -90 # relative left = counter-clockwise
				jal ROTATE
	#################################
	finish_return:	addu $a0, $zero, $a1 # sleep until next command
 					li $v0, 32
 					syscall
 					nop
 					li $s6, 0 #bypass state restoration
					jal STOP_NO_MEM
	j check
	end_check:	lw $a0, HEADING
				addi $a0, $a0, 180 #rotate back
				jal ROTATE
	
	add $ra, $zero, $t6 #restore return address
	jr $ra
	nop
	

GO: li $at, MOVING # change MOVING port
 	addi $a0, $zero,1 # to logic 1,
 	sb $a0, 0($at) # to start running
 	
 	addi $sp, $sp, -8 #make space for storing go command and timestamp
 	addi $at, $zero, 0x1b4 #code for go cmd
 	sw $at, 0($sp)
 	
 	#get system time - lower bits in $a0
	li $v0, 30
	syscall
	sw $a0, 4($sp)
	
 	nop
 	jr $ra
 	nop
	

STOP: 	li $at, MOVING 
		bne $at, $zero, set_duration #if stop from a moving state then store the duration
		j skip_set_duration
	set_duration:	li $v0, 30 #get system time - lower bits in $a0
				syscall
				lw $a1, 4($sp) #a0 = current time, a1 = past time
				sub $a0, $a0, $a1
				sw $a0, 4($sp) #store the time interval in sp
	skip_set_duration:	sb $zero, 0($at) # change MOVING port to 0
 						nop
 	jr $ra
 	nop
	

TRACK: 	li $at, LEAVETRACK # change LEAVETRACK port
 		addi $a0, $zero,1 # to logic 1,
 		sb $a0, 0($at) # to start tracking
 		nop
 		jr $ra
 		nop

UNTRACK:	li $at, LEAVETRACK # change LEAVETRACK port to 0
 			sb $zero, 0($at) # to stop drawing tail
 			nop
 			jr $ra
 			nop
 
ROTATE: li $at, HEADING # change HEADING port
 		sw $a0, 0($at) # to rotate robot
 		
 		lw $at, LEAVETRACK #check if leaving track
		beq $at, $zero, end_rotate #if not then immediately end
		nop
			add $a1, $zero, $ra #store return address for recall
			jal UNTRACK
			nop
			jal TRACK
			nop
			add $ra, $zero, $a1 #restore return address
	end_rotate:	jr $ra
 				nop
	
 	
GO_NO_MEM: 	li $at, MOVING # change MOVING port
 				addi $a0, $zero,1 # to logic 1,
 				sb $a0, 0($at) # to start running
 				nop
 				jr $ra
 				nop
	

STOP_NO_MEM: 	li $at, MOVING # change MOVING port to 0
 				sb $zero, 0($at) # to stop
 				nop
 				jr $ra
 				nop
	
