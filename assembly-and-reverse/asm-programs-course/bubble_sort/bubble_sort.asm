.386
.model flat,stdcall
option casemap:none

include C:\masm32\include\windows.inc
include C:\masm32\include\kernel32.inc
include C:\masm32\include\masm32.inc
includelib C:\masm32\lib\masm32.lib
includelib C:\masm32\lib\kernel32.lib

.data
var1 db "Please input 10 numbers(0~10000):",0Dh,0Ah,0
var2 db "The result is:",0Dh,0Ah,0
buf db 100 DUP(0)
number dd 10 DUP(0)
outbuf db 100 DUP(0)
tempbuf db 12 DUP(0)
outbufPtr dd 0
crlf db 0Dh,0Ah,0

.code
;my_proc1过程将输入的字符转成十进制整数数组（数组大小为10）
my_proc1 PROC
lea esi,buf
lea edi,number
xor eax,eax

Nextchar:
mov bl,[esi]

cmp bl,0
je EndConv
cmp bl,13
je EndConv

cmp bl," "
je Nextnum

imul eax,eax,10
movzx ebx,bl
sub ebx,'0'
add eax,ebx
inc esi
jmp Nextchar

Nextnum:
mov [edi],eax
add edi,4
xor eax,eax
inc esi
jmp Nextchar

EndConv:
mov [edi],eax
ret
my_proc1 ENDP

;将转化好的数进行排序
my_sort PROC
mov ecx,10

outer_loop:
dec ecx
cmp ecx,0
jl EndSort
xor esi,esi

inner_loop:
mov eax,[number+esi*4]
mov ebx,[number+esi*4+4]
cmp eax,ebx
jbe Noswap
mov [number+esi*4],ebx
mov [number+esi*4+4],eax

Noswap:
inc esi
cmp esi,ecx
jl inner_loop
jmp outer_loop

EndSort:
ret
my_sort ENDP

;将排序好的数组转成字符串输出
my_proc2 PROC
    push ebx
    push esi
    push edi
    push ebp

    lea esi, number      
    lea edi, outbuf       
    mov ecx, 10             

convert_next_num:
    mov eax, [esi]         
    add esi, 4             

    lea ebx, tempbuf+11     
    mov byte ptr [ebx], 0
    dec ebx                 

convert_digit:
    xor edx, edx
    mov ebp, 10             
    div ebp                 
    add dl, '0'
    mov [ebx], dl
    dec ebx
    cmp eax, 0
    jne convert_digit
    inc ebx                

copy_to_outbuf:
    mov al, [ebx]
    mov [edi], al
    inc ebx
    inc edi
    cmp al, 0
    jne copy_to_outbuf
    dec edi              
    dec ecx
    cmp ecx, 0
    je finish              

    mov byte ptr [edi], ' '
    inc edi
    jmp convert_next_num

finish:
    mov byte ptr [edi], 0   

    pop ebp
    pop edi
    pop esi
    pop ebx
    ret
my_proc2 ENDP

start:
invoke StdOut,addr var1
invoke StdIn,addr buf,100
call my_proc1
call my_sort
invoke StdOut,addr var2
call my_proc2
invoke StdOut, addr outbuf 
invoke StdOut,addr crlf
invoke ExitProcess,0
END start

 