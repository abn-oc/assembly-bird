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


line1: db '  ______                _____  _______            ____  _____ ____  _____   $'
line2: db ' |  ___|  |        /\   |  __ \|  __ \  \   / /  |  _ \  | | ___  | | __ \   $'
line3: db ' | |__  | |       /  \  | |) | | |) | |  \ / /   | |)| | | | |  | | | | |  $'
line4: db ' |  __| | |      / /\ \ |  ___/|  ___/  \   /    |  _ <  | |  _  /  | | | | $'
line5: db ' | |    | |____ / ____ \| |    | |       | |     | |)| | | | | \ \  | | | | $'
line6: db ' | |    |//    \\|    | |      | |       | |     \ \/ /  | | |  \ \ | |/ /  $' 
line7: db 'A Game by: $'
line8: db 'Abdullah Ihtasham       	23L-2515 $'
line9: db 'Muhammad Wali 			23L-00855 $'
line10: db '                         FALL 2024 $'
line11: db '                            Press Enter to Start   $'


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
    cmp al, 0x39        ; Check if the key is the spacebar
    je space_pressed    ; Jump if spacebar is pressed (make code)
    cmp al, 0xB9        ; Check if the key is spacebar release (break code)
    je space_released   ; Jump if spacebar is released
    jmp out1             ; Exit for other keys

space_pressed:
    mov byte [birdDir], 'U' ; Set bird direction to 'U' (up)
    jmp out1

space_released:
    mov byte [birdDir], 'D' ; Set bird direction to 'D' (down)
    jmp out1

out1:
    mov al, 0x20
    out 0x20, al        ; Send EOI to PIC

    pop es
    pop ax
    iret

;functions
initResPalette:
	;set 13h vga mode
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
	
	;print light blue/teal background
	palette_loop:
		lodsb
		out  dx, al
		loop palette_loop
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
	pop  bp
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
		
copyFromBuffer:
	push si
	push di
	push ds
	push es
	push ax
	call wait_vsync
	mov  ax, 0xA000
	mov  es, ax

	mov ax, 0xA000
	mov ds, ax
	    ; Set the source and destination addresses
    mov si, 0 ; Source address (offscreen buffer at 0xA000)
    mov di, 0 ; Destination address (screen buffer at 0xA000)

    ; Set the number of bytes to copy (assuming 320x200 VGA mode with 320 bytes per line)
    ; For example, if we're copying an entire 320x200 screen (64000 bytes)
    mov cx, 64000 ; Total number of bytes to copy (320 * 200)

copyLoop:
    mov  al,      [ds:si] ; Load a byte from the source buffer
    mov  [es:di], al      ; Store the byte in the destination buffer
    inc  si               ; Move to the next byte in the source buffer
    inc  di               ; Move to the next byte in the destination buffer
    loop copyLoop         ; Repeat the loop until cx becomes 0

	pop ax
	pop es
	pop ds
	pop di
	pop si
    ret

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

	.draw:
		mov ax, [ds:si]
		mov [es:di], ax
		add si, 2
		add di, 2
		loop .draw

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

	mov  ax, 0xA000
	mov  es, ax

	mov ax, 0xE000
	mov ds, ax

	mov si, [bp + 4]  ;pixel data
	mov di, [bp + 12] ;x
	add si, di
	;moving di to the required y cord
	mov bx, [bp + 10] ;y
	cmp bx, 0
	je .cont
	.ydi:
		add di, 320
		sub bx, 1
		jnz .ydi
	
	.cont:
	mov bx, [bp + 8] ;w 
	mov dx, [bp + 6] ;h

	.printRect:
		mov cx, bx
		.printLine:  
			mov  al, [ds:di]
			mov  [es:di], al
			inc  di
			loop .printLine
		;exit function if on ground line
		cmp di, 320*172
		jae .exitfunc
		add di, 320
		sub di, bx
		add si, 160
		sub si, bx
		dec dx
		jnz .printRect

		.exitfunc:
		pop es
		pop ds
		popA
		pop bp
		ret 10

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
		mov  al,   [es:di] ;
        mov  [si], al
        inc  si
        add  di,   320
        loop saveCol
    ;Now I have to move everything to the left
	
	mov di, 173*320
	mov dx, 320
	.loop1:
		mov cx, 10 ;
		mov si, di
		add si, 1
		.loop2:
				mov  byte al,      [es:si]
				mov  byte [es:di], al
				add  di,           320
				mov  si,           di
				add  si,           1
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
		jb .lose
		; jne .cont
		jmp .cont
		.lose:
		;call lose
		;check lower pipe collision
		mov ax, [birdY]
		add ax, 20
		cmp word ax, [pillarsY + si]
		jg .callLose
		
		sub ax, 20
		;check upper pipe collision
		cmp word ax, [pillarsYInv + si]
		jl .callLose
		.cont:
		add si, 2
		cmp si, [numOfPipes]
		je .ret
		jne .l1

	.callLose:
	call lose
	.ret:
	popa
	ret
	
lose:
	;pusha
	mov ax, 0x4c00
	int 0x21
	;popa
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

drawMenu:
    push bp
    mov bp, sp
    pushA

	mov ax, 0xb800
	mov es, ax

	mov cx, 80*25
	mov di, 0
	mov ax, 0x0720
	
	.clrScr:
		stosw
		loop .clrScr

    ; Save the original cursor position
    mov ah, 03h           ; Service 3 - Get cursor position
    mov bh, 0             ; Page 0
    int 10h
    push dx               ; Save the original cursor position on the stack

    ; Set the screen text color to yellow
    mov ax, 0x0E00        ; BIOS Teletype output service (for yellow text)
    mov bl, 0x0E          ; Yellow foreground
    mov ah, 0x09          ; Write character attribute
    int 10h

    ; Draw each line at its respective position
    ; Line 1
    mov ah, 02h           ; Service 2 - Set cursor position
    mov bh, 0             ; Page 0
    mov dh, 3             ; Row 3
    mov dl, 1            ; Column 10
    int 10h
    mov dx, line1
    mov ah, 09h           ; Service 9 - Write string to standard output
    int 21h

    ; Line 2
    mov ah, 02h
    mov dh, 4
    mov dl, 1
    int 10h
    mov dx, line2
    mov ah, 09h
    int 21h

    ; Line 3
    mov ah, 02h
    mov dh, 5
    mov dl, 1
    int 10h
    mov dx, line3
    mov ah, 09h
    int 21h

    ; Line 4
    mov ah, 02h
    mov dh, 6
    mov dl, 1
    int 10h
    mov dx, line4
    mov ah, 09h
    int 21h

    ; Line 5
    mov ah, 02h
    mov dh, 7
    mov dl, 1
    int 10h
    mov dx, line5
    mov ah, 09h
    int 21h

    ; Line 6
    mov ah, 02h
    mov dh, 8
    mov dl, 1
    int 10h
    mov dx, line6
    mov ah, 09h
    int 21h

    ; Line 7
    mov ah, 02h
    mov dh, 9
    mov dl, 1
    int 10h
    mov dx, line7
    mov ah, 09h
    int 21h

    ; Line 8
    mov ah, 02h
    mov dh, 10
    mov dl, 1
    int 10h
    mov dx, line8
    mov ah, 09h
    int 21h

    ; Line 9
    mov ah, 02h
    mov dh, 11
    mov dl, 1
    int 10h
    mov dx, line9
    mov ah, 09h
    int 21h

    ; Line 10
    mov ah, 02h
    mov dh, 12
    mov dl, 1
    int 10h
    mov dx, line10
    mov ah, 09h
    int 21h

    ; Line 11
    mov ah, 02h
    mov dh, 17
    mov dl, 1
    int 10h
    mov dx, line11
    mov ah, 09h
    int 21h

    ; Restore the original cursor position
    pop dx
    mov ah, 02h           ; Service 2 - Set cursor position
    mov bh, 0             ; Page 0
    int 10h

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


start:
	call drawMenu;
	;hooking keyboard interrupt for jumps
	xor ax, ax
	mov es, ax
	cli
	mov word [es:9*4], kbisr	
	mov [es:9*4+2], cs
	mov word [es:8*4], timerInt; store offset at n*4
	mov [es:8*4+2], cs ; store segment at n*4+2
	sti ; enable interrupts

	call initResPalette
	call drawBG
	call saveBG
	
	.gameloop:
			
			;checking collision
			call checkCollision
			
			; Have to draw the bird here
			push word 9		;x
			sub word [birdY], 1
			push word [birdY]							;y
			add word [birdY], 1
			push word 31								;width
			push 22
			push bg		;pixel data
			call drawCroppedBG
	
			;updating birdY
			cmp byte [birdDir], 'D'
			jne .movingUp
			add word [birdY], 1
			cmp word [birdY], 172-21
			je lose
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
	 		push bg            ;pixel data
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
			push bg		;pixel data
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
	jmp .gameloop

exit:
mov ax, 0x4c00
int 0x21