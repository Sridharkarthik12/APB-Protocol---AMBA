
module apb_slave_tb ();
  
	reg 			pclk;
	reg 			preset_n; 	// Active low reset
 
  reg [1:0]		add_i;		// 2'b00 - NOP, 2'b01 - READ, 2'b11 - WRITE
  
	reg 			psel_o;
	reg 			penable_o;
  reg [31:0] paddr_o;
	reg			pwrite_o;
  reg [31:0] 	pwdata_o;
  reg [31:0]	prdata_i;
 	reg			pready_i;
  
  // Implement clock
  always begin
    pclk = 1'b0;
    #5;
    pclk = 1'b1;
    #5;
  end

  
  // Drive stimulus
  initial begin
    preset_n = 1'b0;
    add_i = 2'b00;
    repeat (2) `CLK;
    preset_n = 1'b1;
    repeat (2) `CLK;
    
    // Initiate a read transaction
    add_i = 2'b01;
    `CLK;
    add_i = 2'b00;
    repeat (4) `CLK;
    
    // Initiate a write transaction
    add_i = 2'b11;
    `CLK;
    add_i = 2'b00;
    repeat (4) `CLK;
    $finish();
  end
  
  // APB Slave
  always_ff @(posedge pclk or negedge preset_n) begin
    if (~preset_n)
      pready_i <= 1'b0;
    else begin
    if (psel_o && penable_o) begin
      pready_i <= 1'b1;
      prdata_i <= $random%32'h20;
    end else begin
      pready_i <= 1'b0;
      prdata_i <= $random%32'hFF;
    end
    end
  end 
endmodule
