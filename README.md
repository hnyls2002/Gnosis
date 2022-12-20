#  Gnosis<img src="./doc/assets/Item_Venti_Gnosis.png" height="40" align=center />

<img src="./doc/assets/Character_Venti_Thumb.png" height="80" align=center />

`An item used by The Seven to directly resonate with Celestia, and is proof of an archon's status as one of The Seven.`
***

### AssHeart

```
_________________________________________________________________________________________________________________________
_________________________________________________________________________________________________________________________
_________________________________________________________________________________________________________________________
_________________________________________________________________________________________________________________________
_________________________________________________________________________________________________________________________
_________________________________________________________________________________________________________________________
_______________________________#***##*********++=_______________________#**************++-_______________________________
___________________________#############**********+++-_____________############**********++++-___________________________
________________________####################********++++=_______*###############*********++++++=-________________________
______________________#######################*********+++++___##################**********++++++==-______________________
_____________________#######################*****************##################*********+++++++====-+____________________
___________________########################*****************###############************+*+++++++===--:___________________
__________________########################*#****************#############**************+++++++++====--:__________________
_________________###########################***************#*#########****************++++++++++====---:_________________
________________###########################*******************######**#*************+++++++++++=====---:=________________
________________#########################*******************#*#*###****************++++++++++=======---::________________
_______________#########################*#*****************************************+++++++++========---::=_______________
_______________*^C🤡

```
### Performance

Cost time is directly read from the result of `run_test_fpga.sh` on my laptop, `WSL 1`, `Ubuntu 20.04.1 LTS`, so it may be relative to the machine's performance.

The testcast which is not listed in the table costs nearly no time (0s) to run.

| testcase   | cost time(s) |
| ---------- | ------------ |
| basic_opt1 | 0.015625     |
| bulgarian  | 0.265625     |
| hanoi      | 0.406250     |
| heart      | 197.125000   |
| pi         | 0.578125     |
| qsort      | 1.250000     |
| queens     | 0.296875     |
| superloop  | 0.140625     |
| tak        | 0.062500     |
| testsleep  | 3.890625     |
| uartboom   | 0.171875     |

### Notice

- For some unknown reason, when testing testcases continuously, the testcases which contains input (hanoi, statement_test, tak, etc.) will fail, so I have to run them separately (reprogram the device in vivado or press the reset button on FPGA board).
- The ouput of `testsleep` is correct (the second line is 10), but the actual time cost is not 10s, it's 3.89s. I don't know why.

### Significant Bugs

- hci seems to have some bugs, but it doesn't matter.
- Thanks to my roommate to help me use verilator tool to check the code.
- The handle to jump-wrong will cause so many bugs before final done. I have listed them in commit log.
- The rename id bugs : use head and tail (both integer) in ROB to indicate the id of every instruction, and use tail - head + 1 to find the number of elements in ROB, however, when running heart, both head and tail will overflow.
- Input's commit : an input should be loaded after it is going to be committed, otherwise when jump wrong happens, the input will be lost.

### Modules Design

- MC : Sequential logic only moves the step (LSB_step, IF_step) forward, and according to the number of bytes, the last step will send a signal lsb_done to IF or LSB, then MC will stall for one cycle. Combinational logic directly sends address and other information to RAM, which would significantly reduce the time cost.

- IF : The instruction fetcher contains an ICache. When receiving an instruction (from MC or ICache), IF sends the instruction to ID (sequentially). Noticing that the three buffers (RS/LSB/ROB) need to pass a signal to IF to indicate whether they will be full in the next cycle.

- VQ fetcher : fetch the actual data V or renamed id Q from RF and ROB, this process is implemented in RF. Maybe I can split it (just fetch from RF and ROB) to make the WNS better)
    - Not renamed, fetch from register
    - Renamed and ROB ready, fetch from ROB
    - Execution cdb arrives, fetch from ex_cdb
    - Memory cdb arrives, fetch from ld_cdb
    - ROB commit message arrives, fetch from the message

- LSB : 
  - If jump_wrong_stall, then stop adding instruction and just handle the store (or load) saved in LSB.
  - A store is sended to ROB when it's ready and will be executed after ROB commit it.