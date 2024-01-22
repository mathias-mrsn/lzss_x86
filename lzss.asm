%include "inc.asm"

DEFAULT rel
GLOBAL LzssEncoder
GLOBAL LzssDecoder

SECTION .text

struc _LZSSE_OFF
    .buffer     resb WINDOW_LENGTH*2
    .inputaddr  resq 0x1
    .outputaddr resq 0x1
    .length     resq 0x1
    .buffersize resw 0x1
    .la_index   resw 0x1
    .w_index    resw 0x1
    .cmp_len    resb 0x1
    .match_pos  resw 0x1
    .match_len  resb 0x1
    .character  resb 0x1
    .bits       resb 0x1
    .mask       resb 0x1
endstruc
;-----------------------------------------------------
LzssEncoder:
; @brief Compress data using LZSS algorithm. 
; @param %rdi - Input pointer
; @param %rsi - Input length
; @param %rdx - Output pointer
; @stack - _LZSSE_OFF
;-----------------------------------------------------
.allocate:
    sub         rsp, _LZSSE_OFF_size
.init:
    mov         qword [rsp+_LZSSE_OFF.inputaddr], r1
    mov         qword [rsp+_LZSSE_OFF.outputaddr], r3
    mov         byte [rsp+_LZSSE_OFF.mask], 10000000b
    mov         qword [rsp+_LZSSE_OFF.length], r2
.fill_space:
    XORX        rax, rdi, rcx
    mov         cx, WINDOW_LENGTH-LOOKAHEAD_LENGTH 
    lea         rdi, qword [rsp+_LZSSE_OFF.buffer] 
    mov         al, 0x20
    rep         stosb
.fill_text:
    mov         cx, (WINDOW_LENGTH+LOOKAHEAD_LENGTH)
    cmp         ecx, dword [rsp+_LZSSE_OFF.length]
    cmovg       cx, word [rsp+_LZSSE_OFF.length]
    sub         qword [rsp+_LZSSE_OFF.length], rcx
    lea         rdi, qword [rsp+_LZSSE_OFF.buffer+WINDOW_LENGTH-LOOKAHEAD_LENGTH]
    mov         rsi, qword [rsp+_LZSSE_OFF.inputaddr]
    rep         movsb
    mov         qword [rsp+_LZSSE_OFF.inputaddr], rsi
.init_loop:
    mov         word [rsp+_LZSSE_OFF.buffersize], WINDOW_LENGTH*2
    mov         word [rsp+_LZSSE_OFF.la_index], WINDOW_LENGTH-LOOKAHEAD_LENGTH
    mov         word [rsp+_LZSSE_OFF.w_index], 0x0000
.bufferlp:
    XORX        rax, rdi, rdx
    mov         ax, word [rsp+_LZSSE_OFF.buffersize]
    sub         ax, word [rsp+_LZSSE_OFF.la_index]
    mov         dl, LOOKAHEAD_LENGTH
    cmp         ax, LOOKAHEAD_LENGTH
    cmovl       dx, ax
    mov         byte [rsp+_LZSSE_OFF.cmp_len], dl
    mov         byte [rsp+_LZSSE_OFF.match_len], 0x0
    mov         byte [rsp+_LZSSE_OFF.match_pos], 0x1
    lea         rdi, [rsp+_LZSSE_OFF.buffer]
    XORX        rax
    mov         ax, word [rsp+_LZSSE_OFF.la_index]
    add         rdi, rax
    XORX        rax, rbx
    mov         al, byte [rdi]
    mov         byte [rsp+_LZSSE_OFF.character], al
    mov         bx, word [rsp+_LZSSE_OFF.la_index]
    jmp         .bufferlp.windowlp.condition
.bufferlp.windowlp:
    XORX        rax, rdx
    mov         al, byte [rsp+_LZSSE_OFF.buffer+rbx]
    cmp         byte [rsp+_LZSSE_OFF.character], al
    jne         .bufferlp.windowlp.condition
.bufferlp.windowlp.lookaheadlp:
    XORX        rdx
    lea         rdi, [rsp+_LZSSE_OFF.buffer]
    mov         rsi, rdi
    add         rdi, rbx
    mov         dx, word [rsp+_LZSSE_OFF.la_index]
    add         rsi, rdx
    mov         cl, byte [rsp+_LZSSE_OFF.cmp_len]
    inc         cl
    rep         cmpsb
    jne         $+2
    XORX        rdx
    mov         dl, byte [rsp+_LZSSE_OFF.cmp_len]
    sub         dl, cl
    cmp         dl, byte [rsp+_LZSSE_OFF.match_len]
    jle         .bufferlp.windowlp.condition
    mov         word [rsp+_LZSSE_OFF.match_pos], bx
    mov         byte [rsp+_LZSSE_OFF.match_len], dl
.bufferlp.windowlp.condition:
    dec         bx
    cmp         bx, word [rsp+_LZSSE_OFF.w_index]
    jge         .bufferlp.windowlp
.bufferlp.put:
.bufferlp.put.nomatch:
    cmp         byte [rsp+_LZSSE_OFF.match_len], MIN_LENGTH
    jge         .bufferlp.put.match
    mov         byte [rsp+_LZSSE_OFF.match_len], 0x1
    XORX        rax, rcx, rbx, rdx
    mov         bl, byte [rsp+_LZSSE_OFF.character]
    mov         dx, 100000000b
    or          bx, dx
    jmp         .bufferlp.put.lp
.bufferlp.put.match:
    XORX        rax, rcx, rbx, rdx
    mov         al, byte [rsp+_LZSSE_OFF.match_len]
    and         word [rsp+_LZSSE_OFF.match_pos], WINDOW_LENGTH-1
    sub         al, 0x02
    mov         dl, 1
    shl         edx, POSITION_BITS+LENGTH_BITS
    mov         bx, word [rsp+_LZSSE_OFF.match_pos]
    shl         ebx, LENGTH_BITS
    or          bx, ax
.bufferlp.put.lp:
    mov         eax, ebx
    and         eax, edx
    test        eax, eax
    jnz         .bufferlp.put.one
.bufferlp.put.zero:
    shr         byte [rsp+_LZSSE_OFF.mask], 1
    mov         al, byte [rsp+_LZSSE_OFF.mask]
    test        al, al
    jnz         .bufferlp.put.lp.condition
    jmp         .bufferlp.put.write
.bufferlp.put.one:
    XORX        rax
    mov         al, byte [rsp+_LZSSE_OFF.mask]
    or          byte [rsp+_LZSSE_OFF.bits], al
    shr         byte [rsp+_LZSSE_OFF.mask], 1
    mov         al, byte [rsp+_LZSSE_OFF.mask]
    test        al, al
    jnz         .bufferlp.put.lp.condition
.bufferlp.put.write:
    mov         al, byte [rsp+_LZSSE_OFF.bits]
    mov         rdi, qword [rsp+_LZSSE_OFF.outputaddr]
    mov         byte [rdi], al
    mov         byte [rsp+_LZSSE_OFF.bits], 0x00
    mov         byte [rsp+_LZSSE_OFF.mask], 10000000b
    inc         qword [rsp+_LZSSE_OFF.outputaddr] 
.bufferlp.put.lp.condition:
    shr         edx, 1
    test        edx, edx
    jnz         .bufferlp.put.lp 
    jmp         .bufferlp.inc_indexes
.bufferlp.inc_indexes:
    XORX        rax
    mov         al, byte [rsp+_LZSSE_OFF.match_len]
    add         word [rsp+_LZSSE_OFF.la_index], ax
    add         word [rsp+_LZSSE_OFF.w_index], ax
    cmp         word [rsp+_LZSSE_OFF.la_index], WINDOW_LENGTH*2-LOOKAHEAD_LENGTH
    jl          .bufferlp.condition
.bufferlp.load_buf:
    XORX        rcx
    mov         cx, WINDOW_LENGTH
    lea         rdi, [rsp+_LZSSE_OFF.buffer]
    mov         rsi, rdi
    add         rsi, WINDOW_LENGTH
    rep         movsb
    sub         word [rsp+_LZSSE_OFF.buffersize], WINDOW_LENGTH
    sub         word [rsp+_LZSSE_OFF.la_index], WINDOW_LENGTH
    sub         word [rsp+_LZSSE_OFF.w_index], WINDOW_LENGTH
    mov         cx, WINDOW_LENGTH*2
    sub         cx, word [rsp+_LZSSE_OFF.buffersize]
    cmp         ecx, dword [rsp+_LZSSE_OFF.length]
    cmovg       cx, word [rsp+_LZSSE_OFF.length]
    sub         qword [rsp+_LZSSE_OFF.length], rcx
    lea         rdi, [rsp+_LZSSE_OFF.buffer]
    add         di, word [rsp+_LZSSE_OFF.buffersize]
    mov         rsi, [rsp+_LZSSE_OFF.inputaddr]
    add         word [rsp+_LZSSE_OFF.buffersize], cx
    rep         movsb
    mov         [rsp+_LZSSE_OFF.inputaddr], rsi
.bufferlp.condition:
    mov         ax, word [rsp+_LZSSE_OFF.buffersize]
    cmp         word [rsp+_LZSSE_OFF.la_index], ax
    jl          .bufferlp
.flush_bits:
    cmp         byte [rsp+_LZSSE_OFF.mask], 10000000b
    je          .done
    mov         al, byte [rsp+_LZSSE_OFF.bits]
    mov         rdi, qword [rsp+_LZSSE_OFF.outputaddr]
    mov         byte [rdi], al
    inc         qword [rsp+_LZSSE_OFF.outputaddr]
.done:
    add         rsp, _LZSSE_OFF_size
    ret

struc _LZSSD_OFF
    .buffer     resb WINDOW_LENGTH*2
    .inputaddr  resq 0x1
    .outputaddr resq 0x1
    .length     resq 0x1
    .index      resd 0x1
    .bits_buf   resb 0x1
    .mask       resb 0x1
    .bits       resq 0x1
endstruc
;-----------------------------------------------------
LzssDecoder:
; @brief Uncompress data using LZSS algorithm. 
; @param %rdi - Input pointer
; @param %rsi - Input length
; @param %rdx - Output pointer
; @stack - _LZSSD_OFF
;-----------------------------------------------------
.allocate:
    sub         rsp, _LZSSD_OFF_size
.init:
    mov         qword [rsp+_LZSSD_OFF.inputaddr], r1
    mov         qword [rsp+_LZSSD_OFF.outputaddr], r3
    mov         byte [rsp+_LZSSD_OFF.mask], 0x0
    mov         qword [rsp+_LZSSD_OFF.length], r2
    mov         dword [rsp+_LZSSD_OFF.index], WINDOW_LENGTH-LOOKAHEAD_LENGTH
.fill_space:
    XORX        rax, rdi, rcx
    mov         cx, WINDOW_LENGTH-LOOKAHEAD_LENGTH 
    lea         rdi, qword [rsp+_LZSSD_OFF.buffer] 
    mov         al, 0x20
    rep         stosb
    jmp         .lp.condition
.lp:
    test        rax, rax
    jz          .lp.uncompress
.lp.single_byte:
    mov         cl, 8
    call        .getbits
    XORX        rdi
    mov         rbx, [rsp+_LZSSD_OFF.outputaddr] 
    mov         byte [rbx], al
    inc         qword [rsp+_LZSSD_OFF.outputaddr]
    mov         edi, dword [rsp+_LZSSD_OFF.index]
    mov         byte [rsp+_LZSSD_OFF.buffer+rdi], al
    inc         dword [rsp+_LZSSD_OFF.index]
    and         dword [rsp+_LZSSD_OFF.index], WINDOW_LENGTH-1
    jmp         .lp.condition
.lp.uncompress:
    mov         cl, POSITION_BITS
    call        .getbits
    mov         rsi, rax 
    mov         cl, LENGTH_BITS
    call        .getbits
    inc         rax
    XORX        rdx
    mov         dl, al
    XORX        rax, rcx, rdi
.lp.uncompress.lp:
    XORX        rbx
    mov         bx, si
    add         bx, cx
    and         bx, WINDOW_LENGTH-1
    mov         al, byte [rsp+_LZSSD_OFF.buffer+rbx]
    mov         rbx, [rsp+_LZSSD_OFF.outputaddr] 
    mov         byte [rbx], al
    inc         qword [rsp+_LZSSD_OFF.outputaddr]
    XORX        rdi
    mov         edi, dword [rsp+_LZSSD_OFF.index]
    mov         byte [rsp+_LZSSD_OFF.buffer+rdi], al
    inc         dword [rsp+_LZSSD_OFF.index]
    and         dword [rsp+_LZSSD_OFF.index], WINDOW_LENGTH-1
.lp.uncompress.lp.condition:
    inc         cl
    cmp         cl, dl
    jle         .lp.uncompress.lp
.lp.condition:
    mov         cl, 1
    call        .getbits
    mov         qword [rsp+_LZSSD_OFF.bits], rax
    cmp         qword [rsp+_LZSSD_OFF.length], 0x00
    jg          .lp
    jmp         .done
.getbits:
    pop         rdi
    XORX        rax, rdx, rbx
.getbits.lp:
    cmp         byte [rsp+_LZSSD_OFF.mask], 0x00
    jnz         .getbits.lp.cpy
.getbits.lp.read:
    mov         rbx, qword [rsp+_LZSSD_OFF.inputaddr]
    mov         dl, byte [rbx]
    mov         byte [rsp+_LZSSD_OFF.bits_buf], dl
    inc         qword [rsp+_LZSSD_OFF.inputaddr]
    dec         qword [rsp+_LZSSD_OFF.length]
    mov         byte [rsp+_LZSSD_OFF.mask], 10000000b
.getbits.lp.cpy:
    shl         eax, 1
    mov         dl, byte [rsp+_LZSSD_OFF.bits_buf]
    and         dl, byte [rsp+_LZSSD_OFF.mask]
    test        dl, dl
    jz          $+5
    or          eax, 1
    shr         byte [rsp+_LZSSD_OFF.mask], 1
    loop        .getbits.lp
.getbits.done:
    push        rdi
    ret
.done:
    add         rsp, _LZSSD_OFF_size
    ret
