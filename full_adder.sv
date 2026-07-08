/*******************************************************/
/* ECE 327/627: Digital Hardware Systems - Spring 2026 */
/* Lab 1 - Part 1                                      */
/* Full adder module                                   */
/*******************************************************/

module full_adder (
    input a,    // First operand bit
    input b,    // Second operand bit
    input cin,  // Input Carry bit
    output s,   // Output sum bit
    output cout // Output carry bit
);

/******* Your code starts here *******/

assign s = a ^ b ^ cin; 
assign cout = (a & b) | (a & cin) | (b & cin); 

/******* Your code ends here ********/

endmodule
