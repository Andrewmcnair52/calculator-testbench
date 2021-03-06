`default_nettype none

module calculator_tb;

	typedef struct {			//transaction structure
    bit 	[31:0] 		param1;
    bit		[31:0]		param2;
    bit 	[3:0]			cmd;
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


	bit 			c_clk;
	bit [6:0]		reset;
	
	bit [3:0] 		req1_cmd_in;
	bit [31:0] 		req1_data_in;
	bit [3:0] 		req2_cmd_in;
	bit [31:0] 		req2_data_in;
	bit [3:0] 		req3_cmd_in;
	bit [31:0] 		req3_data_in;
	bit [3:0] 		req4_cmd_in;
	bit [31:0] 		req4_data_in;

	bit [1:0]		out_resp1;
	bit [31:0]		out_data1;
	bit [1:0]		out_resp2;
	bit [31:0]		out_data2;
	bit [1:0]		out_resp3;
	bit [31:0]		out_data3;
	bit [1:0]		out_resp4;
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
	req1Trans.push_back('{32'h5, 32'h1, 4'h1, 0, 0, 0, 0});		//100 + 39 = 139

	if(event_mode) begin	//event_mode test cases
	
	
		//test 1.1
		do_reset(reset);
		run_trans1(0);
		
	end else begin	//cycle mode
	
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

clocking cb @(posedge c_clk);   //specifies when inputs are set and outputs read

        default input #2ns output #2ns;         //read from DUT outputs at posedge - 2ns                                                        
                                                //write to DUT inputs at posedge + 2ns

        //notes, tb inputs are DUt outputs, and vice versa
        //use cb_ signals when setting/reading at clk endge
        output req1_data_in, req1_cmd_in;
        output req2_data_in, req2_cmd_in;
        output req3_data_in, req3_cmd_in;
        output req4_data_in, req4_cmd_in;
        output cb_reset = reset;
        
        input out_data1, out_resp1;
        input out_data2, out_resp2;
        input out_data3, out_resp3;
        input out_data4, out_resp4;


endclocking

//clock generator
initial begin
	forever
  	if(event_mode) begin
      #50ns c_clk=!c_clk;
    end else begin
       c_clk = 1;
    end
end


/////////////////////////////////////////////////////////////////////////////////////// functions that do things

task run_trans1(input int index);

	@(posedge c_clk);
	cb.req1_data_in <= req1Trans[index].param1;	//written @ edge + 2ns
	cb.req1_cmd_in <= req1Trans[index].cmd;			//written @ edge + 2ns

	@(posedge c_clk);
	cb.req1_data_in <= req1Trans[index].param2;	//written @ edge + 2ns
		
	for(int i=0; i<5; i++) begin		//give it 5 cycles to respond
		@(posedge c_clk);
		if(i == 4) begin
			req1Trans[index].actual_resp = out_resp1;
			req1Trans[index].actual_data = out_data1;
			$display("%t: no response, %p", $time, req1Trans[index]);
		end
		else if (out_resp1 != 0) begin
			req1Trans[index].actual_resp = out_resp1;
			req1Trans[index].actual_data = out_data1;
			$display("%t: response after %0d cycles, %p", $time, i+1, req1Trans[index]);
			break;
		end
	end

endtask

task do_reset(inout bit [7:0] reset);	//reset the device

	for (int i=0;i<7;i++) begin	//Hold reset to '1111111'b for seven cycles
		@(posedge c_clk);
		reset[6:0] = 7'b1111111;
	end

	@(posedge c_clk) reset = 7'b0000000;
	
endtask


///////////////////////////////////////////////////////////////////////////////////////

endmodule


