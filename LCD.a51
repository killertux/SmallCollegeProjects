RS equ P2.5						;Instruction enable LCD
RW equ p2.6						;Write enable LCD
EN equ p2.7						;Enable LCD
LCD_LINE1 equ 80h						;Display first line
LCD_LINE2 equ 0c0h						;Display second line

org 0650h	
;*
;*	LCD_MOVE_CURSOR
;*	Moves cursor to the position stored in the accumulator
;*
LCD_MOVE_CURSOR:
	mov P0, A
	clr RS
	clr RW
	setb EN
	nop
	clr EN
	call LCD_DELAY40
	ret

;*
;*	LCD_PRINT_MSG
;*	Print the message pointed by DPTR
;*	String must end with a 00h
;*
LCD_PRINT_MSG:
	push 4
	mov r4, #00h
	LCD_PRINT_MSG_LOOP:
	mov a, r4
	movc a, @a+dptr
	jz LCD_PRINT_MSG_EXIT
	call LCD_PRINT_CHAR
	inc R4
	jmp LCD_PRINT_MSG_LOOP
	LCD_PRINT_MSG_EXIT:
	pop 4
	ret

;*
;*	LCD_PRINT_CHAR
;*	Print the char stored in the accumulator
;*
LCD_PRINT_CHAR:
	clr EN
	mov P0, a
	
	setb RS
	clr RW
	
	setb EN
	nop
	clr EN
	
	call LCD_DELAY20
	ret

;*
;*	LCD_SETUP
;*	Handles the LCD setup
;*
LCD_SETUP:
	clr EN
	clr RS
	clr RW
	
	mov A, #0ah
	mov P0, A
	
	setb EN
	nop
	clr EN
	
	call LCD_DELAY164
	
	mov A, #0ch
	mov P0, A
	
	setb EN
	nop
	clr EN
	
	call LCD_DELAY164
	
	mov A, #01h
	mov P0, A
	
	setb EN
	nop
	clr EN
	
	call LCD_DELAY164
	
	mov A, #02h
	mov P0, A
	
	setb EN
	nop
	clr EN
	
	call LCD_DELAY164
	
	mov A, #3ch
	mov P0, A
	
	setb EN
	nop
	clr EN
	
	call LCD_DELAY40
	
	mov A, #0fh
	mov P0, A
	
	setb EN
	nop
	clr EN
	
	call LCD_DELAY40
	ret
	
LCD_DELAY164:
	push 7
	mov r7, #45h
	LCD_DELAY164_LOOP:
	call LCD_DELAY40
	djnz r7, LCD_DELAY164_LOOP
	pop 7
	ret

LCD_DELAY40:
	push 7
	mov r7, #02h
	LCD_DELAY40_LOOP:
	call LCD_DELAY20
	djnz r7, LCD_DELAY40_LOOP
	pop 7
	ret

LCD_DELAY20:
	push 7
	mov r7, #20h
	djnz r7, $
	pop 7
	ret
