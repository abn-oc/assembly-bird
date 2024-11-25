[org 0x100]
jmp start

;variables
pillarsX: dw 170, 250, 330, 410
pillarsy: dw 80, 30, 50, 100

pipeX:    dw 170
pipeY:    dw 100
pipe2X:   dw 170
pipe2Y:   dw 70
prevCol: times 26 db 0

;included files
%include'bgpalette.asm'
%include'barrier.asm'

;functions
initResPalette:
	;set 13h vga mode
	mov ax, 13h
	int 10h
	mov ax, 0xE000
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
	mov  ax, 0xE000
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

	mov ax, 0xE000
	mov ds, ax
	    ; Set the source and destination addresses
    mov si, 0 ; Source address (offscreen buffer at 0xE000)
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


drawRectTrans:   
	push bp
	mov  bp, sp
	sub  sp, 4
	pushA
	mov  ax, 0xE000
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
		mov  cx,       bx
		push bx
		mov  bx,       [bp - 4]
		mov  [bp - 2], bx
		pop  bx
		.printLine:
			cmp word [bp - 2], 0
			jl  .cont
			mov al,            [ds:si]
            cmp al,            0x0F
			je  .cont
			cmp al,            0x10
			je  .cont
			add al,            55
			
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
		ret 
		
drawRectTransInv:   
	push bp
	mov  bp, sp
	pushA
	mov  ax, 0xE000
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
		mov         cx, bx
		.printLine:        ;explain this part wali....
			mov al, [ds:si]
            cmp al, 0x0F
			je  .cont
			cmp al, 0x10
			je  .cont
			add al, 55
			
			mov  byte [es:di], al
			.cont:
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
		pop bp
		ret 10

drawCroppedBG:   
	push bp
	mov  bp, sp
	pushA
	mov  ax, 0xE000
	mov  es, ax

	mov si, [bp + 4]  ;pixel data
	mov di, [bp + 12] ;x
	add si, di
	;moving di to the required y cord
	mov bx, [bp + 10] ;y
	.ydi:
		add di, 320
		add si, 160
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
		popA
		pop bp
		ret 10

moveGround:
	push bp
	mov  bp, sp
	pushA
	
	mov ax, 0xE000
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
	
    popA
	pop bp
	ret


wait_vsync:
	push ax
    mov  al, 0x8A ; 0x8A is the interrupt for vertical retrace in DOS
    int  0x10     ; Call BIOS video interrupt
	pop  ax
    ret

start:

	call initResPalette
	call drawBG
	
	.gameloop:
		
		call moveGround

		mov cx, 4
		mov si, pillarsX
		.drawPillars:

			add  word [si], 25
			push word [si]     ;x
			sub  word [si], 25
			push word [pipeY]  ;y
			push 4             ;width
			push 80            ;height
	 		push bg            ;pixel data
			call drawCroppedBG
		
			push word [si]     ;x
			push word [pipeY]  ;y
			push 26            ;width
			push 80            ;height
			push barrier       ;pixel data
			call drawRectTrans
			add  si,        2
			sub  word [si], 2

		loop .drawPillars
		
		; add  word [pipe2X], 25
		; push word [pipe2X]     ;x
		; sub  word [pipe2X], 25
		; push word 0            ;y
		; push 4                 ;width
		; add  word [pipe2Y], 1
		; push word [pipe2Y]     ;height
		; sub  word [pipe2Y], 1
		; push bg                ;pixel data
		; call drawCroppedBG
		
		; push word [pipe2X]    ;x
		; push word [pipe2Y]    ;y
		; push 26               ;width
		; push 80               ;height
		; push barrier          ;pixel data
		; call drawRectTransInv
		
		sub word [pipe2X], 2
		cmp word [pipe2X], -28
		jne .st
		mov word [pipe2X], 320-28
		.st:
	call copyFromBuffer

	jmp .gameloop

exit:
mov ax, 0x4c00
int 0x21
