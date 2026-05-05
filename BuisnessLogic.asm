INCLUDE Irvine32.inc
INCLUDE ProtectionMacros_Standalone.inc
.586

.code
PUBLIC XorEncryptOperation
PUBLIC XorDecryptOperation
PUBLIC CaesarEncryptOperation
PUBLIC CaesarDecryptOperation
PUBLIC HashMixOperation
PUBLIC ChecksumOperation

AttackISR PROTO, attackCode:DWORD
XorEncryptCore PROTO, plain:SDWORD, key:SDWORD
XorDecryptCore PROTO, cipher:SDWORD, key:SDWORD
CaesarEncryptCore PROTO, plain:SDWORD, key:SDWORD
CaesarDecryptCore PROTO, cipher:SDWORD, key:SDWORD
HashMixCore PROTO, a:SDWORD, b:SDWORD
ChecksumCore PROTO, a:SDWORD, b:SDWORD

XorEncryptCore PROC, plain:SDWORD, key:SDWORD
    mov eax, plain
    xor eax, key
    ret 8
XorEncryptCore ENDP

; XOR encryption/decryption are symmetric.
XorEncryptOperation PROC USES ebx, plain:SDWORD, key:SDWORD
    LOCAL frame[24]:BYTE
    LOCAL trustedCanary:DWORD
    LOCAL opResult:SDWORD

    INIT_CANARY trustedCanary, frame[16]

    invoke XorEncryptCore, plain, key
    mov opResult, eax

    VERIFY_CANARY frame[16], trustedCanary, XorEncryptGuardFail

    mov eax, opResult
    ret 8

XorEncryptGuardFail:
    invoke AttackISR, 14
    xor eax, eax
    ret 8
XorEncryptOperation ENDP

XorDecryptCore PROC, cipher:SDWORD, key:SDWORD
    mov eax, cipher
    xor eax, key
    ret 8
XorDecryptCore ENDP

XorDecryptOperation PROC USES ebx, cipher:SDWORD, key:SDWORD
    LOCAL frame[24]:BYTE
    LOCAL trustedCanary:DWORD
    LOCAL opResult:SDWORD

    INIT_CANARY trustedCanary, frame[16]

    invoke XorDecryptCore, cipher, key
    mov opResult, eax

    VERIFY_CANARY frame[16], trustedCanary, XorDecryptGuardFail

    mov eax, opResult
    ret 8

XorDecryptGuardFail:
    invoke AttackISR, 14
    xor eax, eax
    ret 8
XorDecryptOperation ENDP

CaesarEncryptCore PROC, plain:SDWORD, key:SDWORD
    mov eax, plain
    add eax, key
    and eax, 0FFh
    ret 8
CaesarEncryptCore ENDP

; Caesar-style byte transform on low 8 bits.
CaesarEncryptOperation PROC USES ebx, plain:SDWORD, key:SDWORD
    LOCAL frame[24]:BYTE
    LOCAL trustedCanary:DWORD
    LOCAL opResult:SDWORD

    INIT_CANARY trustedCanary, frame[16]

    invoke CaesarEncryptCore, plain, key
    mov opResult, eax

    VERIFY_CANARY frame[16], trustedCanary, CaesarEncryptGuardFail

    mov eax, opResult
    ret 8

CaesarEncryptGuardFail:
    invoke AttackISR, 14
    xor eax, eax
    ret 8
CaesarEncryptOperation ENDP

CaesarDecryptCore PROC, cipher:SDWORD, key:SDWORD
    mov eax, cipher
    sub eax, key
    and eax, 0FFh
    ret 8
CaesarDecryptCore ENDP

CaesarDecryptOperation PROC USES ebx, cipher:SDWORD, key:SDWORD
    LOCAL frame[24]:BYTE
    LOCAL trustedCanary:DWORD
    LOCAL opResult:SDWORD

    INIT_CANARY trustedCanary, frame[16]

    invoke CaesarDecryptCore, cipher, key
    mov opResult, eax

    VERIFY_CANARY frame[16], trustedCanary, CaesarDecryptGuardFail

    mov eax, opResult
    ret 8

CaesarDecryptGuardFail:
    invoke AttackISR, 14
    xor eax, eax
    ret 8
CaesarDecryptOperation ENDP

HashMixCore PROC USES ebx, a:SDWORD, b:SDWORD
    mov eax, a
    mov ebx, b
    rol eax, 5
    xor eax, ebx
    imul eax, eax, 45D9F3Bh
    xor eax, 0A5A5A5A5h
    ret 8
HashMixCore ENDP

; Non-cryptographic mixing hash for educational demo.
HashMixOperation PROC USES ebx, a:SDWORD, b:SDWORD
    LOCAL frame[24]:BYTE
    LOCAL trustedCanary:DWORD
    LOCAL opResult:SDWORD

    INIT_CANARY trustedCanary, frame[16]

    invoke HashMixCore, a, b
    mov opResult, eax

    VERIFY_CANARY frame[16], trustedCanary, HashMixGuardFail

    mov eax, opResult
    ret 8

HashMixGuardFail:
    invoke AttackISR, 14
    xor eax, eax
    ret 8
HashMixOperation ENDP

ChecksumCore PROC, a:SDWORD, b:SDWORD
    mov eax, a
    add eax, 09E3779B9h
    xor eax, b
    ror eax, 7
    imul eax, eax, 33
    add eax, b
    ret 8
ChecksumCore ENDP

ChecksumOperation PROC USES ebx, a:SDWORD, b:SDWORD
    LOCAL frame[24]:BYTE
    LOCAL trustedCanary:DWORD
    LOCAL opResult:SDWORD

    INIT_CANARY trustedCanary, frame[16]

    invoke ChecksumCore, a, b
    mov opResult, eax

    VERIFY_CANARY frame[16], trustedCanary, ChecksumGuardFail

    mov eax, opResult
    ret 8

ChecksumGuardFail:
    invoke AttackISR, 14
    xor eax, eax
    ret 8
ChecksumOperation ENDP

END