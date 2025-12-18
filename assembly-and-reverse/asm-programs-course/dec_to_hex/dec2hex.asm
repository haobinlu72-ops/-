include C:\masm32\include\masm32rt.inc
includelib C:\masm32\lib\kernel32.lib
includelib C:\masm32\lib\masm32.lib

.data
msgInput    db "Please input a decimal number(0~4294967295):",13,10,0
msgOutput   db "The hexadecimal number is: ",0
inputbuf    db 32 dup(0)
hexbuf      db 9 dup(0)
crlf        db 13,10,0

.code
dec_to_dw proc
    xor eax, eax
NextChar:
    mov bl, [esi]
    
    cmp bl, 0
    je EndConv
    cmp bl, 13
    je EndConv
    ；处理小于0和大于9的情况
    cmp bl, '0'
    jb SkipChar
    cmp bl, '9'
    ja SkipChar

    imul eax, eax, 10
    movzx ebx,bl
    sub bl, '0'
    add eax, ebx
SkipChar:
    inc esi
    jmp NextChar
EndConv:
    ret
dec_to_dw endp

dw_to_hex proc
    push ebx
    push ecx
    push edx
    mov edx, eax
    mov ecx, 8
    lea ebx, hexbuf+7
HexLoop:
    mov eax, edx
    and eax, 0Fh
    cmp eax, 9
    jg HexLetter
    add eax, '0'
    jmp HexStore
HexLetter:
    add eax, 'A' - 10
HexStore:
    mov [ebx], al
    dec ebx
    shr edx, 4
    loop HexLoop
    pop edx
    pop ecx
    pop ebx
    ret
dw_to_hex endp

start:
    invoke StdOut, addr msgInput
    invoke StdIn, addr inputbuf, 32
    lea esi, inputbuf
    call dec_to_dw
    call dw_to_hex
    invoke StdOut, addr msgOutput
    invoke StdOut, addr hexbuf      
    invoke StdOut, addr crlf
    invoke ExitProcess, 0
end start