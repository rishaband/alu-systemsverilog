/*******************************************************/
/* ECE 327/627: Digital Hardware Systems - Spring 2026 */
/* Lab 1 - Part 2                                      */
/* Multi-bit adder/subtractor module                   */
/*******************************************************/

module add_sub # (
    parameter DATAW = 2 // Bitwidth of adder/subtractor operands
)(
    input  [DATAW-1:0] i_dataa,  // First operand (A)
    input  [DATAW-1:0] i_datab,  // Second operand (B)
    input  i_op,                 // Operation (0: A+B, 1: A-B)
    output [DATAW-1:0] o_result  // Addition/Subtraction result
);

/******* Your code starts here *******/

wire [DATAW-1:0] b_xor; // this creates a wire bus the same width as the inputs 
wire [DATAW:0] carry; // wire bus that is one bit wider than the inputs to handle the carry 

assign carry[0] = i_op;  // sets the very first carry-in to i_op, i_op = 0? normal addition else? twos compliment 

genvar i; // variable for the  loop

generate 
for (i = 0; i < DATAW; i++) begin: adder_chain // create multiple instances of DATAW, does not run one at a time 
    assign b_xor[i] = i_datab[i] ^ i_op; // for each bit position i, XOR that bit of i_datab with i_op
    // so if i_op = 0: bit XOR 0 = bit, then this remains unchanged and gets used for normal addition 
    // if i_op = 1: bit XOR 1 = - bit, it gets inverted and then we go into twos compliment 
    full_adder fa (
        .a (i_dataa[i]), 
        .b (b_xor[i]), 
        .cin (carry[i]), 
        .s (o_result[i]), 
        .cout(carry[i + 1]) // feed into the next adder 
    ); 
    
end 
endgenerate
    
    


/******* Your code ends here ********/

endmodule

