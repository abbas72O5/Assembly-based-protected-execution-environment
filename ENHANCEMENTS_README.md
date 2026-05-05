=============================================================================
STACKGUARD PRODUCT SCALING ENHANCEMENTS
=============================================================================

Three major enhancements have been implemented to scale StackGuard to a 
professional security product and enable integration with other MASM projects:

1. ATTACK PATTERN ENGINE (AttackPatternEngine.asm)
2. TELEMETRY BUFFER (TelemetryBuffer.asm)
3. REUSABLE PROTECTION MACROS (ProtectionMacros.inc)

Current Runtime Status:
  - Macro layer is now active in the main app protection path.
  - InputSecurity.asm, ArithmeticOps.asm, and BuisnessLogic.asm use ProtectionMacros.inc.
  - SecurityProvider.asm remains the low-level primitive provider called by macros.

=============================================================================
1. ATTACK PATTERN ENGINE - AttackPatternEngine.asm
=============================================================================

Purpose:
  Analyzes attack frequency and detects attack cycles to identify 
  coordinated or repeated attack attempts.

Features:
  - Tracks occurrence count for each attack type (codes 10-15)
  - Detects consecutive same-type attacks (cycle detection)
  - Maintains circular history buffer of last 100 attacks
  - Identifies attack patterns and anomalies

Public Functions:

  RecordAttackPattern(attackCode:DWORD)
    Records an attack in the pattern database
    Input: eax = attack code (10-15)
    Output: None
    
  AnalyzePatterns() -> eax
    Analyzes recorded patterns for anomalies
    Output: eax = 1 if cycle detected, 0 otherwise
    
  IsCycleDetected() -> eax
    Quick check if a cycle has been detected
    Output: eax = 1 if cycle present, 0 otherwise
    
  GetPatternReport(pBuffer, bufSize) -> eax
    Generates human-readable pattern analysis
    Input: esi = buffer pointer, ecx = buffer size
    Output: eax = bytes written to buffer

Data Structures:
  
  attackCounters (DWORD[7])
    Counter for each attack type (10-16)
    Index 0 = code 10, Index 1 = code 11, etc.
    
  patternBuffer (DWORD[100])
    Circular history of recent attack codes
    
  consecutiveCount (DWORD)
    How many times the same attack type appeared in a row
    
  cycleThreshold (DWORD) = 5
    Threshold to declare a cycle (configurable)

Configuration:
  cycleThreshold: Change this to adjust cycle sensitivity (lines 12-13)
  MAX_PATTERN_HISTORY: Increase to store more attack history (line 7)

Integration Point:
  Called from AttackISR after logging each attack
  Enables detection of coordinated multi-attack scenarios

Example Usage:
  mov eax, 10                    ; Attack code
  call RecordAttackPattern
  call IsCycleDetected
  cmp eax, 1
  je CycleDetectedHandler

=============================================================================
2. TELEMETRY BUFFER - TelemetryBuffer.asm
=============================================================================

Purpose:
  Circular buffer audit trail preventing unbounded file growth while
  preserving recent security event history for forensics.

Features:
  - Fixed-size circular buffer (256 entries × 32 bytes = 8KB)
  - Records timestamp, attack code, and type for each event
  - Prevents log file bloat on long-running systems
  - Can dump complete history to text file on demand
  - Maintains both binary and text audit trails

Public Functions:

  RecordTelemetry(attackCode:DWORD, pAttackType:PTR BYTE)
    Add entry to telemetry buffer
    Input: eax = attack code, esi = pointer to type string
    Output: None
    
  GetTelemetryEntry(index, pBuffer) -> eax
    Retrieve an entry by index
    Input: eax = index (0=oldest, count-1=newest)
           esi = destination buffer
    Output: eax = 1 if success, 0 if index invalid
    
  GetTelemetryCount() -> eax
    Get number of telemetry entries
    Output: eax = entry count
    
  DumpTelemetryToFile() -> eax
    Write complete buffer to audit_trail.txt
    Output: eax = 1 if success, 0 if failed
    
  ClearTelemetry()
    Reset buffer to empty state
    Output: None

Buffer Layout:
  Total Size: 256 entries × 32 bytes = 8,192 bytes
  Per Entry:
    Offset  Size  Field
    0       4     Timestamp (DWORD, system tick count)
    4       1     Attack Code (BYTE)
    5       16    Attack Type (BYTE[16], space-padded string)
    21      11    Reserved for future use

Configuration:
  MAX_TELEMETRY_ENTRIES: Buffer entry count (line 5)
  TELEMETRY_ENTRY_SIZE: Bytes per entry (line 6)

Output Files:
  audit_trail.bin: Binary telemetry dump (optional)
  audit_trail.txt: Human-readable audit trail

Integration Point:
  Called from AttackISR after pattern recording
  Provides forensic trail of all security events

Example Usage:
  mov eax, 10                    ; Attack code
  mov esi, OFFSET "CANARY_MISMATCH"
  call RecordTelemetry
  
  call GetTelemetryCount
  ; eax now contains number of events
  
  mov eax, 0                     ; Get oldest entry
  mov esi, OFFSET buffer
  call GetTelemetryEntry

=============================================================================
3. REUSABLE PROTECTION MACROS - ProtectionMacros.inc
=============================================================================

Purpose:
  Standalone macro library enabling any MASM project to integrate
  StackGuard protection mechanisms without code modification.

This is the KEY COMPONENT for product scaling and integration.

USAGE IN OTHER MASM PROJECTS:
  
  1. Copy ProtectionMacros.inc to your project
  2. Add to your MASM file:  INCLUDE ProtectionMacros.inc
  3. Use macros in your code (examples below)
  4. No external dependencies - purely macro expansion

Available Macros:

BASIC PROTECTION:

  CREATE_CANARY
    Generates a dynamic canary value
    Output: eax = canary
    Usage:
      CREATE_CANARY
      mov myCanary, eax
    
  SETUP_PROTECTION_FRAME frameSize
    Initialize a protected function frame
    Usage:
      MyFunc PROC
      LOCAL frame[24]:BYTE
      SETUP_PROTECTION_FRAME 24
      ... (protected code)
      ENDP
    
  VALIDATE_PROTECTION framePtr, offset, exitLabel
    Check canary integrity
    Usage:
      VALIDATE_PROTECTION frame, 16, ProtectionFailed
      ; continue if valid
      ProtectionFailed:
      ; handle attack

FUNCTION-LEVEL PROTECTION:

  PROTECTED_CALL funcName, args...
    Call with automatic canary setup/validation
    Usage:
      PROTECTED_CALL MyFunction, arg1, arg2
    
  CANARY_GUARD_ENTER
    Start protected code block
    Output: eax = guard value
    Usage:
      CANARY_GUARD_ENTER
      mov guardVal, eax
      (protected code)
      CANARY_GUARD_EXIT guardVal, ErrorHandler
    
  CANARY_GUARD_EXIT guardVal, errorLabel
    Validate and exit protected code block

ADVANCED PROTECTION:

  RETURN_MARKER_CREATE
    Create marker for return pointer
    Output: eax = marker value
    
  RETURN_MARKER_VALIDATE expectedMarker, errorLabel
    Validate return marker unchanged
    
  STACK_FRAME_SIGNATURE
    Create frame integrity signature
    Output: eax = signature
    
  FUNCTION_POINTER_GUARD_CREATE
    Guard a function pointer value
    Input: eax = function pointer
    Output: eax = guarded value
    
  FUNCTION_POINTER_GUARD_VALIDATE ptr, guardVal, errorLabel
    Validate function pointer guard

COMPREHENSIVE PROTECTION:

  PROTECTED_PROCEDURE_ENTER frameSize
    Full protection setup (all guards)
    Usage:
      MyFunction PROC
      PROTECTED_PROCEDURE_ENTER 24
      (function body)
      PROTECTED_PROCEDURE_EXIT
      ENDP
    
  PROTECTED_PROCEDURE_EXIT shouldValidate
    Full validation on exit
    Usage:
      PROTECTED_PROCEDURE_EXIT 1
    
  QUICK_PROTECT
    Minimal protection for simple ops
    Usage:
      QUICK_PROTECT
      (critical code section)

SPECIALIZED:

  ATTACK_DETECTED attackCode, attackType
    Record detected attack
    Usage:
      ATTACK_DETECTED 10, "CANARY_MISMATCH"
    
  PARTIAL_OVERWRITE_CHECK original, current, errorLabel
    Detect partial corruption
    Usage:
      PARTIAL_OVERWRITE_CHECK eax, ebx, PartialOverflow

EXAMPLE: Using macros in another MASM project
-----------------------------------------------

MyProtectedMath.asm:
  
  INCLUDE Irvine32.inc
  INCLUDE ProtectionMacros.inc         ; Include protection library
  
  .code
  
  PUBLIC SafeMultiply
  
  SafeMultiply PROC USES eax ebx, a:DWORD, b:DWORD
    LOCAL result:DWORD
    LOCAL guardValue:DWORD
    
    ; Enter protected block
    CANARY_GUARD_ENTER
    mov guardValue, eax
    
    mov eax, a
    mov ebx, b
    imul eax, ebx
    mov result, eax
    
    ; Exit protected block
    CANARY_GUARD_EXIT guardValue, DetectedAttack
    
    mov eax, result
    ret 8
    
  DetectedAttack:
    ATTACK_DETECTED 10, "MATH_CANARY"
    xor eax, eax
    ret 8
  SafeMultiply ENDP
  
  END

MACRO LIBRARY FEATURES:

  + No external dependencies (purely macro expansion)
  + Zero runtime overhead for unused macros
  + Self-contained (only needs Irvine32.inc)
  + Highly reusable across projects
  + Can mix macros in same procedure
  + Proper register preservation
  + Clear error handling patterns

=============================================================================
INTEGRATION ARCHITECTURE
=============================================================================

Current Project Flow:

  AttackISR (main handler)
    ↓
    ├── Records to attack_log.txt (existing)
    ├── Calls RecordAttackPattern (new pattern engine)
    ├── Calls RecordTelemetry (new telemetry buffer)
    └── Checks IsCycleDetected (pattern analysis)

Pattern Detection:
  
  Attack Event
    ↓
  AttackISR called with code
    ↓
  RecordAttackPattern tracks frequency
    ↓
  IsCycleDetected checks for repetition
    ↓
  If cycle: Enhanced logging/response possible

Audit Trail:

  RecordTelemetry maintains circular buffer
    ↓
  Fixed 8KB memory footprint
    ↓
  On demand: DumpTelemetryToFile for forensics
    ↓
  Complete history preserved

Macro Usage (Other Projects):

  Include ProtectionMacros.inc
    ↓
  Use protection macros
    ↓
  Macros expand to inline protection code
    ↓
  No linking to StackGuard modules needed
    ↓
  Pure macro-based integration

=============================================================================
DEPLOYMENT SCENARIOS
=============================================================================

1. CURRENT APPLICATION (StackGuard Console)
   - All three components integrated
   - Attack pattern + telemetry + macros
   - Full protection and analysis

2. OTHER MASM PROJECTS
   - Copy ProtectionMacros.inc only
   - Use macros for protection
   - Independent from StackGuard executable
   - Example: Secure DLL exports, system utilities

3. ENTERPRISE DEPLOYMENTS
   - Deploy with pattern engine + telemetry
   - Central audit log collection
   - Attack pattern analysis for threat detection
   - Cycle detection alerts suspicious behavior

=============================================================================
FILE MANIFEST
=============================================================================

NEW FILES:

AttackPatternEngine.asm
  - Pattern tracking engine module
  - Attack frequency analysis
  - Cycle detection logic
  - ~250 lines

TelemetryBuffer.asm
  - Circular buffer audit trail
  - Entry record/retrieve functions
  - Binary/text dump capability
  - ~280 lines

ProtectionMacros.inc
  - Reusable macro library
  - 20+ protection macros
  - Inline protection code generation
  - ~450 lines (includes comments)

MODIFIED FILES:

AttackISR.asm
  - Added calls to pattern engine
  - Added calls to telemetry buffer
  - Cycle detection check
  - Changes at lines 45-60

build_project.bat
  - Added AttackPatternEngine.asm to compile
  - Added TelemetryBuffer.asm to compile
  - Updated link targets

security_gui.py
  - Updated build_project() method
  - Added new .asm files to build pipeline
  - Changes in lines 647-690

=============================================================================
CONFIGURATION & TUNING
=============================================================================

Attack Pattern Cycle Threshold:
  File: AttackPatternEngine.asm
  Line: cycleThreshold DWORD 5
  Meaning: Declare cycle if same attack occurs 5+ times in a row
  Adjust: Lower value = more sensitive, higher = less sensitive

Telemetry Buffer Size:
  File: TelemetryBuffer.asm  
  Line: MAX_TELEMETRY_ENTRIES EQU 256
  Current: 8KB total footprint
  Increase: More history, more memory
  
Canary Generation Entropy:
  File: ProtectionMacros.inc
  Lines: CREATE_CANARY macro
  Uses: RDTSC XOR with constants
  Strength: Medium (sufficient for local attacks)

=============================================================================
TESTING & VALIDATION
=============================================================================

To validate new components:

1. Compile Project:
   cd c:\LABS\Masm615\Masm615\Project
   build_project.bat
   
   Expected output:
   --- BUILD SUCCESSFUL: SecureProject.exe created ---

2. Run Tests:
   SecureProject.exe 2 10 5 3        ; Test arithmetic with protection
   
   Creates:
   - attack_log.txt (existing)
   - audit_trail.txt (new telemetry)
   
3. Check Integration:
   - Verify attack_log.txt contains entries
   - Verify audit_trail.txt created (telemetry buffer dump)
   - Monitor pattern detection with repeated attacks

4. Test Macros (in separate MASM project):
   - Create new test project
   - INCLUDE ProtectionMacros.inc
   - Use macros in simple procedures
   - Verify successful compilation
   - Run and confirm protection activated

=============================================================================
NEXT STEPS & FUTURE ENHANCEMENTS
=============================================================================

Phase 1 (Current):
  ✓ Attack Pattern Engine
  ✓ Telemetry Buffer
  ✓ Reusable Macros
  ✓ Integration into current project
  ✓ Documentation

Phase 2 (Recommended):
  - Web dashboard for real-time pattern visualization
  - Central log aggregation server
  - Alert/notification system for cycles
  - Performance profiling per operation
  - Macro expansion optimizer

Phase 3 (Enterprise):
  - Multi-system telemetry correlation
  - Machine learning for anomaly detection
  - Compliance reporting (SOC 2, ISO 27001)
  - Macro library for other languages (C, Rust wrappers)
  - Hardware protection integration (Intel MPX, ARM PAC)

=============================================================================
SUPPORT & DOCUMENTATION
=============================================================================

For integrating macros into other projects:
  1. Review ProtectionMacros.inc comments
  2. Copy macro definitions to your project
  3. Study usage examples in comments
  4. Adjust constants for your threat model
  5. Test with simple functions first

For extending the pattern engine:
  1. Modify cycleThreshold constant
  2. Add new attack type tracking
  3. Create custom pattern detection
  4. Integrate with external monitoring

For telemetry analysis:
  1. Parse audit_trail.txt for forensics
  2. Correlate with system logs
  3. Feed into SIEM systems
  4. Build custom dashboards

=============================================================================
END OF DOCUMENTATION
=============================================================================
