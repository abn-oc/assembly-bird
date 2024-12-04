[org 0x100]
jmp start

;included files
%include'bgpalette.asm'
%include'barrier.asm'

;variables
pillarYPrev: dw 0
numOfPipes: dw 4
pillarsX: dw 170, 250, 330, 410
pillarsY: dw 60+60, 80+60, 45+60, 70+60 	;keep y coordinate 95(highest) or above and dont make it above 150(lowest)
pillarsYInv: dw 60, 80, 45, 70  ;keep y coordinate 30(highest) or above and dont make it above 75(lowest)
birdY: dw 90
birdDir: db 'D'

prevCol: times 26 db 0

timerCounter: dw 0
bird: db 0
pauseFlag: db 0

line1: db '___________.____                                 __________.__           .___', 0
line2: db '\_   _____/|    |   _____  ______ ______ ___.__. \______   \__|______  __| _/', 0
line3: db ' |    __)  |    |   \__  \ \____ \\____ <   |  |  |    |  _/  \_  __ \/ __ | ', 0
line4: db ' |     \   |    |___ / __ \|  |_> >  |_> >___  |  |    |   \  ||  | \/ /_/ | ', 0
line5: db ' \___  /   |_______ (____  /   __/|   __// ____|  |______  /__||__|  \____ | ', 0
line6: db '     \/            \/    \/|__|   |__|   \/              \/               \/ ',0
 
line7: db 'Made by', 0
line8: db 'Abdullah Ihtasham        23L-2515', 0
line9: db 'Muhammad Wali            23L-00855', 0
line10: db 'FALL 2024', 0
line11: db 'Press Enter to Start', 0

headerLine1: db '  ________                        ________                      ',0
headerLine2: db ' /  _____/_____    _____   ____   \_____  \___  __ ___________ ', 0
headerLine3: db '/   \  ___\__  \  /     \_/ __ \   /   |   \  \/ // __ \_  __ \', 0
headerLine4: db '\    \_\  \/ __ \|  Y Y  \  ___/  /    |    \   /\  ___/|  | \/', 0
headerLine5: db ' \______  (____  /__|_|  /\___  > \_______  /\_/  \___  >__|   ', 0
headerLine6: db '        \/     \/      \/     \/          \/          \/        ', 0

headerLine7: db '  ________                        __________                                .___', 0
headerLine8: db ' /  _____/_____    _____   ____   \______   \_____   __ __  ______ ____   __| _/', 0
headerLine9: db '/   \  ___\__  \  /     \_/ __ \   |     ___/\__  \ |  |  \/  ___// __ \ / __ | ', 0
headerLine10: db '\    \_\  \/ __ \|  Y Y  \  ___/   |    |     / __ \|  |  /\___ \\  ___// /_/ | ', 0
headerLine11: db ' \______  (____  /__|_|  /\___  >  |____|    (____  /____//____  >\___  >____ | ', 0
headerLine12: db '        \/     \/      \/     \/                  \/           \/     \/     \/ ', 0


pausedText: db 'Game Paused. Press Enter to continue.', 0
gameOverText: db 'Press any key to exit the game', 0


oldTimerIsr dd 0
oldKbIsr dd 0

;interrupts
timerInt:
	pushA
	add word [timerCounter], 1

	cmp word [timerCounter], 2
	jl .End
	mov word [timerCounter], 0
	cmp byte [bird], 1
	je .putZero
		mov byte [bird], 1
		jmp .End	
	.putZero: 
		mov byte [bird], 0

	.End:
	mov al, 0x20
	out 0x20, al
	popA
	iret

kbisr:
    push ax
    push es
    in al, 0x60         ; Read scan code from keyboard controller
	cmp al, 0xB9        ; Check if the key is spacebar release (break code)
    je .spaceReleased   ; Jump if spacebar is released
    cmp al, 0x39        ; Check if the key is the spacebar
    je .spacePressed    ; Jump if spacebar is pressed (make code)
	cmp al, 01h
	je .pauseGame
    jmp .outKbIsr        ; Exit for other keys
	

.spacePressed:
    mov byte [birdDir], 'U'
    jmp .outKbIsr

.spaceReleased:
    mov byte [birdDir], 'D'
    jmp .outKbIsr

.pauseGame:
	mov byte [pauseFlag], 1

.outKbIsr:
    mov al, 0x20
    out 0x20, al

    pop es
    pop ax
    iret

printLine:
	push bp
	mov bp, sp
	push ax
	push es

	mov ax, 0xb800
	mov es, ax

	mov ax, 80
	mul word [bp + 4]
	add ax, [bp + 6]
	shl ax, 1
	mov di, ax 
	mov si, [bp + 8]
	mov ah, 0x0E
	.drawLine:
		mov al, [ds:si]
		cmp al, 0
		je .continue 
		mov [es:di], ax
		add si, 1
		add di, 2
		jmp .drawLine

.continue:
	pop es
	pop ax
	mov sp, bp
	pop bp
	ret 6

pauseTheGame:
	; Wait for Enter key to be pressed
	mov ah, 00h   ; BIOS function to set video mode
	mov al, 03h   ; Set mode to 03h (80x25 text mode)
	int 10h       ; Call BIOS interrupt

	mov ax, 0xb800
	mov es, ax

	push headerLine7
	push word 0
	push word 1
	call printLine

	push headerLine8
	push word 0
	push word 2
	call printLine

	push headerLine9
	push word 0
	push word 3
	call printLine

	push headerLine10
	push word 0
	push word 4
	call printLine

	push headerLine11
	push word 0
	push word 5
	call printLine

	push headerLine12
	push word 0
	push word 6
	call printLine

	push pausedText
	push word 20
	push word 16
	call printLine


.wait_for_enter:
	in al, 0x60          ; Read scan code from the keyboard controller
	cmp al, 0x1C         ; Check if Enter key is pressed (scan code for Enter)
	jne .wait_for_enter  ; Keep waiting if not Enter

	;call delay
		mov byte [pauseFlag], 0
		call initResPalette
		call drawBG
	ret

gameOver:
	mov ah, 00h   ; BIOS function to set video mode
	mov al, 03h   ; Set mode to 03h (80x25 text mode)
	int 10h       ; Call BIOS interrupt

	push headerLine1
	push word 10
	push word 1
	call printLine

	push headerLine2
	push word 10
	push word 2
	call printLine

	push headerLine3
	push word 10
	push word 3
	call printLine

	push headerLine4
	push word 10
	push word 4
	call printLine

	push headerLine5
	push word 10
	push word 5
	call printLine

	push headerLine6
	push word 10
	push word 6
	call printLine

	push gameOverText
	push word 24
	push word 16
	call printLine

.wait_for_enter:
	in al, 0x60          ; Read scan code from the keyboard controller
	cmp al, 0x1C         ; Check if Enter key is pressed (scan code for Enter)
	jne .wait_for_enter  ; Keep waiting if not Enter

	call clrscr			; Clear the screen
	; Restore the cursor position.
	mov ah, 02h
    mov bh, 0          ; Page 0
    mov dh, 24         ; 24th Row
    mov dl, 0          ; 0th Column
    int 10h

	; Unhooking the previous interrupts.
	xor ax, ax
	mov es, ax

	mov ax, [oldKbIsr]								; read old offset in ax
	mov bx, [oldKbIsr + 2]							; read old segment in bx
			
	cli												; disable interrupts
	mov [es:9*4], ax								; restore old offset from ax
	mov [es:9*4+2], bx								; restore old segment from bx
	sti												; enable the interrupts

	mov ax, [oldTimerIsr]								; read old offset in ax
	mov bx, [oldTimerIsr + 2]							; read old segment in bx
			
	cli												; disable interrupts
	mov [es:8*4], ax								; restore old offset from ax
	mov [es:8*4+2], bx								; restore old segment from bx
	sti												; enable the interrupts

	mov ax, 0x4c00
	int 21h

;functions
initResPalette:
	;set 13h vga mode
	pushA
	mov ax, 13h
	int 10h
	mov ax, 0xA000
	mov es, ax
	
	;set color pallete
	mov dx, 03c8h        ; DAC write index register
	mov al, 0            ; Start at color index 0
	out dx, al
	mov dx, 03c9h        ; DAC data register
	mov cx, 768          ; 256 colors 3 (RGB)
	mov si, palette_data
	
	palette_loop:
		lodsb
		out  dx, al
		loop palette_loop
	
	popA
	ret
	
drawBG:
	push bp
	mov  bp, sp
	
	;first half of bg
	push 0        ;x
	push 0        ;y
	push 160      ;width
	push 200      ;height
	push bg       ;pixel data
	call drawRect

	;second half of bg
	push 159      ;x
	push 0        ;y
	push 160      ;width
	push 200      ;height
	push bg       ;pixel data
	call drawRect

	mov sp, bp
	pop bp
	ret

drawRect:   
	push bp
	mov  bp, sp
	pushA
	mov  ax, 0xA000
	mov  es, ax

	mov si, [bp + 4]  ;pixel data
	mov di, [bp + 12] ;x
	;moving di to the required y cord
	mov bx, [bp + 10] ;y
	.ydi:
		add di, 320
		sub bx, 1
		jnz .ydi
	mov bx, [bp + 8] ;w 
	mov dx, [bp + 6] ;h

	.printRect:
		mov cx, bx
		.printLine:  
			mov  al,           [ds:si]
			mov  byte [es:di], al
			inc  di
			inc  si
			loop .printLine
		add di, 320
		sub di, bx
		dec dx
		jnz .printRect

		popA
		pop bp
		ret 10

; This subroutine saves the background to the 0xE000 segment for easy retrieval afterwards.
saveBG:
	push bp
	mov bp, sp
	pushA
	push ds
	push es

	mov ax, 0xE000
	mov es, ax
	mov ax, 0xA000
	mov ds, ax

	xor di, di
	xor si, si

	mov cx, 64000

	.loop:
		mov ax, [ds:si]
		mov [es:di], ax
		add si, 2
		add di, 2
		loop .loop

	pop es
	pop ds
	popA
	mov sp, bp
	pop bp
	ret

drawRectTrans:   
	push bp
	mov  bp, sp
	sub  sp, 4
	pushA
	mov  ax, 0xA000
	mov  es, ax
	
	mov si,       [bp + 4]  ;pixel data
	mov di,       [bp + 12] ;x
	mov [bp - 2], di
	mov [bp - 4], di
	;moving di to the required y cord
	mov bx,       [bp + 10] ;y
	.ydi:
		add di, 320
		sub bx, 1
		jnz .ydi
	mov bx, [bp + 8] ;w 
	mov dx, [bp + 6] ;h

	.printRect:
		mov  cx, bx
		push bx
		mov  bx, [bp - 4]
		mov  [bp - 2], bx
		pop  bx
		.printLine:
			cmp word [bp - 2], 0
			jl  .cont
			cmp word [bp - 2], 320
			jge .cont
			mov al, [ds:si]
			
			cmp word [bp + 16], 1
			je .isBird
            cmp al, 0x0F
			je  .cont
			cmp al, 0x10
			je  .cont
			.isBird:
		 	cmp al, 0x00
			je  .cont
			add al, [bp + 14]
			
			mov  byte [es:di],  al
			.cont:
			add  word [bp - 2], 1
			inc  di
			inc  si
			loop .printLine
		;exit function if on ground line
		cmp di, 320*172
		jae .exitfunc

		add di, 320
		sub di, bx
		dec dx
		jnz .printRect
		.exitfunc:
		popA
		add sp, 4
		pop bp
		ret 14
		
drawRectTransInv:   
	push bp
	mov  bp, sp
	sub  sp, 4

	pushA
	mov  ax, 0xA000
	mov  es, ax
	
	mov si, [bp + 4]  ;pixel data
	mov di, [bp + 12] ;x
	mov [bp - 2], di
	mov [bp - 4], di
	;moving di to the required y cord
	mov bx, [bp + 10] ;y
	cmp bx, 0
	je .cont1
	.ydi:
		add di, 320
		sub bx, 1
		jnz .ydi
	.cont1:
	mov bx, [bp + 8] ;w 
	mov dx, [bp + 6] ;h

	.printRect:
		mov cx, bx
		push bx
		mov  bx, [bp - 4]
		mov  [bp - 2], bx
		pop  bx
		.printLine:        ;explain this part wali....
			cmp word [bp - 2], 0
			jl  .cont
			cmp word [bp - 2], 320
			jge .cont
			mov al, [ds:si]
            cmp al, 0x0F
			je  .cont
			cmp al, 0x10
			je  .cont
			add al, 55
			
			mov  byte [es:di], al
			.cont:
			add  word [bp - 2], 1
			inc  di
			inc  si
			loop .printLine
		;exit function if on ground line
		cmp di, 320
		jbe .exitfunc
		
		sub di, 320
		sub di, bx
		dec dx
		jnz .printRect
		.exitfunc:
		popA
		add sp, 4
		pop bp
		ret 10


drawCroppedBG:   
	push bp
	mov  bp, sp

	pushA
	push ds
	push es

	mov ax, 0xA000
	mov es, ax

	mov ax, 0xE000
	mov ds, ax

	mov ax, 320
	mul word [bp + 8]
	add ax, [bp + 10]
	mov di, ax

	mov cx, [bp + 4] ; height
	mov bx, [bp + 6]
	.printRect:
		push cx
		mov cx, bx ; width
		.printLine:  
			mov  al, [ds:di]
			mov  [es:di], al
			inc  di
			loop .printLine
		pop cx
		cmp di, 320*172
		jae .exitfunc
		add di, 320
		sub di, bx
		loop .printRect
	.exitfunc:
		pop es
		pop ds
		popA
		pop bp
		ret 8

moveGround:
	push bp
	mov  bp, sp
	pushA
	
	mov ax, 0xA000
	mov es, ax
	
	;Copying leftmost column 
    mov di, 173*320
    mov si, prevCol
    mov cx, 10      ;
    saveCol:
		mov  al,[es:di] ;
        mov  [si], al
        inc  si
        add  di, 320
        loop saveCol
    ;Now I have to move everything to the left
	
	mov di, 173*320
	mov dx, 320
	.loop1:
		mov cx, 10 ;
		mov si, di
		add si, 1
		.loop2:
				mov  byte al, [es:si]
				mov  byte [es:di], al
				add  di, 320
				mov  si, di
				add  si, 1
				loop .loop2
		sub di, 320*10 ;
		add di, 1
		sub dx, 1
	jnz .loop1
	
	;Now I have to paste the saved Column at right end
	mov di, 173*320
	add di, 318
    mov si, prevCol
    mov cx, 10      ;
	pasteCol:
		mov  al,           [si]
        mov  byte [es:di], al
        inc  si
        add  di,           320
        loop pasteCol
	
	retmg:
    popA
	pop bp
	ret
	
checkCollision:
	pusha
	mov word si, 0
	.l1:
		cmp word [pillarsX + si], 38
		jb .checkIsTheBirdInGap

		jmp .continue
		.checkIsTheBirdInGap:
		mov ax, [birdY]
		add ax, 20
		cmp word ax, [pillarsY + si]
		jg .callGameOver
		
		sub ax, 20
		;check upper pipe collision
		cmp word ax, [pillarsYInv + si]
		jl .callGameOver
		.continue:
		add si, 2
		cmp si, [numOfPipes]
		je .return
		jne .l1

	.callGameOver:
	call gameOver
	.return:
	popa
	ret
	

wait_vsync:
	push ax
    mov  al, 0x8A ; 0x8A is the interrupt for vertical retrace in DOS
    int  0x10     ; Call BIOS video interrupt
	pop  ax
    ret
	
delay:
	push cx
	mov cx, 0xffff
	.a: loop .a
	mov cx, 0xffff
	.b: loop .b
	pop cx
	ret

clrscr:
	pushA
	push es
	mov ax, 0xb800
	mov es, ax

	mov cx, 80*25
	mov di, 0
	mov ax, 0x0720
	
	.loop:
		stosw
		loop .loop

	pop es
	popA
	ret

drawMenu:
    push bp
    mov bp, sp
    pushA

	call clrscr

	push line1
	push word 0
	push word 1
	call printLine

	push line2
	push word 0
	push word 2
	call printLine

	push line3
	push word 0
	push word 3
	call printLine

	push line4
	push word 0
	push word 4
	call printLine

	push line5
	push word 0
	push word 5
	call printLine

	push line6
	push word 0
	push word 6
	call printLine

	
	push line7
	push word 2
	push word 8
	call printLine

	push line8
	push word 2
	push word 9
	call printLine

	push line9
	push word 2
	push word 10
	call printLine
	
	push line10
	push word 2
	push word 11
	call printLine
	
	push line11
	push word 20
	push word 16
	call printLine


	.delayWithK:
		mov ah, 0 ; service 0 – get keystroke
		int 0x16 ;
		cmp al, 0x0D ; check if enter key is pressed
		jne .delayWithK ; if not, keep waiting

	.cont:
    popA
    mov sp, bp
    pop bp
    ret

hookAndSaveTheInterrupts:
	pushA
	push es

	xor ax, ax
	mov es, ax

	mov ax, [es:9*4]
	mov [oldKbIsr], ax								; save offset of old routine
	mov ax, [es:9*4+2]
	mov [oldKbIsr + 2], ax

	mov ax, [es:8*4]
	mov [oldTimerIsr], ax							; save offset of old routine
	mov ax, [es:8*4+2]
	mov [oldTimerIsr + 2], ax

	cli
	mov word [es:9*4], kbisr	
	mov [es:9*4+2], cs
	mov word [es:8*4], timerInt
	mov [es:8*4+2], cs
	sti 

	pop es
	popA
	ret

start:
	call drawMenu

	call hookAndSaveTheInterrupts

	call initResPalette
	call drawBG
	call saveBG
	
	gameloop:
			
			;checking if game is paused
			cmp byte [pauseFlag], 1
			jne notPausing
			call pauseTheGame
			notPausing:
			;checking collision
			call checkCollision
			
			; Have to draw the bird here
			push word 9		;x
			sub word [birdY], 1
			push word [birdY]							;y
			add word [birdY], 1
			push word 31								;width
			push 22
			call drawCroppedBG
	
			;updating birdY
			cmp byte [birdDir], 'D'
			jne .movingUp
			add word [birdY], 1
			cmp word [birdY], 172-21
			je gameOver
			jmp .contGameLoop
			.movingUp:
				cmp word [birdY], 5
				je .contGameLoop
				sub word [birdY], 1
			.contGameLoop:

			cmp byte [bird], 0
			je .drawBird2

			;drawing Bird
			push 1
			push 90
			push 10     ;x
			push word [birdY]		;y
			push 30            ;width
			push 21            ;height
			push bird_pixel_data       ;pixel data
			call drawRectTrans	
			jmp .drawPillarsLoop

			.drawBird2:
			push 1
			push 169
			push 10     ;x
			push word [birdY]		;y
			push 30            ;width
			push 21            ;height
			push bird2_pixel_data       ;pixel data
			call drawRectTrans

		.drawPillarsLoop:
		mov cx, 4
		mov si, 0
		.drawPillars:
			
			;drawing cropped bg for down pipe
			add  word [pillarsX + si], 25
			push word [pillarsX + si]     ;x
			sub  word [pillarsX + si], 25
			push  word [pillarsY + si]

			push 4             ;width
			push 80            ;height
			call drawCroppedBG
			
			;drawing sprite of down pipe
			push 0 ;isBird = false
			push 55
			push word [pillarsX + si]     ;x
			push  word [pillarsY + si]
			push 26            ;width
			push 80            ;height
			push barrier       ;pixel data
			call drawRectTrans
			sub  word [pillarsX + si], 1

			; drawing cropped bg for up pipe
			add word [pillarsX + si], 25
			push word [pillarsX + si]		;x
			sub word [pillarsX + si], 25
			push word 0							;y

			push 4								;width
			add word [pillarsYInv + si], 1
			push word [pillarsYInv + si]
			sub word [pillarsYInv + si], 1
			call drawCroppedBG

			;drawing cropped bg for down pipe
			
			;drawing sprite of up pipe
			push word [pillarsX + si]	;x
			push word [pillarsYInv + si]	;y
			push 26							;width
			push 80							;height
			push barrier					;pixel data
			call drawRectTransInv
			sub  word [pillarsX + si], 1
			
			add si, 2 ; draw the next pillar
		loop .drawPillars
		

			;+169
		.warpPillars:
		;code for warping pillars
			cmp word [pillarsX], -26
			jnl .ext
			push cx
			mov cx, 3
			mov di, 0
			push ax
			mov ax, [pillarsYInv]
			mov [pillarYPrev], ax
			pop ax
			.shiftArr:
				mov ax, [pillarsX + di + 2]
				mov [pillarsX + di], ax
				mov ax, [pillarsY + di + 2]
				mov [pillarsY + di], ax
				mov ax, [pillarsYInv + di + 2]
				mov [pillarsYInv + di], ax

				add di, 2
				loop .shiftArr
			pop cx
			mov word [pillarsX + 6], 320
			push ax
			mov ax, [pillarYPrev]
			mov word [pillarsYInv + 6], ax;temp hardcoded value: will be randomized later
			add ax, 60
			mov word [pillarsY + 6], ax	;temp hardcoded value: will be randomized later
			pop ax

	.ext:
	
	call moveGround
	jmp gameloop

exit:
mov ax, 0x4c00
int 0x21