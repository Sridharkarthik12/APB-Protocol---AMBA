module Apb (
  input  			      pclk,
  input  			      preset_n, 	// Active low reset
 
  input	[1:0]		    add_i,		// 2'b00 - NOP, 2'b01 - READ, 2'b11 - WRITE
  
  output 			      sel,      // to select the slave.here since only on slave,only one bit
  output  			    enable,     
  input             ready_i,    // slave ready 
  output  [31:0]	  addr,      // address
  output 		        write_o,  // 1=WRITE , 0=READ
  input [31:0]      rdata_i,  // read data
  output  [31:0] 	  wdata_o   //write data
);
  
  reg [1:0]         current_state;
 parameter ST_IDLE=2'b00, ST_SETUP=2'b01, ST_ACCESS=2'b10;
  reg [1:0]         nxt_state;
  

  
  reg  nxt_write;  //to capture add[0] at setup
  reg  write_q;    // 1=write,0=read;finally we will assign this to write_o
  
  reg [31:0] nxt_rdata;
  reg [31:0] rdata_q;
  
  always @(posedge pclk or negedge preset_n)
  if (~preset_n)
      current_state <= ST_IDLE;
  else
      current_state <= nxt_state;
  
  always @(posedge pclk) 
  begin
    nxt_write = write_q;
    nxt_rdata = rdata_q;
  case (current_state)
    ST_IDLE:
      if (add_i[0]) begin
          nxt_state = ST_SETUP;
          nxt_write = add_i[1];
      end else begin
          nxt_state = ST_IDLE;
      end
    ST_SETUP: nxt_state = ST_ACCESS;
    ST_ACCESS:
      if (ready_i) begin
        if (~write_q)
            nxt_rdata = rdata_i;
            nxt_state = ST_IDLE;
      end else
          nxt_state = ST_ACCESS;
    default: nxt_state = ST_IDLE;
  endcase
end
  
 
  
  assign sel = (current_state == ST_SETUP)| (current_state == ST_ACCESS);
  assign enable = current_state== ST_ACCESS;
  
  // APB Address
  assign paddr_o = {32{current_state==ST_ACCESS}} & 32'hA000;
  
  // APB PWRITE control signal
  always  @(posedge pclk or negedge preset_n)
    if (~preset_n)
      write_q <= 1'b0;
  	else
      write_q <= nxt_write;
  
  assign write_o = write_q;
  
  // APB PWDATA data signal
  // ADDER
  // Read a value from the slave at address 0xA000
  // Increment that value
  // Send that value back during the write operation to address 0xA000
  
  assign wdata_o = {32{current_state==ST_ACCESS}} & (rdata_q + 32'h1);
  
  
  always @(posedge pclk or negedge preset_n)
    if (~preset_n)
      rdata_q <= 32'h0;
  	else
      rdata_q <= nxt_rdata;
  
endmodule
