### extensions in vscode

- verilog-format
    - 这东西bug太多了
    - settings 打成 setting 不说，你至少给个正确的 if else 的缩进吧
    - 直接把 verilog-format 给禁用了，自己缩进，不美观就算了吧
- verilog-HDL
    - 不支持linting

### eclipse or vivado

- 先暂时用wavetrace 的八根线吧

### riscv-tool-chain
- install path : `/opt/riscv/` 
- add the path `/opt/riscv/bin` in the `.zshrc` file

交叉编译库因为国内的问题，换了很多种方式都下载不下来。 

晚上用了lyl的直接编译好的文件拖进去放在`/opt/riscv`里面，结果有个文件没有拖进去，找了一个小时

build_test.sh 里面有个 `riscv32-unknown-elf/8.2.0/` 会因为版本错误的问题而导致找不到  `-lgcc` ，又找了我好久，把 8.2.0 改成 10.1.0 就解决了。