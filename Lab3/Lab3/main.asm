;
; Lab3.asm
;
; Created: 08/12/2021 15:13:29
; Author : hadia
;

	.equ	SECOND_TICKS = 62500 - 1

	.org	$0000
	jmp		MAIN
	
	.org	OC1Aaddr
	jmp		INTERRUPT




	.org	INT_VECTORS_SIZE
MAIN:
	; initierar stacken
	ldi		r16, HIGH(RAMEND)
	out		SPH, r16
	ldi		r16, LOW(RAMEND)
	out		SPL, r16

	; konfigurerar bit 4 i PORTB som utgång
	sbi		DDRB, 4 
	
	; initierar timer som ger 1s puls
	call	TIMER1_INIT
	sei


WAIT:
	jmp		WAIT

TIMER1_INIT:
	ldi		r16, (1<<WGM12) | (1<<CS12)
	sts		TCCR1B,r16
	ldi		r16,HIGH(SECOND_TICKS)
	sts		OCR1AH,r16
	ldi		r16,LOW(SECOND_TICKS)
	sts		OCR1AL,r16
	ldi		r16,(1<<OCIE1A)
	sts		TIMSK1,r16
	ret


INTERRUPT:
	push	r18
	push	r17
	push	r16
	
	in		r16, SREG
	
	in		r17, PORTB
	ldi		r18, 0b00000000
	eor		r17, r18
	out		PORTB, r18

	out		SREG, r16
	
	pop		r16
	pop		r17
	pop		r18

	reti

