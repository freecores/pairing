`include "inc.v"

// c == a+b in GF(3^{3*M})
module f33m_add(a, b, c);
    input [`W3:0] a,b;
    output [`W3:0] c;
    wire [`WIDTH:0] a0,a1,a2,b0,b1,b2,c0,c1,c2;
    assign {a2,a1,a0} = a;
    assign {b2,b1,b0} = b;
    assign c = {c2,c1,c0};
    f3m_add
        ins1 (a0,b0,c0),
        ins2 (a1,b1,c1),
        ins3 (a2,b2,c2);
endmodule

// c == a-b in GF(3^{3*M})
module f33m_sub(a, b, c);
    input [`W3:0] a,b;
    output [`W3:0] c;
    wire [`WIDTH:0] a0,a1,a2,b0,b1,b2,c0,c1,c2;
    assign {a2,a1,a0} = a;
    assign {b2,b1,b0} = b;
    assign c = {c2,c1,c0};
    f3m_sub
        ins1 (a0,b0,c0),
        ins2 (a1,b1,c1),
        ins3 (a2,b2,c2);
endmodule

// c == a*b in GF(3^{3*M})
module f33m_mult(clk, reset, a, b, c, done);
    input clk, reset;
    input [`W3:0] a, b;
    output reg [`W3:0] c;
    output reg done;

    reg [`WIDTH:0] x0, x1, x2, x3, x4, x5;
    wire [`WIDTH:0]  a0, a1, a2,
                     b0, b1, b2,
                     c0, c1, c2,
                     v1, v2, v3, v4, v5, v6,
                     nx0, nx2, nx5,
                     d0, d1, d2, d3, d4;
    reg [6:0] K;
    wire e0, e1, e2, 
         e3, e4, e5,
         mult_done, p, rst;
    wire [`WIDTH:0] in0, in1;
    wire [`WIDTH:0] o;
    reg mult_reset, delay1, delay2;

    assign {e0,e1,e2,e3,e4,e5} = K[6:1];
    assign {a2,a1,a0} = a;
    assign {b2,b1,b0} = b;
    assign d4 = x0;
    assign d0 = x5;
    assign rst = delay2;

    f3m_mux6
        ins1 (a2,v1,a1,v3,v5,a0,e0,e1,e2,e3,e4,e5,in0), // $in0$ is the first input
        ins2 (b2,v2,b1,v4,v6,b0,e0,e1,e2,e3,e4,e5,in1); // $in1$ is the second input
    f3m_mult
        ins3 (clk, mult_reset, in0, in1, o, mult_done); // o == in0 * in1
    func6
        ins4 (clk, mult_done, p);
    f3m_add
        ins5 (a1, a2, v1), // v1 == a1+a2
        ins6 (b1, b2, v2), // v2 == b1+b2
        ins7 (a0, a2, v3), // v3 == a0+a2
        ins8 (b0, b2, v4), // v4 == b0+b2
        ins9 (a0, a1, v5), // v5 == a0+a1
        ins10 (b0, b1, v6), // v6 == b0+b1
        ins11 (d0, d3, c0), // c0 == d0+d3
        ins12 (d2, d4, c2); // c2 == d2+d4
    f3m_neg
        ins13 (x0, nx0), // nx0 == -x0
        ins14 (x2, nx2), // nx2 == -x2
        ins15 (x5, nx5); // nx5 == -x5
    f3m_add3
        ins16 (x1, nx0, nx2, d3), // d3 == x1-x0-x2
        ins17 (x4, nx2, nx5, d1), // d1 == x4-x2-x5
        ins18 (d1, d3, d4, c1); // c1 == d1+d3+d4
    f3m_add4
        ins19 (x3, x2, nx0, nx5, d2); // d2 == x3+x2-x0-x5

    always @ (posedge clk)
      begin
        if (reset) K <= 7'b1000000;
        else if (p) K <= {1'b0,K[6:1]};
      end
    
    always @ (posedge clk)
      begin
        if (e0) x0 <= o; // x0 == a2*b2
        if (e1) x1 <= o; // x1 == (a2+a1)*(b2+b1)
        if (e2) x2 <= o; // x2 == a1*b1
        if (e3) x3 <= o; // x3 == (a2+a0)*(b2+b0)
        if (e4) x4 <= o; // x4 == (a1+a0)*(b1+b0)
        if (e5) x5 <= o; // x5 == a0*b0
      end
    
    always @ (posedge clk)
      begin
        if (reset) done <= 0;
        else if (K[0]) 
          begin
            done <= 1; c <= {c2,c1,c0};
          end
      end
    
    always @ (posedge clk)
      begin
        if (rst) mult_reset <= 1;
        else if (mult_done) mult_reset <= 1;
        else mult_reset <= 0;
      end
    
    always @ (posedge clk)
      begin
        delay2 <= delay1; delay1 <= reset;
      end
endmodule

