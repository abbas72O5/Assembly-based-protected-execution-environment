INCLUDE Irvine32.inc

; Attack Pattern Engine - Tracks attack frequency and cycles
; Stores counters for each attack type and detects repeated attacks

MAX_ATTACK_TYPES EQU 7          ; Attack codes 10-16
MAX_HISTORY EQU 100             ; Keep last 100 attacks
CYCLE_THRESHOLD EQU 5           ; X consecutive same attacks = cycle

.data
    attackCounters DWORD MAX_ATTACK_TYPES DUP(0)   ; Count per type
    patternHistory DWORD MAX_HISTORY DUP(0)        ; Circular history
    historyIndex DWORD 0                           ; Current write position
    historyFilled DWORD 0                          ; Has wrapped?
    
    lastAttackCode DWORD 0                         ; Last attack seen
    consecutiveCount DWORD 0                       ; Same attacks in row
    cycleDetected DWORD 0                          ; Flag: cycle active

.code
PUBLIC RecordAttackPattern
PUBLIC IsCycleDetected
PUBLIC GetAttackCounter
PUBLIC GetConsecutiveCount
PUBLIC ResetPattern

; RecordAttackPattern - Record attack in pattern database
; Input: attackCode = attack code (10-15)
RecordAttackPattern PROC USES eax ebx ecx edx esi, attackCode:DWORD
    mov ebx, attackCode     ; ebx = attack code
    
    ; Validate code range
    cmp ebx, 10
    jl RecordEnd
    cmp ebx, 16
    jge RecordEnd
    
    ; Increment counter for this type
    sub ebx, 10             ; Convert to index (0-6)
    lea esi, attackCounters
    mov ecx, DWORD PTR [esi + ebx*4]
    inc ecx
    mov DWORD PTR [esi + ebx*4], ecx
    
    ; Check for consecutive same attacks
    mov eax, ebx
    add eax, 10             ; Convert back to code
    cmp eax, lastAttackCode
    je ConsecutiveAttack
    
    ; Different attack type
    mov lastAttackCode, eax
    mov consecutiveCount, 1
    mov cycleDetected, 0
    jmp AddToHistory
    
ConsecutiveAttack:
    ; Same attack type
    mov ecx, consecutiveCount
    inc ecx
    mov consecutiveCount, ecx
    
    ; Check if threshold exceeded
    cmp ecx, CYCLE_THRESHOLD
    jle AddToHistory
    mov cycleDetected, 1
    
AddToHistory:
    ; Add to circular history
    mov eax, historyIndex
    mov ebx, eax
    add eax, 1
    cmp eax, MAX_HISTORY
    jl NoWrap
    xor eax, eax
    mov historyFilled, 1
    
NoWrap:
    mov historyIndex, eax
    
    lea esi, patternHistory
    mov eax, ebx
    mov ecx, lastAttackCode
    mov DWORD PTR [esi + eax*4], ecx
    
RecordEnd:
    ret 4
RecordAttackPattern ENDP

; IsCycleDetected - Check if cycle was detected
; Output: eax = 1 if cycle, 0 otherwise
IsCycleDetected PROC
    mov eax, cycleDetected
    ret
IsCycleDetected ENDP

; GetAttackCounter - Returns frequency for a specific attack code.
; Input: attackCode = attack code (10-15)
; Output: eax = count
GetAttackCounter PROC USES ebx esi, attackCode:DWORD
    mov eax, 0
    mov ebx, attackCode
    cmp ebx, 10
    jl GetCounterDone
    cmp ebx, 16
    jge GetCounterDone

    sub ebx, 10
    lea esi, attackCounters
    mov eax, DWORD PTR [esi + ebx*4]

GetCounterDone:
    ret 4
GetAttackCounter ENDP

; GetConsecutiveCount - Returns repeated-attack streak length.
; Output: eax = consecutive count
GetConsecutiveCount PROC
    mov eax, consecutiveCount
    ret
GetConsecutiveCount ENDP

; ResetPattern - Clear pattern database
ResetPattern PROC USES ecx edi
    lea edi, attackCounters
    mov ecx, MAX_ATTACK_TYPES
    xor eax, eax
    rep stosd
    
    lea edi, patternHistory
    mov ecx, MAX_HISTORY
    rep stosd
    
    mov historyIndex, 0
    mov historyFilled, 0
    mov lastAttackCode, 0
    mov consecutiveCount, 0
    mov cycleDetected, 0
    
    ret
ResetPattern ENDP

END
