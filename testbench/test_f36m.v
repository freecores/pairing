`timescale 1ns / 1ps

module test_f36m;

    // Inputs
    reg clk;
    reg reset;
    reg [1163:0] a, b;

    // Outputs
    wire done;
    wire [1163:0] c;

    // Instantiate the Unit Under Test (UUT)
    f36m_mult uut (
        .clk(clk), 
        .reset(reset), 
        .a(a), 
        .b(b), 
        .c(c), 
        .done(done)
    );

    initial begin
        // Initialize Inputs
        clk = 0;
        reset = 0;
        a = 0;
        b = 0;

        // Wait 100 ns for global reset to finish
        #100;
        
        // Add stimulus here
        a = {{194'h8864990666a959a88500249a244495aaa26a2a0194082aa1,194'h2a9481526946468065456052045865262520a4a9520a5a665},{194'h185218150022515648a249a8945625895448860a18905a018,194'h269862628a1aa4489059585a002520602618299155aa0aa54},{194'h24a8112565595199615504222108089046890965559999a54,194'h989802898a9580a8264a8516568952918645268868608988}};
        b = {{194'h116698585aa229805611194a6520151245204aa9114a89200,194'h8855225a25520a048a912141800501862189941946906540},{194'h292a05921518651529280825a940a22016016415906190642,194'h25a4455a419606606081860a1094a05996914048469499412},{194'h11a1415465625aa59489642111440112690a8546992a61802,194'h690a815a0a6885852602a4a5a1281458010a81184288441a}};

        @ (negedge clk); reset = 1;
        @ (negedge clk); reset = 0;
        @ (posedge done);
        if(c !== {{194'h20964a58198526a89908a8246a49a0958a50656861418129a,194'h82844161404829960541524906188a258291288809246094},{194'h244a6514510aa60069644265a521a842510205155684162a9,194'h855a41584a4a255a40140599a9615a659295558a28416964},{194'h244640626652050a984212441486528499a42961809802284,194'h54281a964289aa80a65948592648549526652aa40504254}})
            $display("E");
        #100;
        $finish;
    end

    always #5 clk = ~clk;
endmodule

