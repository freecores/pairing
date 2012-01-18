// fun.v: Have you got fun reading the code ?
`include "inc.v"

// turn "00000001111111111111111" into "00000001000000000000000"
module func6(clk, in, out);
    input clk, in;
    output out;
    reg reg1, reg2;
    always @ (posedge clk)
      begin
        reg1 <= in; reg2 <= reg1;
      end
    assign out = {reg2,reg1}==2'b01 ? 1 : 0;
endmodule

