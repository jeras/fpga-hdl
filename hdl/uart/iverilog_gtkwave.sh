#!/bin/bash

# cleanup first
rm uart.out
rm uart.vcd

# compile the verilog sources (testbench and RTL)
iverilog -g2012 -o uart.out \
uart_tb.sv \
uart_tx.sv \
uart.sv

# run the simulation
vvp uart.out

# open the waveform and detach it
#gtkwave uart.vcd gtkwave.sav &
