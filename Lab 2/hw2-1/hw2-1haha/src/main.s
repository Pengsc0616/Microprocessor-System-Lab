	.syntax unified
	.cpu cortex-m4
	.thumb


.data
	user_stack_bottom: .zero 128
	expr_result: .word 0

.text
	.global main
	postfix_expr: .asciz "-5    200 -40 + 2 - -"
	.align 2


main:
	LDR	R0, =postfix_expr
	ldr sp, =user_stack_bottom
	add sp, sp, #128
	bl string_length
	movs r1, #0		//i=0
	adds r9, r1, #0
	big_loop:    //for(i=0; i<strlen; i++)
		movs r4, r0
		adds r4, r4, r1
		ldrb r4, [r4]    //get the charactor
		cmp r4, #32
		bne cant_ignore		//it's space
		adds r1, r1, #1
		b big_loop
		cant_ignore:
			cmp r4, #43
			beq plus_sign
			cmp r4, #45
			beq minus_or_negitive
			numbers:
				bl atoi
				cmp r1, r3
				blt big_loop         //no case should jump to end_point
			plus_sign:
				pop {r6,r5}
				adds r5,r5,r6
				push {r5}
				adds r1,r1,#1
				cmp r1, r3
				bge end_point
				b big_loop
			minus_or_negitive:
				adds r1, r1, #1
				movs r4, r0
				adds r4, r4, r1
				ldrb r4, [r4]
				cmp r4, #32
				beq minus_sign
				cmp r4, #0
				beq minus_sign
				movs r9, #1    //r9==1 means it's negitive
				b numbers
				minus_sign:
					pop {r6,r5}
					sub r5,r6,r5
					push {r5}
					//adds r4,r4,#1   //don't need to add again
					cmp r1, r3
					bge end_point
					b big_loop
	end_point:
		ldr r4, =expr_result
		str r5, [r4]
		b program_end
/*TODO: Setup stack pointer to end of user_stack and calculate the
expression using PUSH, POP operators, and store the result into
expr_result
*/

program_end:
	B	program_end

atoi:
	/*TODO: implement a "convert string to integer" function*/
	movs r7, #0    //j=0
	find_digit:
		movs r4, r0
		adds r4, r4, r1
		adds r4, r4, r7
		ldrb r4, [r4]
		cmp r4, #32
		beq end_find_digit
		adds r7, r7, #1
		b find_digit     //if "471", r7=3
	end_find_digit:
		//add r1, r1, r7    //reset r1 to next space
 		movs r2, r7
		movs r5, #10    //r5=10
		movs r8, #1		//r2=times*10
		movs r6, #0		//the final integer
		sub r7, r7, #1  //digit in the position of that integer
		integer_made:
			movs r4, r0
			adds r4, r4, r1
			adds r4, r4, r7
			ldrb r4, [r4]
			sub r4, r4, #48
			mul r4, r4, r8
			adds r6, r6, r4  //one digit (without neg or not) is made
			sub r7, r7, #1
			mul r8, r8, r5
			cmp r7, #0
			bge integer_made
			cmp r9, #0   //check if it is negitive
			//movs r9, #0  //is_negitive
			beq ready_push
			movs r9, #0
			sub r9, r9, #1
			mul r6, r6, r9
			movs r9, #0
			ready_push:
				add r1,r1,r2
				push {r6}
				bx lr

string_length:
	mov r3, #0		//r3=string_length
	loop_haha:
		movs r4, r0
		adds r4, r4, r3
		ldrb r4, [r4]
		cmp r4, #0
		beq strlen_finish
		adds r3, r3, #1
		b loop_haha
	strlen_finish:
		bx lr














