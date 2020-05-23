%macro PrintInt 1

        push ebx
        mov ebx, %1
        call printInt
        pop ebx

%endmacro

%macro PrintPrefix 1

        push ecx
        mov ecx, %1
        call printStr
        pop ecx

%endmacro

section	.text
	global _start       ;must be declared for using gcc
_start:     ;tell linker entry point
    mov eax, msg1
    push eax
    mov eax, 5671230
    push eax
    mov eax, 5671230
    push eax
    mov eax, 5671230
    push eax
    mov eax, 5671230
    push eax
    mov eax, '$'
    push eax
    mov eax, '$'
    push eax
    mov eax, msg
    push eax
    call my_printf 
    
    mov	eax, 1	    ;system call number (sys_exit)
	int	0x80        ;call kernel


; printf(char* tmp_string, args...)
; In 32-bit all arguments are passed using stack

; In 64-bit we would need to save return adress, than put args
; from registers on stack, and then reestablish return adress 

; my_printf supports %d, %c, %s, %x, %b
my_printf:
        push    ebp
        mov     ebp,esp
        
        push ebx
        
        mov ebx, [ebp + 8] ; Pointer to the template string
        mov edx,  ebp
        add edx, 12        ; Pointer to the first argument

        ; In process loop we want to iterate over template string
        ; and parse it char-by-char.
        ; The idea is simple:
        ; |
        ; +> If we see '%', we will use the next symbol as argument type.
        ; |
        ; +> If we see '\0', we will stop our proccess loop, because template string is over
        ; |
        ; +> If we see any other character we simply gonna print it
        ; Considering all of the above, let's understand what functions we need:
        ; - printChr
        ; - printStr
        ; - printHex
        ; - printOct
        ; - printBin
        ; - printDec
        process_loop:
            ; End of string
            cmp byte [ebx], 0
            je end
            
            ; Some argument
            cmp byte [ebx], '%'
            je switchcase
            
            ; Default
            default_:
                mov ecx, ebx
                call printChr
                jmp finish_loop

        switchcase:
            add ebx, 1
            xor eax, eax
            mov al, byte [ebx]
            sub eax, 'b'
            jmp [jmp_tbl + eax * 4]

            
        handleChr:
            mov ecx, edx ; Get current argument adress
            add edx, 4   ; Shift current argument ptr
            
            call printChr
            jmp finish_loop
            
            
        handleBin:
            mov ecx, edx
            add edx, 4
            
            ; Printing default prefix (like 0b... , 0x ...)
            PrintPrefix bin_prefix
            
            ; Chosing system base (2, 8, 10, 16 ... ?)
            PrintInt 2
            
            jmp finish_loop
        
            
        handleOct:
            mov ecx, edx
            add edx, 4
            
            PrintPrefix oct_prefix
            
            PrintInt 8
            
            jmp finish_loop
            
            
        handleDec:
            mov ecx, edx
            add edx, 4
            
            PrintInt 10
            
            jmp finish_loop
            
        handleHex:
            mov ecx, edx
            add edx, 4
            
            PrintPrefix hex_prefix
            
            PrintInt 16
            
            jmp finish_loop

            
        handleStr:
            mov ecx, [edx]
            add edx, 4
            call printStr
            
            jmp finish_loop
            

            
        ; ecx - pointer to char
        printChr:
            push ebx
            push edx
            
            mov	eax, 4	    ;system call number (sys_write)
            mov	ebx, 1	    ;file descriptor (stdout)
            mov	edx, 1      ;message length
	        int	0x80
	        
	        pop edx
            pop ebx
            ret
            
        ; ecx - pointer to int
        ; ebx - base
        printInt:
            push edx
            mov eax, [ecx]
            mov ecx, 0
            .loop:
                mov edx, 0
                div ebx
                push edx
                or edx, eax
                jz .end_loop
                pop edx
                inc ecx
                add edx, digit
                push edx
                jmp .loop
            .end_loop:
                pop edx
            .loop_r:
                push ecx
                mov ecx, esp
                add ecx, 4
                mov ecx, [ecx]
                mov edx, [ecx]
                call printChr
                pop ecx
                pop edx
                loop .loop_r
            pop edx
            ret
            
            
        ; ecx - pointer to the the beginning of the string
        printStr:
            push ebx
            push edx
            .loop:
                cmp byte [ecx], 0
                je .end_loop
                call printChr
                inc ecx
                jmp .loop
                
            .end_loop:
                pop edx
                pop ebx
                ret


        finish_loop:
            add ebx, 1
            jmp process_loop

        end:
            pop ebx
            ; Epilogue
            mov esp, ebp
            pop ebp
            ret

section	.data

hex_prefix db '0x', 0
oct_prefix db '0o', 0
bin_prefix db '0b', 0

digit   db  '0123456789ABCDEF',  
msg	    db	'Hello, World! This is printf written on a%c%cembler. Different representations of %d: binary is %b, oct is %o, hex is %x :( Now this is random string %s. Thats it! ', 0
msg1	db	'4 // chosen by an absolutely random dice ...', 0
jmp_tbl:
    dd handleBin, ; b - binary
    dd handleChr, ; c - char
    dd handleDec, ; d - decimal
    dd default_,  ; e 
    dd default_,  ; f
    dd default_,  ; g
    dd default_,  ; h
    dd default_,  ; i
    dd default_,  ; j
    dd default_,  ; k
    dd default_,  ; l
    dd default_,  ; m
    dd default_,  ; n
    dd handleOct, ; o - octimal
    dd default_,  ; p
    dd default_,  ; q
    dd default_,  ; r
    dd handleStr, ; s - string
    dd default_,  ; t
    dd default_,  ; u
    dd default_,  ; v
    dd default_,  ; w
    dd handleHex  ; x
