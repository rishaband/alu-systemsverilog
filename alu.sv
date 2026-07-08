/*******************************************************/
/* ECE 327/627: Digital Hardware Systems - Spring 2026 */
/* Lab 1 - Part 3                                      */
/* Shift-Left, Add, Subract ALU module                 */
/*******************************************************/

module alu # (
    parameter DATAW = 32 // Bitwidth of ALU operands
)(
    input  clk,                   // Input clock signal
    input  rstn,                  // Active-low reset signal
    input  [DATAW-1:0] i_dataa,   // First operand (A)
    input  [DATAW-1:0] i_datab,   // Second operand (B)
    input  [1:0] i_op,            // Operation code (00: A+B, 01: A-B, 10: A*B, 11: A^2)
    output [DATAW-1:0] o_result   // ALU output
);

// Remember that you are required to register all inputs and outputs of the ALU and use 
// the adder/subtractor module you implemented in Part 2 of this lab.

/******* Your code starts here *******/

logic [DATAW-1:0] dataa_reg; 
logic [DATAW-1:0] datab_reg; 
logic [1:0] op_reg; 
 

always_ff @(posedge clk) begin 
    if (!rstn) begin
        dataa_reg <= '0; 
        datab_reg <= '0; 
        op_reg <= '0; 
    end else begin
        dataa_reg <= i_dataa; 
        datab_reg <= i_datab; 
        op_reg <= i_op; 
    end 
end 


// instantiate add_sub for adding and subtracting 


logic [DATAW-1:0] addsub_result; 

add_sub #(.DATAW(DATAW)) addsub_inst (
    .i_dataa (dataa_reg), 
    .i_datab (datab_reg),
    .i_op (op_reg[0]), // op[0] = 0 -> add, op[0]=1 -> subtract
    .o_result (addsub_result)
);   

// combinational intermediate results 

logic [DATAW-1:0] mul_result; 
logic [DATAW-1:0] sqr_result; 

always_comb begin 
    mul_result = dataa_reg * datab_reg; 
    sqr_result = dataa_reg * dataa_reg; 
end 

// register output 

logic [DATAW-1:0] result_reg; 
always_ff @(posedge clk) begin 
    if(!rstn) begin
        result_reg <= '0;
    end else begin
        
        case (op_reg) // can also use an if else block here but case makes it easier to read 
            2'b00: result_reg <= addsub_result; // addition, using our own convention here, we can easily change this to a different operation 
            2'b01: result_reg <= addsub_result; // subtraction 
            2'b10: result_reg <= mul_result; // multiplication 
            2'b11: result_reg <= sqr_result; // squaring 
        endcase
        
    end 
end 

assign o_result = result_reg; // just copy the signal at the end with a continous assignment  
            

/******* Your code ends here ********/

endmodule
