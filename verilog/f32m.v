`include "inc.v"

// C == A+B in GF(3^{2M})
module f32m_add(a, b, c);
    input [`W2:0] a, b;
    output [`W2:0] c;
    f3m_add a1 (a[`W2:`WIDTH+1], b[`W2:`WIDTH+1], c[`W2:`WIDTH+1]);
    f3m_add a2 (a[`WIDTH:0], b[`WIDTH:0], c[`WIDTH:0]);
endmodule

// C == A-B in GF(3^{2M})
module f32m_sub(a, b, c);
    input [`W2:0] a, b;
    output [`W2:0] c;
    f3m_sub s1 (a[`W2:`WIDTH+1], b[`W2:`WIDTH+1], c[`W2:`WIDTH+1]);
    f3m_sub s2 (a[`WIDTH:0], b[`WIDTH:0], c[`WIDTH:0]);
endmodule

// C == A*B in GF(3^{2M})
module f32m_mult(clk, reset, a, b, c, done);
    input reset, clk;
    input [`W2:0] a, b;
    output reg [`W2:0] c;
    output reg done;
    wire [`WIDTH:0] a0,a1,b0,b1,
                    v1,v2,v6,
                    c0,c1,
                    in1,in2,o;
    reg [`WIDTH:0] v3,v4,v5;
    reg [3:0] K;
    wire load1, load2, load3, set1, set2, set3;
    reg mult_reset;
    wire mult_done;
    reg delay1, delay2;
    wire delay3;
    wire rst;
    
    assign rst = delay2;
    assign {a1,a0} = a;
    assign {b1,b0} = b;
    assign {load1,load2,load3} = K[3:1];
    assign {set1,set2,set3} = K[3:1];

    f3m_add
        ins1 (a0, a1, v1), // v1 == a0 + a1
        ins2 (b0, b1, v2), // v2 == b0 + b1
        ins3 (v3, v4, v6); // v6 == v3 + v4 = a0*b0 + a1*b1
    f3m_sub
        ins7 (v5, v6, c1), // c1 == v5 - v6 = (a0+a1) * (b0+b1) - (a0*b0 + a1*b1)
        ins8 (v3, v4, c0); // c0 == a0*b0 - a1*b1

    // only one $f3m_mult$ module doing three multiplication
    // v3 == a0 * b0
    // v4 == a1 * b1
    // v5 == v1 * v2 = (a0+a1) * (b0+b1)
    func8 
        ins9 (a0, load1, a1, load2, v1, load3, in1),
        ins10 (b0, load1, b1, load2, v2, load3, in2);
    f3m_mult
        ins11 (clk, mult_reset, in1, in2, o, mult_done); // o == in1 * in2 in GF(3^m)
    
    func6
        ins12 (clk, mult_done, delay3);
    
    always @ (posedge clk)
      begin
        if (set1) begin v3 <= o; end
        if (set2) begin v4 <= o; end
        if (set3) begin v5 <= o; end
      end
    
    always @ (posedge clk)
      begin
        if (reset) K <= 4'b1000;
        else if (delay3) K <= {1'b0,K[3:1]}; // wait for Mr. Comb. Logic :)
      end
    
    always @ (posedge clk)
      begin
        if (rst) mult_reset <= 1; // wait for Mr. Comb. Logic :)
        else if (mult_done) mult_reset <= 1;
        else mult_reset <= 0;
      end

    always @ (posedge clk)
      if (reset)
        done <= 0;
      else if (K[0])
        begin
          done <= 1; c <= {c1, c0};
        end
    
    always @ (posedge clk)
      begin
        delay2 <= delay1; delay1 <= reset;
      end
endmodule

// C == A^3 in GF(3^{2m})
module f32m_cubic(clk, a, c);
    input clk;
    input [`W2:0] a;
    output reg [`W2:0] c;
    wire [`WIDTH:0] a0,a1,c0,c1,v;
    assign {a1,a0} = a;
    f3m_cubic
        ins1 (a0, c0), // c0 == a0^3
        ins2 (a1, v);  // v == a1^3
    f3m_neg
        ins3 (v, c1);  // c1 == -v == - a1^3
    always @ (posedge clk)
        c <= {c1,c0};
endmodule
