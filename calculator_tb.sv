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
	transaction concurrent_trans[$];        //concurrent operation transactions
	transaction corner_cases[$];            //corner cases tests
	transaction port_priority[$];           //test for port priority
	transaction shift_trans[$];				//test for only the lower 5 bits of the second shift operand is used
	
	int random_sequence_queue[$];
	
	int channel_responded[4];
	int port_priority_count[16];
	
	int error_count=0, success_count=0;
  string error_messages[$];
  string tmp_string;

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

	$display("\n");	//space seperator for output
	
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
		
		error_messages.push_back("\n1.1 and 1.3: test responses\n");
		
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
		
		error_messages.push_back("\n1.2: basic operations testing\n");
		
		//1.2 operations testing for each channel
		for(int j=1; j<5; j++) begin		//for every channel
		  foreach(operation_trans[i]) begin
		   set_expected(operation_trans[i]);
		   run_trans(operation_trans[i], j, 0);      //debug on
		   check_trans(operation_trans[i], j, 3);    //mode 3: check data and response
		  end
		
		  do_reset(reset);  //reset after finnished with each channel
		  
	  end
	  
	  error_messages.push_back("\n2.1.1: test for 'dirty state' issues\n");
	  
	  //2.1.1 test that device state is clean after each operation
	  //direct testing
		state_trans.push_back('{32'hFF236, 32'h5CCAB2, 4'h1, 0, 0, 0, 0,"addtion test"});
		state_trans.push_back('{32'h11111111, 32'h212134, 4'h1, 0, 0, 0, 0,"addtion test"});
		state_trans.push_back('{32'h1A618A23, 32'hCE456712, 4'h1, 0, 0, 0, 0,"addtion test"});
		
		state_trans.push_back('{32'hFFFF236, 32'h5CCAB2, 4'h2, 0, 0, 0, 0,"subtraction test"});
		state_trans.push_back('{32'h11111111, 32'h212134, 4'h2, 0, 0, 0, 0,"subtraction test"});
		state_trans.push_back('{32'hFA618A23, 32'hCE456712, 4'h2, 0, 0, 0, 0,"subtraction test"});
		
		state_trans.push_back('{32'hFFFF236, 32'h11, 4'h5, 0, 0, 0, 0,"shift left test"});
		state_trans.push_back('{32'h11111111, 32'h8, 4'h5, 0, 0, 0, 0,"shift left test"});
		state_trans.push_back('{32'hFA618A23, 32'h10, 4'h5, 0, 0, 0, 0,"shift left test"});
		
		state_trans.push_back('{32'hFFFF236, 32'h11, 4'h6, 0, 0, 0, 0,"shift right test"});
		state_trans.push_back('{32'h11111111, 32'h8, 4'h6, 0, 0, 0, 0,"shift right test"});
		state_trans.push_back('{32'hFA618A23, 32'hCE456712, 4'h6, 0, 0, 0, 0,"shift right test"});
		//random testing not allowed
		/*
		for(int i=0; i<80; i++) begin            //generate 80 random operations (20 operations per channel)
		  //select random operation
      if($urandom_range(1,2) == 1) begin  //select low
	      if($urandom_range(1,2)==1) begin  //select addition
		      state_trans.push_back('{$urandom, $urandom, 4'h1, 0, 0, 0, 0,"addtion test"});
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
    */
    
    //test dirty state generation on each channel
    for(int i=1; i<5; i++) begin          //for each channel
		  foreach(state_trans[j])  begin      //run operations sequentially
		    set_expected(state_trans[j]);
		    run_trans(state_trans[j], i, 0);
		    check_trans(state_trans[j], i, 3);     //mode 3: check data and response
		  end
		  
		  do_reset(reset);  //reset when done with each channel
		  
		end
    
    //test dirty state generation between channels
    for(int i=1; i<5; i++) begin          //for each channel
      for(int j=0; j<3; j++) begin       //allocate 3 operations
        random_sequence_queue.push_back(i);
      end
    end
    random_sequence_queue.shuffle();      //randomize order
    
    //run tests
    for(int i=0; i<state_trans.size(); i++) begin
      set_expected(state_trans[i]);
		  run_trans(state_trans[i], random_sequence_queue[i], 0);
		  check_trans(state_trans[i], random_sequence_queue[i], 3);    //mode 3: check data and response
    end
    
    do_reset(reset); //reset when done
    
    error_messages.push_back("\n2.1.2: concurrent operations testing\n");
    
    //2.1.2 test concurrent operations
    
    //direct testing
    for(int i=0; i<3; i++) begin  //generates 36 transactions
		  concurrent_trans.push_back('{32'hFF236, 32'h5CCAB2, 4'h1, 0, 0, 0, 0,"addtion test"});
		  concurrent_trans.push_back('{32'h11111111, 32'h212134, 4'h1, 0, 0, 0, 0,"addtion test"});
		  concurrent_trans.push_back('{32'h1A618A23, 32'hCE456712, 4'h1, 0, 0, 0, 0,"addtion test"});
		  
		  concurrent_trans.push_back('{32'hFFFF236, 32'h5CCAB2, 4'h2, 0, 0, 0, 0,"subtraction test"});
		  concurrent_trans.push_back('{32'h11111111, 32'h212134, 4'h2, 0, 0, 0, 0,"subtraction test"});
		  concurrent_trans.push_back('{32'hFA618A23, 32'hCE456712, 4'h2, 0, 0, 0, 0,"subtraction test"});
		  
		  concurrent_trans.push_back('{32'hFFFF236, 32'h11, 4'h5, 0, 0, 0, 0,"shift left test"});
		  concurrent_trans.push_back('{32'h11111111, 32'h8, 4'h5, 0, 0, 0, 0,"shift left test"});
		  concurrent_trans.push_back('{32'hFA618A23, 32'h10, 4'h5, 0, 0, 0, 0,"shift left test"});
		  
		  concurrent_trans.push_back('{32'hFFFF236, 32'h11, 4'h6, 0, 0, 0, 0,"shift right test"});
		  concurrent_trans.push_back('{32'h11111111, 32'h8, 4'h6, 0, 0, 0, 0,"shift right test"});
		  concurrent_trans.push_back('{32'hFA618A23, 32'hCE456712, 4'h6, 0, 0, 0, 0,"shift right test"});
    end
    //generate 40 random operations
    /*  random testing not allowed
    for(int i=0; i<40; i++) begin
      if($urandom_range(1,2) == 1) begin  //select low
	      if($urandom_range(1,2)==1) begin  //select addition
		      concurrent_trans.push_back('{$urandom, $urandom, 4'h1, 0, 0, 0, 0,"addtion test"});
	      end else begin                   //select subtraction
		      concurrent_trans.push_back('{$urandom, $urandom, 4'h2, 0, 0, 0, 0,"subtraction test"});  //set values to prevent underflow
		    end
		  end else begin                      //select high
		    if($urandom_range(5,6)==5) begin  //select shift left
          concurrent_trans.push_back('{$urandom, $urandom_range(0,10), 4'h5, 0, 0, 0, 0,"shift left test"});
	      end else begin                   //select shift right
		      concurrent_trans.push_back('{$urandom, $urandom_range(0,10), 4'h6, 0, 0, 0, 0,"shift right test"});
		    end
		  end
    end
    */
    
    foreach(concurrent_trans[i]) begin    //set expected on its own loop, since we're running 4 transactions at a time
      set_expected(concurrent_trans[i]);
    end
    
    for(int i=0; i<36; i = i+4) begin //run with an operation on each channel, loop 9 times
		  run_trans_concurrent(concurrent_trans[i], concurrent_trans[i+1], concurrent_trans[i+2], concurrent_trans[i+3], 0);
    end
    
    for(int i=0, c=1; i<concurrent_trans.size(); i++) begin    //check transactions in its own loop, since we're running 4 transactions at a time
      check_trans(concurrent_trans[i], c,3);
      if(c==4) begin  //reset channel counter if 4
        c = 1;
      end else begin  //else increment channel counter
        c = c + 1;
      end
    end
    
    do_reset(reset); //reset when done
    
    //2.2 port priority
    
    //save 4 operations
    port_priority.push_back('{32'h227, 32'h568, 4'h1, 0, 0, 0, 0, "port priority test"});
    
    for(int i=0; i<20; i++) begin    //run concurrently, 20 iterations
		   
      @(posedge c_clk);
	    cb.req1_data_in <= concurrent_trans[0].param1;
	    cb.req1_cmd_in <= concurrent_trans[0].cmd;
	    cb.req2_data_in <= concurrent_trans[0].param1;
	    cb.req2_cmd_in <= concurrent_trans[0].cmd;
	    cb.req3_data_in <= concurrent_trans[0].param1;
	    cb.req3_cmd_in <= concurrent_trans[0].cmd;
	    cb.req4_data_in <= concurrent_trans[0].param1;
	    cb.req4_cmd_in <= concurrent_trans[0].cmd;

	    @(posedge c_clk);
	    cb.req1_data_in <= concurrent_trans[0].param2;
	    cb.req1_cmd_in <= 2'b00;
	    cb.req2_data_in <= concurrent_trans[0].param2;
	    cb.req2_cmd_in <= 2'b00;
	    cb.req3_data_in <= concurrent_trans[0].param2;
	    cb.req3_cmd_in <= 2'b00;
	    cb.req4_data_in <= concurrent_trans[0].param2;
	    cb.req4_cmd_in <= 2'b00;
		      
		  foreach(channel_responded[i]) begin
	      channel_responded[i] = 0;
	    end
		      
	    for(int j=0,k=0; j<15; j++) begin		//collect repsonses over 15 cycles
	      @(posedge c_clk);
	      if ( (out_resp1 != 0) && (channel_responded[0]!=1) ) begin
	         port_priority_count[k] = port_priority_count[k] + 1;
	         k = k + 4;   //iterate k to count next place
	         channel_responded[0] = 1;
	      end
	      if ( (out_resp2 != 0) && (channel_responded[1]!=1) ) begin
	         port_priority_count[1+k] = port_priority_count[1+k] + 1;
	         k = k + 4;   //iterate k to count next place
	         channel_responded[1] = 1;
	      end
	      if ( (out_resp3 != 0) && (channel_responded[2]!=1) ) begin
          port_priority_count[2+k] = port_priority_count[2+k] + 1;
          k = k + 4;   //iterate k to count next place
          channel_responded[2] = 1;
        end
        if ( (out_resp4 != 0) && (channel_responded[3]!=1) ) begin
          port_priority_count[3+k] = port_priority_count[3+k] + 1;
          k = k + 4;   //iterate k to count next place
          channel_responded[3] = 1;
        end
      end
    
    end
    
    error_messages.push_back("\n2.2: port priority test\n");
    $sformat(tmp_string, "first place counts:  ch1:%0d, ch2:%0d, ch3:%0d, ch4:%0d",port_priority_count[0],port_priority_count[1],port_priority_count[2],port_priority_count[3]);
    error_messages.push_back(tmp_string);
    $sformat(tmp_string, "second place counts: ch1:%0d, ch2:%0d, ch3:%0d, ch4:%0d",port_priority_count[4],port_priority_count[5],port_priority_count[6],port_priority_count[7]);
    error_messages.push_back(tmp_string);
    $sformat(tmp_string, "third place counts:  ch1:%0d, ch2:%0d, ch3:%0d, ch4:%0d",port_priority_count[8],port_priority_count[9],port_priority_count[10],port_priority_count[11]);
    error_messages.push_back(tmp_string);
    $sformat(tmp_string, "fourth place counts: ch1:%0d, ch2:%0d, ch3:%0d, ch4:%0d", port_priority_count[12], port_priority_count[13], port_priority_count[14], port_priority_count[15]);
    error_messages.push_back(tmp_string);
    
    
    //2.3 check that only the lower 5 bits of the second shift operand is used

	do_reset(reset); //reset when done
    error_messages.push_back("\n2.3: check that only the lower 5 bits of the second shift operand is used\n");
	
	//Test left shift with higher bits set
	shift_trans.push_back('{32'hFFFFFFFF, 32'h00A0CC03, 4'h5, 0, 0, 0, 0,"shift left with higher bits set test"});
	shift_trans.push_back('{32'h0000FFFF, 32'h00A0CC03, 4'h5, 0, 0, 0, 0,"shift left with higher bits set test"}); 	
	//Test right shift with higher bits set
	shift_trans.push_back('{32'hFFFFFFFF, 32'h00A0CC03, 4'h6, 0, 0, 0, 0,"shift right with higher bits set test"});
	shift_trans.push_back('{32'hFFFF0000, 32'h00A0CC13, 4'h6, 0, 0, 0, 0,"shift right with higher bits set test"});

	//1.2 operations testing for each channel
		for(int j=1; j<5; j++) begin		//for every channel
		  foreach(shift_trans[i]) begin		  
		   set_shift_expected(shift_trans[i]);
		   run_trans(shift_trans[i], j, 0);      //debug on
		   check_trans(shift_trans[i], j, 3);    //mode 3: check data and response
		  end
		
		  do_reset(reset);  //reset after finnished with each channel
		  
	  end
    
    do_reset(reset);
    error_messages.push_back("\n2.4: corner cases \n");
    
    //corner cases 2.4.1: add 2 numbers that overflow by one
    corner_cases.push_back('{32'hC4437B63, 32'h3BBC849D, 4'h1, 0, 0, 0, 0, "overflow by 1"});
    
    //corner cases 2.4.2: add 2 numbers which sum to 0xFFFFFFFF
    corner_cases.push_back('{32'hC4437B62, 32'h3BBC849D, 4'h1, 0, 0, 0, 0, "exactly max"});
    
    //corner cases 2.4.3: subtract 2 equal numbers
    corner_cases.push_back('{32'hADD267E4, 32'hADD267E4, 4'h2, 0, 0, 0, 0, "subtract equal"});
    
    //corner cases 2.4.4: subtract a number that underflows by 1
    corner_cases.push_back('{32'hC4437B62, 32'hC4437B63, 4'h2, 0, 0, 0, 0, "underflow by 1"});
    
    //corner cases 2.4.5: shift left/right zero places
    corner_cases.push_back('{32'hC4437B62, 32'h0, 4'h5, 0, 0, 0, 0, "shift left 0 places"});
    corner_cases.push_back('{32'hC4437B62, 32'h0, 4'h6, 0, 0, 0, 0, "shift right 0 places"});
    
    //corner cases 2.4.6: shift left/right 31 places
    corner_cases.push_back('{32'hC4437B62, 32'h1F, 4'h5, 0, 0, 0, 0, "shift left 31 places"});
    corner_cases.push_back('{32'hC4437B62, 32'h1F, 4'h6, 0, 0, 0, 0, "shift right 31 places"});
    
    //run each corner case on each channel
    for(int i=1; i<5; i++) begin
      foreach(corner_cases[j]) begin
        set_expected(corner_cases[j]);
		    run_trans(corner_cases[j], i, 0);
		    check_trans(corner_cases[j], i, 3);    //mode 3: check data and response
      end
    end
    
    error_messages.push_back("\n2.5: check that data is ignored when its supposed to be\n");
    
    //corner cases 2.5: check that data is ignored when its supposed to be
    //this requires a custom run function
    do_reset(reset);
    
    for(int k=1; k<5; k++) begin        //for every channel
      
      do_reset(reset);  //reset before testing on each channel begins
      
      foreach(operation_trans[j]) begin //for each operation
    
        if(k == 1) begin

	        @(posedge c_clk);
	        cb.req1_data_in <= operation_trans[j].param1;
	        cb.req1_cmd_in <= operation_trans[j].cmd;

	        @(posedge c_clk);
	        cb.req1_data_in <= operation_trans[j].param2;
	        cb.req1_cmd_in <= 2'b10;
	        
	        @(posedge c_clk);
	        cb.req1_data_in <= 32'hFF3;
	        cb.req1_cmd_in <= 2'b10;
		      
	        for(int i=0; i<10; i++) begin		//give it 10 cycles to respond
		        @(posedge c_clk);
		        if(i == 9) begin
		        	operation_trans[j].actual_resp = out_resp1;
	        		operation_trans[j].actual_data = out_data1;
		        end
		        else if (out_resp1 != 0) begin
			        operation_trans[j].actual_resp = out_resp1;
			        operation_trans[j].actual_data = out_data1;
			        i = 10;
		        end
	        end
	        
        end else if(k == 2) begin
        
          @(posedge c_clk);
	        cb.req2_data_in <= operation_trans[j].param1;
	        cb.req2_cmd_in <= operation_trans[j].cmd;

	        @(posedge c_clk);
	        cb.req2_data_in <= operation_trans[j].param2;
	        cb.req2_cmd_in <= 2'b00;
	        
	        @(posedge c_clk);
	        cb.req1_data_in <= 32'hFF3;
	        cb.req1_cmd_in <= 2'b10;
		      
	        for(int i=0; i<10; i++) begin		//give it 10 cycles to respond
		        @(posedge c_clk);
		        if(i == 9) begin
		        	operation_trans[j].actual_resp = out_resp2;
	        		operation_trans[j].actual_data = out_data2;
		        end
		        else if (out_resp2 != 0) begin
			        operation_trans[j].actual_resp = out_resp2;
			        operation_trans[j].actual_data = out_data2;
			        i = 10;
		        end
	        end
        
        end else if(k == 3) begin
        
          @(posedge c_clk);
	        cb.req3_data_in <= operation_trans[j].param1;	//written @ edge + 2ns
	        cb.req3_cmd_in <= operation_trans[j].cmd;			//written @ edge + 2ns

	        @(posedge c_clk);
	        cb.req3_data_in <= operation_trans[j].param2;	//written @ edge + 2ns
	        cb.req3_cmd_in <= 2'b00;
	        
	        @(posedge c_clk);
	        cb.req1_data_in <= 32'hFF3;
	        cb.req1_cmd_in <= 2'b10;
		      
	        for(int i=0; i<10; i++) begin		//give it 10 cycles to respond
		        @(posedge c_clk);
		        if(i == 9) begin
		        	operation_trans[j].actual_resp = out_resp3;
	        		operation_trans[j].actual_data = out_data3;
		        end
		        else if (out_resp3 != 0) begin
			        operation_trans[j].actual_resp = out_resp3;
			        operation_trans[j].actual_data = out_data3;
			        i = 10;
		        end
	        end
        
        end else if(k == 4) begin
        
          @(posedge c_clk);
	        cb.req4_data_in <= operation_trans[j].param1;
	        cb.req4_cmd_in <= operation_trans[j].cmd;

	        @(posedge c_clk);
	        cb.req4_data_in <= operation_trans[j].param2;
	        cb.req4_cmd_in <= 2'b00;
	        
	        @(posedge c_clk);
	        cb.req1_data_in <= 32'hFF3;
	        cb.req1_cmd_in <= 2'b10;
		      
	        for(int i=0; i<10; i++) begin		//give it 10 cycles to respond
		        @(posedge c_clk);
		        if(i == 9) begin
		        	operation_trans[j].actual_resp = out_resp4;
	        		operation_trans[j].actual_data = out_data4;
		        end
		        else if (out_resp4 != 0) begin
			        operation_trans[j].actual_resp = out_resp4;
			        operation_trans[j].actual_data = out_data4;
			        i = 10;
		        end
	        end
    
        end
        
        //queue reused, actual_data overwritten on next iteration, so check transaction immediatly
        check_trans(operation_trans[j], k, 3);
        
      end //close foreach(operation_trans[j])
    end //close channel iteration loop, iterator k
    
    //END OF EVENT MODE TESTING

	end else begin	//cycle mode, could not find any mention of how this works, or whether we need to test it
	
	end

  //summary: print summary of tests
  $display("\n=======================================================\nSUMMARY\n=======================================================\n");
  $display("errors: %0d, successes: %0d\n", error_count, success_count);
  foreach(error_messages[i]) begin
    $display(error_messages[i]);
  end
  
  

end

/////////////////////////////////////////////////////////////////////////////////////// DUT hookup

calc1_top calc1_top(
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
			  i = 10;
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
			  i = 10;
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
			  i = 10;
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
			  i = 10;
		  end
	  end
  
  end

endtask

task automatic run_trans_concurrent(ref transaction t1, t2, t3, t4, input integer debug);

  @(posedge c_clk);
	cb.req1_data_in <= t1.param1;
	cb.req1_cmd_in <= t1.cmd;
	cb.req2_data_in <= t2.param1;
	cb.req2_cmd_in <= t2.cmd;
	cb.req3_data_in <= t3.param1;
	cb.req3_cmd_in <= t3.cmd;
	cb.req4_data_in <= t4.param1;
	cb.req4_cmd_in <= t4.cmd;

	@(posedge c_clk);
	cb.req1_data_in <= t1.param2;
	cb.req1_cmd_in <= 2'b00;
	cb.req2_data_in <= t2.param2;
	cb.req2_cmd_in <= 2'b00;
	cb.req3_data_in <= t3.param2;
	cb.req3_cmd_in <= 2'b00;
	cb.req4_data_in <= t4.param2;
	cb.req4_cmd_in <= 2'b00;
		
	foreach(channel_responded[i]) begin
	  channel_responded[i] = 0;
	end
		
	for(int i=0; i<10; i++) begin		//give it 10 cycles to respond
	  @(posedge c_clk);
	  if(i == 9) begin
	  
	     if(channel_responded[0]==0) begin
	       t1.actual_resp = out_resp1;
		     t1.actual_data = out_data1;
		     if(debug==1) begin
	         $display("no response on channel 1, %p", t1);
	       end
	     end else if(channel_responded[1]==0) begin
	       t2.actual_resp = out_resp2;
		     t2.actual_data = out_data2;
		     if(debug==1) begin
	         $display("no response on channel 2, %p", t2);
	       end
	     end else if(channel_responded[2]==0) begin
	       t3.actual_resp = out_resp3;
		     t3.actual_data = out_data3;
		     if(debug==1) begin
	         $display("no response on channel 3, %p", t3);
	       end
	     end else if(channel_responded[3]==0) begin
	       t4.actual_resp = out_resp4;
		     t4.actual_data = out_data4;
		     if(debug==1) begin
	         $display("no response on channel 4, %p", t4);
	       end
	     end
	     
	  end else if (out_resp1 != 0) begin
	    t1.actual_resp = out_resp1;
		  t1.actual_data = out_data1;
		  if(debug==1) begin
		    $display("channel 1 response after %0d cycles, %p", i+1, t1);
		  end
		  channel_responded[0] = 1;
	  end else if (out_resp2 != 0) begin
	    t2.actual_resp = out_resp2;
		  t2.actual_data = out_data2;
		  if(debug==1) begin
		    $display("channel 2 response after %0d cycles, %p", i+1, t2);
		  end
		  channel_responded[1] = 1;
	  end else if (out_resp3 != 0) begin
	    t3.actual_resp = out_resp3;
		  t3.actual_data = out_data3;
		  if(debug==1) begin
		    $display("channel 3 response after %0d cycles, %p", i+1, t3);
		  end
		  channel_responded[2] = 1;
	  end else if (out_resp4 != 0) begin
	    t4.actual_resp = out_resp4;
		  t4.actual_data = out_data4;
		  if(debug==1) begin
		    $display("channel 4 response after %0d cycles, %p", i+1, t4);
		  end
		  channel_responded[3] = 1; 
	  end
	  
	  if(channel_responded[0]&&channel_responded[1]&&channel_responded[2]&&channel_responded[3]) begin
		  i=10; //if every channel has responded, break loop
	  end
	  
  end

endtask

/////////////////////////////////////////////////////////////////////////////////////// other functions

task automatic set_expected (ref transaction t);

	if(t.cmd==4'b0000) begin				//no response
			
		t.expected_resp = 2'b00;
	
	end
	else if(t.cmd==4'b0001) begin	//addition
		
		longint result = t.param1 + t.param2;
		longint max = 64'h00000000FFFFFFFF;
		
		if( result > max ) begin	//overflow
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

task automatic set_shift_expected (ref transaction t);


	t.param2=t.param2[4:0];
	if(t.cmd==4'b0101) begin	//shift left
		
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

    if( (t.actual_data==t.expected_data) && (t.actual_resp==t.expected_resp) ) begin
      success_count = success_count + 1;
    end else begin
      error_count = error_count + 1;
      $sformat(tmp_string, "%s: sent [%h,%h] with command %h, got [%h,%h] when expecting [%h,%h], on channel %0d",
      t.desc, t.param1, t.param2, t.cmd, t.actual_data, t.actual_resp, t.expected_data, t.expected_resp, channel);
      error_messages.push_back(tmp_string);
    end

  end

endfunction


///////////////////////////////////////////////////////////////////////////////////////

endmodule


