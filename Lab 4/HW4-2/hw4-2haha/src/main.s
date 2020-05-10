	.syntax unified
	.cpu cortex-m4
	.thumb

.data
	student_id: .byte 15, 10, 12, 11, 13, 14, 10 //TODO: put your student id here

.text
	.global main
	.equ	RCC_AHB2ENR,	0x4002104C
	.equ	GPIOA_MODER,	0x48000000
	.equ	GPIOA_OSPEEDER,	0x48000008
	.equ	GPIOA_PUPDR,	0x4800000C
	.equ	GPIOA_IDR,		0x48000010
	.equ	GPIOA_ODR,		0x48000014
	.equ	GPIOA_BSRR,		0x48000018 //set 1
	.equ	GPIOA_BRR,		0x48000028 //clear 0

	.equ 	DIN,	0b100000 	//PA5
	.equ	CS,		0b1000000	//PA6
	.equ	CLK,	0b10000000	//PA7

	.equ	DECODE,			0x9
	.equ	INTENSITY,		0xA
	.equ	SCAN_LIMIT,		0xB
	.equ	SHUT_DOWN,		0xC
	.equ	DISPLAY_TEST,	0xF

main:
    BL   GPIO_init
    BL   max7219_init
    //TODO: display your student id on 7-Seg LED
    BL	Display_work
    BX LR

Display_work:
	mov r0, 0x8 //r0 = which digit
	mov r2, 0x0 //arr pointer
	ldr r3, =student_id
main_loop:
	subs r0, r0, 1 //digit -1
	ldrb r1, [r3,r2] //student_id1[r2]
	bl MAX7219Send
	adds r2, r2, 1 //move arr pointer
	cmp r0, 1 //first digit finish
	bne main_loop
	b Display_work

GPIO_init:
	//TODO: Initialize three GPIO pins as output for max7219 DIN, CS and CLK
	//RCC_AHB2ENR: enable GPIOA
	mov r0, 0b1
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

	//GPIOA_OTYPER: push-pull

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
	ldr r1, =0xFF //CODE B decode for digit 0-7
	bl MAX7219Send

	ldr r0, =DISPLAY_TEST
	ldr r1, =0x0 //normal operation
	bl MAX7219Send

	ldr r0, =INTENSITY
	ldr r1, =0xA //21/32
	bl MAX7219Send

	ldr r0, =SCAN_LIMIT
	ldr r1, =0x6 //light up digit 0-6
	bl MAX7219Send

	ldr r0, =SHUT_DOWN
	ldr r1, =0x1 //normal operation
	bl MAX7219Send

	pop {r0, r1, PC}
	BX LR
