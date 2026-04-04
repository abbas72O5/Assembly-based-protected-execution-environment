@echo off

:: 1. Assemble all four files
:: Irvine32.inc is located in ..\INCLUDE
ml /c /coff /Cp /Zi /I "..\INCLUDE" Main.asm InputSecurity.asm ArithmeticOps.asm SecurityProvider.asm

if errorlevel 1 goto terminate

:: 2. Link all four .obj files
:: Irvine32.lib is located in ..\LIB
..\LINK32.EXE /SUBSYSTEM:CONSOLE /LIBPATH:"..\LIB" Main.obj InputSecurity.obj ArithmeticOps.obj SecurityProvider.obj Irvine32.lib kernel32.lib user32.lib /OUT:SecureProject.exe

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