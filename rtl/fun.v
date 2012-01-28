// fun.v: Have you got fun reading the code ?
`include "inc.v"

// turn "00000001111111111111111" into "00000001000000000000000"
module func6(clk, reset, in, out);
    input clk, reset, in;
    output out;
    reg reg1, reg2;
    always @ (posedge clk)
        if (reset)
          begin
            reg1 <= 0; reg2 <= 0;
          end
        else
          begin
            reg2 <= reg1; reg1 <= in;
          end
    assign out = {reg2,reg1}==2'b01 ? 1 : 0;
endmodule

