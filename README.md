# VerySimpleCPU
The object of this project is to design, implement, verify and synthesize a fully
functional Very Simple CPU (VSCPU) using Verilog HDL. The design will support the
standard VSCPU instruction set architecture (ISA) and will be extended with two new
instructions: SUB and SUBi.  
The EDAPLAYGROUND link of the project: [https://edaplayground.com/x/RD59](https://edaplayground.com/x/RD59)

## Full Datapath and Control Signal Explanation
The design has 5 states: Fetch, Decode, Load R1, Load R2 and Execute states. Below
given explanations for each state:

### State 0: Fetch
- Purpose: Retrieve the instruction from memory.
- Operation: Place the current value of PC into memory address bus (addr = PC).
- Next State: Transition to Decode state.

### State 1: Decode
- Purpose: To capture the fetched instruction and prepare for operand fetching.
- Operation: Load the 32-bit instruction from the data bus into the IW register (IWN = data_fromRAM). Load the address that will be loaded into R1 (addr = data_fromRAM[27:14] // Different for CP, CPi and CPI).
- Next State: Transition to Load R1/R2 state. 

### State 2: Load R1/R2
- Purpose: To load the first source operand into the internal register R1 and/or R2.
- Operation: The data arriving from memory is latched into the R1 register (R1N = data_fromRAM). If operation is immediate (except for CPIi), load the R2 register with immediate value (R2N = IW[13:0]), else load the address that will be loaded into R2 (addr = IW[13:0]).
- Next State: Transition to Load R2 state if operation is non-immediate, if it is skip Load
R2 state and transition to Execute state.

### State 3: Load R2
- Purpose: To load the first source operand into the internal register R2.
- Operation: The data arriving from memory is latched into the R2 register (R2N = data_fromRAM).
- Next State: Transition to Execute state.

### State 4: Execute
- Purpose: To perform the ALU operation and write the result back to memory.
- Operation: The ALU performs the specific operation (ADD, NAND, MUL, etc.) based on the opcode (data_toRAM = ... // Corresponding ALU operation). Write enable is set to 1 (wrEn = 1’b1 // Except for BZJ and BZJi), and the result is written to RAM . The address bus is set to the destination (addr = IW[27:14] // Except for CPIi). Program Counter is incremented (PCN = PC + 14’d1) or updated to a new target for branch (BZJ) instructions
- Next State: Transition back to Fetch state to begin a new instruction cycle

## Implementation of Instructions

### Register
```
reg [31:0] IW; // Instruction Word
reg [13:0] PC; // Program Counter
reg [31:0] R1; // General-Purpose Register
reg [31:0] R2; // General-Purpose Register
```

### Instruction Word
Each instruction has a fixed length of 32.
```
IW[31:29] // opcode
IW[28] // im
IW[27:14] // A
IW[13:0] // B
```

### Implementations
- ADD (opcode: 000, im: 0)
```
R1 <- mem[ A ]
R2 <- mem[ B ]
mem[ A ] <- (R1 + R2)
PC <- PC + 1
```

- ADDi (opcode: 000, im: 1)
```
R1 <- mem[ A ]
R2 <- B
mem[ A ] <- (R1 + R2)
PC <- PC + 1
```

- NAND (opcode: 001, im: 0)
```
R1 <- mem[ A ]
R2 <- mem[ B ]
mem[ A ] <- ~(R1 & R2)
PC <- PC + 1
```

- NANDi (opcode: 001, im: 1)
```
R1 <- mem[ A ]
R2 <- B
mem[ A ] <- ~(R1 & R2)
PC <- PC + 1
```

- SRL (opcode: 010, im: 0)
```
R1 <- mem[ A ]
R2 <- mem[ B ]
mem[ A ] <- (R2 < 32) ? (R1 >> R2) : (R1 << (R2-32))
PC <- PC + 1
```

- SRLi (opcode: 010, im: 1)
```
R1 <- mem[ A ]
R2 <- B
mem[ A ] <- (R1 + R2)
PC <- PC + 1
```

- LT (opcode: 011, im: 0)
```
R1 <- mem[ A ]
R2 <- mem[ B ]
mem[ A ] <- (R1 < R2) ? 1 : 0
PC <- PC + 1
```

- LTi (opcode: 011, im: 1)
```
R1 <- mem[ A ]
R2 <- B
mem[ A ] <- (R1 < R2) ? 1 : 0
PC <- PC + 1
```

- CP (opcode: 100, im: 0)
```
R2 <- mem [ B ]
mem[ A ] <- R2
PC <- PC + 1
```

- CPi (opcode: 100, im: 1)
```
R2 <- B
mem[ A ] <- R2
PC <- PC + 1
```

- CPI (opcode: 101, im: 0)
```
R1 <- mem[ B ]
R2 <- mem[ R1 ]
mem[ R1 ] <- R2
PC <- PC + 1
```

- CPIi (opcode: 101, im: 1)
```
R1 <- mem[ A ]
R2 <- mem[ B ]
mem[ A ] <- (R1 + R2)
PC <- PC + 1
```

- BZJ (opcode: 110, im: 0)
```
R1 <- mem[ A ]
R2 <- mem[ B ]
PC <- (R2 == 0) ? R1 : (PC + 1)
```

- BZJi (opcode: 110, im: 1)
```
R1 <- mem[ A ]
R2 <- B
PC <- (R2 == 0) ? R1 : (PC + 1)
```

- MUL (opcode: 111, im: 0)
```
R1 <- mem[ A ]
R2 <- mem[ B ]
mem[ A ] <- (R1 * R2)
PC <- PC + 1
```

- MULi (opcode: 111, im: 1)
```
R1 <- mem[ A ]
R2 <- B
mem[ A ] <- (R1 * R2)
PC <- PC + 1
```

#### Extended Instructions

- SUB (opcode: 000, im: 0, IW[13] = 1)
```
R1 <- mem[ A ]
R2 <- mem[ B ]
mem[ A ] <- (R1 - (~R2 + 1))
PC <- PC + 1
```

- SUBi (opcode: 000, im: 1, IW[13] = 1)
```
R1 <- mem[ A ]
R2 <- B
mem[ A ] <- (R1 - (~R2 + 1))
PC <- PC + 1
```
