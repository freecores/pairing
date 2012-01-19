`include "inc.v"
// The Modified Duursma-Lee Algorithm
// out == e_({xp,yp}, {xr,yr})
module duursma_lee_algo(clk, reset, xp, yp, xr, yr, done, out);
    input clk, reset;
    input [`WIDTH:0] xp, yp, xr, yr;
    output reg done;
    output reg [`W6:0] out;
    
    reg [`W6:0] t;
    reg [`WIDTH:0] a, b, y;
    reg [1:0] d;
    reg [`M:0] i;
    reg f3m_reset, delay1, delay2;
    wire [`W6:0] g,v7,v8;
    wire [`WIDTH:0] mu /* my name is "mew" */,nmu,ny,
                    x,v2,v3,v4,v5,v6;
    wire [`WIDTH:0] two,zero;
    wire [1:0] v9;
    wire f36m_reset, dummy, f3m_done, f36m_done, finish;
    
    assign g = {zero,two,zero,nmu,v6,v5};
    assign two = 2;
    assign zero = 0;
    assign finish = (i[1:0]==2'b01 ? 1 : 0);
    
    f3m_cubic
        ins1 (xr, x), // x == {x_r}^3
        ins2 (yr, v2); // v2 == {y_r}^3
    f3m_nine
        ins3 (clk, a, v3), // v3 == a^9
        ins4 (clk, b, v4); // v4 == b^9
    f3m_add3
        ins5 (v3, x, {{(2*`M-2){1'b0}},d}, mu); // mu == a^9+x+d
    f3m_neg
        ins6 (mu, nmu), // nmu == -mu
        ins7 (y,  ny);  // ny  == -y
    f3m_mult
        ins8 (clk, delay2, mu, nmu, v5, f3m_done), // v5 == - mu^2
        ins9 (clk, delay2, v4, ny,  v6, dummy); // v6 == - (b^9)*y
    f36m_cubic
        ins10 (clk, t, v7); // v7 == t^3
    f36m_mult
        ins11 (clk, f36m_reset, v7, g, v8, f36m_done); // v8 == v7*g = (t^3)*g
    func6
        ins12 (clk, f36m_done, change),
        ins13 (clk, f3m_done, f36m_reset);
    f3_sub
        ins14 (d, 1, v9); // v9 == d-1
    
    always @ (posedge clk)
      begin
        if (reset)
          begin
            a <= xp; b <= yp; t <= 1; 
            y <= v2; d <= 1;  i <= ~0;
          end
        else if (change)
          begin
            a <= v3; b <= v4; t <= v8;
            y <= ny; d <= v9; i <= i >> 1;
          end
      end

    always @ (posedge clk)
        if (reset) 
          begin done <= 0; out <= 0; end
        else if (finish) 
          begin done <= 1; out <= v8; end
    
    always @ (posedge clk)
        begin delay2 <= delay1; delay1 <= f3m_reset; end
    
    always @ (posedge clk)
        if (reset) f3m_reset <= 1;
        else if (change) f3m_reset <= 1;
        else f3m_reset <= 0;
endmodule
