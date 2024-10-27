[org 0x100]
jmp start

;variables
pipeX: dw 280
pipeY: dw 100
pipe2X: dw 5
pipe2Y: dw 70
prevCol: times 26 db 0

;included files
%include'bgpalette.asm'
%include'barrier.asm'

;functions
initResPalette:
	;set 13h vga mode
	mov ax, 13h
	int 10h
	mov ax, 0xA000
	mov es, ax
	
	;set color pallete
	mov dx, 03c8h; DAC write index register
	mov al, 0 ; Start at color index 0
	out dx, al
	mov dx, 03c9h; DAC data register
	mov cx, 768 ; 256 colors 3 (RGB)
	mov si, palette_data
	
	;print light blue/teal background
	palette_loop:
		lodsb
		out dx, al
		loop palette_loop
	ret
	
drawBG:
	push bp
	mov bp ,sp
	
	;first half of bg
	push 0				;x
	push 0				;y
	push 160			;width
	push 200			;height
	push bg		;pixel data
	call drawRect

	;second half of bg
	push 159			;x
	push 0				;y
	push 160			;width
	push 200			;height
	push bg		;pixel data
	call drawRect
	pop bp
	ret
	
drawRect:   
	push bp
	mov bp, sp
	pushA
	mov ax, 0xA000
	mov es, ax

	mov si, [bp + 4]	;pixel data
	mov di, [bp + 12]	;x
	;moving di to the required y cord
	mov bx, [bp + 10]	;y
	.ydi:
		add di, 320
		sub bx, 1
		jnz .ydi
	mov bx, [bp + 8]	;w 
	mov dx, [bp + 6]	;h

	.printRect:
		mov cx, bx
		.printLine:  
			mov al, [ds:si]
			mov byte [es:di], al
			inc di
			inc si
			loop .printLine
		add di, 320
		sub di, bx
		dec dx
		jnz .printRect

		popA
		pop bp
		ret 10
		
drawRectTrans:   
	push bp
	mov bp, sp
	pushA
	mov ax, 0xA000
	mov es, ax
	
	mov si, [bp + 4]	;pixel data
	mov di, [bp + 12]	;x
	;moving di to the required y cord
	mov bx, [bp + 10]	;y
	.ydi:
		add di, 320
		sub bx, 1
		jnz .ydi
	mov bx, [bp + 8]	;w 
	mov dx, [bp + 6]	;h

	.printRect:
		mov cx, bx
		.printLine:  	;explain this part wali....
			mov al, [ds:si]
            cmp al, 0x0F
			je .cont
			cmp al, 0x10
			je .cont
			add al, 55
			
			mov byte [es:di], al
			.cont:
			inc di
			inc si
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
		pop bp
		ret 
		
drawRectTransInv:   
	push bp
	mov bp, sp
	pushA
	mov ax, 0xA000
	mov es, ax
	
	mov si, [bp + 4]	;pixel data
	mov di, [bp + 12]	;x
	;moving di to the required y cord
	mov bx, [bp + 10]	;y
	.ydi:
		add di, 320
		sub bx, 1
		jnz .ydi
	mov bx, [bp + 8]	;w 
	mov dx, [bp + 6]	;h

	.printRect:
		mov cx, bx
		.printLine:  	;explain this part wali....
			mov al, [ds:si]
            cmp al, 0x0F
			je .cont
			cmp al, 0x10
			je .cont
			add al, 55
			
			mov byte [es:di], al
			.cont:
			inc di
			inc si
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
	mov bp, sp
	pushA
	mov ax, 0xA000
	mov es, ax

	mov si, [bp + 4]	;pixel data
	mov di, [bp + 12]	;x
	add si, di
	;moving di to the required y cord
	mov bx, [bp + 10]	;y
	.ydi:
		add di, 320
		add si, 160
		sub bx, 1
		jnz .ydi
	mov bx, [bp + 8]	;w 
	mov dx, [bp + 6]	;h

	.printRect:
		mov cx, bx
		.printLine:  
			mov al, [ds:si]
			mov byte [es:di], al
			inc di
			inc si
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
	mov bp, sp
	pushA
	
	mov ax, 0xA000
	mov es, ax

	;Copying leftmost column 
    mov di, 173*320
    mov si, prevCol
    mov cx, 10;
    saveCol:
		mov al, [es:di];
        mov [si], al
        inc si
        add di, 320
        loop saveCol
    ;Now I have to move everything to the left
	
	mov di, 173*320
	mov dx, 320
	.loop1:
		mov cx, 10;
		mov si, di
		add si, 1
		.loop2:
				mov byte al, [es:si]
				mov byte [es:di], al
				add di, 320
				mov si, di
				add si, 1
				loop .loop2
		sub di, 320*10;
		add di, 1
		sub dx, 1
	jnz .loop1
	
	;Now I have to paste the saved Column at right end
	mov di, 173*320
	add di, 318
    mov si, prevCol
    mov cx, 10;
	pasteCol:
		mov al, [si]
        mov byte [es:di], al
        inc si
        add di, 320
        loop pasteCol
	
    popA
	pop bp
	ret

start:

	call initResPalette
	call drawBG
	
	.gameloop:
		
		call moveGround
		
		add word [pipeX], 25
		push word [pipeX]		;x
		sub word [pipeX], 25
		push word [pipeY]		;y
		push 2			;width
		push 80		;height
		push bg		;pixel data
		call drawCroppedBG
		
		push word [pipeX]	;x
		push word [pipeY]	;y
		push 26				;width
		push 80			;height
		push barrier		;pixel data
		call drawRectTrans
		
		add word [pipe2X], 25
		push word [pipe2X]		;x
		sub word [pipe2X], 25
		push word 0		;y
		push 2			;width
		add word [pipe2Y], 1
		push word [pipe2Y]		;height
		sub word [pipe2Y], 1
		push bg		;pixel data
		call drawCroppedBG
		
		push word [pipe2X]	;x
		push word [pipe2Y]	;y
		push 26				;width
		push 80			;height
		push barrier		;pixel data
		call drawRectTransInv
		
		sub word [pipeX], 1
		sub word [pipe2X], 1
		cmp word [pipe2X], -28
		jne .st
		mov word [pipe2X], 320-28
		.st:
	jmp .gameloop

exit:
mov ax, 0x4c00
int 0x21
