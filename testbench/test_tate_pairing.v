`timescale 1ns / 1ps
`include "../rtl/inc.v"

module test_tate_pairing;

	// Inputs
	reg clk;
	reg reset;
	reg [`WIDTH:0] x1, y1, x2, y2;
	reg [7:0] sel;
    reg [149:0] o0,o1,o2,o3,o4,o5,o6,o7;
    reg [`W6:0] wish;

	// Outputs
	wire done;
	wire [149:0] out;

	// Instantiate the Unit Under Test (UUT)
	tate_pairing uut (
		.clk(clk), 
		.reset(reset), 
		.x1(x1), 
		.y1(y1), 
		.x2(x2), 
		.y2(y2), 
		.done(done), 
		.sel(sel), 
		.out(out)
	);

	initial begin
		// Initialize Inputs
		clk = 0;
		reset = 0;
		x1 = 0;
		y1 = 0;
		x2 = 0;
		y2 = 0;
		sel = 0;
        o0 = 0;
        o1 = 0;
        o2 = 0;
        o3 = 0;
        o4 = 0;
        o5 = 0;
        o6 = 0;
        o7 = 0;

		// Wait 100 ns for global reset to finish
		#100;
        
		// Add stimulus here
        x1 = 194'h6a18950064046a122a14118668466a262a91509688159890;
        y1 = 194'h69112569422aa0a25224aa010888066061124a8685566825;
        x2 = 194'h155945aa8924654812564110544995a28845901211454814;
        y2 = 194'h8481099460280628960a82559920000a99a2106955289a40;
        wish = {{194'h148a60225a14a81189aa09a22848104418aa6505801246205,194'h520094820010a12551069915258a58848501052005a85609},{194'ha484046591204499252009806480198a2549624a5181695,194'h21905848428558a806805a4518844049651812a88955a8868},{194'h5565059245921805891121a95a6949564201a2a068910558,194'ha6298884510610298462582969269a122260a05a8241055a}};
        @ (negedge clk); reset = 1;
        @ (negedge clk); reset = 0;
        @ (posedge done); @ (negedge clk);
        sel = 8'b0000_0001; #20; o0=out;
        sel = 8'b0000_0010; #20; o1=out;
        sel = 8'b0000_0100; #20; o2=out;
        sel = 8'b0000_1000; #20; o3=out;
        sel = 8'b0001_0000; #20; o4=out;
        sel = 8'b0010_0000; #20; o5=out;
        sel = 8'b0100_0000; #20; o6=out;
        sel = 8'b1000_0000; #20; o7=out;
        if ({o7[113:0],o6,o5,o4,o3,o2,o1,o0} !== wish) begin $display("E"); end
        $finish;
	end
    
    always #5 clk = ~clk;
endmodule

