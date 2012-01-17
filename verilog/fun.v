// fun.v: Have you got fun reading the code ?
`include "inc.v"

// out = S - q*R
module func1(S, R, q, out);
    input [`WIDTH+2:0] S, R;
    input [1:0] q;
    output [`WIDTH+2:0] out;
    wire [`WIDTH+2:0] t;
    func4 f(R, q, t); // t == q*R
    genvar i;
    generate for(i=0; i<=`WIDTH+2; i=i+2) begin: label
        f3_sub s1(S[i+1:i], t[i+1:i], out[i+1:i]); // out == S - t
    end endgenerate
endmodule

// out = x*A
module func2(A, out);
    input [`WIDTH+2:0] A;
    output [`WIDTH+2:0] out;
    assign out = {A[`WIDTH:0], 2'd0};
endmodule

// C = (x*B mod p(x))
module func3(B, C);
    input [`WIDTH+2:0] B;
    output [`WIDTH+2:0] C;
    wire [`WIDTH+2:0] A;
    assign A = {B[`WIDTH:0], 2'd0}; // A == B*x
    wire [1:0] w0;
    f3_mult m0 (A[195:194], 2'd2, w0);
    f3_sub s0 (A[1:0], w0, C[1:0]);
    assign C[23:2] = A[23:2];
    wire [1:0] w12;
    f3_mult m12 (A[195:194], 2'd1, w12);
    f3_sub s12 (A[25:24], w12, C[25:24]);
    assign C[193:26] = A[193:26];
    assign C[195:194] = 0;
endmodule

// C = a * A; A,C \in GF(3^m); a \in GF(3)
module func4(A, aa, C);
    input [`WIDTH+2:0] A;
    input [1:0] aa;
    output [`WIDTH+2:0] C;
    genvar i;
    generate
      for(i=0; i<=`WIDTH+2; i=i+2) 
      begin: label
        f3_mult m(A[i+1:i], aa, C[i+1:i]);
      end 
    endgenerate
endmodule

// C = (A/x) mod p, \in GF(3^m)
module func5(A, C);
    input [`WIDTH+2:0] A;
    output [`WIDTH+2:0] C;
    assign C[195:194] = 0;
    assign C[193:192] = A[1:0];
    assign C[191:24] = A[193:26];
    f3_add a11 (A[25:24], A[1:0], C[23:22]);
    assign C[21:0] = A[23:2];
endmodule

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

// out = (v1 & l1) | (v2 & l2)
module func7(v1, l1, v2, l2, out);
    input [`WIDTH:0] v1, v2;
    input l1, l2;
    output [`WIDTH:0] out;
    genvar i;
    generate
        for(i=0;i<=`WIDTH;i=i+1)
          begin : label
            assign out[i] = (v1[i] & l1) | (v2[i] & l2);
          end 
    endgenerate
endmodule

// out = (v1 & l1) | (v2 & l2) | (v3 & l3)
module func8(v1, l1, v2, l2, v3, l3, out);
    input [`WIDTH:0] v1, v2, v3;
    input l1, l2, l3;
    output [`WIDTH:0] out;
    wire [`WIDTH:0] a;
    func7 
        c1 (v1, l1, v2, l2, a),
        c2 (a, 1'b1, v3, l3, out);
endmodule

// out = (v1 & l1) | (v2 & l2) | (v3 & l3) | ... | (v6 & l6)
module func9(v0, v1, v2, v3, v4, v5, l0, l1, l2, l3, l4, l5, out);
    input l0, l1, l2, l3, l4, l5;
    input [`W2:0] v0, v1, v2, v3, v4, v5;
    output reg [`W2:0] out;
    always @ (l0,l1,l2,l3,l4,l5,v0,v1,v2,v3,v4,v5)
      case ({l0,l1,l2,l3,l4,l5})
        6'b100000: out = v0;
        6'b010000: out = v1;
        6'b001000: out = v2;
        6'b000100: out = v3;
        6'b000010: out = v4;
        6'b000001: out = v5;
        default: out = 0;
      endcase
endmodule

// C = -A in GF(3^{2M})
module func10(a, c);
    input [`W2:0] a;
    output [`W2:0] c;
    genvar i;
    generate 
        for (i=0;i<=`W2;i=i+2)
          begin:label
            assign c[i+1:i] = {a[i], a[i+1]};
          end
    endgenerate
endmodule

// C = a0 + a1 + a2 in GF(3^{2M})
module func11(a0, a1, a2, c);
    input [`W2:0] a0, a1, a2;
    output [`W2:0] c;
    wire [`W2:0] t;
    f32m_add
        ins1 (a0, a1, t),
        ins2 (t, a2, c);
endmodule

// C = a0 + a1 + a2 + a3 in GF(3^{2M})
module func12(a0, a1, a2, a3, c);
    input [`W2:0] a0, a1, a2, a3;
    output [`W2:0] c;
    wire [`W2:0] t;
    f32m_add
        ins1 (a2, a3, t); // t == a2 + a3
    func11
        ins2 (a0, a1, t, c); // c == a0 + a1 + t == a0 + a1 + a2 + a3
endmodule
