### Bugs

~~什么傻逼hci.v~~

程序的终止端口0x30004，如果不先进行一次memory access, 会导致`io_en`一直是`x`电位。程序无法正常终止。

~~但似乎也必须要先读取指令~~

~~:clown_face: :clown_face: :clown_face: :clown_face: :clown_face:~~

## modules design

### `mem_ctrl`
Fetch ins and memory access. When conflict, `mem_ctrl` should randomly choose one to execute.

**Instruction contains four bytes**, so it can't be divided. We need to specify the request so that `mem_ctrl` can handling 4/2/1 bytes memory access.

### `inst_fetcher`

`inst_cache`

### `dispatcher` : get `ins_data` from `i_fetcher` and dispatch instruction.

`decoder` : decode the instruction first

then send the arguments to the corresponding modules

### `RS`

### `LSB`