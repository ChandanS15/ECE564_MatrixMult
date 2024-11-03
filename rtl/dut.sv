
// vlog -sv +incdir+../rtl/common ../rtl/dut.sv

`include "common.vh"

//`include "common.vh"
module MyDesign(
// System signals
  input wire reset_n,
  input wire clk,

// Control signals
  input wire dut_valid,
  output wire dut_ready,

// Input SRAM interface
  output wire dut__tb__sram_input_write_enable,
  output wire [`SRAM_ADDR_RANGE] dut__tb__sram_input_write_address,
  output wire [`SRAM_DATA_RANGE] dut__tb__sram_input_write_data,
  output wire [`SRAM_ADDR_RANGE] dut__tb__sram_input_read_address,
  input  wire [`SRAM_DATA_RANGE] tb__dut__sram_input_read_data,

// Weight SRAM interface
  output wire dut__tb__sram_weight_write_enable,
  output wire [`SRAM_ADDR_RANGE] dut__tb__sram_weight_write_address,
  output wire [`SRAM_DATA_RANGE] dut__tb__sram_weight_write_data,
  output wire [`SRAM_ADDR_RANGE] dut__tb__sram_weight_read_address,
  input  wire [`SRAM_DATA_RANGE] tb__dut__sram_weight_read_data,

// Result SRAM interface
  output wire dut__tb__sram_result_write_enable,
  output wire [`SRAM_ADDR_RANGE] dut__tb__sram_result_write_address,
  output wire [`SRAM_DATA_RANGE] dut__tb__sram_result_write_data,
  output wire [`SRAM_ADDR_RANGE] dut__tb__sram_result_read_address,
  input  wire [`SRAM_DATA_RANGE] tb__dut__sram_result_read_data,

  // scratchpad SRAM interface
  output wire dut__tb__sram_scratchpad_write_enable,
  output wire [`SRAM_ADDR_RANGE] dut__tb__sram_scratchpad_write_address,
  output wire [`SRAM_DATA_RANGE] dut__tb__sram_scratchpad_write_data,
  output wire [`SRAM_ADDR_RANGE] dut__tb__sram_scratchpad_read_address,
  input  wire [`SRAM_DATA_RANGE] tb__dut__sram_scratchpad_read_data
);


reg [`SRAM_DATA_RANGE/2] input_matrix_columns;       // register to number of memory locations to be read from Sram A and B
reg [`SRAM_DATA_RANGE/2] input_matrix_rows;          // register to number of memory locations to be read from Sram A and B

reg [`SRAM_DATA_RANGE/2 ] weight_matrix_columns;       // register to number of memory locations to be read from Sram A and B
reg [`SRAM_DATA_RANGE/2] weight_matrix_rows;          // register to number of memory locations to be read from Sram A and B

reg clear_mac_signal;

// Declare intermediate registers  to store the address of values to be read from SRAM A and B.
reg [`SRAM_ADDR_RANGE] dut__tb__sram_input_read_address_reg;
reg [`SRAM_ADDR_RANGE] dut__tb__sram_weight_read_address_reg;

reg [`SRAM_ADDR_RANGE] dut__tb__sram_result_write_address_reg;
reg [`SRAM_ADDR_RANGE] dut__tb__sram_scratchpad_write_address_reg;

reg [`SRAM_DATA_RANGE] dut__tb__sram_result_write_data_reg;
reg [`SRAM_DATA_RANGE] dut__tb__sram_scratchpad_write_data_reg;



  reg                           get_array_size            ;
  reg [1:0]                     read_addr_sel             ;
  reg                           compute_accumulation      ;
  reg                           save_array_size           ;
  reg                           write_enable          ;
  wire  [31:0] accumulator_ouput;   // Result from FP_add
  reg   [31:0] accumulator_addend;   // Input A of the FP_add 

reg dut_ready_reg; // register to store current DUT state
reg compute_complete;
reg read_cycle_complete;

reg all_write_complete_signal;

reg dut__tb__sram_scratchpad_write_enable_reg;
reg dut__tb__sram_result_write_enable_reg;
reg dut__tb__sram_weight_write_enable_reg;
reg dut__tb__sram_input_write_enable_reg;

wire [`SRAM_DATA_RANGE] mac_input_a;
wire [`SRAM_DATA_RANGE] mac_input_b;
wire [`SRAM_DATA_RANGE] mac_input_c;



reg [`SRAM_DATA_RANGE] input_matrix_column_counter;
reg [`SRAM_DATA_RANGE] input_matrix_row_counter;


reg [`SRAM_DATA_RANGE] weight_matrix_counter;
reg [`SRAM_DATA_RANGE] input_matrix_counter;

reg [`SRAM_DATA_RANGE] globalReadCounter;


reg weight_matrix_Read_Complete_Cycle_Complete_Signal;
reg input_matrix_Read_Complete_Cycle_Complete_Signal;
reg switch_to_next_weight_matrix_signal;


reg [`SRAM_DATA_RANGE] read_cycle_counter;
reg [`SRAM_DATA_RANGE] current_write_count;

 typedef enum bit[2:0] {
    IDLE                              = 3'd0, 
    READ_SRAM_ZERO_ADDR               = 3'd1,   
    READ_SRAM_FIRST_ARRAY_ELEMENT     = 3'd2,   
    READ_ALL_ELEMENTS                 = 3'd3,   
    WRITE_ACCUMULATED_VALUE           = 3'd4,   
    MAC_CLEAR                         = 3'd5, 
    COMPUTE_COMPLETE                  = 3'd6 } states;

states current_state, next_state;

//  typedef enum bit[2:0] {
    
//     QUERY = 3'd0,
//     KEY   = 3'd1,
//     VALUE = 3'd2,
//     SCORE = 3'd3,
//     ATTENTION = 3'd4
    
//  } matrix_multiplication;

// matrix_multiplication current_matrix;

reg [2:0] current_matrix;



always @(posedge clk) begin : proc_next_state
// Synchronous active low reset.
if(!reset_n) begin
  // If reset stay in the idle state.  
  current_state <= IDLE;

end else begin
  // if not in reset go to state 0 and read the 0th address.
  current_state <= next_state;
end
end

/* next state logic and output logic – combined so as to share state decode logic */
always @(*) begin : proc_next_state_fsm
  case (current_state)

    IDLE                    : begin
      if (dut_valid) begin
        dut_ready_reg       = 1'b0;
        get_array_size      = 1'b0;
        read_addr_sel       = 2'b00;
        compute_accumulation= 1'b0;
        save_array_size     = 1'b0;
        write_enable        = 1'b0;
        clear_mac_signal    = 1'b0;   
        input_matrix_Read_Complete_Cycle_Complete_Signal = 0;
        weight_matrix_Read_Complete_Cycle_Complete_Signal = 0;
        switch_to_next_weight_matrix_signal = 0;
        next_state          = READ_SRAM_ZERO_ADDR;
      end
      else begin
        dut_ready_reg       = 1'b1;
        get_array_size      = 1'b0;
        read_addr_sel       = 2'b00;
        compute_accumulation= 1'b0;
        write_enable        = 1'b0;
        save_array_size     = 1'b0;
        clear_mac_signal    = 1'b0;
        input_matrix_Read_Complete_Cycle_Complete_Signal = 0;
        weight_matrix_Read_Complete_Cycle_Complete_Signal = 0;
        switch_to_next_weight_matrix_signal = 0;
        next_state          = IDLE;
      end
    end
  
    READ_SRAM_ZERO_ADDR  : begin
      dut_ready_reg         = 1'b0;
      get_array_size        = 1'b1;
      read_addr_sel         = 2'b01;  // Increment the read addr
      compute_accumulation  = 1'b0;
      save_array_size       = 1'b0;
      clear_mac_signal      = 1'b0;
      write_enable          = 1'b0;
      input_matrix_Read_Complete_Cycle_Complete_Signal = 0;
      weight_matrix_Read_Complete_Cycle_Complete_Signal = 0;
      switch_to_next_weight_matrix_signal = 0;
      next_state            = READ_SRAM_FIRST_ARRAY_ELEMENT;
    end 

    READ_SRAM_FIRST_ARRAY_ELEMENT: begin
      dut_ready_reg         = 1'b0;
      get_array_size        = 1'b0;
      read_addr_sel         = 2'b01;  // Increment the read addr
      compute_accumulation  = 1'b0;
      save_array_size       = 1'b1; 
      clear_mac_signal      = 1'b0;      
      write_enable      = 1'b0;
      input_matrix_Read_Complete_Cycle_Complete_Signal = 0;
      weight_matrix_Read_Complete_Cycle_Complete_Signal = 0;
      switch_to_next_weight_matrix_signal = 0;
      next_state            = READ_ALL_ELEMENTS;    
    end

    READ_ALL_ELEMENTS     : begin
      dut_ready_reg         = 1'b0;
      get_array_size        = 1'b0;
      read_addr_sel         = read_cycle_complete ? ( all_write_complete_signal ? 2'b00 : 2'b10) : 2'b01;  // Keep incrementing the read addr
      compute_accumulation  = 1'b1;
      clear_mac_signal      = 1'b0;
      save_array_size       = 1'b1;
      write_enable          = 1'b0;
      input_matrix_Read_Complete_Cycle_Complete_Signal = (input_matrix_column_counter == input_matrix_columns ) ? 1 : 0;        
      weight_matrix_Read_Complete_Cycle_Complete_Signal = (weight_matrix_counter == ( current_matrix * (weight_matrix_columns * weight_matrix_rows)) ) ? 1: 0;
      switch_to_next_weight_matrix_signal =  (globalReadCounter  == ( current_matrix * input_matrix_rows) * (weight_matrix_columns * weight_matrix_rows)) ? 1 : 0;
      next_state            = read_cycle_complete ? WRITE_ACCUMULATED_VALUE : READ_ALL_ELEMENTS;
    end 

    WRITE_ACCUMULATED_VALUE : begin
      dut_ready_reg         = 1'b0;
      get_array_size        = 1'b0;
      read_addr_sel         = all_write_complete_signal ? 2'b00 :2'b10;  // Hold the address
      compute_accumulation  = 1'b1;
      save_array_size       = 1'b1;
      write_enable          = 1'b1;      
      clear_mac_signal      = 1'b0;
      input_matrix_Read_Complete_Cycle_Complete_Signal = 0;
      weight_matrix_Read_Complete_Cycle_Complete_Signal = 0;      
      switch_to_next_weight_matrix_signal = 0;
      next_state            = all_write_complete_signal ? COMPUTE_COMPLETE :MAC_CLEAR;
    end

    MAC_CLEAR : begin
      dut_ready_reg         = 1'b0;
      get_array_size        = 1'b0;
      read_addr_sel         = all_write_complete_signal ? 2'b00 : 2'b01;  // increment
      compute_accumulation  = 1'b1;
      save_array_size       = 1'b1;
      write_enable          = 1'b0;      
      clear_mac_signal      = 1'b1;
      input_matrix_Read_Complete_Cycle_Complete_Signal = 0;
      weight_matrix_Read_Complete_Cycle_Complete_Signal = 0;      
      switch_to_next_weight_matrix_signal = 0;
      next_state            = all_write_complete_signal ? COMPUTE_COMPLETE :  READ_ALL_ELEMENTS;  
    end

    COMPUTE_COMPLETE        : begin
      dut_ready_reg         = 1'b1;
      get_array_size        = 1'b0;
      read_addr_sel         = 2'b00;  
      compute_accumulation  = 1'b0;            
      clear_mac_signal      = 1'b0;
      input_matrix_Read_Complete_Cycle_Complete_Signal = 0;
      weight_matrix_Read_Complete_Cycle_Complete_Signal = 0;      
      switch_to_next_weight_matrix_signal = 0;
      save_array_size       = 1'b0;
      write_enable          = 1'b0;
      next_state            = IDLE;      
    end

    default                 :  begin
      dut_ready_reg         = 1'b1;
      get_array_size        = 1'b0;
      read_addr_sel         = 2'b00;  
      compute_accumulation  = 1'b0;
      save_array_size       = 1'b0;      
      clear_mac_signal      = 0;
      input_matrix_Read_Complete_Cycle_Complete_Signal = 0;
      weight_matrix_Read_Complete_Cycle_Complete_Signal = 0;      
      switch_to_next_weight_matrix_signal = 0;
      write_enable      = 1'b0;      
      next_state            = IDLE;
    end
  endcase
end

always @(posedge clk) begin : proc_initial_handshake
  if(!reset_n) begin
    compute_complete <= 0;
  end else begin
    compute_complete <= (dut_ready_reg) ? 1'b1 : 1'b0;
  end
end
assign dut_ready = compute_complete;


always @(posedge clk) begin : proc_read_zero_address
  if(!reset_n) begin
    input_matrix_columns  <= `SRAM_ADDR_WIDTH'b0;
    input_matrix_rows     <= `SRAM_ADDR_WIDTH'b0;
    weight_matrix_columns  <= `SRAM_ADDR_WIDTH'b0;
    weight_matrix_rows     <= `SRAM_ADDR_WIDTH'b0;
    dut__tb__sram_result_write_enable_reg <= 1'b0;
    dut__tb__sram_input_write_enable_reg <= 1'b0;
    dut__tb__sram_weight_write_enable_reg <= 1'b0;
    dut__tb__sram_scratchpad_write_enable_reg <= 1'b0;
  end else begin
    // If get_array_size is enabled in state, assign teh read data from sram to this register if not     
    input_matrix_rows    <= get_array_size ? tb__dut__sram_input_read_data[31:16] : (save_array_size ? input_matrix_rows : `SRAM_ADDR_WIDTH'b0);
    input_matrix_columns <= get_array_size ? tb__dut__sram_input_read_data[15:0] : (save_array_size ? input_matrix_columns : `SRAM_ADDR_WIDTH'b0);

    weight_matrix_rows    <= get_array_size ? tb__dut__sram_weight_read_data[31:16] : (save_array_size ? weight_matrix_rows : `SRAM_ADDR_WIDTH'b0);
    weight_matrix_columns <= get_array_size ? tb__dut__sram_weight_read_data[15:0] : (save_array_size ? weight_matrix_columns : `SRAM_ADDR_WIDTH'b0);
  end
end


// SRAM read address generator
always @(posedge clk) begin : proc_matrices_read
    if (!reset_n) begin

      input_matrix_row_counter <= 1;
      input_matrix_column_counter <= 0;
      dut__tb__sram_input_read_address_reg <= 0;


      dut__tb__sram_weight_read_address_reg <= 0;
      weight_matrix_counter <= 0;
      
      globalReadCounter <= 0;
    end
    else begin

      case(read_addr_sel)

      2'b00 :begin 
        dut__tb__sram_input_read_address_reg <= `SRAM_ADDR_WIDTH'b0;
        dut__tb__sram_weight_read_address_reg <= `SRAM_ADDR_WIDTH'b0;
        globalReadCounter <= 0;
        input_matrix_column_counter <= 0;
        input_matrix_row_counter <= 1;
        weight_matrix_counter <= 0;
      end

      2'b01: begin

        globalReadCounter <= globalReadCounter + 1;

        // Matrix A Address Generator
        dut__tb__sram_input_read_address_reg <= input_matrix_Read_Complete_Cycle_Complete_Signal ? 
                                                ( weight_matrix_Read_Complete_Cycle_Complete_Signal ?
                                                ( switch_to_next_weight_matrix_signal ? 
                                                  1 : (dut__tb__sram_input_read_address_reg + 1) ) : 
                                                  (( input_matrix_row_counter - 1) *input_matrix_columns + 1) ) : (dut__tb__sram_input_read_address_reg  + 1);

        input_matrix_column_counter <= input_matrix_Read_Complete_Cycle_Complete_Signal ? 1 : (input_matrix_column_counter + 1) ;
        input_matrix_row_counter <= weight_matrix_Read_Complete_Cycle_Complete_Signal ? ( switch_to_next_weight_matrix_signal  ? 1: (input_matrix_row_counter + 1)) : input_matrix_row_counter;

        // Matrix B Address Generator
        dut__tb__sram_weight_read_address_reg <= weight_matrix_Read_Complete_Cycle_Complete_Signal ? ( switch_to_next_weight_matrix_signal ? dut__tb__sram_weight_read_address_reg + 1 : (((current_matrix * (weight_matrix_columns * weight_matrix_rows)) + 1) - (weight_matrix_columns * weight_matrix_rows) ) ) : dut__tb__sram_weight_read_address_reg + 1;
        weight_matrix_counter <= weight_matrix_Read_Complete_Cycle_Complete_Signal ? ( switch_to_next_weight_matrix_signal ? weight_matrix_counter + 1 : ( ((current_matrix - 1)  * ( weight_matrix_columns * weight_matrix_rows)) + 1   )): weight_matrix_counter + 1; 
  

      end

      2'b10: begin

        dut__tb__sram_input_read_address_reg <= dut__tb__sram_input_read_address_reg;
        dut__tb__sram_weight_read_address_reg <= dut__tb__sram_weight_read_address_reg;
      end


      default: begin
          dut__tb__sram_input_read_address_reg <= `SRAM_ADDR_WIDTH'b01;
          dut__tb__sram_weight_read_address_reg <= `SRAM_ADDR_WIDTH'b01;  
      end
      endcase

    end
        
end


assign dut__tb__sram_weight_read_address = dut__tb__sram_weight_read_address_reg;



assign dut__tb__sram_input_read_address = dut__tb__sram_input_read_address_reg;

// READ N-elements in SRAM 
always @(posedge clk) begin : proc_read_cycle_computation
  if(!reset_n) begin    
    read_cycle_complete <= 1'b0;
  end else begin
    read_cycle_complete <= ( globalReadCounter == (current_write_count ? (input_matrix_columns* ( 1 + current_write_count))  : input_matrix_columns ) ) ? 1'b1 : 1'b0;    
  end
end

// READ N-elements in SRAM 
always @(posedge clk) begin : proc_write_completion
  if(!reset_n) begin    
    all_write_complete_signal <= 1'b0;
  end else begin
    all_write_complete_signal <= (((( 3 *(input_matrix_rows * weight_matrix_columns) ) ) - 1) == current_write_count) ? 1'b1 : 1'b0;
  end
end



// READ N-elements in SRAM 
always @(posedge clk) begin : proc_write_address_increment
  if(!reset_n) begin  
    current_write_count <= 0;
  end else begin
      current_write_count <= compute_complete ? 0 : write_enable ? current_write_count + 1 : current_write_count;
  end
end

always @(posedge clk) begin : proc_current_matrix_computation
  if(!reset_n) begin  
    current_matrix <= 1;
  end else begin
    current_matrix <= dut_ready_reg ? 1 : ( switch_to_next_weight_matrix_signal ? current_matrix + 1 : current_matrix);
  end
end


assign dut__tb__sram_result_write_enable = write_enable;
assign dut__tb__sram_scratchpad_write_enable = write_enable;
assign dut__tb__sram_input_write_enable  = dut__tb__sram_input_write_enable_reg;
assign dut__tb__sram_weight_write_enable = dut__tb__sram_weight_write_enable_reg;


// SRAM write address logic
always @(posedge clk) begin : proc_sram_write_address_r
  if(!reset_n) begin
    dut__tb__sram_result_write_address_reg <= 1'b0;
    dut__tb__sram_scratchpad_write_address_reg <= 1'b0;
  end else begin
    dut__tb__sram_result_write_address_reg <= compute_complete ? 0 : ((write_enable) ? dut__tb__sram_result_write_address_reg + 1 : dut__tb__sram_result_write_address_reg) ;
    dut__tb__sram_scratchpad_write_address_reg <= compute_complete ? 0 : ((write_enable) ? dut__tb__sram_scratchpad_write_address_reg + 1 : dut__tb__sram_scratchpad_write_address_reg) ;  
  end
end

assign dut__tb__sram_result_write_address = dut__tb__sram_result_write_address_reg;
assign dut__tb__sram_scratchpad_write_address = dut__tb__sram_scratchpad_write_address_reg;


// SRAM write data logic
always @(posedge clk) begin : proc_sram_write_data_r
  if(!reset_n) begin
    dut__tb__sram_result_write_data_reg <= `SRAM_DATA_WIDTH'b0;
    dut__tb__sram_scratchpad_write_data_reg <= `SRAM_DATA_WIDTH'b0;
  end else begin
    dut__tb__sram_result_write_data_reg <= (read_cycle_complete) ? accumulator_ouput : `SRAM_DATA_WIDTH'b0;
    dut__tb__sram_scratchpad_write_data_reg <= (read_cycle_complete) ? accumulator_ouput : `SRAM_DATA_WIDTH'b0;
  end
end

assign dut__tb__sram_result_write_data = dut__tb__sram_result_write_data_reg;
assign dut__tb__sram_scratchpad_write_data = dut__tb__sram_scratchpad_write_data_reg;

assign accumulator_ouput = (clear_mac_signal)  ? 0 : (tb__dut__sram_input_read_data * tb__dut__sram_weight_read_data) + accumulator_addend;

// Accumulation logic 
always @(posedge clk) begin : proc_accumulation
  if(!reset_n) begin
    accumulator_addend   <= `SRAM_DATA_WIDTH'b0;
  end else begin
    if (compute_accumulation) begin
      accumulator_addend <= accumulator_ouput;
    end
    else begin
      accumulator_addend <= `SRAM_DATA_WIDTH'b0;
    end
  end
end



//assign mac_input_a = (clear_mac_signal)  ? 0 : tb__dut__sram_input_read_data;
//assign mac_input_b = (clear_mac_signal)  ? 0 : tb__dut__sram_weight_read_data;
assign mac_input_c = (clear_mac_signal)  ? 0 : accumulator_addend;




// // Floating-point multiply-accumulate instance
// DW_fp_mac_inst FP_MAC (
//   .inst_a(mac_input_a),
//   .inst_b(mac_input_b),
//   .inst_c(mac_input_c),
//   .inst_rnd(3'd0),
//   .z_inst(accumulator_ouput),
//   .status_inst()
// );

endmodule


