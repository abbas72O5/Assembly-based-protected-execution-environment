INCLUDE Irvine32.inc
INCLUDE ProtectionMacros_Standalone.inc
.586

.code
PUBLIC AddOperation
PUBLIC SubOperation
PUBLIC MulOperation
PUBLIC DivOperation
PUBLIC FactorialOperation
PUBLIC FibonacciOperation
PUBLIC ReverseNumberOperation

AttackISR PROTO, attackCode:DWORD
AddCoreOperation PROTO, a:SDWORD, b:SDWORD
SubCoreOperation PROTO, a:SDWORD, b:SDWORD
MulCoreOperation PROTO, a:SDWORD, b:SDWORD
DivCoreOperation PROTO, a:SDWORD, b:SDWORD
FactorialCoreOperation PROTO, n:SDWORD
FibonacciCoreOperation PROTO, n:SDWORD
ReverseCoreOperation PROTO, n:SDWORD

AddCoreOperation PROC, a:SDWORD, b:SDWORD
    mov eax, a
    add eax, b
    ret 8
AddCoreOperation ENDP

AddOperation PROC USES ebx, a:SDWORD, b:SDWORD
    LOCAL frame[24]:BYTE
    LOCAL trustedCanary:DWORD
    LOCAL opResult:SDWORD

    INIT_CANARY trustedCanary, frame[16]

    invoke AddCoreOperation, a, b
    mov opResult, eax

    VERIFY_CANARY frame[16], trustedCanary, AddGuardFail

    mov eax, opResult
    ret 8

AddGuardFail:
    invoke AttackISR, 14
    xor eax, eax
    ret 8
AddOperation ENDP

SubCoreOperation PROC, a:SDWORD, b:SDWORD
    mov eax, a
    sub eax, b
    ret 8
SubCoreOperation ENDP

SubOperation PROC USES ebx, a:SDWORD, b:SDWORD
    LOCAL frame[24]:BYTE
    LOCAL trustedCanary:DWORD
    LOCAL opResult:SDWORD

    INIT_CANARY trustedCanary, frame[16]

    invoke SubCoreOperation, a, b
    mov opResult, eax

    VERIFY_CANARY frame[16], trustedCanary, SubGuardFail

    mov eax, opResult
    ret 8

SubGuardFail:
    invoke AttackISR, 14
    xor eax, eax
    ret 8
SubOperation ENDP

MulCoreOperation PROC, a:SDWORD, b:SDWORD
    mov eax, a
    imul eax, b
    ret 8
MulCoreOperation ENDP

MulOperation PROC USES ebx, a:SDWORD, b:SDWORD
    LOCAL frame[24]:BYTE
    LOCAL trustedCanary:DWORD
    LOCAL opResult:SDWORD

    INIT_CANARY trustedCanary, frame[16]

    invoke MulCoreOperation, a, b
    mov opResult, eax

    VERIFY_CANARY frame[16], trustedCanary, MulGuardFail

    mov eax, opResult
    ret 8

MulGuardFail:
    invoke AttackISR, 14
    xor eax, eax
    ret 8
MulOperation ENDP

DivCoreOperation PROC USES ebx edx, a:SDWORD, b:SDWORD
    mov eax, a
    cdq
    mov ebx, b
    idiv ebx
    ret 8
DivCoreOperation ENDP

DivOperation PROC USES ebx, a:SDWORD, b:SDWORD
    LOCAL frame[24]:BYTE
    LOCAL trustedCanary:DWORD
    LOCAL opResult:SDWORD

    INIT_CANARY trustedCanary, frame[16]

    invoke DivCoreOperation, a, b
    mov opResult, eax

    VERIFY_CANARY frame[16], trustedCanary, DivGuardFail

    mov eax, opResult
    ret 8

DivGuardFail:
    invoke AttackISR, 14
    xor eax, eax
    ret 8
DivOperation ENDP

FactorialCoreOperation PROC USES ebx ecx, n:SDWORD
    mov ecx, n
    cmp ecx, 0
    jl FactInvalid
    cmp ecx, 1
    jbe FactOne

    mov eax, 1
    mov ebx, 2

FactLoop:
    imul eax, ebx
    inc ebx
    cmp ebx, ecx
    jle FactLoop
    ret 4

FactOne:
    mov eax, 1
    ret 4

FactInvalid:
    xor eax, eax
    ret 4
FactorialCoreOperation ENDP

FactorialOperation PROC USES ebx, a:SDWORD, b:SDWORD
    LOCAL frame[24]:BYTE
    LOCAL trustedCanary:DWORD
    LOCAL opResult:SDWORD

    INIT_CANARY trustedCanary, frame[16]

    invoke FactorialCoreOperation, a
    mov opResult, eax

    VERIFY_CANARY frame[16], trustedCanary, FactorialGuardFail

    mov eax, opResult
    ret 8

FactorialGuardFail:
    invoke AttackISR, 14
    xor eax, eax
    ret 8
FactorialOperation ENDP

FibonacciCoreOperation PROC USES ebx ecx edx esi edi, n:SDWORD
    mov ecx, n
    cmp ecx, 0
    jl FibInvalid
    je FibZero
    cmp ecx, 1
    je FibOne

    xor esi, esi
    mov edi, 1
    mov ebx, 2

FibLoop:
    mov eax, esi
    add eax, edi
    mov edx, edi
    mov esi, edx
    mov edi, eax
    inc ebx
    cmp ebx, ecx
    jle FibLoop

    mov eax, edi
    ret 4

FibZero:
    xor eax, eax
    ret 4

FibOne:
    mov eax, 1
    ret 4

FibInvalid:
    xor eax, eax
    ret 4
FibonacciCoreOperation ENDP

FibonacciOperation PROC USES ebx, a:SDWORD, b:SDWORD
    LOCAL frame[24]:BYTE
    LOCAL trustedCanary:DWORD
    LOCAL opResult:SDWORD

    INIT_CANARY trustedCanary, frame[16]

    invoke FibonacciCoreOperation, a
    mov opResult, eax

    VERIFY_CANARY frame[16], trustedCanary, FibonacciGuardFail

    mov eax, opResult
    ret 8

FibonacciGuardFail:
    invoke AttackISR, 14
    xor eax, eax
    ret 8
FibonacciOperation ENDP

ReverseCoreOperation PROC USES ebx ecx edx esi, n:SDWORD
    mov eax, n
    xor ecx, ecx
    xor esi, esi
    cmp eax, 0
    jge ReversePrepare
    neg eax
    mov esi, 1

ReversePrepare:
    mov ebx, 10

ReverseLoop:
    xor edx, edx
    div ebx
    imul ecx, ecx, 10
    add ecx, edx
    cmp eax, 0
    jne ReverseLoop

    mov eax, ecx
    cmp esi, 1
    jne ReverseDone
    neg eax

ReverseDone:
    ret 4
ReverseCoreOperation ENDP

ReverseNumberOperation PROC USES ebx, a:SDWORD, b:SDWORD
    LOCAL frame[24]:BYTE
    LOCAL trustedCanary:DWORD
    LOCAL opResult:SDWORD

    INIT_CANARY trustedCanary, frame[16]

    invoke ReverseCoreOperation, a
    mov opResult, eax

    VERIFY_CANARY frame[16], trustedCanary, ReverseGuardFail

    mov eax, opResult
    ret 8

ReverseGuardFail:
    invoke AttackISR, 14
    xor eax, eax
    ret 8
ReverseNumberOperation ENDP

END
