./build_test.sh ${1%.*}
./run_test.sh ${1%.*}
iverilog src/*.v src/common/*/*.v sim/*.v -o test/a.out
./test/a.out