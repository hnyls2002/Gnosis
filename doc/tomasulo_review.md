# Tomasulo Review

### Hazards

- `RAW` : true dependency.
- `WAW`,`WAR` : false dependency.

### CPU basic components
- `common registers`
- `memory`
- `ALU`

### Tomasulo components

- `RS` : Reservation Station. 
- `LSB` : Load Store Buffer.
- `RegFile` : Register Statue (busy and renamed id)
- `ROB` : Reorder Buffer
- `CDB` : Common data bus

### Renaming and `RS`

Fake hazards can be resolved by register renaming.

All instructions are **issued by order**.

When issuing an instruction : 

- Every instruction was placed in a `RS` line.
    - Have `rs` and `rd`.
    - source : `V1`,`V2` for direct value, `Q1`,`Q2` for register renaming.

- `rs`: if `busy`, then waiting for the data. The data will be ready when some instruction in `RS` done.

- `rd` : update the `RegFile`, which means the `rd` is `busy` (refresh whether it is now `busy` or not).

### Accurate breakpoint and in-order commit

For branch prediction, all instrcutions are commit by order.

When commit : 

- modify the `reg`.
- access the `memory`.

### `ROB`

A `rs`'s renamed `id` means where is the **not yet executed instruction** (that is "waiting for this instruction done").

It can be stored in `RS` or `LSB`, where to get it ? 

- When not renamed, `busy` is `false`, just go to `reg`.
- When executed but not commited, `busy` is `true`, go to `ROB`, `ROB` is ready.
    - So when execution done, `ROB` need to have its result.
- When not yet executed, `busy` is `true`, `ROB` is not ready.
    - Waiting for the execution done.

### Execution

- Instructions in `RS` or `LSB` is ready : execute.
- Execution done : `CDB` to update some components.
    - `ROB` : update the result.
    - `RS` : update the `Q` to `V` (direct value).
    - `LSB` : update the `Q` to `V` (direct value).

### About `ROB` , in-order commit and renaming

- renaming `id` : instead of using the id in `RS` or `ROB`, we use the id in `ROB`.
    - It is the **issue id**.
    - Execution done : update the value in `ROB` by `id`.
    - Execution done : traverse the `RS` and `LSB` to update the `Q`(`Q` = `id`) to `V` (direct value).

- regfile
    - `busy` means whether is commited.

- So `reg` is CPU solid component, when accurate breakpoint, it should be sync with instructions.
- `data` in ROB is the current result, may not be commited at last(**branch misprediction**), but we still need to have it for the later instruction to fetch the value.