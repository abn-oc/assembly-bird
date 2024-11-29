[org 0x100]
jmp start

;variables
pillarsX: dw 170, 250, 330
pillarsY: dw 95, 120, 150	;keep y coordinate 95(highest) or above and dont make it above 150(lowest)

pillarsYInv: dw 30, 60, 75  ;keep y coordinate 30(highest) or above and dont make it above 75(lowest)

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
	.ydi:
		add di, 320
		sub bx, 1
		jnz .ydi
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
	.ydi:
		add di, 320
		sub bx, 1
		jnz .ydi

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
	
    popA
	pop bp
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

start:

	call initResPalette
	call drawBG
	call saveBG
	
	.gameloop:

		; Have to draw the bird here
			push 1
			push 90
			push 10     ;x
			push 10
			push 30            ;width
			push 21            ;height
			push bird_pixel_data       ;pixel data
			call drawRectTrans

		mov cx, 3
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
			push word 1							;y

			push 4								;width
			; add word [pillarsYInv + si], 1
			; push word [pillarsYInv + si]		;height
			; sub word [pillarsYInv + si], 1
			push 80
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
		
		;code for warping pillars
			cmp word [pillarsX], -26
			jnl .ext
			push cx
			mov cx, 2
			mov di, 0
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
			mov word [pillarsX + 4], 320
			mov word [pillarsY + 4], 100	;temp hardcoded value: will be randomized later
			mov word [pillarsYInv + 4], 70	;temp hardcoded value: will be randomized later

	.ext:
	
	;call copyFromBuffer
	call moveGround
	jmp .gameloop

exit:
mov ax, 0x4c00
int 0x21