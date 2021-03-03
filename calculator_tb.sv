`default_nettype none

module test;

	typedef struct {			//transaction structure
    bit 	[31:0] 		stimulus_data;
    bit 	[3:0]			stimulus_cmd;
    bit 	[31:0] 		expected_data;
    logic [31:0] 		actual_data;
    bit		[1:0]			expected_resp;
    logic	[1:0]			actual_resp;
  } transaction;

	transaction req1Trans[$];		//transaction queue for request1
	transaction req2Trans[$];		//transaction queue for request2
	transaction req3Trans[$];		//transaction queue for request3
	transaction req4Trans[$];		//transaction queue for request4


	bit clk;
	bit [7:0]			reset;
	
	bit [3:0] 		req1_cmd_in;
	bit [31:0] 		req1_data_in;
	bit [3:0] 		req2_cmd_in;
	bit [31:0] 		req2_data_in;
	bit [3:0] 		req3_cmd_in;
	bit [31:0] 		req3_data_in;
	bit [3:0] 		req4_cmd_in;
	bit [31:0] 		req4_data_in;

	bit [1:0]			out_resp1;
	bit [31:0]		out_data1;
	bit [1:0]			out_resp2;
	bit [31:0]		out_data2;
	bit [1:0]			out_resp3;
	bit [31:0]		out_data3;
	bit [1:0]			out_resp4;
	bit [31:0]		out_data4;
	
	/*	input commands
			0: no-op
			1: add operand1 and operand2
			2: subtract operand1 from operand2
			5: shift left operand1 by operand2 places
			6: shift right operand1 by operand2 places
			
			operand 1 arrives with command
			operand 2 arrives on following cycle	
	*/
	
	bit event_mode = 1;		//event mode if high, else cycle mode

initial begin

	//initialization


	if(event_mode) begin	//event_mode test cases
	
		for(int i=0; i<7; i++) begin	//Hold resetto '1111111'b for seven cycles
			@(posedge c_clk);
			reset = 7b1111111;
		end
		
		
	
	end else begin	//cycle mode test cases
	
	
	
	end



end


calc1_top calc1_top(	//i'm assuming the encrypted module is called calc1_top ....
	.c_clk(c_clk),
	.reset(reset),
	.req1_cmd_in(req1_cmd_in),
	.req1_data_in(req1_data_in),
	.req2_cmd_in(req2_cmd_in),
	.req2_data_in(req2_data_in),
	.req3_cmd_in(req3_cmd_in),
	.req3_data_in(req3_data_in),
	.req4_cmd_in(req4_cmd_in),
	.req4_data_in(req4_data_in),
	.out_resp1(out_resp1),
	.out_data1(out_data1),
	.out_resp2(out_resp2),
	.out_data2(out_data2),
	.out_resp3(out_resp3),
	.out_data3(out_data3),
	.out_resp4(out_resp4),
	.out_data4(out_data4)
);

initial begin
	forever 
		if(event_mode) begin
			#50ns c_clk=!c_clk;
		end else begin
			c_clk = 1;
		end
end
endmodule


