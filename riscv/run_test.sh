#!/bin/sh
# build testcase
./build_test.sh $@

# copy test input
if [ -f ./testcase/$@.in ]; then cp ./testcase/$@.in ./test/test.in; fi

# copy test output
if [ -f ./testcase/$@.ans ]; then cp ./testcase/$@.ans ./test/test.ans; fi

# add your own test script here
# Example:
# - iverilog/gtkwave/vivado
# - diff ./test/test.ans ./test/test.out

# compile and run
iverilog src/Def.v src/*.v src/common/*/*.v sim/*.v -o test/a.out
./test/a.out

# dump waveform
# vvp test/a.out