`default_nettype none

module calculator_tb;

	typedef struct {			//transaction structure
    bit 	[31:0] 		stimulus_data;
    bit 	[3:0]			stimulus_cmd;
    bit 	[31:0] 		expected_data;
    logic [31:0] 		actual_data;
    bit		[1:0]			expected_resp;
    logic	[1:0]			actual_resp;
  } transaction;

	//setup transaction queue for each request, see homework 2
	transaction req1Trans[$];		//transaction queue for request1
	transaction req2Trans[$];		//transaction queue for request2
	transaction req3Trans[$];		//transaction queue for request3
	transaction req4Trans[$];		//transaction queue for request4


	bit c_clk;
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

/////////////////////////////////////////////////////////////////////////////////////// testing begins

initial begin

	//initialization


	if(event_mode) begin	//event_mode test cases
	
		do_reset();
		
		
	
	end else begin	//cycle mode test cases
	
	end



end

/////////////////////////////////////////////////////////////////////////////////////// DUT hookup

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

/////////////////////////////////////////////////////////////////////////////////////// timing stuff

clocking cb @(posedge c_clk);	//specifies when inputs are set and outputs read

	default input #2ns output #2ns;		//read from DUT outputs at posedge - 2ns
																		//write to DUT inputs at posedge + 2ns

	//notes, tb inputs are DUt outputs, and vice versa
	//use cb_ signals when setting/reading at clk endge
	output cb_din1 = req1_data_in;
	output cb_din2 = req2_data_in;
	output cb_din3 = req3_data_in;
	output cb_din4 = req4_data_in;
	output cb_cin1 = req1_cmd_in;
	output cb_cin2 = req2_cmd_in;
	output cb_cin3 = req3_cmd_in;
	output cb_cin4 = req4_cmd_in;
	output cb_reset = reset;
	
	input cb_resp1 = out_resp1;
	input cb_resp2 = out_resp2;
	input cb_resp3 = out_resp3;
	input cb_resp4 = out_resp4;
	input cb_dout1 = out_data1;
	input cb_dout2 = out_data2;
	input cb_dout3 = out_data3;
	input cb_dout4 = out_data4;
	

endclocking

//clock generator
initial begin
	forever 
		if(event_mode) begin
			#20ns c_clk=!c_clk;
		end else begin
			c_clk = 1;
		end
end

/////////////////////////////////////////////////////////////////////////////////////// functions that do things


task do_reset(inout bit [8:0] reset);
      
	for (int i=0;i<7;i++) begin	//Hold reset to '1111111'b for seven cycles
		@(posedge c_clk);
		reset[7:1] = 7'b1111111;		//should be written at posedge+2ns
		$display("time = %tns, i = %0d, reset=%b", $time, i,reset);
	end
	
endtask


///////////////////////////////////////////////////////////////////////////////////////

endmodule


