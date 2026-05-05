@echo off

:: 1. Assemble all project files
:: Irvine32.inc is located in ..\INCLUDE
ml /c /coff /Cp /Zi /I "..\INCLUDE" Main.asm InputSecurity.asm ArithmeticOps.asm BuisnessLogic.asm AttackISR.asm AttackPatternEngine.asm AttackerSimulation.asm

if errorlevel 1 goto terminate

:: 2. Link all .obj files
:: Irvine32.lib is located in ..\LIB
..\LINK32.EXE /SUBSYSTEM:CONSOLE /LIBPATH:"..\LIB" Main.obj InputSecurity.obj ArithmeticOps.obj BuisnessLogic.obj AttackISR.obj AttackPatternEngine.obj AttackerSimulation.obj Irvine32.lib kernel32.lib user32.lib /OUT:SecureProject.exe

if errorlevel 1 goto terminate

echo.
echo --- BUILD SUCCESSFUL: SecureProject.exe created ---
echo.
pause
exit

:terminate
echo.
echo --- BUILD FAILED ---
pause