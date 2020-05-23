    .intel_syntax noprefix
    .global main

    .text

test:
    enter 1, 1
    leave
    ret

// grant-permission(int no_test - whether or not this call is for checking service to work).
grant_permission:
    cmp rdi, 0
    jne .Lno_test

    mov rdi, offset service_works_str
    call puts
    ret

.Lno_test:

    mov rdi, offset granted_str
    call puts

    mov rdi, 0
    call _exit


deny_permission:
    mov rdi, offset denied_str
    call puts

    mov rdi, 0
    call _exit


// prompt_for_password(int attempt)
prompt_for_password:
    enter 0xA8, 1 // 0x8E for main_str and entered password, another 0x20 for filename, other 8 for future alignment on 16 byte boundary
    push rdi
    .equ BUF,           -0x8E
    .equ DBG_STR_LEN,   0x7E
    .equ BUF_LEN,       0x8E
    .equ PASSWORD,      -0x10
    .equ FILENAME,      -0xA0
    .equ FILENAME_LEN,  0x20

    // Zeroing the space for PASSWORD
    mov qword ptr [rbp+PASSWORD  ], 0
    mov qword ptr [rbp+PASSWORD+8], 0

    // Display attempt.
    mov rax, rdi
    mov rdi, offset attempt_fmt
    mov rsi, rax
    mov al,  2
    call printf



    // Please enter the file password:
    mov rdi, offset enter_pass
    call puts

    // Read filename
    lea rsi, [rbp+FILENAME]
    mov rdi, offset scanf_filename_fmt
    mov al, 2
    call scanf



    // memcpy format debug string
    mov rdx, DBG_STR_LEN
    mov rsi, offset main_str
    lea rdi, [rbp+BUF]
    call memcpy

    // fopen file given
    mov rsi, offset fopen_fmt
    lea rdi, [rbp+FILENAME]
    call fopen
    push rax

    // fread the password with too large available buffer
    mov rcx, rax
    mov rdx, 4096
    mov rsi, 1
    lea rdi, [rbp+PASSWORD]
    call fread

    // fclose
    pop rax
    mov rdi, rax
    call fclose



    // Check the grantitude service.
    mov rdi, 0
    mov rax, offset grant_permission // accidentally push this to the stack
    push rax
    push rax // for alignment
    call rax


    // You've entered:
    mov rdi, offset you_entered
    call puts

    // Display debug string.
    mov rsi, 123
    mov rdx, 345
    mov rcx, 829
    mov r8,  213
    mov r9,  992
    lea rdi, [rbp+BUF]
    mov al,  6
    call printf

    pop rax
    pop rax

.Lend:
    pop rdi
    leave
    ret


main:
    mov rdi, 4

.Loop:
    call prompt_for_password
    dec rdi
    cmp rdi, 0
    jne .Loop

    call deny_permission

    ret

    .data

granted_str:              .asciz "Permission granted\n"
denied_str:               .asciz "Permission denied\n"
service_works_str:        .asciz "permission grantitude service works\n"
main_str:                 .asciz "DEBUG INFO: (report if you see this message)\ntime=%8d\npassword_size=%zu\nuser_id=%d\ntitit_id=%d\nsv_cheats=%d\n\nPASSWORD_ENTERED=" // len = 126
attempt_fmt:              .asciz "\n\nAttempts left: %d\n"
enter_pass:               .asciz "Please enter the name of the file containing the password (password's length is 16 characters): "
fopen_fmt:                .asciz "rb"
scanf_filename_fmt:       .asciz "%s"
you_entered:              .asciz "You've entered:\n"
