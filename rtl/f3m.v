`include "inc.v"
`define MOST 2*`M+1:2*`M

// out = (v1 & l1) | (v2 & l2) | (v3 & l3)
module f3m_mux3(v1, l1, v2, l2, v3, l3, out);
    input [`WIDTH:0] v1, v2, v3;
    input l1, l2, l3;
    output [`WIDTH:0] out;
    genvar i;
    generate
        for(i=0;i<=`WIDTH;i=i+1)
          begin : label
            assign out[i] = (v1[i] & l1) | (v2[i] & l2) | (v3[i] & l3);
          end 
    endgenerate
endmodule

// out = (v0 & l0) | (v1 & l1) | (v2 & l2) | ... | (v5 & l5)
module f3m_mux6(v0, v1, v2, v3, v4, v5, l0, l1, l2, l3, l4, l5, out);
    input l0, l1, l2, l3, l4, l5;
    input [`WIDTH:0] v0, v1, v2, v3, v4, v5;
    output reg [`WIDTH:0] out;
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

// f3m_add: C = A + B, in field F_{3^M}
module f3m_add(A, B, C);
    input [`WIDTH : 0] A, B;
    output [`WIDTH : 0] C;
    genvar i;
    generate
        for(i=0; i<`M; i=i+1) begin: aa
            f3_add aa(A[(2*i+1) : 2*i], B[(2*i+1) : 2*i], C[(2*i+1) : 2*i]);
        end
    endgenerate
endmodule

// f3m_add3: c == a0+a1+a2, in field GF(3^M)
module f3m_add3(a0, a1, a2, c);
    input [`WIDTH:0] a0,a1,a2;
    output [`WIDTH:0] c;
    wire [`WIDTH:0] v;
    f3m_add
        ins1 (a0,a1,v), // v == a0+a1
        ins2 (v,a2,c);  // c == v+a2 == a0+a1+a2
endmodule

// f3m_add4: c == a0+a1+a2+a3, in field GF(3^M)
module f3m_add4(a0, a1, a2, a3, c);
    input [`WIDTH:0] a0,a1,a2,a3;
    output [`WIDTH:0] c;
    wire [`WIDTH:0] v1,v2;
    f3m_add
        ins1 (a0,a1,v1), // v1 == a0+a1
        ins2 (a2,a3,v2), // v2 == a2+a3
        ins3 (v1,v2,c);  // c == v1+v2 == a0+a1+a2+a3
endmodule

// f3m_neg: c == -a in GF(3^M)
module f3m_neg(a, c);
    input [`WIDTH:0] a;
    output [`WIDTH:0] c;
    genvar i;
    generate
        for(i=0;i<=`WIDTH;i=i+2)
          begin:label
            assign c[i+1:i] = {a[i],a[i+1]};
          end
    endgenerate
endmodule

// f3m_sub: C = A - B, in field F_{3^M}
module f3m_sub(A, B, C);
    input [`WIDTH : 0] A, B;
    output [`WIDTH : 0] C;
    genvar i;
    generate
        for(i=0; i<`M; i=i+1) begin: aa
            f3_sub aa(A[(2*i+1) : 2*i], B[(2*i+1) : 2*i], C[(2*i+1) : 2*i]);
        end
    endgenerate
endmodule

// f3m_mult: C = A * B, in field GF(3^M)
module f3m_mult(clk, reset, A, B, C, done);
    input [`WIDTH : 0] A, B;
    input clk;
    input reset;
    output reg [`WIDTH : 0] C;
    output reg done;
    reg [`WIDTH : 0] x, y, z;
    wire [`WIDTH : 0] z1, z2, z4;
    wire [`WIDTH+2 : 0] z3;
    reg [`M : 0] i;
    wire done1;
    wire [1:0] dummy;

    func4 
        ins1 ({2'b0,x}, y[1:0], {dummy,z1}); // z1 == A * B[0]
    f3m_add
        ins2 (z1, z, z2); // z2 == z1 + z == A*B[0] + z
    assign z4 = {2'd0, y[`WIDTH:2]}; // z4 == y >> 2
    func3
        ins3 ({2'd0,x}, z3); // z3 == X*x mod p(x)
    assign done1 = i[0];
    
    always @ (posedge clk)
        if (done1)
            C <= z;
    
    always @ (posedge clk)
        if (reset)
            done <= 0;
        else if (done1)
            done <= 1;

    always @ (posedge clk) 
      begin
        if (reset)
          begin
            x <= A; y <= B; z <= 0; i <= {1'b1,{`M{1'b0}}};
          end
        else
          begin
            x <= z3[`WIDTH:0]; y <= z4; z <= z2; i <= i >> 1;
          end
      end
endmodule

// c0 == a0*b0; c1 == a1*b1; c2 == a2*b2; all in GF(3^M)
module f3m_mult3(clk, reset, 
                 a0, b0, c0,
                 a1, b1, c1, 
                 a2, b2, c2, 
                 done);
    input clk, reset;
    input [`WIDTH:0] a0, b0, a1, b1, a2, b2;
    output reg [`WIDTH:0] c0, c1, c2;
    output reg done;
    reg [3:0] K;
    reg mult_reset, delay1, delay2;
    wire e1, e2, e3, mult_done, delay3, rst;
    wire [`WIDTH:0] in1, in2, o;
    
    assign rst = delay2;
    assign {e1,e2,e3} = K[3:1];

    f3m_mux3
        ins9 (a0, e1, a1, e2, a2, e3, in1),
        ins10 (b0, e1, b1, e2, b2, e3, in2);
    f3m_mult
        ins11 (clk, mult_reset, in1, in2, o, mult_done); // o == in1 * in2 in GF(3^m)
    func6
        ins12 (clk, reset, mult_done, delay3);

    always @ (posedge clk)
      begin
        if (e1) c0 <= o;
        if (e2) c1 <= o;
        if (e3) c2 <= o;
      end
    
    always @ (posedge clk)
        if (reset) K <= 4'b1000;
        else if (delay3 | K[0]) K <= {1'b0,K[3:1]};
    
    always @ (posedge clk)
      begin
        if (rst) mult_reset <= 1;
        else if (mult_done) mult_reset <= 1;
        else mult_reset <= 0;
      end

    always @ (posedge clk)
        if (reset)     done <= 0;
        else if (K[0]) done <= 1;
    
    always @ (posedge clk)
      begin 
        delay2 <= delay1; delay1 <= reset; 
      end
endmodule

/* out == in^3 mod p(x) */
/* p(x) == x^97 + x^12 + 2 */
module f3m_cubic(input [193:0] in, output [193:0] out);
wire [1:0] w0; f3_add a0(in[131:130], in[139:138], w0);
wire [1:0] w1; f3_add a1(in[133:132], in[141:140], w1);
wire [1:0] w2; f3_add a2(in[135:134], in[143:142], w2);
wire [1:0] w3; f3_add a3(in[137:136], in[145:144], w3);
wire [1:0] w4; f3_add a4(in[147:146], in[155:154], w4);
wire [1:0] w5; f3_add a5(in[149:148], in[157:156], w5);
wire [1:0] w6; f3_add a6(in[151:150], in[159:158], w6);
wire [1:0] w7; f3_add a7(in[153:152], in[161:160], w7);
wire [1:0] w8; f3_add a8(in[163:162], in[171:170], w8);
wire [1:0] w9; f3_add a9(in[165:164], in[173:172], w9);
wire [1:0] w10; f3_add a10(in[167:166], in[175:174], w10);
wire [1:0] w11; f3_add a11(in[169:168], in[177:176], w11);
wire [1:0] w12; f3_add a12(in[179:178], in[187:186], w12);
wire [1:0] w13; f3_add a13(in[181:180], in[189:188], w13);
wire [1:0] w14; f3_add a14(in[183:182], in[191:190], w14);
wire [1:0] w15; f3_add a15(in[185:184], in[193:192], w15);
wire [1:0] w16;
f3_add a16(in[1:0], w12, w16);
assign out[1:0] = w16;
wire [1:0] w17;
f3_add a17({in[122],in[123]}, in[131:130], w17);
assign out[3:2] = w17;
assign out[5:4] = in[67:66];
wire [1:0] w18;
f3_add a18(in[3:2], w13, w18);
assign out[7:6] = w18;
wire [1:0] w19;
f3_add a19({in[124],in[125]}, in[133:132], w19);
assign out[9:8] = w19;
assign out[11:10] = in[69:68];
wire [1:0] w20;
f3_add a20(in[5:4], w14, w20);
assign out[13:12] = w20;
wire [1:0] w21;
f3_add a21({in[126],in[127]}, in[135:134], w21);
assign out[15:14] = w21;
assign out[17:16] = in[71:70];
wire [1:0] w22;
f3_add a22(in[7:6], w15, w22);
assign out[19:18] = w22;
wire [1:0] w23;
f3_add a23({in[128],in[129]}, in[137:136], w23);
assign out[21:20] = w23;
assign out[23:22] = in[73:72];
wire [1:0] w24;
f3_add a24(in[9:8], {in[178],in[179]}, w24);
assign out[25:24] = w24;
wire [1:0] w25;
f3_add a25(in[123:122], w0, w25);
assign out[27:26] = w25;
wire [1:0] w26;
f3_add a26({in[66],in[67]}, in[75:74], w26);
assign out[29:28] = w26;
wire [1:0] w27;
f3_add a27(in[11:10], {in[180],in[181]}, w27);
assign out[31:30] = w27;
wire [1:0] w28;
f3_add a28(in[125:124], w1, w28);
assign out[33:32] = w28;
wire [1:0] w29;
f3_add a29({in[68],in[69]}, in[77:76], w29);
assign out[35:34] = w29;
wire [1:0] w30;
f3_add a30(in[13:12], {in[182],in[183]}, w30);
assign out[37:36] = w30;
wire [1:0] w31;
f3_add a31(in[127:126], w2, w31);
assign out[39:38] = w31;
wire [1:0] w32;
f3_add a32({in[70],in[71]}, in[79:78], w32);
assign out[41:40] = w32;
wire [1:0] w33;
f3_add a33(in[15:14], {in[184],in[185]}, w33);
assign out[43:42] = w33;
wire [1:0] w34;
f3_add a34(in[129:128], w3, w34);
assign out[45:44] = w34;
wire [1:0] w35;
f3_add a35({in[72],in[73]}, in[81:80], w35);
assign out[47:46] = w35;
wire [1:0] w36;
f3_add a36(in[17:16], {in[186],in[187]}, w36);
assign out[49:48] = w36;
wire [1:0] w37;
f3_add a37(in[147:146], w0, w37);
assign out[51:50] = w37;
wire [1:0] w38;
f3_add a38({in[74],in[75]}, in[83:82], w38);
assign out[53:52] = w38;
wire [1:0] w39;
f3_add a39(in[19:18], {in[188],in[189]}, w39);
assign out[55:54] = w39;
wire [1:0] w40;
f3_add a40(in[149:148], w1, w40);
assign out[57:56] = w40;
wire [1:0] w41;
f3_add a41({in[76],in[77]}, in[85:84], w41);
assign out[59:58] = w41;
wire [1:0] w42;
f3_add a42(in[21:20], {in[190],in[191]}, w42);
assign out[61:60] = w42;
wire [1:0] w43;
f3_add a43(in[151:150], w2, w43);
assign out[63:62] = w43;
wire [1:0] w44;
f3_add a44({in[78],in[79]}, in[87:86], w44);
assign out[65:64] = w44;
wire [1:0] w45;
f3_add a45(in[23:22], {in[192],in[193]}, w45);
assign out[67:66] = w45;
wire [1:0] w46;
f3_add a46(in[153:152], w3, w46);
assign out[69:68] = w46;
wire [1:0] w47;
f3_add a47({in[80],in[81]}, in[89:88], w47);
assign out[71:70] = w47;
assign out[73:72] = in[25:24];
wire [1:0] w48;
f3_add a48(in[139:138], w4, w48);
assign out[75:74] = w48;
wire [1:0] w49;
f3_add a49({in[82],in[83]}, in[91:90], w49);
assign out[77:76] = w49;
assign out[79:78] = in[27:26];
wire [1:0] w50;
f3_add a50(in[141:140], w5, w50);
assign out[81:80] = w50;
wire [1:0] w51;
f3_add a51({in[84],in[85]}, in[93:92], w51);
assign out[83:82] = w51;
assign out[85:84] = in[29:28];
wire [1:0] w52;
f3_add a52(in[143:142], w6, w52);
assign out[87:86] = w52;
wire [1:0] w53;
f3_add a53({in[86],in[87]}, in[95:94], w53);
assign out[89:88] = w53;
assign out[91:90] = in[31:30];
wire [1:0] w54;
f3_add a54(in[145:144], w7, w54);
assign out[93:92] = w54;
wire [1:0] w55;
f3_add a55({in[88],in[89]}, in[97:96], w55);
assign out[95:94] = w55;
assign out[97:96] = in[33:32];
wire [1:0] w56;
f3_add a56(in[163:162], w4, w56);
assign out[99:98] = w56;
wire [1:0] w57;
f3_add a57({in[90],in[91]}, in[99:98], w57);
assign out[101:100] = w57;
assign out[103:102] = in[35:34];
wire [1:0] w58;
f3_add a58(in[165:164], w5, w58);
assign out[105:104] = w58;
wire [1:0] w59;
f3_add a59({in[92],in[93]}, in[101:100], w59);
assign out[107:106] = w59;
assign out[109:108] = in[37:36];
wire [1:0] w60;
f3_add a60(in[167:166], w6, w60);
assign out[111:110] = w60;
wire [1:0] w61;
f3_add a61({in[94],in[95]}, in[103:102], w61);
assign out[113:112] = w61;
assign out[115:114] = in[39:38];
wire [1:0] w62;
f3_add a62(in[169:168], w7, w62);
assign out[117:116] = w62;
wire [1:0] w63;
f3_add a63({in[96],in[97]}, in[105:104], w63);
assign out[119:118] = w63;
assign out[121:120] = in[41:40];
wire [1:0] w64;
f3_add a64(in[155:154], w8, w64);
assign out[123:122] = w64;
wire [1:0] w65;
f3_add a65({in[98],in[99]}, in[107:106], w65);
assign out[125:124] = w65;
assign out[127:126] = in[43:42];
wire [1:0] w66;
f3_add a66(in[157:156], w9, w66);
assign out[129:128] = w66;
wire [1:0] w67;
f3_add a67({in[100],in[101]}, in[109:108], w67);
assign out[131:130] = w67;
assign out[133:132] = in[45:44];
wire [1:0] w68;
f3_add a68(in[159:158], w10, w68);
assign out[135:134] = w68;
wire [1:0] w69;
f3_add a69({in[102],in[103]}, in[111:110], w69);
assign out[137:136] = w69;
assign out[139:138] = in[47:46];
wire [1:0] w70;
f3_add a70(in[161:160], w11, w70);
assign out[141:140] = w70;
wire [1:0] w71;
f3_add a71({in[104],in[105]}, in[113:112], w71);
assign out[143:142] = w71;
assign out[145:144] = in[49:48];
wire [1:0] w72;
f3_add a72(in[179:178], w8, w72);
assign out[147:146] = w72;
wire [1:0] w73;
f3_add a73({in[106],in[107]}, in[115:114], w73);
assign out[149:148] = w73;
assign out[151:150] = in[51:50];
wire [1:0] w74;
f3_add a74(in[181:180], w9, w74);
assign out[153:152] = w74;
wire [1:0] w75;
f3_add a75({in[108],in[109]}, in[117:116], w75);
assign out[155:154] = w75;
assign out[157:156] = in[53:52];
wire [1:0] w76;
f3_add a76(in[183:182], w10, w76);
assign out[159:158] = w76;
wire [1:0] w77;
f3_add a77({in[110],in[111]}, in[119:118], w77);
assign out[161:160] = w77;
assign out[163:162] = in[55:54];
wire [1:0] w78;
f3_add a78(in[185:184], w11, w78);
assign out[165:164] = w78;
wire [1:0] w79;
f3_add a79({in[112],in[113]}, in[121:120], w79);
assign out[167:166] = w79;
assign out[169:168] = in[57:56];
wire [1:0] w80;
f3_add a80(in[171:170], w12, w80);
assign out[171:170] = w80;
wire [1:0] w81;
f3_add a81({in[114],in[115]}, in[123:122], w81);
assign out[173:172] = w81;
assign out[175:174] = in[59:58];
wire [1:0] w82;
f3_add a82(in[173:172], w13, w82);
assign out[177:176] = w82;
wire [1:0] w83;
f3_add a83({in[116],in[117]}, in[125:124], w83);
assign out[179:178] = w83;
assign out[181:180] = in[61:60];
wire [1:0] w84;
f3_add a84(in[175:174], w14, w84);
assign out[183:182] = w84;
wire [1:0] w85;
f3_add a85({in[118],in[119]}, in[127:126], w85);
assign out[185:184] = w85;
assign out[187:186] = in[63:62];
wire [1:0] w86;
f3_add a86(in[177:176], w15, w86);
assign out[189:188] = w86;
wire [1:0] w87;
f3_add a87({in[120],in[121]}, in[129:128], w87);
assign out[191:190] = w87;
assign out[193:192] = in[65:64];
endmodule

/* nine square in GF(3^m), out = in^9 mod p(x) */
/* p(x) == x^97 + x^12 + 2 */
module f3m_nine(clk, in, out);
    input clk;
    input [`WIDTH:0] in;
    output reg [`WIDTH:0] out;
    wire [`WIDTH:0] a,b;
    f3m_cubic
        ins1 (in, a), // a == in^3
        ins2 (a, b);  // b == a^3 == in^9
    always @ (posedge clk)
        out <= b;
endmodule

// inversion in GF(3^m). C = A^(-1)
module f3m_inv(clk, reset, A, C, done);
	input [`WIDTH:0] A;
	input clk;
	input reset;
	output reg [`WIDTH:0] C;
    output reg done;
	
	reg [`WIDTH+2:0] S, R, U, V, d;
	reg [2*`M:0] i;
	wire [1:0] q;
	wire [`WIDTH+2:0] S1, S2,
	                  R1,
	                  U1, U2, U3,
	                  V1, V2,
	                  d1, d2;
	wire don;

	assign d1 = {d[`WIDTH+1:0], 1'b1}; // d1 == d+1
	assign d2 = {1'b0, d[`WIDTH+2:1]}; // d2 == d-1
	assign don = i[0];
	
	f3_mult 
	    q1(S[`MOST], R[`MOST], q); // q = s_m / r_m
	func1
	    ins1(S, R, q, S1), // S1 = S - q*R
	    ins2(V, U, q, V1); // V1 = V - q*U
	func2
	    ins3(S1, S2), // S2 = x*S1 = x*(S-q*R)
	    ins4(R, R1); // R1 = x*R
	func3
	    ins5(U, U1), // U1 = x*U mod p
	    ins6(V1, V2); // V2 = x*V1 mod p = x*(V-qU) mod p
    func4
        ins7(U, R[`MOST], U2); // U2 = U/r_m
    func5
        ins8(U, U3); // U3 = (U/x) mod p
    
	always @ (posedge clk)
        if (reset)
            done <= 0;
	    else if (don)
          begin
	        done <= 1; C <= U2[`WIDTH:0];
          end

    always @ (posedge clk) 
        if (reset)
            i <= {1'b1, {(2*`M){1'b0}}};
        else
            i <= i >> 1;
    
    always @ (posedge clk)
        if (reset) 
          begin
            S<=`PX; R<=A; U<=1; V<=0; d<=0;
          end
        else if (R[`MOST] == 2'b0)
          begin
            R<=R1; U<=U1; d<=d1;
          end
        else if (d[0] == 1'b0) // d == 0
          begin
            R<=S2; S<=R; U<=V2; V<=U; d<=d1;
          end
        else // d != 0
          begin
            S<=S2; V<=V1; U<=U3; d<=d2;
          end
endmodule

// put func1~5 here for breaking circular dependency in "f3m", "fun"

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
