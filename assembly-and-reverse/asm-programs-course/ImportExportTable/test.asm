.386
.model flat, stdcall
option casemap:none

include C:\masm32\include\windows.inc
include C:\masm32\include\kernel32.inc
includelib C:\masm32\lib\kernel32.lib
include C:\masm32\include\user32.inc
includelib C:\masm32\lib\user32.lib
.DATA
msg BYTE "This is exported function!",0

.CODE

; =============================
; 导出函数 1
; =============================
MyPrintMessage PROC
    push ebp
    mov  ebp, esp

    push offset msg
    call dword ptr [MessageBoxA] ; 调用导入 API

    mov esp, ebp
    pop ebp
    ret
MyPrintMessage ENDP

; ============================
; 导出函数 2
; ============================
AddTwoNumbers PROC a:DWORD, b:DWORD
    push ebp
    mov  ebp, esp

    mov eax, [ebp+8]  ; a
    add eax, [ebp+12] ; b

    mov esp, ebp
    pop ebp
    ret
AddTwoNumbers ENDP

; ============================
; 主程序（用于确保有导入表）
; ============================
start:
    push 0
    push offset msg
    push 0
    push 0
    call MessageBoxA
    call ExitProcess

END start
