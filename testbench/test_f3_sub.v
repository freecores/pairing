`timescale 1ns / 1ps

module test_f3_sub;

	// Inputs
	reg [1:0] A;
	reg [1:0] B;

	// Outputs
	wire [1:0] C;

	// Instantiate the Unit Under Test (UUT)
	f3_sub uut (
		.A(A), 
		.B(B), 
		.C(C)
	);

   task check;
	  begin
         #10;
			if (A != (B+C) % 3) 
			   begin 
				   $display("Error A:%d B:%d C:%d", A, B, C); $finish; 
				end
	  end
	endtask

	initial begin
		// Initialize Inputs
		A = 0;
		B = 0;

		// Wait 100 ns for global reset to finish
		#100;
        
		// Add stimulus here
		A = 0; B = 0; check;
		A = 0; B = 1; check;
		A = 0; B = 2; check;
		A = 1; B = 0; check;
		A = 1; B = 1; check;
		A = 1; B = 2; check;
		A = 2; B = 0; check;
		A = 2; B = 1; check;
		A = 2; B = 2; check;
		$finish;
	end
   
endmodule

