$NOMOD51
$INCLUDE (reg_C51.inc)		;To add SFR definition in the ASEM-51 assembler
$INCLUDE (LCD.a51)

;Variables and Flags
TWI_BUSY		BIT 2fh.0
TWI_READ		BIT 2fh.1
TWI_FAIL		BIT 2fh.2
PRINT_ENABLE		BIT 2fh.3
NEEDS_LEAP_YEAR		BIT 2fh.4
TWI_DATA		equ 70h
TWI_DATA_SIZE		equ 71h
TWI_DEBUG		equ 72h
VALUE			equ 73h
TIMER1_VAR		equ 74h

RTC_ADDRESS			equ 49h
RTC_SECONDS			equ 50h
RTC_MINUTES			equ 51h
RTC_HOURS			equ 52h
RTC_DAY				equ 53h
RTC_DATE			equ 54h
RTC_MONTH			equ 55h
RTC_YEAR			equ 56h
RTC_CONTROL			equ 57h
RTC_ALARM_SECONDS	equ 58h
RTC_ALARM_MINUTES	equ 59h
RTC_ALARM_HOURS		equ 5ah
RTC_YEAR_HIGH		equ 5bh
RTC_OLD_YEAR		equ 5ch

;Constants

;TWI SSCON bits
STA		equ 20h
STO		equ 10h
SI		equ 08h
AA		equ 04h

org 0000h
	ljmp MAIN

org 000bh
	ljmp TIMER0

org 001bh
	ljmp TIMER1

org 0043h
	ljmp TWI_IT

org 0100h
MAIN:
	call LCD_SETUP
	clr TWI_BUSY
	setb P4.0
	setb P4.1
	setb PRINT_ENABLE
	mov TIMER1_VAR, #50d
	
	mov SSCON, #01000000b	;TWI Master mode with Fosc/256
	orl IEN1, #00000010b	;Enable ETWI
	
	mov IPL1, #00h
	mov IPH1, #02h			;TWI interrupt as high priority
	
	mov TMOD, #11h
	mov TH0, #00h
	mov TL0, #00h
	mov TH1, #0b1h
	mov TL1, #0dfh
	setb Et1
	clr TR0
	clr TR1
	setb ET0
	mov IPH0, #08h		;Interrupt priority
	setb EA

	call CLOCK_INIT
	setb TR0

	MAIN_LOOP:
		call READ
		mov A, VALUE
		xrl A, #'*'
		jz J_NEW_CLOCK
		mov A, VALUE
		xrl A, #'#'
		jz J_PRINT_ALARM
		jmp MAIN_LOOP

	J_NEW_CLOCK:
		call ADD_TIME
		jmp MAIN_LOOP
	J_PRINT_ALARM:
		call PRINT_ALARM
		jmp MAIN_LOOP

PRINT_ALARM:
	clr PRINT_ENABLE
	call LCD_SETUP
	mov A, #LCD_LINE1
	add A, #03h
	call LCD_MOVE_CURSOR

	mov A, RTC_ALARM_HOURS
	swap A
	anl A, #03h
	add A, #'0'
	call LCD_PRINT_CHAR
	mov A, RTC_ALARM_HOURS
	anl A, #0fh
	add A, #'0'
	call LCD_PRINT_CHAR
	mov A, #':'
	call LCD_PRINT_CHAR
	
	mov A, RTC_ALARM_MINUTES
	swap A
	anl A, #0fh
	add A, #'0'
	call LCD_PRINT_CHAR
	mov A, RTC_ALARM_MINUTES
	anl A, #0fh
	add A, #'0'
	call LCD_PRINT_CHAR
	mov A, #':'
	call LCD_PRINT_CHAR
	
	mov A, RTC_ALARM_SECONDS
	swap A
	anl A, #07h
	add A, #'0'
	call LCD_PRINT_CHAR
	mov A, RTC_ALARM_SECONDS
	anl A, #0fh
	add A, #'0'
	call LCD_PRINT_CHAR

	PRINT_ALARM_LOOP:
		call READ
		mov A, VALUE
		xrl A, #'#'
		jz PRINT_ALARM_END
		mov A, VALUE
		xrl A, #'*'
		jz EDIT_ALARM
		jmp PRINT_ALARM_LOOP

	PRINT_ALARM_END:
	call LCD_SETUP
	setb PRINT_ENABLE
	ret

EDIT_ALARM:
	clr tr0
	mov A, #LCD_LINE1
	add A, #03h
	call LCD_MOVE_CURSOR
	
	mov A, #'h'
	call LCD_PRINT_CHAR
	mov A, #'h'
	call LCD_PRINT_CHAR
	mov A, #':'
	call LCD_PRINT_CHAR
	mov A, #'m'
	call LCD_PRINT_CHAR
	mov A, #'m'
	call LCD_PRINT_CHAR
	mov A, #':'
	call LCD_PRINT_CHAR
	mov A, #'s'
	call LCD_PRINT_CHAR
	mov A, #'s'
	call LCD_PRINT_CHAR

	mov A, #LCD_LINE1
	add A, #03h
	call LCD_MOVE_CURSOR

	SET_ALARM_HOUR_1:
		call read
		clr C
		mov A, VALUE
		subb A, #03h
		jnc SET_ALARM_HOUR_1
		mov r5, VALUE
		mov a, VALUE
		add A, #'0'
		call LCD_PRINT_CHAR
	SET_ALARM_HOUR_2:
		call read
		mov A, r5
		xrl A, #02h
		jz SH2_ALARM_LESS_3
		clr C
		mov A, VALUE
		subb A, #0ah
		jnc SET_ALARM_HOUR_2
		SH2_ALARM_EXIT:
			mov r4, VALUE
			mov a, VALUE
			add A, #'0'
			call LCD_PRINT_CHAR
			mov A, #':'
			call LCD_PRINT_CHAR

			mov A, r5
			swap A
			anl A, #30h
			orl A, r4
			mov RTC_ALARM_HOURS, A
			jmp SET_ALARM_MINUTE_1
		SH2_ALARM_LESS_3:
			clr C
			mov A, VALUE
			subb A, #04h
			jnc SET_ALARM_HOUR_2
			jmp SH2_ALARM_EXIT
	SET_ALARM_MINUTE_1:
		call read
		clr C
		mov A, VALUE
		subb A, #06h
		jnc SET_ALARM_MINUTE_1
		mov r5, VALUE
		mov a, VALUE
		add A, #'0'
		call LCD_PRINT_CHAR
	SET_ALARM_MINUTE_2:
		call read
		clr C
		mov A, VALUE
		subb A, #0ah
		jnc SET_ALARM_MINUTE_2
		mov r4, VALUE
		mov a, VALUE
		add A, #'0'
		call LCD_PRINT_CHAR
		mov A, #':'
		call LCD_PRINT_CHAR

		mov A, r5
		swap A
		orl A, r4
		mov RTC_ALARM_MINUTES, A
		jmp SET_ALARM_SECOND_1

	SET_ALARM_SECOND_1:
		call read
		clr C
		mov A, VALUE
		subb A, #06h
		jnc SET_ALARM_SECOND_1
		mov r5, VALUE
		mov a, VALUE
		add A, #'0'
		call LCD_PRINT_CHAR
	SET_ALARM_SECOND_2:
		call read
		clr C
		mov A, VALUE
		subb A, #0ah
		jnc SET_ALARM_SECOND_2
		mov r4, VALUE
		mov a, VALUE
		add A, #'0'
		call LCD_PRINT_CHAR

		mov A, r5
		swap A
		orl A, r4
		mov RTC_ALARM_SECONDS, A

	mov RTC_ADDRESS, #08h
	mov TWI_DATA, #RTC_ALARM_SECONDS
	mov TWI_DATA_SIZE, #03h
	call RTC_WRITE
	
	setb tr0
	jmp PRINT_ALARM_END

ADD_TIME:
	clr tr0
	clr NEEDS_LEAP_YEAR
	;Let's print the new screen
	mov A, #LCD_LINE1
	add A, #03h
	call LCD_MOVE_CURSOR
	
	mov A, #'h'
	call LCD_PRINT_CHAR
	mov A, #'h'
	call LCD_PRINT_CHAR
	mov A, #':'
	call LCD_PRINT_CHAR
	mov A, #'m'
	call LCD_PRINT_CHAR
	mov A, #'m'
	call LCD_PRINT_CHAR
	mov A, #':'
	call LCD_PRINT_CHAR
	mov A, #'s'
	call LCD_PRINT_CHAR
	mov A, #'s'
	call LCD_PRINT_CHAR

	mov A, #LCD_LINE2
	add A, #01h
	call LCD_MOVE_CURSOR

	mov A, #'D'
	call LCD_PRINT_CHAR
	mov A, #'D'
	call LCD_PRINT_CHAR
	mov A, #'/'
	call LCD_PRINT_CHAR
	mov A, #'M'
	call LCD_PRINT_CHAR
	mov A, #'M'
	call LCD_PRINT_CHAR
	mov A, #'/'
	call LCD_PRINT_CHAR
	mov A, #'A'
	call LCD_PRINT_CHAR
	mov A, #'A'
	call LCD_PRINT_CHAR
	mov A, #'A'
	call LCD_PRINT_CHAR
	mov A, #'A'
	call LCD_PRINT_CHAR
	mov A, #' '
	call LCD_PRINT_CHAR
	mov A, #'W'
	call LCD_PRINT_CHAR
	mov A, #' '
	call LCD_PRINT_CHAR
	mov A, #' '
	call LCD_PRINT_CHAR

	mov A, #LCD_LINE1
	add A, #03h
	call LCD_MOVE_CURSOR
	
	SET_HOUR_1:
		call read
		clr C
		mov A, VALUE
		subb A, #03h
		jnc SET_HOUR_1
		mov r5, VALUE
		mov a, VALUE
		add A, #'0'
		call LCD_PRINT_CHAR
	SET_HOUR_2:
		call read
		mov A, r5
		xrl A, #02h
		jz SH2_LESS_3
		clr C
		mov A, VALUE
		subb A, #0ah
		jnc SET_HOUR_2
		SH2_EXIT:
			mov r4, VALUE
			mov a, VALUE
			add A, #'0'
			call LCD_PRINT_CHAR
			mov A, #':'
			call LCD_PRINT_CHAR

			mov A, r5
			swap A
			anl A, #30h
			orl A, r4
			mov RTC_HOURS, A
			jmp SET_MINUTE_1
		SH2_LESS_3:
			clr C
			mov A, VALUE
			subb A, #04h
			jnc SET_HOUR_2
			jmp SH2_EXIT
	SET_MINUTE_1:
		call read
		clr C
		mov A, VALUE
		subb A, #06h
		jnc SET_MINUTE_1
		mov r5, VALUE
		mov a, VALUE
		add A, #'0'
		call LCD_PRINT_CHAR
	SET_MINUTE_2:
		call read
		clr C
		mov A, VALUE
		subb A, #0ah
		jnc SET_MINUTE_2
		mov r4, VALUE
		mov a, VALUE
		add A, #'0'
		call LCD_PRINT_CHAR
		mov A, #':'
		call LCD_PRINT_CHAR

		mov A, r5
		swap A
		orl A, r4
		mov RTC_MINUTES, A
		jmp SET_SECOND_1

	SET_SECOND_1:
		call read
		clr C
		mov A, VALUE
		subb A, #06h
		jnc SET_SECOND_1
		mov r5, VALUE
		mov a, VALUE
		add A, #'0'
		call LCD_PRINT_CHAR
	SET_SECOND_2:
		call read
		clr C
		mov A, VALUE
		subb A, #0ah
		jnc SET_SECOND_2
		mov r4, VALUE
		mov a, VALUE
		add A, #'0'
		call LCD_PRINT_CHAR

		mov A, r5
		swap A
		orl A, r4
		mov RTC_SECONDS, A

	mov A, #LCD_LINE2
	add A, #01h
	call LCD_MOVE_CURSOR

	SET_DATE_1:
		call READ
		clr C
		mov A, VALUE
		subb A, #04h
		jnc SET_DATE_1
		mov r5, VALUE
		mov a, VALUE
		add A, #'0'
		call LCD_PRINT_CHAR
	SET_DATE_2:
		call READ
		mov a, r5
		xrl a, #03h
		jz SD2T
		clr C
		mov A, VALUE
		subb A, #0ah
		jnc SET_DATE_2
		SDT2_CONTINUE:
		mov A, VALUE
		orl A, r5
		jz SET_DATE_2
		mov r4, VALUE
		mov a, VALUE
		add A, #'0'
		call LCD_PRINT_CHAR
		mov A, #'/'
		call LCD_PRINT_CHAR
		mov A, r5
		swap A
		orl A, r4
		mov RTC_DATE, A
		jmp SET_MONTH_1
		SD2T:
			clr C
			mov A, VALUE
			subb A, #02h
			jnc SET_DATE_2
			jmp SDT2_CONTINUE
	SET_MONTH_1:
		call READ
		clr C
		mov A, VALUE
		subb A, #02h
		jnc SET_MONTH_1
		mov r5, VALUE
		mov a, VALUE
		add A, #'0'
		call LCD_PRINT_CHAR
	SET_MONTH_2:
		call READ
		mov A, VALUE
		orl A, r5
		jz SET_DATE_2
		mov A, r5
		mov B, #0ah
		mul AB
		add A, VALUE
		mov r4,a
		xrl A, #02h
		jnz SM2CC
		clr C
		mov A, RTC_DATE
		subb A, #30h
		jnc SET_MONTH_2
		mov A, RTC_DATE
		xrl A, #29h
		jnz SM2CC
		setb NEEDS_LEAP_YEAR
		SM2CC:
		clr C
		mov A, r4
		subb A, #08h
		jc SM2C
		mov a, r4
		clr c
		subb a, #07h
		SM2C:
			anl a, #01h
			jz SM22
			SM2E:
				mov a, VALUE
				add A, #'0'
				call LCD_PRINT_CHAR
				mov A, #'/'
				call LCD_PRINT_CHAR
	
				mov A, r5
				swap A
				orl A, VALUE
				mov RTC_MONTH, A
				jmp SET_YEAR_1
			SM22:
				mov a, RTC_DATE
				subb a, #31h
				jnc SET_MONTH_2
				jmp SM2E

	SET_YEAR_1:
		call READ
		mov A, VALUE
		jz SET_YEAR_1
		clr C
		subb A, #03h
		jnc SET_YEAR_1
		mov r5, value
		mov a, VALUE
		add A, #'0'
		call LCD_PRINT_CHAR
	SET_YEAR_2:
		call READ
		mov a, r5
		xrl a, #01h
		jz SY2ONE
		mov A, VALUE
		anl A, #0feh
		jnz SET_YEAR_2
		jb NEEDS_LEAP_YEAR, SY22
		SY2END:
		mov r4, VALUE
		mov a, VALUE
		add A, #'0'
		call LCD_PRINT_CHAR
		jmp SET_YEAR_3
		SY2ONE:
			mov A, VALUE
			xrl A, #09h
			jnz SET_YEAR_2
			jmp SY2END
		SY22:
			mov A, VALUE
			xrl A, #01h
			jz SET_YEAR_2
			jmp SY2END
	SET_YEAR_3:
		call READ
		mov A, r4
		xrl A, #09h
		jz SY3SEVEN
		mov A, r4
		xrl A, #01h
		jz SY3ONE
		mov A, VALUE
		SY3C:
		clr C
		subb A, #0ah
		jnc SET_YEAR_3
		mov r3, value
		mov a, VALUE
		add A, #'0'
		call LCD_PRINT_CHAR
		jmp SET_YEAR_4
		SY3SEVEN:
			mov A, VALUE
			nop
			clr C
			subb A, #07h
			jc SET_YEAR_3
			jmp SY3C
		SY3ONE:
			mov A, VALUE
			jnz SET_YEAR_3
			jmp SY3C

	SET_YEAR_4:
		call READ
		mov A, r4
		xrl A, #01h
		jz SY4ONE
		mov A, VALUE
		clr C
		subb A, #0ah
		jnc SET_YEAR_4
		jb NEEDS_LEAP_YEAR, SY4_LEAP
		SY4C:
		mov a, VALUE
		add A, #'0'
		call LCD_PRINT_CHAR

		mov a, r5
		swap A
		orl A, r4
		mov RTC_YEAR_HIGH, A

		mov A, r3
		swap A
		orl A, VALUE
		mov RTC_YEAR, A

		mov A, #' '
		call LCD_PRINT_CHAR
		jmp SET_DAY
		SY4_LEAP:
			mov A, r3
			mov B, #0ah
			mul AB
			add A, VALUE
			mov B, #04h
			div AB
			mov A, B
			jnz SET_YEAR_4
			jmp SY4C
		SY4ONE:
			mov A, VALUE
			jnz SET_YEAR_4
			jmp SY4C
		
	SET_DAY:
		call READ
		mov A, VALUE
		jz SET_DAY
		clr C
		subb A, #08h
		jnc SET_DAY
		mov RTC_DAY, value
		mov a, VALUE
		add A, #'0'
		call LCD_PRINT_CHAR

	ADD_DATE_EXIT:
	mov RTC_ADDRESS, #00h
	mov A, RTC_YEAR
	mov RTC_OLD_YEAR, A
	mov TWI_DATA, #RTC_SECONDS
	mov TWI_DATA_SIZE, #0dh
	call RTC_WRITE
	setb TR0
	ret

;Write data to RTC
;IN		RTC_ADDR		<- Address to write on the RTC RAM
;IN		TWI_DATA		<- Pointer to transfer buffer
;IN		TWI_DATA_SIZE	<- Number of bytes to transfer
;OUT	TWI_FAIL		<- Set if failed occoured
RTC_WRITE:
	push 5
	push 4
	push 3
	mov r4, TWI_DATA
	INC TWI_DATA_SIZE
	mov r5, TWI_DATA_SIZE
	mov r3, #02h						;Number of tries if error occoured
	clr TWI_READ						;Just to be sure
	RTC_WRITE_ERROR:
		clr TWI_FAIL
		setb TWI_BUSY
		orl SSCON, #STA					;Start
		jb TWI_BUSY, $
		jnb TWI_FAIL, RTC_WRITE_EXIT
		mov TWI_DATA, r4
		mov TWI_DATA_SIZE, r5
		djnz r3, RTC_WRITE_ERROR
	RTC_WRITE_EXIT:
	pop 3
	pop 4
	pop 5
	ret

;Read data from RTC
;IN		RTC_ADDR		<- Address to read on the RTC RAM
;IN		TWI_DATA		<- Pointer to transfer buffer
;IN		TWI_DATA_SIZE	<- Number of bytes to transfer
;OUT	TWI_FAIL		<- Set if failed occoured
RTC_READ:
	push 6
	push 5
	push 4
	push 3
	mov r4, TWI_DATA
	mov r5, TWI_DATA_SIZE
	clr C
	mov A, RTC_ADDRESS
	subb A, #01h
	mov RTC_ADDRESS, A
	mov r6, RTC_ADDRESS
	mov r3, #02h						;Number of tries if error occoured
	RTC_READ_ERROR:
		setb TWI_READ					;We are reading
		clr TWI_FAIL
		setb TWI_BUSY
		orl SSCON, #STA					;Start
		jb TWI_BUSY, $
		jnb TWI_FAIL, RTC_READ_EXIT
		mov TWI_DATA, r4
		mov TWI_DATA_SIZE, r5
		mov RTC_ADDRESS, r6
		djnz r3, RTC_READ_ERROR
	RTC_READ_EXIT:
	clr TWI_READ
	pop 3
	pop 4
	pop 5
	pop 6
	ret

;Clock init
;Makes sure that the hour is in the correct format
;Loads the RTC
;Sees if the year is in the correct format as well
CLOCK_INIT:

	mov RTC_SECONDS, #00h
	mov RTC_MINUTES, #00h
	mov RTC_HOURS, #00h
	mov RTC_DAY, #01h
	mov RTC_DATE, #01h
	mov RTC_MONTH, #01h
	mov RTC_YEAR, #70h
	mov RTC_YEAR_HIGH, #19h
	mov RTC_OLD_YEAR, #70h
	mov RTC_CONTROL, #00h
	mov RTC_ALARM_SECONDS, #00h
	mov RTC_ALARM_MINUTES, #00h
	mov RTC_ALARM_HOURS, #07h

	mov TWI_DATA, #RTC_SECONDS
	mov TWI_DATA_SIZE, #0dh
	mov RTC_ADDRESS, #00h
	call RTC_WRITE

	;call DELAY_50MS
	;call DELAY_50MS
	;Lets be sure that CH is cleared
	;mov RTC_ADDRESS, #00h
	;mov TWI_DATA, #RTC_SECONDS
	;mov TWI_DATA_SIZE, #0dh
	;call RTC_READ

	;mov RTC_SECONDS, #0ffh
	;mov RTC_ADDRESS, #00h
	;mov TWI_DATA, #RTC_SECONDS
	;mov TWI_DATA_SIZE, #02h
	;call RTC_WRITE
	
	;mov RTC_SECONDS, #00h
	;mov RTC_DAY, #01h
	;anl RTC_SECONDS, #07Fh
	;anl RTC_HOURS, #0bfh
	;mov A, RTC_DAY
	;subb A, #08h
	;jc CLOCK_INIT_CONTINUE
	;mov RTC_DAY, #01h
	;CLOCK_INIT_CONTINUE:
	;mov A, RTC_DAY
	;jnz CLOCK_INIT_CONTINUE2
	;mov RTC_DAY, #01h
	;CLOCK_INIT_CONTINUE2:
	;mov RTC_ADDRESS, #00h
	;mov TWI_DATA, #RTC_SECONDS
	;mov TWI_DATA_SIZE, #0dh
	;call RTC_WRITE

	
	
	ret

PRINT_DATE:
	push 1
	mov A, #LCD_LINE1
	add A, #03h
	call LCD_MOVE_CURSOR

	mov A, RTC_HOURS
	swap A
	anl A, #03h
	add A, #'0'
	call LCD_PRINT_CHAR
	mov A, RTC_HOURS
	anl A, #0fh
	add A, #'0'
	call LCD_PRINT_CHAR
	mov A, #':'
	call LCD_PRINT_CHAR
	
	mov A, RTC_MINUTES
	swap A
	anl A, #0fh
	add A, #'0'
	call LCD_PRINT_CHAR
	mov A, RTC_MINUTES
	anl A, #0fh
	add A, #'0'
	call LCD_PRINT_CHAR
	mov A, #':'
	call LCD_PRINT_CHAR
	
	mov A, RTC_SECONDS
	swap A
	anl A, #07h
	add A, #'0'
	call LCD_PRINT_CHAR
	mov A, RTC_SECONDS
	anl A, #0fh
	add A, #'0'
	call LCD_PRINT_CHAR

	mov A, #LCD_LINE2
	add A, #01h
	call LCD_MOVE_CURSOR
	
	mov A, RTC_DATE
	swap A
	anl A, #0fh
	add A, #'0'
	call LCD_PRINT_CHAR
	mov A, RTC_DATE
	anl A, #0fh
	add A, #'0'
	call LCD_PRINT_CHAR
	mov A, #'/'
	call LCD_PRINT_CHAR
	
	mov A, RTC_MONTH
	swap A
	anl A, #0fh
	add A, #'0'
	call LCD_PRINT_CHAR
	mov A, RTC_MONTH
	anl A, #0fh
	add A, #'0'
	call LCD_PRINT_CHAR
	mov A, #'/'
	call LCD_PRINT_CHAR
	
	mov A, RTC_YEAR_HIGH
	swap A
	anl A, #0fh
	add A, #'0'
	call LCD_PRINT_CHAR
	mov A, RTC_YEAR_HIGH
	anl A, #0fh
	add A, #'0'
	call LCD_PRINT_CHAR
	mov A, RTC_YEAR
	swap A
	anl A, #0fh
	add A, #'0'
	call LCD_PRINT_CHAR
	mov A, RTC_YEAR
	anl A, #0fh
	add A, #'0'
	call LCD_PRINT_CHAR
	mov A, #' '
	call LCD_PRINT_CHAR
	
	;Converts 0-7 in 'DOM' - 'SAB'
	clr C
	mov r1, RTC_DAY
	mov a, r1
	jnz PC1
	mov r1, #01h
	PC1:
	mov a, r1
	subb a, #08h
	jc PC2
	mov r1, #07h
	PC2:
	mov A, r1
	nop
	dec A
	mov B, #04h
	mul AB
	mov DPTR, #DAY_MSG
	add A, DPL
	mov DPL, A
	mov A, DPH
	addc A, #00h
	mov DPH, A
	call LCD_PRINT_MSG
	pop 1
	ret

TIMER1:
	mov TH1, #0b1h
	mov TL1, #0dfh
	djnz TIMER1_VAR, TIMER1_EXIT
	mov TIMER1_VAR, #50d
	cpl p3.6
	TIMER1_EXIT:
	reti

;Timer0 interrupt handler
TIMER0:
	push ACC
	push B
	push PSW
	mov TH0, #00h
	mov TL0, #00h
	
	mov RTC_ADDRESS, #00h
	mov TWI_DATA, #RTC_SECONDS
	mov TWI_DATA_SIZE, #0dh
	
	call RTC_READ

	
	mov A, RTC_YEAR
	jz CHECK_CENTURY

	jnb PRINT_ENABLE, TIMER0_EXIT
	call PRINT_DATE
	call CHECK_ALARM
	TIMER0_EXIT:
	pop PSW
	pop B
	pop ACC
	reti
	
CHECK_CENTURY:
	mov A, RTC_YEAR
	xrl A, RTC_OLD_YEAR
	jz	TIMER0_EXIT			;We didn't just changed centuries
	mov A, RTC_YEAR_HIGH
	add A, #01h
	da A					;Fix BCD
	mov RTC_YEAR_HIGH, A
	mov RTC_OLD_YEAR, #00h

	jnb PRINT_ENABLE, CHECK_CENTURY_EXIT
	call PRINT_DATE
	call CHECK_ALARM
	
	;mov RTC_ADDRESS, #00h
	;mov TWI_DATA, #RTC_SECONDS
	;mov TWI_DATA_SIZE, #0dh
	;call RTC_WRITE			;Let's write our changes
	CHECK_CENTURY_EXIT:
	jmp TIMER0_EXIT
	

CHECK_ALARM:
	mov A, RTC_HOURS
	xrl A, RTC_ALARM_HOURS
	jnz CHECK_ALARM_EXIT
	mov A, RTC_MINUTES
	xrl A, RTC_ALARM_MINUTES
	jnz CHECK_ALARM_EXIT
	mov A, RTC_SECONDS
	xrl A, RTC_ALARM_SECONDS
	jnz CHECK_ALARM_EXIT
	setb TR1
	jmp ALARM
	CHECK_ALARM_EXIT:
	ret

ALARM:
	call read
	clr tr1
	setb p3.6
;Handle TWI interrupts
TWI_IT:
	push ACC
	push PSW

	;mov A, SSCS
	;swap A
	;anl A, #0fh
	;add A, #'0'
	;call LCD_PRINT_CHAR
	;mov A, SSCS
	;anl A, #0fh
	;add A, #'0'
	;call LCD_PRINT_CHAR
	mov A, SSCS
	jz TWI_ERROR		;Code is 00h, error in the BUS
	
	mov A, SSCS
	xrl A, #08h
	jz TWI_START		;Code is 08h, Start codition has been transmitted
	
	mov A, SSCS
	xrl A, #10h
	jz TWI_RESTART		;Code is 10h, Repeated start codition has been transmitted
	
	mov A, SSCS
	xrl A, #18h
	jz TWI_SLAW_ACK		;Code is 18h, SLA+W transmitted with ACK received
	
	mov A, SSCS
	xrl A, #20h
	jz TWI_ERROR		;Code is 20h, SLA+W transmitted with NACK received
	
	mov A, SSCS
	xrl A, #28h
	jz TWI_W_DATA_ACK	;Code is 28h, Data transmitted with ACK received
	
	mov A, SSCS
	xrl A, #30h
	jz TWI_ERROR		;Code is 30h, Data transmitted with NACK received
	
	mov A, SSCS
	xrl A, #38h
	jz TWI_ERROR		;Code is 38h, Arbitration lost in SLAW or Data
	
	mov A, SSCS
	xrl A, #40h
	jz TWI_SLR_ACK		;Code is 40h, SLA+R transmitted with ACK received
	
	mov A, SSCS
	xrl A, #48h
	jz TWI_ERROR		;Code is 48h, SLA+R transmitted with NACK received
	
	mov A, SSCS
	xrl A, #50h
	jz TWI_R_DATA_ACK	;Code is 50h, Data read with ACK returned
	
	mov A, SSCS
	xrl A, #58h
	jz TWI_R_DATA_NACK	;Code is 58h, Data read with NACK returned
	
	TWI_EXIT:
	pop PSW
	pop ACC
	reti

TWI_ERROR:
	mov TWI_DEBUG, SSCS
	anl SSCON, #(NOT (SI OR STA))		;Clear STA, SI and AA, Just to be sure
	orl SSCON, #STO							;Stop
	clr TWI_BUSY
	setb TWI_FAIL
	jmp TWI_EXIT

TWI_START:
	mov SSDAT, #11010000b					;RTC Address + W
	anl SSCON, #(NOT (STA OR STO OR SI))	;Clear STA, SI and STO, Just to be sure
	jmp TWI_EXIT

TWI_RESTART:
	mov SSDAT, #11010001b					;RTC Address + R
	anl SSCON, #(NOT (STA OR STO OR SI))	;Clear STA, SI and STO, Just to be sure
	jmp TWI_EXIT

TWI_SLAW_ACK:
	mov SSDAT, RTC_ADDRESS
	anl SSCON, #(NOT (STA OR STO OR SI))	;Clear STA, SI and STO, Just to be sure
	jmp TWI_EXIT

TWI_W_DATA_ACK:
	jb TWI_READ, TWDAR
	djnz TWI_DATA_SIZE, TWDAW
	
	anl SSCON, #(NOT (STA OR SI))
	orl SSCON, #STO
	clr TWI_BUSY
	jmp TWI_EXIT
	
	TWDAW:
		mov r0, TWI_DATA
		mov SSDAT, @r0
		anl SSCON, #(NOT (STO OR STA OR SI))	;CLEAR STO, STA and SI
		inc TWI_DATA
		jmp TWI_EXIT
	
	TWDAR:
		anl SSCON, #(NOT (STO OR SI))
		orl SSCON, #STA						;Restart
		jmp TWI_EXIT

TWI_SLR_ACK:
	anl SSCON, #(NOT (STA OR STO OR SI))	;Clear STA, SI and STO
	djnz TWI_DATA_SIZE, TSAR
	
	anl SSCON, #(NOT AA)
	jmp TWI_EXIT
	
	TSAR:
		orl SSCON, #AA
		jmp TWI_EXIT

TWI_R_DATA_ACK:
	mov r0, TWI_DATA
	mov @r0, SSDAT

	;call DEBUG
	inc TWI_DATA
	
	
	anl SSCON, #(NOT (STA OR STO OR SI))
	djnz TWI_DATA_SIZE, TRDAR
	
	anl SSCON, #(NOT AA)
	jmp TWI_EXIT
	TRDAR:
		orl SSCON, #AA
		jmp TWI_EXIT

TWI_R_DATA_NACK:
	mov r0, TWI_DATA
	mov @r0, SSDAT
	anl SSCON, #(NOT (STA OR SI OR AA))
	orl SSCON, #STO
	clr TWI_BUSY
	jmp TWI_EXIT

read:
	call delay_50ms
	mov P1, #0F7h
	mov DPTR, #input_line4
	jnb P1.0, read_column_3
	jnb P1.1, read_column_2
	jnb P1.2, read_column_1
	mov P1, #0EFh
	mov DPTR, #input_line3
	jnb P1.0, read_column_3
	jnb P1.1, read_column_2
	jnb P1.2, read_column_1
	mov P1, #0DFh
	mov DPTR, #input_line2
	jnb P1.0, read_column_3
	jnb P1.1, read_column_2
	jnb P1.2, read_column_1
	mov P1, #0BFh
	mov DPTR, #input_line1
	jnb P1.0, read_column_3
	jnb P1.1, read_column_2
	jnb P1.2, read_column_1
	jmp read
	ret

read_column_3:
	mov A, #02h
	movc A, @A+DPTR
	mov VALUE, A
	jmp read_delay

read_column_2:
	mov A, #01h
	movc A, @A+DPTR
	mov VALUE, A
	jmp read_delay
	
read_column_1:
	mov A, #00h
	movc A, @A+DPTR
	mov VALUE, A
	jmp read_delay

read_delay:
	call delay_50ms
	jnb P1.0, $
	jnb P1.1, $
	jnb P1.2, $
	call delay_50ms
	ret

delay_50ms:
	push 6
	mov r6, #0C8h
	delay_50ms_loop:
	call delay_250u
	djnz r6, delay_50ms_loop
	pop 6
	ret

delay_250u:
	push 7
	mov r7, #0FAh
	djnz r7, $
	pop 7
	ret

DAY_MSG:	db	'DOM', 00h, 'SEG', 00h, 'TER', 00h, 'QUA', 00h, 'QUI', 00h, 'SEX', 00h, 'SAB', 00h

input_line1:			db 01h, 02h, 03h
input_line2:			db 04h, 05h, 06h
input_line3:			db 07h, 08h, 09h
input_line4:			db '*', 00h, '#'

end
