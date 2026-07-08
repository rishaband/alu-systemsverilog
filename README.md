# building an alu in verilog

> SystemVerilog implementation of a 32-bit ALU built from a full adder, supporting addition, subtraction, multiplication, and squaring — with registered pipeline and FPGA synthesis.

---

this writing covers how to make a very simple arithmetic logical unit in systemverilog using full adder. an alu is the core building block inside a processor. it is primarily responsible for performing mathematical and logical operations on binary data. to implement this alu, we need to implement 2 other different parts which include a full adder and multi-bit adder.

---

## part 1: full adder implementation

a full adder is the most fundamental building block of arithmetic circuits. before a multi-bit adder can be implemented, the system needs to add at a single bit level. so for example, the system wants to perform 19 + 13. in this case, the system would add the right most column first (9+3=12), write down 2 and carry over 1 to the next column. then the system would add the next column including the carry. binary addition works the same way but with 0's and 1's. a key thing to keep in mind is the carry. this carry means more bits (+1) are needed to handle it if a column chain wants to be implemented. so for this full adder, the following i/o exists:

```
input  a,    // first bit being added
input  b,    // second bit being added
input  cin,  // carry coming IN from the previous column
output s,    // sum bit result
output cout  // carry going OUT to the next column
```

there is a need to chain multiple columns together so 3 inputs have to be used rather than 2 inputs, which is a half adder. to actually implement this full adder, 2 equations are required; 1 for the output and 1 for the carry. these expressions can be derived from the truth table below using kmaps (not shown here).

```
a  b  cin | cout  s
0  0   0  |  0    0    (0+0+0 = 0,  no carry)
0  0   1  |  0    1    (0+0+1 = 1,  no carry)
0  1   0  |  0    1    (0+1+0 = 1,  no carry)
0  1   1  |  1    0    (0+1+1 = 2,  write 0 carry 1)
1  0   0  |  0    1    (1+0+0 = 1,  no carry)
1  0   1  |  1    0    (1+0+1 = 2,  write 0 carry 1)
1  1   0  |  1    0    (1+1+0 = 2,  write 0 carry 1)
1  1   1  |  1    1    (1+1+1 = 3,  write 1 carry 1)
```

these expressions come out to be the following:

- **Sum** — output is 1 when an odd number of inputs are 1 → XOR → `s = a ^ b ^ cin`
- **Carry** — output is 1 when at least two inputs are 1 → majority function → `cout = (a & b) | (a & cin) | (b & cin)`

in verilog, the code is really simple. you can use `assign` (continuously combinational logic) to set the sum and carry output:

```systemverilog
module full_adder (
    input  a,
    input  b,
    input  cin,
    output s,
    output cout
);
    assign s    = a ^ b ^ cin;
    assign cout = (a & b) | (a & cin) | (b & cin);
endmodule
```

a full adder is stateless — it has no memory, clock, or history. given the same inputs, it will always produce the same outputs instantly. this is crucial because in a multi-bit adder, the carry output needs to propagate through the chain instantly.

---

## part 2: multi-bit adder and subtractor

a single full adder only handles 1 bit. real numbers can be 8, 16, 32... bits wide. this multi-bit adder and subtractor handles a parameterized `DATAW`-bit number, implemented purely as a chain of full adder instances using `generate`. i/o:

```
input  [DATAW-1:0] i_dataa,  // first full number (e.g. 8 bits wide)
input  [DATAW-1:0] i_datab,  // second full number
input              i_op,     // 0 = add, 1 = subtract
output [DATAW-1:0] o_result  // the result
```

since only full adders are used, `DATAW` full adders are needed — one per bit column — connected like:

```
bit7        bit6        bit1        bit0
  ┌──────┐    ┌──────┐    ┌──────┐    ┌──────┐
  │  FA  │◄───│  FA  │◄───│  FA  │◄───│  FA  │◄── carry[0]=i_op
  └──────┘    └──────┘    └──────┘    └──────┘
     │            │           │           │
  result[7]   result[6]   result[1]   result[0]
```

the carry ripples left through every adder — hence the name **ripple carry adder**. each full adder must wait for the carry from the adder to its right before producing its final result.

**subtraction via two's complement:** A - B = A + (~B) + 1. XOR gates handle the inversion and the carry-in handles the +1:

```
b_xor[i] = i_datab[i] XOR i_op
i_op=0: b XOR 0 = b      → B unchanged    → addition
i_op=1: b XOR 1 = NOT b  → B inverted     → first step of negation

carry[0] = i_op
i_op=0: carry[0] = 0  → no extra addition    → A + B
i_op=1: carry[0] = 1  → adds 1 to ~B         → A + ~B + 1 = A - B
```

full implementation:

```systemverilog
module add_sub #(
    parameter DATAW = 2
)(
    input  [DATAW-1:0] i_dataa,
    input  [DATAW-1:0] i_datab,
    input              i_op,
    output [DATAW-1:0] o_result
);
    wire [DATAW-1:0] b_xor;
    wire [DATAW:0]   carry;

    assign carry[0] = i_op;

    genvar i;
    generate
        for (i = 0; i < DATAW; i++) begin : adder_chain
            assign b_xor[i] = i_datab[i] ^ i_op;
            full_adder fa (
                .a    (i_dataa[i]),
                .b    (b_xor[i]),
                .cin  (carry[i]),
                .s    (o_result[i]),
                .cout (carry[i + 1])
            );
        end
    endgenerate
endmodule
```

this part is purely combinational — inputs go in, outputs come out immediately with no timing control. to build the full ALU, we wrap this in a clocked, registered system by adding:

1. input registers
2. output registers
3. additional operations (multiply, square)
4. a selection mechanism

---

## part 3: building the alu

the ALU supports four operations on a `DATAW`-bit number:

| op code | operation      |
|---------|---------------|
| `2'b00` | addition (A + B) |
| `2'b01` | subtraction (A - B) |
| `2'b10` | multiplication (A * B) |
| `2'b11` | squaring (A²) |

the key difference from parts 1 & 2 is that this implementation is **sequential** — it has a clock and registers.

i/o:

```
input              clk,     // clock signal
input              rstn,    // active-low synchronous reset
input  [DATAW-1:0] i_dataa, // first operand
input  [DATAW-1:0] i_datab, // second operand
input  [1:0]       i_op,    // 2-bit operation selector
output [DATAW-1:0] o_result // result
```

**why register inputs and outputs?** this is pipelining and timing closure. in purely combinational logic, signals propagate through gates with delay — for larger circuits these delays add up. by registering inputs and outputs we:

1. sample inputs on the clock rising edge
2. hold outputs stable between clock edges
3. allow the synthesis tool to perform timing analysis

the tradeoff is latency — results take 2 clock cycles to appear (one to register inputs, one to register outputs). throughput remains 1 operation per clock cycle once the pipeline is full.

full ALU implementation:

```systemverilog
module alu #(
    parameter DATAW = 32
)(
    input  clk,
    input  rstn,
    input  [DATAW-1:0] i_dataa,
    input  [DATAW-1:0] i_datab,
    input  [1:0]       i_op,
    output [DATAW-1:0] o_result
);
    logic [DATAW-1:0] dataa_reg, datab_reg;
    logic [1:0]       op_reg;

    // register inputs
    always_ff @(posedge clk) begin
        if (!rstn) begin
            dataa_reg <= '0;
            datab_reg <= '0;
            op_reg    <= '0;
        end else begin
            dataa_reg <= i_dataa;
            datab_reg <= i_datab;
            op_reg    <= i_op;
        end
    end

    // instantiate add/sub
    logic [DATAW-1:0] addsub_result;
    add_sub #(.DATAW(DATAW)) addsub_inst (
        .i_dataa  (dataa_reg),
        .i_datab  (datab_reg),
        .i_op     (op_reg[0]),
        .o_result (addsub_result)
    );

    // combinational intermediate results
    logic [DATAW-1:0] mul_result, sqr_result;
    always_comb begin
        mul_result = dataa_reg * datab_reg;
        sqr_result = dataa_reg * dataa_reg;
    end

    // register output
    logic [DATAW-1:0] result_reg;
    always_ff @(posedge clk) begin
        if (!rstn) begin
            result_reg <= '0;
        end else begin
            case (op_reg)
                2'b00: result_reg <= addsub_result;
                2'b01: result_reg <= addsub_result;
                2'b10: result_reg <= mul_result;
                2'b11: result_reg <= sqr_result;
            endcase
        end
    end

    assign o_result = result_reg;
endmodule
```

data flow across clock cycles:

```
Cycle 1 - Rising edge:
    i_dataa, i_datab, i_op → sampled into dataa_reg, datab_reg, op_reg

Between cycles 1 and 2 - Combinational:
    dataa_reg, datab_reg → add_sub      → addsub_result (instantly)
    dataa_reg, datab_reg → *            → mul_result    (instantly)
    dataa_reg            → *            → sqr_result    (instantly)

Cycle 2 - Rising edge:
    case(op_reg) selects correct result → latched into result_reg
    result_reg → o_result (via assign)
```

---

## fpga resource utilization

synthesized and run on the Kria KV260 FPGA :

| resource | used | available | utilization |
|----------|------|-----------|-------------|
| LUT      | 86   | 117,120   | 0.07%       |
| FF       | 98   | 234,240   | 0.04%       |
| DSP      | 3    | 1,248     | 0.24%       |
| I/O      | 100  | 189       | 52.91%      |

- **LUT (lookup tables):** implement the combinational logic — XOR gates, carry logic, case statement mux. 86 is tiny.
- **FF (flip flops):** the registers. `dataa_reg` (32) + `datab_reg` (32) + `op_reg` (2) + `result_reg` (32) = 98.
- **DSP blocks:** dedicated hardware multipliers. the `*` operator for multiplication and squaring maps here — far more efficient than LUTs for multiplication.
- **I/O pins:** 52.91% is high but expected — 32-bit wide buses require a lot of physical pins.

**key takeaway:** the ALU uses <1% of the FPGA's LUTs and flip flops. this shows how much headroom modern FPGAs have.

---

*rishab anand*
