`default_nettype none

module calculator_tb;

	typedef struct {			//transaction structure
    bit 	[31:0] 		param1;
    bit		[31:0]		param2;
    bit 	[3:0]     cmd;
    logic [31:0]    actual_data;
    logic	[1:0]     actual_resp;
    bit 	[31:0] 		expected_data;
    bit		[1:0]     expected_resp;
    string          desc;
  } transaction;

	//setup transaction queues to store transactions (transactions are tests)
	transaction response_trans[$];          //response test transactions
	transaction operation_trans[$];         //tests for basic operations
	transaction state_trans[$];             //clean state test transactions
	
	int error_count=0, success_count=0;
  string error_messages[$];

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

	$display();	//space seperator for output
	
	//1.1 response test stimulus
	response_trans.push_back('{32'h64, 32'h27, 4'h0, 0, 0, 0, 0, "no response test"});
	response_trans.push_back('{32'h64, 32'h27, 4'h1, 0, 0, 0, 0, "data ready response test"});
	response_trans.push_back('{32'hFFFFFFFF, 32'h1, 4'h1, 0, 0, 0, 0, "overflow response test"});
	response_trans.push_back('{32'h22, 32'h23, 4'h2, 0, 0, 0, 0, "underflow response test"});
	
	//1.2 basic operation testing on all channels     <- should probibly add more of a sample size
	operation_trans.push_back('{32'h5, 32'h1, 4'h1, 0, 0, 0, 0,"addtion test"});      //100 + 39 = 139
	operation_trans.push_back('{32'h5, 32'h2, 4'h2, 0, 0, 0, 0,"subtraction test"});  //5 - 2 = 3
	operation_trans.push_back('{32'h3, 32'h2, 4'h5, 0, 0, 0, 0,"shift left test"});   //3 << 2 = 12
	operation_trans.push_back('{32'hc, 32'h2, 4'h6, 0, 0, 0, 0,"shift right test"});  //12 >> 2 = 3


	if(event_mode) begin	//event_mode test cases (always event mode for now)
		
		error_messages.push_back("\ntest responses\n");
		
		//1.1 and 1.3 test response
		do_reset(reset);
			
		for(int j=1; j<5; j++) begin		//for every channel
			foreach(response_trans[i]) begin	//run each test
				set_expected(response_trans[i]);
				run_trans(response_trans[i], j, 0);      //channels 1-4, no debug messages
				check_trans(response_trans[i], j, 0);    //mode 0: check response only
			end
			
			do_reset(reset);  //reset after finnished with each channel
			
		end
		
		error_messages.push_back("\nbasic operations testing\n");
		
		//1.2 operations testing for each channel
		for(int j=1; j<5; j++) begin		//for every channel
		  foreach(operation_trans[i]) begin
		   set_expected(operation_trans[i]);
		   run_trans(operation_trans[i], j, 0);      //debug on
		   check_trans(operation_trans[i], j, 3);    //mode 3: check data and response
		  end
		
		  do_reset(reset);  //reset after finnished with each channel
		  
	  end
	  
	  error_messages.push_back("\ntest for 'dirty state' issues\n");
	  
	  //2.1.1/2.1.2 test that device state is clean after each operation
		
		//test interference between channels
		//will do this randomly due to too many possibilities
		for(int i=1; i<5; i++) begin            //for each channel
		  for(int j=0; j<10; j++) begin         //each channel runs 20 operations
		    //select random operation
		    if($urandom_range(1,2) == 1) begin  //select low
		      if($urandom_range(1,2)==1) begin  //select addition
		        state_trans.push_back('{$urandom $urandom, 4'h1, 0, 0, 0, 0,"addtion test"});
		       end else begin                   //select subtraction
		        state_trans.push_back('{$urandom, $urandom, 4'h2, 0, 0, 0, 0,"subtraction test"});  //set values to prevent underflow
		       end
		    end else begin                      //select high
		      if($urandom_range(5,6)==5) begin  //select shift left
		        state_trans.push_back('{$urandom, $urandom_range(0,10), 4'h5, 0, 0, 0, 0,"shift left test"});
		       end else begin                   //select shift right
		        state_trans.push_back('{$urandom, $urandom_range(0,10), 4'h6, 0, 0, 0, 0,"shift right test"});
		       end
		    end
		  end
    end
    state_trans.shuffle(); //randomize order
    
    foreach(state_trans[i]) begin
      $display("%p", state_trans[i]);
    end
    

	end else begin	//cycle mode, dunno how this works or if we need to test it
	
	end

  //summary: print summary of tests
  $display("\n=======================================================\nSUMMARY\n=======================================================\n");
  $display("errors: %0d, successes: %0d\n", error_count, success_count);
  foreach(error_messages[i]) begin
    $display(error_messages[i]);
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


/////////////////////////////////////////////////////////////////////////////////////// run transactions

task automatic run_trans(ref transaction t, input integer channel, input integer debug);

  if(channel == 1) begin

	  @(posedge c_clk);
	  cb.req1_data_in <= t.param1;	//written @ edge + 2ns
	  cb.req1_cmd_in <= t.cmd;			//written @ edge + 2ns

	  @(posedge c_clk);
	  cb.req1_data_in <= t.param2;	//written @ edge + 2ns
	  cb.req1_cmd_in <= 2'b00;										//written @ edge + 2ns
		
	  for(int i=0; i<10; i++) begin		//give it 10 cycles to respond
		  @(posedge c_clk);
		  if(i == 9) begin
		  	t.actual_resp = out_resp1;
	  		t.actual_data = out_data1;
	  		if(debug==1) begin
	  			$display("(1) no response, %p", t);
	  		end
		  end
		  else if (out_resp1 != 0) begin
			  t.actual_resp = out_resp1;
			  t.actual_data = out_data1;
			  if(debug==1) begin
				  $display("(1) response after %0d cycles, %p", i+1, t);
			  end
			  break;
		  end
	  end
	  
  end else if(channel == 2) begin
  
    @(posedge c_clk);
	  cb.req2_data_in <= t.param1;	//written @ edge + 2ns
	  cb.req2_cmd_in <= t.cmd;			//written @ edge + 2ns

	  @(posedge c_clk);
	  cb.req2_data_in <= t.param2;	//written @ edge + 2ns
	  cb.req2_cmd_in <= 2'b00;										//written @ edge + 2ns
		
	  for(int i=0; i<10; i++) begin		//give it 10 cycles to respond
		  @(posedge c_clk);
		  if(i == 9) begin
		  	t.actual_resp = out_resp2;
	  		t.actual_data = out_data2;
	  		if(debug==1) begin
	  			$display("(2) no response, %p", t);
	  		end
		  end
		  else if (out_resp2 != 0) begin
			  t.actual_resp = out_resp2;
			  t.actual_data = out_data2;
			  if(debug==1) begin
				  $display("(2) response after %0d cycles, %p", i+1, t);
			  end
			  break;
		  end
	  end
  
  end else if(channel == 3) begin
  
    @(posedge c_clk);
	  cb.req3_data_in <= t.param1;	//written @ edge + 2ns
	  cb.req3_cmd_in <= t.cmd;			//written @ edge + 2ns

	  @(posedge c_clk);
	  cb.req3_data_in <= t.param2;	//written @ edge + 2ns
	  cb.req3_cmd_in <= 2'b00;										//written @ edge + 2ns
		
	  for(int i=0; i<10; i++) begin		//give it 10 cycles to respond
		  @(posedge c_clk);
		  if(i == 9) begin
		  	t.actual_resp = out_resp3;
	  		t.actual_data = out_data3;
	  		if(debug==1) begin
	  			$display("(3) no response, %p", t);
	  		end
		  end
		  else if (out_resp3 != 0) begin
			  t.actual_resp = out_resp3;
			  t.actual_data = out_data3;
			  if(debug==1) begin
				  $display("(3) response after %0d cycles, %p", i+1, t);
			  end
			  break;
		  end
	  end
  
  end else if(channel == 4) begin
  
    @(posedge c_clk);
	  cb.req4_data_in <= t.param1;	//written @ edge + 2ns
	  cb.req4_cmd_in <= t.cmd;			//written @ edge + 2ns

	  @(posedge c_clk);
	  cb.req4_data_in <= t.param2;	//written @ edge + 2ns
	  cb.req4_cmd_in <= 2'b00;										//written @ edge + 2ns
		
	  for(int i=0; i<10; i++) begin		//give it 10 cycles to respond
		  @(posedge c_clk);
		  if(i == 9) begin
		  	t.actual_resp = out_resp4;
	  		t.actual_data = out_data4;
	  		if(debug==1) begin
	  			$display("(4) no response, %p", t);
	  		end
		  end
		  else if (out_resp4 != 0) begin
			  t.actual_resp = out_resp4;
			  t.actual_data = out_data4;
			  if(debug==1) begin
				  $display("(4) response after %0d cycles, %p", i+1, t);
			  end
			  break;
		  end
	  end
  
  end 

endtask

/////////////////////////////////////////////////////////////////////////////////////// other functions

task automatic set_expected (ref transaction t);

	if(t.cmd==4'b0000) begin				//no response
			
		t.expected_resp = 2'b00;
	
	end
	else if(t.cmd==4'b0001) begin	//addition
		
		if( t.param1 + t.param2 > 42'hFFFFFFF ) begin	//overflow
			t.expected_resp = 2'b10;
		end else begin
			t.expected_resp = 2'b01;
			t.expected_data = t.param1 + t.param2;
		end
	
	end
	else if(t.cmd==4'b0010) begin		//subtraction
	
		if(t.param1 < t.param2) begin	//underflow
			t.expected_resp = 2'b10;
		end else begin
			t.expected_resp = 2'b01;
			t.expected_data = t.param1 - t.param2;
		end
	
	end
	else if(t.cmd==4'b0101) begin	//shift left
		
		t.expected_resp = 2'b01;
		t.expected_data = t.param1 << t.param2;
		
	end
	else if(t.cmd==4'b0110) begin	//shift right
		
		t.expected_resp = 2'b01;
		t.expected_data = t.param1 >> t.param2;
		
	end
	else  begin

		t.expected_resp = 2'b11;

	end

endtask



task do_reset(inout bit [7:0] reset);	//reset the device

	for (int i=0;i<7;i++) begin	//Hold reset to '1111111'b for seven cycles
		@(posedge c_clk);
		reset[6:0] = 7'b1111111;
	end

	@(posedge c_clk) reset = 7'b0000000;
	
endtask



function automatic void check_trans(ref transaction t, input int channel, input int mode); //check transactions for actual/expected mismatches

  string tmp_string;

  if(mode == 0) begin   //check response only
  
    if(t.actual_resp != t.expected_resp) begin
      error_count = error_count + 1;
      $sformat(tmp_string, "%s: sent [%h,%h] with command %h, got [%h,%h] when expecting [%h,%h], on channel %0d",
      t.desc, t.param1, t.param2, t.cmd, t.actual_data, t.actual_resp, t.expected_data, t.expected_resp, channel);
     error_messages.push_back(tmp_string);
    end else begin
      success_count = success_count + 1;
    end
  
  end else if(mode == 1) begin  //check data only
  
    if(t.actual_data != t.expected_data) begin
      error_count = error_count + 1;
      $sformat(tmp_string, "%s: sent [%h,%h] with command %h, got [%h,%h] when expecting [%h,%h], on channel %0d",
      t.desc, t.param1, t.param2, t.cmd, t.actual_data, t.actual_resp, t.expected_data, t.expected_resp, channel);
     error_messages.push_back(tmp_string);
    end else begin
      success_count = success_count + 1;
    end
  
  end else begin  //check data and response

    if( (t.actual_data!=t.expected_data) && (t.actual_resp!=t.expected_resp) ) begin
      error_count = error_count + 1;
      $sformat(tmp_string, "%s: sent [%h,%h] with command %h, got [%h,%h] when expecting [%h,%h], on channel %0d",
      t.desc, t.param1, t.param2, t.cmd, t.actual_data, t.actual_resp, t.expected_data, t.expected_resp, channel);
      error_messages.push_back(tmp_string);
    end else begin
      success_count = success_count + 1;
    end

  end

endfunction


///////////////////////////////////////////////////////////////////////////////////////

endmodule


