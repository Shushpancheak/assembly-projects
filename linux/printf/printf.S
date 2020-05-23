    .intel_syntax noprefix
	.global main

    .section .text

//--------------------------------
//
// Preserves ebx, prints int.
//
//--------------------------------
.macro print_int_guarded what
    push ebx
    mov ebx, \what
    call print_int
    pop ebx
.endm

//-------------------------------
//
// Preserves ecx, prints string
//
//-------------------------------
.macro print_prefix what
    push ecx
    mov ecx, \what
    call print_string
    pop ecx
.endm


main:
    mov eax, offset string_to_display
    push eax
    mov eax, 1234
    push eax
    mov eax, 1234
    push eax
    mov eax, 1234
    push eax
    mov eax, 1234
    push eax
    mov eax, '$'
    push eax
    mov eax, '$'
    push eax
    mov eax, offset test_str
    push eax
    call my_printf

    mov	eax, 1
    int	0x80

//;-------------------------------------------------------------------------
//; printf(char* tmp_string, args...)
//; Uses 32-bit calling convention.
//;
//; Supports %d, %c, %s, %x, %b formats.
//;------------------------------------------------------------------------
my_printf:
    push ebp
    mov ebp, esp

    .equ TEMP_STR,                  0x08 // First argument (for the function)
    .equ FIRST_TEMP_ARG, TEMP_STR + 0x04

    push ebx

    mov ebx, [ebp+TEMP_STR]
    lea edx, dword ptr [ebp+FIRST_TEMP_ARG]

    process_loop:
        // End of string
        cmp byte ptr [ebx], 0
        je end
        // Some argument
        cmp byte ptr [ebx], '%'
        je switch_case
        // Default
        UNDEFINED:
            mov ecx, ebx
            call print_char
            jmp finish_loop

    switch_case:
        add ebx, 1
        xor eax, eax
        mov al, byte [ebx]
        sub eax, 'b'
        jmp [jump_table + eax * 4]


    process_char:
        mov ecx, edx // Get current argument address
        add edx, 4   // Shift current argument ptr

        call print_char
        jmp finish_loop


    process_binary:
        mov ecx, edx
        add edx, 4

        // Printing default prefix (like 0b... , 0x ...)
        print_prefix bin_prefix

        // Chosing system base (2, 8, 10, 16 ... ?)
        print_int_guarded 2

        jmp finish_loop


    process_octal:
        mov ecx, edx
        add edx, 4

        print_prefix oct_prefix

        print_int_guarded 8

        jmp finish_loop


    process_decimal:
        mov ecx, edx
        add edx, 4

        print_int_guarded 10

        jmp finish_loop

    process_hex:
        mov ecx, edx
        add edx, 4

        print_prefix hex_prefix

        print_int_guarded 16

        jmp finish_loop


    process_string:
        mov ecx, [edx]
        add edx, 4
        call print_string

        jmp finish_loop


    // ecx - pointer to char
    printChar:
        push ebx
        push edx

        mov	eax, 4	    // system call number (sys_write)
        mov	ebx, 1	    // file descriptor (stdout)
        mov	edx, 1      // message length
        int	0x80

        pop edx
        pop ebx
        ret

    // ecx - pointer to int
    // ebx - base
    print_int:
        push edx
        mov eax, [ecx]
        mov ecx, 0
        .Loop:
            mov edx, 0
            div ebx
            push edx
            or edx, eax
            jz .Lend_loop
            pop edx
            inc ecx
            add edx, digit
            push edx
            jmp .Loop
        .Lend_loop:
            pop edx
        .Loop_r:
            push ecx
            mov ecx, esp
            add ecx, 4
            mov ecx, [ecx]
            mov edx, [ecx]
            call print_char
            pop ecx
            pop edx
            loop .Loop_r
        pop edx
        ret

    // ecx - pointer to the the beginning of the string
    print_string:
        push ebx
        push edx
        .Lloop:
            cmp byte ptr [ecx], 0
            je .Llend_loop
            call print_char
            inc ecx
            jmp .Lloop

        .Llend_loop:
            pop edx
            pop ebx
            ret


    finish_loop:
        add ebx, 1
        jmp process_loop

    end:

        pop ebx
        mov esp, ebp
        pop ebp
        ret

        .data
hex_prefix:          .asciz  "0x"
bin_prefix:          .asciz  "0b"
oct_prefix:          .asciz  "0o"

digit:               .asciz  "0123456789abcdef"
test_str:            .asciz  "Test: These numbers are equal: dec: %d, hex: %x, octal: %o, binary: %b, char: %c, now a string: %s"
string_to_display:   .asciz  "Some string"

jump_table:
.Lprocess_binary:      .int offset process_binary  // b
.Lprocess_char:        .int offset process_char    // c
.Lprocess_decimal:     .int offset process_decimal // d
                       .int offset UNDEFINED       // e
                       .int offset UNDEFINED       // f
                       .int offset UNDEFINED       // g
                       .int offset UNDEFINED       // h
                       .int offset UNDEFINED       // i
                       .int offset UNDEFINED       // j
                       .int offset UNDEFINED       // k
                       .int offset UNDEFINED       // l
                       .int offset UNDEFINED       // m
                       .int offset UNDEFINED       // n
.Lprocess_octal:       .int offset process_octal   // o
                       .int offset UNDEFINED       // p
                       .int offset UNDEFINED       // q
                       .int offset UNDEFINED       // r
.Lprocess_string:      .int offset process_string  // s
                       .int offset UNDEFINED       // t
                       .int offset UNDEFINED       // u
                       .int offset UNDEFINED       // v
                       .int offset UNDEFINED       // w
.Lprocess_hex:         .int offset process_hex     // x
