@echo off
powershell -Command "./nasm main.asm -o flappy.com"
REM Start DOSBox with the necessary commands to mount the directory, assemble the code, and run the programD
DOSBoxPortable.exe -c "flappy"
pause