@echo off
powershell -Command "./nasmW main.asm -o main.com"
REM Start DOSBox with the necessary commands to mount the directory, assemble the code, and run the programD
DOSBoxPortable.exe -c "main"
pause