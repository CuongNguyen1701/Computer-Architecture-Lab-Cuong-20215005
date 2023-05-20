#Nguyen Truc Cuong 20215005
#Nguyen Thanh Dat 20215028
#mini-Project 14
.data
string1: .asciiz "aabcbbca"
array1: .space 128 #array of 128 bytes in size, correspond to string 1
string2: .asciiz "adcaca"
array2: .space 128 #correspond to string 2
result_string: .asciiz	"The number of common character of string \""
and_string: .asciiz		"\" and \""
is_string: .asciiz	"\" is: "
.text
main:
preprocessing:
    # Initialize all elements of the array to zero
    la $t0, array1      
    la $t1, array2
    li $t2, 128          # size of the arrays in bytes
    li $t3, 0             # counter
    loop:
        beq $t3, $t2, end_loop  # if we have initialized all elements, exit the loop
        add $t4, $t0, $t3   # calculate the address of the current element
        add	$t5, $t1, $t3
        sb $zero, 0($t4)       # store the value 0 at the address
        sb $zero, 0($t5)       # store the value 0 at the address
        addi $t3, $t3, 1    # increment the counter
        j loop
    end_loop:
    
commonCharacterCount:

	la	$a0, string1
	la	$a1, array1
	jal character_count_and_map
	
	la	$a0, string2
	la	$a1, array2
	jal character_count_and_map
	
	la $t0, array1      
    	la $t1, array2
    	li $t2, 128          # size of the arrays in bytes
    	li $t3, 0             # counter
    	li	$s0, 0	#common character counter
	check_loop:
        	beq $t3, $t2, end_check_loop  # if we have initialized all elements, exit the loop
        	# calculate the address of the current element
        	add $t4, $t0, $t3   
        	add	$t5, $t1, $t3
        	
        	#get the value stored in the array
        	lb	$t6, 0($t4)
        	lb	$t7, 0($t5)
        	sub	$t8, $t6, $t7 #t8 = t6 - t7
		bgtz $t8, greater_than
		
		smaller_than_or_equal: #t6 <= t7
			add		$s0, $s0, $t6		#increase s0 by the number of character in the index of the array which have the smaller element
			j continue
		
		greater_than: #$t6 > $t7
			add		$s0, $s0, $t7		#increase s0 by the number of character in the index of the array which have the smaller element
		continue:
        	addi $t3, $t3, 1    # increment the counter
        	j check_loop
    	end_check_loop:
    	#print result
    	li 	$v0, 4
	la	$a0, result_string
	syscall
    	li 	$v0, 4
	la	$a0, string1
	syscall
    	li 	$v0, 4
	la	$a0, and_string
	syscall
    	li 	$v0, 4
	la	$a0, string2
	syscall
    	li 	$v0, 4
	la	$a0, is_string
	syscall
    	li	$v0, 1
    	add	$a0, $zero, $s0
    	syscall

end_main:
	li	$v0, 10	#terminate
	syscall
character_count_and_map:
	#Perform mapping from character's ascii value and the array index ('a' => 0, 'b' => 1, ... , 'z' => 25)
	#The appearance count is mapped to the value stored in the corresponding index of the array (i. e. A[0] = countChar(string, 'a'))
	add	$t6, $zero, $a0 #string pointer
	add	$t7, $zero, $a1 #array pointer
	string_iteration:
		lb	$t8, 0($t6)
		beqz $t8, end_string_iteration #if char == '\0' break from loop
		addi  $t9, $t8, -97 #get the index mapping of a character
		#t9 = t9*4
		add $t9, $t9, $t9
		add $t9, $t9, $t9 
		add $t0, $t7, $t9 #add the index to the array pointer - get the corresponding location of a letter in the array
		#update the value in memory
		lb	$t1, 0($t0)
		addi $t1, $t1, 1
		sb	$t1, 0($t0)
		addi $t6, $t6, 1 #go to the next byte
		j	string_iteration
	end_string_iteration:
	
	jr	$ra	

	

	
	
	
	
	
	
	
	