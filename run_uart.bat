
@echo off
setlocal

set "GHDL=C:\Users\Admin\Tools\GHDL\bin\ghdl.exe"
set "GHDL_PREFIX=C:\Users\Admin\Tools\GHDL\lib\ghdl"

cd /d "%~dp0vhdl" || exit /b 1

echo Compiling UART...
"%GHDL%" -a --std=08 uart_tx.vhd uart_rx.vhd ..\tb\tb_uart.vhd || exit /b 1

echo Preparing testbench...
"%GHDL%" -e --std=08 tb_uart || exit /b 1

echo Running simulation...
"%GHDL%" -r --std=08 tb_uart --vcd=..\simulation\uart.vcd || exit /b 1

echo UART simulation completed successfully.
