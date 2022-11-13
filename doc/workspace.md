# Something to be installed

### Extensions in vscode

- `verilog-format`
- `verilog-HDL`

### `eclipse` or `vivado` ?

- 似乎`wavetrace`的八根线就已经够用了（听说

### riscv-tool-chain
- `install path` : `/opt/riscv/` 
- Added the path `/opt/riscv/bin` in the `.zshrc` file

~~傻逼~~交叉编译，`github.com`下载不下来，镜像站也下载不下来。

晚上用了lyl的直接编译好的文件拖进去放在`/opt/riscv`里面，结果有个文件没有拖进去。。。 找了一个小时

`.build_test.sh` 里面有个 `riscv32-unknown-elf/8.2.0/` 会因为版本错误的问题而导致找不到  `-lgcc` ，又找了我好久，把 `8.2.0` 改成 `10.1.0` 就解决了。

~~草，这玩意儿竟然折腾了一下午~~

### make file

### shell instructions

### vcd file