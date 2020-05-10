	.syntax unified
	.cpu cortex-m4
	.thumb
.data
	//TODO: put 0 to F 7-Seg LED pattern here
	arr1: .byte 0x7E, 0x30, 0x6D, 0x79, 0x33, 0x5B, 0x5F, 0x70, 0x7F, 0x7B, 0x77, 0x1F, 0x4E, 0x3D, 0x4F, 0x47
	arr2: .byte 0x47, 0x4F, 0x3D, 0x4E, 0x1F, 0x77, 0x7B, 0x7F, 0x70, 0x5F, 0x5B, 0x33, 0x79, 0x6D, 0x30, 0x7E
.text
	.global main
	.equ	RCC_AHB2ENR,	0x4002104C
	.equ	GPIOA_MODER,	0x48000000
	.equ	GPIOA_OTYPER,	0x48000004
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

	.equ	one_sec,		1000000

main:
    BL   GPIO_init
    BL   max7219_init

Display0toF:
	//TODO: Display 0 to F at first digit on 7-SEG LED Display one per second
	mov r2, 0x0
	ldr r3, =arr1
display_loop1:
	mov r0, 0x1
	ldrb r1, [r3,r2]
	bl MAX7219Send

	ldr r0, =one_sec
	bl Delay

	add r2, 1
	cmp r2, 0x10
	bne display_loop1
	//b	Display0toF

	mov r2, 0x0
	ldr r3, =arr2
display_loop2:
	mov r0, 0x1
	ldrb r1, [r3,r2]
	bl MAX7219Send

	ldr r0, =one_sec
	bl Delay

	add r2, 1
	cmp r2, 0x10
	bne display_loop2
	b	Display0toF


GPIO_init:
	//TODO: Initialize three GPIO pins as output for max7219 DIN, CS and CLK
	//RCC_AHB2ENR: enable GPIOA
	mov r0, 0b1
	ldr r1, =RCC_AHB2ENR
	str r0, [r1]

	//GPIOA_MODER: PA7,6,5: output
	ldr r0, =0b010101
	lsl r0, 10
	ldr r1, =GPIOA_MODER
	ldr r2, [r1]
	and r2, 0xFFFF03FF //clear 7 6 5
	orrs r2, r2, r0 //7 6 5  --> output
	str r2, [r1]

	//GPIO_OSPEEDR: high speed
	mov r0, 0b101010 	//PA2,1,0: high speed
	lsl r0, 10
	ldr r1, =GPIOA_OSPEEDER
	ldr r2, [r1]
	and r2, 0xFFFF03FF
	orrs r2, r2, r0
	str r0, [r1]

	//GPIOA_OTYPER: push-pull

	BX LR //back to loop

MAX7219Send:
   //input parameter: r0 is ADDRESS , r1 is DATA
	//TODO: Use this function to send a message to max7219
	push {r0, r1, r2, r3, LR}
	lsl	r0, 8 //move to D15-D8
	add r0, r1 //r0 == din
	ldr r1, =DIN
	ldr r2, =CS
	ldr r3, =CLK
	ldr r4, =GPIOA_BSRR //-> 1
	ldr r5, =GPIOA_BRR //-> 0
	ldr r6, =0xF //current sending bit

max7219send_loop:
	mov r7, 1
	lsl r7, r6
	str r3, [r5] //CLK -> 0
	tst r0, r7 //same as ANDS but discard the result (update condition flag)
	beq set_0
	str r1, [r4] //din = 1
	b if_done

set_0:
	str r1, [r5] //din = 0

if_done:
	str r3, [r4] //CLK = 1
	subs r6, 0x1
	bge max7219send_loop
	str r2, [r5] //CS = 0
	str r2, [r4] //CS = 1
	pop {r0, r1, r2, r3, PC}
	BX LR

max7219_init:
	//TODO: Initialize max7219 registers
	push {r0, r1, LR}
	ldr r0, =DECODE
	ldr r1, =0x0 //NO DECODE
	bl MAX7219Send

	ldr r0, =DISPLAY_TEST
	ldr r1, =0x0 //normal operation
	bl MAX7219Send

	ldr r0, =INTENSITY
	ldr r1, =0xA // 21/32
	bl MAX7219Send

	ldr r0, =SCAN_LIMIT
	ldr r1, =0x0 //light digit 0
	bl MAX7219Send

	ldr r0, =SHUT_DOWN
	ldr r1, =0x1 //normal operation
	bl MAX7219Send

	pop {r0, r1, PC}
	BX LR

Delay:
   //TODO: Write a delay 1sec function
	beq  delay_end
	subs r0, 0x4
	b    Delay

delay_end:
	bx   lr