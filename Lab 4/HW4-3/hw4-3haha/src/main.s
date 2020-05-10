	.syntax unified
	.cpu cortex-m4
	.thumb

.data
	fib_array: .asciz "01123581321345589144233377610987159725844181676510946177112865746368750251213931964183178115142298320401346269217830935245785702887922746514930352241578173908816963245986:1"
	num_digit: .byte 0x1, 0x1, 0x1, 0x1, 0x1, 0x1, 0x1, 0x2, 0x2, 0x2, 0x2, 0x2, 0x3, 0x3, 0x3, 0x3, 0x3, 0x4, 0x4, 0x4, 0x4, 0x5, 0x5, 0x5, 0x5, 0x5, 0x6, 0x6, 0x6, 0x6, 0x6, 0x7, 0x7, 0x7, 0x7, 0x7, 0x8, 0x8, 0x8, 0x8, 0x2

.text
	.global main
	.equ	RCC_AHB2ENR,	0x4002104C
	.equ	GPIOA_MODER,	0x48000000
	.equ	GPIOA_OTYPER,	0x48000004
	.equ	GPIOA_OSPEEDER,	0x48000008
	.equ	GPIOA_PUPDR,	0x4800000C
	.equ	GPIOA_IDR,		0x48000010
	.equ	GPIOA_ODR,		0x48000014
	.equ	GPIOA_BSRR,		0x48000018 //set bit -> 1
	.equ	GPIOA_BRR,		0x48000028 //clear bit -> 0

	.equ 	DIN,	0b100000 	//PA5
	.equ	CS,		0b1000000	//PA6
	.equ	CLK,	0b10000000	//PA7

	.equ	DECODE,			0x9
	.equ	INTENSITY,		0xA
	.equ	SCAN_LIMIT,		0xB
	.equ	SHUT_DOWN,		0xC
	.equ	DISPLAY_TEST,	0xF

	.equ	GPIOC_MODER,	0x48000800
	.equ	GPIOC_OTYPER,	0x48000804
	.equ	GPIOC_OSPEEDER,	0x48000808
	.equ	GPIOC_PUPDR,	0x4800080C
	.equ	GPIOC_IDR,		0x48000810
	//timer
	.equ	press_long,		10000
	.equ 	press_short,	100

main:
    BL	GPIO_init
    BL	max7219_init
    mov r4, 0x0  //******* # of current number **********
    mov r5, 0x0  //******* current number's "Start Position" in fib_array *********
    start_from_find_digit:
	ldr r2, =fib_array
	ldr r3, =num_digit
	ldrb r11, [r3,r4]  //r11 now = the digit of current number
	subs r1, r11, 1
	ldr r0, =SCAN_LIMIT
	bl MAX7219Send 	  //set digit finish
	mov r0, 0x0
	important_loop:
	//mov r0, r11	      //r0 = position in LED
	adds r0, r0, #1
	subs r11, r11, #1
	adds r11, r11, r5
	ldrb r1, [r2,r11]
	subs r11, r11, r5 //maintain r11
	sub r1, r1, #48	  //r1 = char of current number digit
	bl check_bottom
	bl MAX7219Send
	cmp r11, 0
	bne important_loop
	b start_from_find_digit

check_bottom:
	ldr r6, [r7]
	lsr r6, r6, #13
	and r6, r6, 0x1
	cmp r6, #0
	it eq
	addseq r8, r8, #1

	cmp r6, #1
	it eq
	moveq r8, #0
	ldr r9, =press_short
	ldr r10, =press_long

	cmp r8, r9
	ittt eq
	ldrbeq r12, [r3,r4]
	addeq r4, r4, 0x1   //r4 move = go to next fib number
	addeq r5, r5, r12

	cmp r8, r10
	itt eq
	moveq r5, #0        //restart fib_array
	moveq r4, #0		//restart num_digit

	cmp r4, #40
	itt ge
	movsge r4, #40
	movsge r5, #170

	bx lr


GPIO_init:
	//TODO: Initialize three GPIO pins as output for max7219 DIN, CS and CLK
	//RCC_AHB2ENR: enable GPIOA
	mov r0, 0b101
	ldr r1, =RCC_AHB2ENR
	str r0, [r1]

	//GPIOA_MODER: PA567: output
	ldr r0, =0b010101
	lsl r0, 10
	ldr r1, =GPIOA_MODER
	ldr r2, [r1]
	and r2, 0xFFFF03FF
	orrs r2, r2, r0
	str r2, [r1]

	//GPIO_OSPEEDR: high speed
	mov r0, 0b101010
	lsl r0, 10
	ldr r1, =GPIOA_OSPEEDER
	ldr r2, [r1]
	and r2, 0xFFFF03FF
	orrs r2, r2, r0
	str r0, [r1]

	//GPIOA_OTYPER: push-pull (reset state)

	ldr r0, =GPIOC_MODER
	ldr r1, [r0]
	and r1, r1, 0xf3ffffff
	str r1, [r0]

	ldr r7, =GPIOC_IDR    //**********R7=GPIOC_IDR************

	BX LR

MAX7219Send:
	//input parameter: r0 is ADDRESS , r1 is DATA
	//TODO: Use this function to send a message to max7219
	push {r0, r1, r2, r3, r4, r5, r6, r7, LR}
	lsl	r0, 8 //move to D15-D8
	add r0, r1 //r0 == din
	ldr r1, =DIN
	ldr r2, =CS
	ldr r3, =CLK
	ldr r4, =GPIOA_BSRR //-> 1
	ldr r5, =GPIOA_BRR //-> 0
	ldr r6, =0xF //now sending (r6)-th bit

max7219send_loop:
	mov r7, 1
	lsl r7, r6
	str r3, [r5] //CLK = 0
	tst r0, r7 //same as ANDS but no result (update condition flag)
	beq set_0
	str r1, [r4] //din = 1
	b finish

set_0:
	str r1, [r5] //din = 0

finish:
	str r3, [r4] //CLK = 1
	subs r6, 0x1
	bge max7219send_loop
	str r2, [r5] //CS = 0
	str r2, [r4] //CS = 1
	pop {r0, r1, r2, r3, r4, r5, r6, r7, PC}
	BX LR


max7219_init:
	//TODO: Initialize max7219 registers
	push {r0, r1, LR}
	ldr r0, =DECODE
	ldr r1, =0xFF //NO DECODE
	bl MAX7219Send

	ldr r0, =DISPLAY_TEST
	ldr r1, =0x0 //normal operation
	bl MAX7219Send

	ldr r0, =INTENSITY
	ldr r1, =0xA // 21/32
	bl MAX7219Send

	ldr r0, =SCAN_LIMIT
	ldr r1, =0x0 //light up digit 0
	bl MAX7219Send

	ldr r0, =SHUT_DOWN
	ldr r1, =0x1 //normal operation
	bl MAX7219Send

	pop {r0, r1, PC}
	BX LR
