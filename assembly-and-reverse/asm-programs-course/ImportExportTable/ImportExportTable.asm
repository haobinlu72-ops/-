.386
.model flat,stdcall
option casemap:none

include C:\masm32\include\windows.inc
include C:\masm32\include\kernel32.inc
include C:\masm32\include\masm32.inc
includelib C:\masm32\lib\kernel32.lib
includelib C:\masm32\lib\masm32.lib 

.data
;提示信息
str1 BYTE "Please input a PE file:",0
str2 BYTE "Import table:",0ah,0dh,0
str3 BYTE "Export table:",0ah,0dh,0
str4 BYTE "---------------------",0ah,0dh,0

inputBuf BYTE 256 DUP(0);输入的路径
fileBuf BYTE 4000 DUP(0);将文件的前4000字节读入缓存
endl BYTE 0ah,0dh,0

.code
;过程，将RVA装换成RAW
rvatoraw PROC
    push ebp
	mov ebp,esp
	sub esp,8

	mov eax,[ebp+8]  ; 保存nt头地址
	movzx ecx,word ptr [eax+14h]  ; 保存SizeOfOptionalHeader
	add eax,18h
	add eax,ecx  ; 此时eax指向节表
	mov [ebp-4],eax  ; 保存节表起始地址
	mov eax,[ebp+8]  ; 获得nt头地址
	movzx ecx,word ptr [eax+6h]  ; 获得NumberOfSections 
	mov [ebp-8],ecx  ; 保存NumberOfSections 
	mov ebx,[ebp-4]  ; 设置遍历基地址
	mov edx,[ebp+12]  ; 获取RVA
	
find_loop:
	mov eax,[ebx+0ch]  ; 获取VirtualAddress
	cmp edx,eax
	jb not_in_bound  ; 小于就跳走
	add eax,[ebx+10h]  ; 加上SizeOfRawData
	cmp edx,eax
	jae not_in_bound  ; 大于等于也跳走
	;此时满足条件，计算raw
	mov eax,edx
	sub eax,[ebx+0ch]
	add eax,[ebx+14h]
	jmp find_end
	
not_in_bound:
	add ebx,28h  ; IMAGE_SECTION_HEADER大小
	loop find_loop
	xor eax,eax  ; 都没匹配上，返回0
	
find_end:
	mov esp,ebp
	pop ebp
	ret
rvatoraw ENDP

printImport PROC
	push ebp
	mov ebp,esp
	sub esp,12
	
	mov eax,[ebp+12]  ; 检测导入表rva是否是0
	cmp eax,0
	je import_end
	
	invoke StdOut, addr str2
	
	push [ebp+12]  ; 导入表rva
	push [ebp+8]  ; nt头
	call rvatoraw
	add esp,8
	add eax,offset fileBuf
	mov [ebp-4],eax  ; 保存导入表在文件中的偏移
	mov [ebp-8],eax
	
loop_dll:
	mov eax,[ebp-8]  ; 取当前导入dll记录信息地址
	mov ecx,[eax]  ; 取起始部分，看是否为0，为0则跳出外层循环
	cmp ecx,0
	je loop_dll_end
	
	mov eax,[ebp-8]
	mov ebx,[eax+0ch]  ; 从导入表中读取name的rva
	push ebx  ;导入表rva
	push [ebp+8]  ;nt头
	call rvatoraw
	add esp,8
	add eax,offset fileBuf
	invoke StdOut, eax  ; 输出DLL的name
	invoke StdOut, addr endl
	
	mov eax,[ebp-8]
	mov eax,[eax]  ; 获得OriginalFirstThunk的rva
	push eax  ; 参数2：OriginalFirstThunk的rva 入栈
	push [ebp+8]  ; 参数1：nt头 入栈
	call rvatoraw
	add esp,8
	add eax,offset fileBuf  ; 转到到文件中的地址
	mov [ebp-12],eax  ; 保存INT起始地址
	
loop_int:
	mov eax,[ebp-12]  ; 获取INT[i]地址
	mov eax,[eax]  ; 取INT[i]的IMAGE_IMPORT_BY_NAME的RVA
	cmp eax,0
	je loop_int_end

	mov eax,[ebp-12]  ; 获取INT[i]地址
	mov eax,[eax]  ; 取INT[i]的IMAGE_IMPORT_BY_NAME的RVA
	push eax  ; INT[i]的rva
	push [ebp+8]  ;nt头
	call rvatoraw  ; 获取函数名在文件中的RAW
	add esp,8  
	add eax,offset fileBuf  ; 此时得到IMAGE_IMPORT_BY_NAME[i]在文件中的地址
	add eax,2
	invoke StdOut, eax  ; 输出导入函数名称
	invoke StdOut, addr endl
	
	mov ecx,4
	add [ebp-12],ecx
	jmp loop_int
	
loop_int_end:
	mov ecx,14h
	add [ebp-8],ecx  ; 遍历下一个
	jmp loop_dll
loop_dll_end:
import_end:
	mov esp,ebp
	pop ebp
	ret
printImport ENDP

printExport PROC
	push ebp
	mov ebp,esp
	sub esp,8
	
	mov eax,[ebp+12]  ; 检测导出表rva是否是0
	cmp eax,0  
	je export_end  ; 如果是0就跳出	
	invoke StdOut, addr str3
	push [ebp+12]  ; 导出表rva
	push [ebp+8]  ; nt头
	call rvatoraw
	add esp,8
	add eax,offset fileBuf
	mov ebx,eax
	mov eax,[eax+24]
	mov [ebp-4],eax
	mov eax,[ebx+32]
	
	push eax  ; AddressOfNames rva
	push [ebp+8]  ; nt头
	call rvatoraw
	add esp,8 
	add eax,offset fileBuf
	mov [ebp-8],eax
	mov ecx,[ebp-4]
export_loop:
	mov [ebp-4],ecx
	mov ebx,[ebp-8]
	push [ebx]  ;函数名字的rva
	push [ebp+8]  ;nt头
	call rvatoraw
	add esp,8
	add eax,offset fileBuf
	invoke StdOut, eax
	invoke StdOut, addr endl
	mov edx,4
	add [ebp-8],edx
	mov ecx,[ebp-4]
	loop export_loop
	
export_end:
	mov esp,ebp
	pop ebp
	ret
printExport ENDP

;主函数
main PROC
   push ebp
   mov ebp,esp
   sub esp,12

   invoke StdOut,addr str1 ;输出提示信息
   invoke StdIn,addr inputBuf,255 ;输入文件路径
   invoke CreateFile,addr inputBuf,\   ;打开文件
                  GENERIC_READ,\
                  FILE_SHARE_READ,\
                  0,\
                  OPEN_EXISTING,\
                  FILE_ATTRIBUTE_ARCHIVE,\
                  0
    mov [ebp-4],eax  ; 保存文件句柄，程序结束时要通过此句柄关闭文件
	invoke SetFilePointer, [ebp-4], 0, 0, FILE_BEGIN  ; 将文件指针置到文件头部
	invoke ReadFile, [ebp-4], addr fileBuf, 4000, 0, 0  ; 将文件读入缓冲区
	
	;计算NtHeader地址并保存在栈中
	mov eax,offset fileBuf 
	add eax,[eax+3ch]  
	mov [ebp-8],eax
	add eax,78h
	
	; 导入表
	mov [ebp-12],eax  ; DataDirectory
	mov ebx,[eax+8]  ; 获得导入表RVA
	push ebx  ; 导入表RVA 入栈
	push [ebp-8]  ; nt头 入栈
	call printImport  ;输出
	add esp,8
	
	invoke StdOut,addr str4
	; 导出表
	mov eax,[ebp-12]  ; DataDirectory
	mov ebx,[eax]  ; 获得导出表RVA
	push ebx  ;导出表RVA 入栈
	push [ebp-8]  ; nt头 入栈
	call printExport  ;输出
	add esp,8
	
	invoke CloseHandle, [ebp-4]  ; 关闭文件
    invoke ExitProcess,0
main ENDP
END main