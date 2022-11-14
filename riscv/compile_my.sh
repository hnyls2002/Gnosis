sh build_test.sh ${1%.*}
sh run_test.sh ${1%.*}
iverilog src/definitions.v src/*.v src/common/*/*.v sim/*.v -o test/a.out