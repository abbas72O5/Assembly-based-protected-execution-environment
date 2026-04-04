INCLUDE Irvine32.inc

.code
PUBLIC AddOperation
PUBLIC SubOperation
PUBLIC MulOperation
PUBLIC DivOperation

AddOperation PROC, a:SDWORD, b:SDWORD
    mov eax, a
    add eax, b
    ret 8
AddOperation ENDP

SubOperation PROC, a:SDWORD, b:SDWORD
    mov eax, a
    sub eax, b
    ret 8
SubOperation ENDP

MulOperation PROC, a:SDWORD, b:SDWORD
    mov eax, a
    imul eax, b
    ret 8
MulOperation ENDP

DivOperation PROC USES ebx edx, a:SDWORD, b:SDWORD
    mov eax, a
    cdq
    mov ebx, b
    idiv ebx
    ret 8
DivOperation ENDP

END
