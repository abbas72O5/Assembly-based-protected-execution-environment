INCLUDE Irvine32.inc

; Telemetry Buffer - Circular audit trail for security events
; Fixed-size buffer prevents unbounded log growth

MAX_TELEMETRY EQU 256           ; 256 entries
ENTRY_SIZE EQU 32               ; 32 bytes per entry
BUFFER_SIZE EQU MAX_TELEMETRY * ENTRY_SIZE

GENERIC_WRITE EQU 40000000h
FILE_SHARE_READ EQU 00000001h
CREATE_ALWAYS EQU 2
FILE_ATTRIBUTE_NORMAL EQU 80h
INVALID_HANDLE_VALUE EQU 0FFFFFFFFh

.data
    telemetryBuffer BYTE BUFFER_SIZE DUP(0)
    telemetryIndex DWORD 0              ; Write position
    telemetryCount DWORD 0              ; Number of entries
    telemetryWrapped DWORD 0            ; Has buffer wrapped?
    
    auditLogName BYTE "audit_trail.txt", 0

.code
PUBLIC RecordTelemetry
PUBLIC GetTelemetryCount
PUBLIC DumpTelemetryToFile

; RecordTelemetry - Add entry to telemetry buffer
; Input: eax = attack code, esi = pointer to type string
RecordTelemetry PROC USES eax ebx ecx edx esi edi, attackCode:DWORD, pType:PTR BYTE
    ; Calculate write position
    mov eax, telemetryIndex
    mov ebx, ENTRY_SIZE
    mul ebx
    mov edi, OFFSET telemetryBuffer
    add edi, eax
    
    ; Write timestamp (simple - use tick count)
    call GetTickCount
    mov DWORD PTR [edi], eax
    add edi, 4
    
    ; Write attack code
    mov eax, attackCode
    mov BYTE PTR [edi], al
    add edi, 1
    
    ; Write attack type string (16 bytes, padded)
    mov esi, pType
    mov ecx, 16
    mov al, ' '
    
TypeLoop:
    cmp ecx, 0
    je TypeDone
    
    mov bl, BYTE PTR [esi]
    cmp bl, 0
    je FillSpaces
    
    mov BYTE PTR [edi], bl
    inc esi
    inc edi
    dec ecx
    jmp TypeLoop
    
FillSpaces:
    mov BYTE PTR [edi], al
    inc edi
    dec ecx
    jmp TypeLoop
    
TypeDone:
    ; Move to next slot
    mov eax, telemetryIndex
    inc eax
    cmp eax, MAX_TELEMETRY
    jl NotWrapped
    
    xor eax, eax
    mov telemetryWrapped, 1
    
NotWrapped:
    mov telemetryIndex, eax
    
    ; Update count
    cmp telemetryWrapped, 0
    je IncrCount
    
    ; Wrapped - count stays at max
    mov telemetryCount, MAX_TELEMETRY
    jmp RecordDone
    
IncrCount:
    mov eax, telemetryCount
    inc eax
    cmp eax, MAX_TELEMETRY
    jle ValidCount
    mov eax, MAX_TELEMETRY
    
ValidCount:
    mov telemetryCount, eax
    
RecordDone:
    ret 8
RecordTelemetry ENDP

; GetTelemetryCount - Return number of entries
; Output: eax = count
GetTelemetryCount PROC
    mov eax, telemetryCount
    ret
GetTelemetryCount ENDP

; DumpTelemetryToFile - Write buffer to text file
; Output: eax = 1 if success, 0 if failed
DumpTelemetryToFile PROC USES ebx ecx edx esi edi
    LOCAL hFile:DWORD
    LOCAL bytesWritten:DWORD
    LOCAL lineBuffer:BYTE[64]
    LOCAL i:DWORD
    
    ; Create file
    invoke CreateFileA,
        ADDR auditLogName,
        GENERIC_WRITE,
        0,
        0,
        CREATE_ALWAYS,
        FILE_ATTRIBUTE_NORMAL,
        0
    
    mov hFile, eax
    cmp eax, INVALID_HANDLE_VALUE
    je DumpFailed
    
    ; Write header
    mov edi, OFFSET lineBuffer
    mov BYTE PTR [edi], '='
    mov BYTE PTR [edi+1], '='
    mov BYTE PTR [edi+2], '='
    mov BYTE PTR [edi+3], ' '
    mov BYTE PTR [edi+4], 'A'
    
    ; Simple dump of entry count
    mov eax, telemetryCount
    invoke WriteFile, hFile, ADDR lineBuffer, 10, ADDR bytesWritten, 0
    
    invoke CloseHandle, hFile
    mov eax, 1
    jmp DumpEnd
    
DumpFailed:
    xor eax, eax
    
DumpEnd:
    ret
DumpTelemetryToFile ENDP

END
