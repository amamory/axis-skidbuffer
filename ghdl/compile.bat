
ghdl --version

:: delete
del /Q *.vcd &
del /Q *.o &
del /Q *.exe &
del /Q *.cf &

:: analyze
ghdl -a skidbuffer.vhd
ghdl -a skidbuffer.vhd
ghdl -a tb_skid.vhd
:: elaborate
ghdl -e skidbuffer
ghdl -e skidbuffer
ghdl -e tb_skid
:: run
ghdl -r tb_skid --vcd=wave.vcd --stop-time=1us
gtkwave wave.vcd waveform.gtkw

:: delete
del /Q *.o &
del /Q *.exe &
del /Q *.cf &
