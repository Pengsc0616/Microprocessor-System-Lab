	.syntax unified
	.cpu cortex-m4
	.thumb
.data
	result: .word	0
	max_size:	.word	0
.text
	m:	.word	0x27
	n:	.word	0x41
	.global main

GCD:
		/*TODO: Implement your GCD function */
	ldr r2, [sp,#4]	//r2=m
	ldr r3, [sp] //r3=n
	pop	{r1, r0}		//r0=m, r1=n
	push {lr}

		cmp r2, #0		//if(m==0) return n
		beq return_n
		cmp	r3, #0		//if(n==0) return m;
		beq	return_m
		and r5,r2,#1
		cmp r5, #0
		beq maybe_also	//if(m%2==0) or if(m%2==0 && n%2==0)
		and r5,r3,#1
		cmp r5, #0
		beq	only_n_isEven //if(n%2==0) return GCD(m, n>>1)
		b final_return
		//else return GCD(abs(m-n),min(m,n))

	return_n:
		movs r8,r3
		b ohGod
	return_m:
		movs r8,r2
		b ohGod
	maybe_also:
		and r5, r3, #1
		cmp r5, #0
		beq both_even
		b only_m_isEven
	both_even:
		add r7,r7,#1    //calculate how many times the result should *2
		lsr r2, #1
		lsr r3, #1
		b turns_round
	only_m_isEven:
		lsr r2, #1
		b turns_round
	only_n_isEven:
		lsr r3, #1
		b turns_round
	final_return:
		cmp r2,r3
		bgt mBigger
		blt	nBigger
	mBigger:
		sub r2, r2, r3
		b turns_round
	nBigger:
		sub r3, r3, r2
		b turns_round
	turns_round:
		movs r0, r2
		movs r1, r3
		push {r0,r1}
		bl GCD                //branch point
		ohGod:
			pop {lr}
			add r9, r9, #1
			bx lr

main:
	/* r0 = m, r1 = n */
	ldr	r0,m
	ldr r1,n
	movs r7, #0		   //how many times the result should *2
	movs r8, #0        //result
	movs r9, #0        //times of recursive
	push	{r0,r1}
	BL GCD
	lsl r8, r7
	ldr r4, =result
	ldr r6, =max_size
	str r8, [r4]
	str r9, [r6]
L: B L
	/* get return val and store into result */
/*
int GCD(int a, int b)
{
if(a==0) return b;
if(b==0) return a;
if(a%2==0 && b%2==0) return 2*GCD(a>>1,b>>1)
else if(a%2==0) return GCD(a>>1, b)
else if(b%2==0) return GCD(a, b>>1)
else return GCD(abs(a-b),min(a,b))
}
/*

/*
	MOVS	RO, #1
	MOVS	R1, #2
	PUSH	{R0, R1}
	LDR	R2, [sp]
	LDR	R3, [sp, #4]
	POP	{R0, R1}
*/
