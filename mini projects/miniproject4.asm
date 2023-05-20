#Nguyen Truc Cuong 20215005
#Nguyen Thanh Dat 20215028
#mini-Project 4
.data
enter_array_size: .asciiz "Enter array size: "
enter_index_number: .asciiz "Enter integer A["
colon: .asciiz "]:"
menu_text: .asciiz "\nChoose the action you want to do: \n [0] Find the maximum element of the array \n [1] Calculate the number of elements in the range of (m, M) \n [2] Exit \n\nYour option: "
maximum_element_in_array_is: .asciiz "\nThe maximum element in the array is: "
enter_m: .asciiz "\nEnter m: "
enter_M: .asciiz "\nEnter M: "
the_number_of_elements_in_the_range_from: .asciiz "\nThe number of element in the range from "
to: .asciiz " to "
is: .asciiz  " is:"
.text
main:
	#get array size
	li 	$v0, 4
	la	$a0, enter_array_size
	syscall	
	li	$v0, 5
	syscall
	
	add	$t0, $zero, $v0 #Array element count
preprocessing:
	add $t1, $t0, $t0
	add $t1, $t1, $t1 #Array size in bytes n = sizeof(arraySize) = 4*arraySize
	sub $t2, $zero, $t1 #get the negative value for stack pointer
	 
	add	$t3, $zero, $sp #Store the stack begin pointer
	add	$sp, $sp, $t2	#adjust stack pointer(make space to store array) sp = sp - n
	li $t4, 0
	input_loop:
		beq	$t3, $sp, input_loop_end
		
		#"Enter integer A[i]"
		li 	$v0, 4
		la	$a0, enter_index_number
		syscall	
		li 	$v0, 1
		add	$a0, $zero, $t4
		syscall	
		li 	$v0, 4
		la	$a0, colon
		syscall
		#Get integer
		li	$v0, 5
		syscall
		
		#Store integer
		sw	$v0, 0($t3)
		addi $t4, $t4, 1#i=i+1
		addi $t3, $t3, -4 #goto next element
		j	input_loop
	input_loop_end:
	add	$t3, $t3, $t1 #t3 = t3 + (array size in bytes) #Restore t3
	
	li	$t5, -1	#init menu option
menu:
	#print menu
	li 	$v0, 4
	la	$a0, menu_text
	syscall
	#get user's option
	li	$v0, 5
	syscall
	add	$t5, $zero, $v0	#load the menu option

	beq	$t5, 0, find_max
	beq	$t5, 1, count_in_range
	beq	$t5, 2, end_main #terminate program if the user choose to exit
	j menu
	find_max:
		li	$t6, -0x8000 #smallest 16-bit signed integer, t6 is the current max
		max_loop:
		beq	$t3, $sp, max_loop_end
		lw $t7, 0($t3)
		check_max:
			blt	$t7, $t6, no_new_max #branch if the number from array is smaller than the current max - t6
			add $t6, $zero, $t7	#set new max
		no_new_max:
		addi $t3, $t3, -4 #goto next element
		j	max_loop
		max_loop_end:
		add	$t3, $t3, $t1 #t3 = t3 + (array size in bytes) #Restore t3
		li 	$v0, 4
		la	$a0, maximum_element_in_array_is
		syscall
		#print the max value
		li	$v0, 1
		add	$a0, $zero, $t6
		syscall	
		j	menu
	count_in_range:
		li 	$v0, 4
		la	$a0, enter_m
		syscall
		#get m
		li	$v0, 5
		syscall
		#store m
		add $t8, $zero, $v0
		
		li 	$v0, 4
		la	$a0, enter_M
		syscall
		#get M
		li	$v0, 5
		syscall
		#store M
		add $t9, $zero, $v0
		
		li	$t6, 0 #init count to 0
		in_range_loop:
			beq	$t3, $sp, in_range_loop_end
			lw $t7, 0($t3)
			check_smaller_than_min:
			blt	$t7, $t8, not_in_range
			check_greater_than_max:
			blt	$t9, $t7, not_in_range #if not in range then skip
			#if in range then increase the count
			addi $t6, $t6, 1
			
			not_in_range:
			addi $t3, $t3, -4 #goto next element
			j	in_range_loop
		in_range_loop_end:
		add	$t3, $t3, $t1 #t3 = t3 + (array size in bytes) #Restore t3
		#print result
		li 	$v0, 4
		la	$a0, the_number_of_elements_in_the_range_from
		syscall
		li 	$v0, 1
		add	$a0, $zero, $t8
		syscall
		li 	$v0, 4
		la	$a0, to
		syscall
		li 	$v0, 1
		add	$a0, $zero, $t9
		syscall
		li 	$v0, 4
		la	$a0, is
		syscall
		#result value
		li 	$v0, 1
		add	$a0, $zero, $t6
		syscall
		j	menu
end_main:
	add	$sp, $sp, $t1
	li	$v0, 10	#terminate
	syscall
