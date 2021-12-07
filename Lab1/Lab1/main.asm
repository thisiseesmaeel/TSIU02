	; r16-r19 free to use
	.def	num = r20 ; number 0-9
	.def	key = r21 ; key pressed yes/no

	;set stack
	ldi		r16,HIGH(RAMEND)
	out		SPH,r16
	ldi		r16,LOW(RAMEND)
	out		SPL,r16

	call	INIT
	clr		num
FOREVER:
	call	GET_KEY		; get keypress in boolean 'key'
LOOP:
	cpi		key,0
	breq	FOREVER		; until key
	out		PORTB,num	; print digit
	call	DELAY
	inc		num			; num++
	cpi		num,10		; num==10?
	brne	NOT_10		; no, so jump
	clr		num			; was 10
NOT_10:
	call	GET_KEY
	jmp		LOOP

	;
	; -- GET_key. Returns key != 0 if key pressed
GET_KEY:
	clr		key
	sbic	PINC,0		; <---- skip over if not pressed
	dec		key			; key=$FF
	ret

	;
	; --- Init. A0 in, B3-B0 out
INIT:
	clr		r16
	out		DDRC,r16
	ldi		r16,$0F
	out		DDRB,r16
	ret

	;
	; --- DELAY. Wait a lot!
	
DELAY:
	ldi		r18,3
D_3:
	ldi		r17,0
D_2:
	ldi		r16,0
D_1:
	dec		r16
	brne	D_1
	dec		r17
	brne	D_2
	dec		r18
	brne	D_3
	ret
