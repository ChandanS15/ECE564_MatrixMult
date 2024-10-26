`include "common.vh"

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
  input  wire [`SRAM_DATA_RANGE] tb__dut__sram_result_read_data
);


reg [`SRAM_DATA_RANGE] previous_value;     // register to store accumulated value
wire[`SRAM_DATA_RANGE] current_result;
wire[`SRAM_DATA_RANGE] mac_result_z;
reg[`SRAM_DATA_RANGE] computed_result_reg;
wire[`SRAM_DATA_RANGE] computed_result_wire;
reg[`SRAM_DATA_RANGE] accumulated_reg;

reg [`SRAM_DATA_RANGE/2] matrixAColumns;       // register to number of memory locations to be read from Sram A and B
reg [`SRAM_DATA_RANGE/2] matrixARows;          // register to number of memory locations to be read from Sram A and B

reg [`SRAM_DATA_RANGE/2 ] matrixBColumns;       // register to number of memory locations to be read from Sram A and B
reg [`SRAM_DATA_RANGE/2] matrixBRows;          // register to number of memory locations to be read from Sram A and B

reg clear_mac_signal;
reg clear_mac_signal2;

// Declare intermediate registers  to store the address of values to be read from SRAM A and B.
reg [`SRAM_ADDR_RANGE] dut__tb__sram_input_read_address_reg;
reg [`SRAM_ADDR_RANGE] dut__tb__sram_weight_read_address_reg;
reg [`SRAM_ADDR_RANGE] dut__tb__sram_result_write_address_reg;
reg [`SRAM_DATA_RANGE]dut__tb__sram_result_write_data_reg;
reg [`SRAM_DATA_RANGE] sram_result_write_address_reg;



  reg                           get_array_size            ;
  reg [1:0]                     read_addr_sel             ;
  reg                           all_element_read_completed;
  reg                           compute_accumulation      ;
  reg                           save_array_size           ;
  reg                           write_enable_sel          ;
  reg                           switch_matrix_A_row_signal;
  wire  [31:0] sum_w;   // Result from FP_add
  reg   [31:0] sum_r;   // Input A of the FP_add 

reg dut_ready_reg; // register to store current DUT state
reg write_enable;
reg read_enable;
reg compute_complete;
reg read_cycle_complete;

reg all_write_complete;

reg dut__tb__sram_result_write_enable_reg;
reg dut__tb__sram_weight_write_enable_reg;
reg dut__tb__sram_input_write_enable_reg;

reg [`SRAM_DATA_RANGE] default_mac_input;

wire [`SRAM_DATA_RANGE] mac_input_a;
wire [`SRAM_DATA_RANGE] mac_input_b;
wire [`SRAM_DATA_RANGE] mac_input_c;



reg [ `SRAM_DATA_RANGE/2 ] matrix_A_read_counter;
reg [ `SRAM_DATA_RANGE/2 ] matrix_A_read_counter_1;
reg [ `SRAM_DATA_RANGE/2 ] matrix_A_read_cycle_counter; // Brows
reg [ `SRAM_DATA_RANGE/2 ] matrix_B_read_cycle_counter; // Arows
reg [ `SRAM_DATA_RANGE/2 ] matrix_B_read_counter_1;
reg [ `SRAM_DATA_RANGE/2 ] matrix_B_read_counter_2;
reg [`SRAM_DATA_RANGE] global_read_cycle_counter;
reg [`SRAM_DATA_RANGE] matrixBReadLimit;
reg [`SRAM_DATA_RANGE] numOfReads;
reg [`SRAM_DATA_RANGE] numOfWrites;

reg [`SRAM_DATA_RANGE] totalNumOfWrites;

reg [`SRAM_DATA_RANGE] numOfReadsToSwitchOver;

reg [`SRAM_DATA_RANGE] currentWriteCount;

reg [`SRAM_DATA_RANGE] matrixASwitchOverLimit;

reg [`SRAM_DATA_RANGE ] matrix_C_result_write_address_reg;
reg [`SRAM_DATA_RANGE ]    matrix_A_address;

 reg [`SRAM_DATA_RANGE ]   matrix_A_col_counter;
 reg [`SRAM_DATA_RANGE ]   matrix_B_row_repeat_counter;

 reg [`SRAM_DATA_RANGE ]   matrix_A_row_counter;



 typedef enum bit[2:0] {
    IDLE                              = 3'd0, 
    READ_SRAM_ZERO_ADDR               = 3'd1,   
    READ_SRAM_FIRST_ARRAY_ELEMENT     = 3'd2,   
    READ_A_COL_ELEMENTS               = 3'd3,   
    WRITE_ACCUMULATED_VALUE           = 3'd4,   
    MAC_CLEAR                         = 3'd5,
    SWITCH_MATRIX_A_ROWS              = 3'd6,   
    COMPUTE_COMPLETE                  = 3'd7 } states;

states current_state, next_state;



always @(posedge clk) begin
// Synchronous active low reset.
if(!reset_n) begin
  // If reset stay in the idle state.
  dut_ready_reg <= 1'b1;
  current_state <= IDLE;
  global_read_cycle_counter <= `SRAM_ADDR_WIDTH'b0;
  matrixBReadLimit <= `SRAM_ADDR_WIDTH'b0;

end else begin
  // if not in reset go to state 0 and read the 0th address.
  current_state <= next_state;
end
end


always @(*) begin : proc_next_state_fsm
  case (current_state)

    IDLE                    : begin
      if (dut_valid) begin
        dut_ready_reg       = 1'b0;
        get_array_size      = 1'b0;
        read_addr_sel       = 2'b00;
        compute_accumulation= 1'b0;        
        read_cycle_complete  = 1'b0;
        save_array_size     = 1'b0;
        all_write_complete  = 1'b0;
        write_enable_sel    = 1'b0;
        clear_mac_signal    = 1'b0;       
        switch_matrix_A_row_signal = 1'b0;
        next_state          = READ_SRAM_ZERO_ADDR;
      end
      else begin
        dut_ready_reg       = 1'b1;
        get_array_size      = 1'b0;
        read_addr_sel       = 2'b00;
        compute_accumulation= 1'b0;
        all_write_complete  = 1'b0;        
        read_cycle_complete   = 1'b0;
        write_enable_sel    = 1'b0;
        save_array_size     = 1'b0;
        clear_mac_signal    = 1'b0;
        clear_mac_signal2     = 1'b0;       
        switch_matrix_A_row_signal = 1'b0;
        next_state          = IDLE;
      end
    end
  
    READ_SRAM_ZERO_ADDR  : begin
      dut_ready_reg         = 1'b0;
      get_array_size        = 1'b1;
      read_addr_sel         = 2'b01;  // Increment the read addr
      compute_accumulation  = 1'b0;
      all_write_complete  = 1'b0;        
      read_cycle_complete   = 1'b0;
      save_array_size       = 1'b0;
      clear_mac_signal    = 1'b0;
      clear_mac_signal2     = 1'b0;
      write_enable_sel      = 1'b0;
      switch_matrix_A_row_signal = 1'b0;
      next_state            = READ_SRAM_FIRST_ARRAY_ELEMENT;
    end 

    READ_SRAM_FIRST_ARRAY_ELEMENT: begin
      dut_ready_reg         = 1'b0;
      get_array_size        = 1'b0;
      read_addr_sel         = 2'b01;  // Increment the read addr
      compute_accumulation  = 1'b0;
      save_array_size       = 1'b1;
      all_write_complete  = 1'b0;        
      read_cycle_complete   = 1'b0;
      clear_mac_signal    = 1'b0;
      clear_mac_signal2     = 1'b0;      
      write_enable_sel      = 1'b0;
      switch_matrix_A_row_signal = 1'b0;
      matrixBReadLimit      = matrixBColumns * matrixBRows;
      global_read_cycle_counter = matrixBReadLimit * matrixARows;
      totalNumOfWrites =      (matrixARows * matrixBColumns) - 1;  
      numOfReadsToSwitchOver =     matrixBColumns * matrixBRows ;
      next_state            = READ_A_COL_ELEMENTS;    
    end

    READ_A_COL_ELEMENTS     : begin
      dut_ready_reg             = 1'b0;
      get_array_size        = 1'b0;
      read_addr_sel         = ((numOfReads-1) % numOfReadsToSwitchOver == 0) ?  2'b10: 2'b01;  // Keep incrementing the read addr
      compute_accumulation  = 1'b1;
      clear_mac_signal      = 1'b0;
      save_array_size       = 1'b1;
      all_write_complete    = 1'b0;
      write_enable_sel      = 1'b0;
      switch_matrix_A_row_signal =  ((numOfReads-1) % numOfReadsToSwitchOver == 0) ?  1: 0;
      //next_state            = read_cycle_complete ?  WRITE_ACCUMULATED_VALUE: READ_A_COL_ELEMENTS;
      next_state            = read_cycle_complete ? WRITE_ACCUMULATED_VALUE : READ_A_COL_ELEMENTS;
    end 

    WRITE_ACCUMULATED_VALUE : begin
      dut_ready_reg         = 1'b0;
      get_array_size        = 1'b0;
      read_addr_sel         = 2'b10;  // Hold the address
      compute_accumulation  = 1'b1;
      read_cycle_complete   = 1'b0;
      save_array_size       = 1'b1;
      write_enable_sel      = 1'b1;
      switch_matrix_A_row_signal = 1'b0;
      next_state            = MAC_CLEAR;
    end

    MAC_CLEAR : begin
      dut_ready_reg         = 1'b0;
      get_array_size        = 1'b0;
      read_addr_sel         = 2'b01;  // increment
      compute_accumulation  = 1'b1;
      read_cycle_complete   = 1'b0;
      save_array_size       = 1'b1;
      write_enable_sel      = 1'b0;      
      clear_mac_signal      = 1'b1;
      clear_mac_signal2     = 1'b0;      
      switch_matrix_A_row_signal = 1'b0;
      //next_state            = all_write_complete ? COMPUTE_COMPLETE : READ_A_COL_ELEMENTS;
      next_state            = all_write_complete ? COMPUTE_COMPLETE :  READ_A_COL_ELEMENTS;  
    end

    SWITCH_MATRIX_A_ROWS : begin
      dut_ready_reg         = 1'b0;
      get_array_size        = 1'b0;
      read_addr_sel         = 2'b01;  // increment
      compute_accumulation  = 1'b1;
      read_cycle_complete   = 1'b0;
      save_array_size       = 1'b1;
      write_enable_sel      = 1'b0;      
      clear_mac_signal      = 1'b1;
      switch_matrix_A_row_signal = 1'b1;
      next_state            = all_write_complete ? COMPUTE_COMPLETE : READ_A_COL_ELEMENTS; 
    end

    COMPUTE_COMPLETE        : begin
      dut_ready_reg         = 1'b1;
      get_array_size        = 1'b0;
      read_addr_sel         = 2'b00;  
      compute_accumulation  = 1'b0;
      save_array_size       = 1'b0;
      write_enable_sel      = 1'b0;
      next_state            = IDLE;      
    end

    default                 :  begin
      dut_ready_reg         = 1'b1;
      get_array_size        = 1'b0;
      read_addr_sel         = 2'b00;  
      compute_accumulation  = 1'b0;
      save_array_size       = 1'b0;
      write_enable_sel      = 1'b0;      
      next_state            = IDLE;
    end
  endcase
end

always @(posedge clk) begin 
  if(!reset_n) begin
    compute_complete <= 0;
  end else begin
    compute_complete <= (dut_ready_reg) ? 1'b1 : 1'b0;
  end
end
assign dut_ready = compute_complete;


always @(posedge clk) begin
  if(!reset_n) begin
    matrixAColumns  <= `SRAM_ADDR_WIDTH'b0;
    matrixARows     <= `SRAM_ADDR_WIDTH'b0;
    matrixBColumns  <= `SRAM_ADDR_WIDTH'b0;
    matrixBRows     <= `SRAM_ADDR_WIDTH'b0;
    matrix_A_read_counter    <= `SRAM_ADDR_WIDTH'b1;
    matrix_A_read_cycle_counter <= `SRAM_ADDR_WIDTH'b1;
    matrix_B_read_cycle_counter <= `SRAM_ADDR_WIDTH'b1;
    matrix_B_read_counter_1   <= `SRAM_ADDR_WIDTH'b1;
    matrix_B_read_counter_2   <= `SRAM_ADDR_WIDTH'b1;
    matrix_C_result_write_address_reg <= `SRAM_ADDR_WIDTH'b0;
    sram_result_write_address_reg <= `SRAM_ADDR_WIDTH'b0;
    matrix_A_address <= 1;
    matrix_A_row_counter <= 1;
    matrix_A_col_counter <= 1;
    default_mac_input <= 0;
    sum_r <= 0;
    matrix_B_row_repeat_counter <= 1;
    numOfReads <= `SRAM_ADDR_WIDTH'b0;
  end else begin
    // If get_array_size is enabled in state, assign teh read data from sram to this register if not     
    matrixARows    <= get_array_size ? tb__dut__sram_input_read_data[31:16] : (save_array_size ? matrixARows : `SRAM_ADDR_WIDTH'b0);
    matrixAColumns <= get_array_size ? tb__dut__sram_input_read_data[15:0] : (save_array_size ? matrixAColumns : `SRAM_ADDR_WIDTH'b0);

    matrixBRows    <= get_array_size ? tb__dut__sram_weight_read_data[31:16] : (save_array_size ? matrixBRows : `SRAM_ADDR_WIDTH'b0);
    matrixBColumns <= get_array_size ? tb__dut__sram_weight_read_data[15:0] : (save_array_size ? matrixBColumns : `SRAM_ADDR_WIDTH'b0);
  end
end


// SRAM read address generator
always @(posedge clk) begin
    if (!reset_n) begin
      dut__tb__sram_input_read_address_reg  <= 0;
      dut__tb__sram_weight_read_address_reg  <= 0;
    end
    else begin

      case(read_addr_sel)

      2'b00 :begin 
                  dut__tb__sram_input_read_address_reg <= `SRAM_ADDR_WIDTH'b0;
                  dut__tb__sram_weight_read_address_reg <= `SRAM_ADDR_WIDTH'b0;
      end

      2'b01: begin
                  // Matrix A Address generator
        numOfReads <= numOfReads + 1;
        
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


always@(posedge clk) begin
if (!reset_n) begin
    dut__tb__sram_weight_read_address_reg <= `SRAM_DATA_WIDTH'b0;
    matrix_B_read_counter_1 <= `SRAM_DATA_WIDTH'b1;
    matrix_B_read_cycle_counter <= `SRAM_DATA_WIDTH'b1;
end
else if(read_addr_sel == 2'b01)begin
            // Matrix B Address generator
          if(matrix_B_read_cycle_counter <= matrixARows) begin
            if(matrix_B_read_counter_1 <= matrixBReadLimit ) begin 
                    
              dut__tb__sram_weight_read_address_reg <= dut__tb__sram_weight_read_address_reg + `SRAM_DATA_WIDTH'b1;
              matrix_B_read_counter_1 <= matrix_B_read_counter_1 + `SRAM_DATA_WIDTH'b1;
              
            end else begin
              matrix_B_read_counter_1 <= `SRAM_DATA_WIDTH'b1;
              dut__tb__sram_weight_read_address_reg <= `SRAM_DATA_WIDTH'b1;
            end
          end else begin        
              matrix_B_read_cycle_counter <= matrix_B_read_cycle_counter + `SRAM_DATA_WIDTH'b1;   
          end
      end
end


assign dut__tb__sram_weight_read_address = dut__tb__sram_weight_read_address_reg;


always@(posedge clk) begin
if (!reset_n) begin
    dut__tb__sram_input_read_address_reg <= `SRAM_DATA_WIDTH'b0;
    matrix_A_col_counter <= `SRAM_DATA_WIDTH'b1;
    matrix_B_row_repeat_counter <= `SRAM_DATA_WIDTH'b1;
    sram_result_write_address_reg <= `SRAM_DATA_WIDTH'b0;
end
else if(read_addr_sel == 2'b01)begin
            // Repeat the same row Brow times
          if (matrix_B_row_repeat_counter <= matrixBRows) begin
        // Fetch the elements of the current row one at a time
            if (matrix_A_col_counter < matrixAColumns) begin
                // Assign the current read address to the SRAM input
                dut__tb__sram_input_read_address_reg <= (((matrix_A_row_counter - 1) * matrixAColumns) + matrix_A_col_counter);

                // Increment the column counter
                matrix_A_col_counter <= matrix_A_col_counter + 1;

                // Ensure write enable is low when fetching
                //write_enable_sel <= 1'b0;

            end else begin
                // After fetching all columns in the row, reset column counter and increment repeat counter
                matrix_A_col_counter <= 1;  // Reset to 0 to start from the first column
                matrix_B_row_repeat_counter <= matrix_B_row_repeat_counter + 1;

                // Update SRAM input read address for the first column of the next fetch
                dut__tb__sram_input_read_address_reg <= (((matrix_A_row_counter - 1) * matrixAColumns) + matrix_A_col_counter);

                // Set write enable to high after fetching all columns
                //write_enable_sel <= 1'b1;
                //sram_result_write_address_reg <= sram_result_write_address_reg + 1;
            end
          end 
  end
end


assign dut__tb__sram_input_read_address = dut__tb__sram_input_read_address_reg;

// READ N-elements in SRAM 
always @(posedge clk) begin : proc_read_cycle_completion
  if(!reset_n) begin    
    read_cycle_complete <= 1'b0;
  end else begin
    read_cycle_complete <= ( numOfReads == (currentWriteCount ? (matrixAColumns* ( 1 + currentWriteCount))  : matrixAColumns ) ) ? 1'b1 : 1'b0;
  end
end

// READ N-elements in SRAM 
always @(posedge clk) begin : proc_write_completion
  if(!reset_n) begin    
    all_write_complete <= 1'b0;
  end else begin
    all_write_complete <= (totalNumOfWrites == currentWriteCount) ? 1'b1 : 1'b0;
  end
end

// READ N-elements in SRAM 
always @(posedge clk) begin : proc_write_address_increment
  if(!reset_n) begin    
    all_write_complete <= 1'b0;
    currentWriteCount <= 0;
  end else begin
    if(write_enable_sel) begin
      currentWriteCount <= currentWriteCount + 1;
      sram_result_write_address_reg <= sram_result_write_address_reg + 1;
    end
  end
end



// SRAM write enable logic
always @(posedge clk) begin : proc_sram_write_enable_r
  if(!reset_n) begin
    dut__tb__sram_result_write_enable_reg <= 1'b0;
    dut__tb__sram_input_write_enable_reg <= 1'b0;
    dut__tb__sram_weight_write_enable_reg <= 1'b0;
  end else begin
    dut__tb__sram_result_write_enable_reg <= write_enable_sel ? 1'b1 : 1'b0;
  end
end

assign dut__tb__sram_result_write_enable = dut__tb__sram_result_write_enable_reg;
assign dut__tb__sram_input_write_enable = dut__tb__sram_input_write_enable_reg;
assign dut__tb__sram_weight_write_enable = dut__tb__sram_weight_write_enable_reg;


// SRAM write address logic
always @(posedge clk) begin : proc_sram_write_address_r
  if(!reset_n) begin
    dut__tb__sram_result_write_address_reg <= 1'b0;
  end else begin
    dut__tb__sram_result_write_address_reg <= (write_enable_sel) ? sram_result_write_address_reg : `SRAM_DATA_WIDTH'b0;  
  end
end

assign dut__tb__sram_result_write_address = dut__tb__sram_result_write_address_reg;


// SRAM write data logic
always @(posedge clk) begin : proc_sram_write_data_r
  if(!reset_n) begin
    dut__tb__sram_result_write_data_reg <= `SRAM_DATA_WIDTH'b0;
  end else begin
    dut__tb__sram_result_write_data_reg <= (write_enable_sel) ? sum_w : `SRAM_DATA_WIDTH'b0;
  end
end

assign dut__tb__sram_result_write_data = dut__tb__sram_result_write_data_reg;

// Accumulation logic 
always @(posedge clk) begin : proc_accumulation
  if(!reset_n) begin
    sum_r   <= `SRAM_DATA_WIDTH'b0;
  end else begin
    if (compute_accumulation) begin
      sum_r <= sum_w;
    end
    else begin
      sum_r <= `SRAM_DATA_WIDTH'b0;
    end
  end
end

always @(posedge clk) begin : proc_mac_clear_when_matrix_Switch
  if(!reset_n) begin
    clear_mac_signal2 <= 0;
  end else begin
    if (clear_mac_signal && ((numOfReads-1) % numOfReadsToSwitchOver == 0)) begin
      clear_mac_signal2 <= 1;
    end
  end
end

always@(posedge clk)begin
if(clear_mac_signal2)begin
clear_mac_signal2 = 0;
end

end

assign mac_input_a = (clear_mac_signal |clear_mac_signal2) ? default_mac_input : tb__dut__sram_input_read_data;
assign mac_input_b = (clear_mac_signal |clear_mac_signal2)  ? default_mac_input : tb__dut__sram_weight_read_data;
assign mac_input_c = (clear_mac_signal |clear_mac_signal2)  ? default_mac_input : sum_r;

always @(posedge clk) begin : proc_switch_matrix_a_rows
  if(!reset_n) begin
    matrix_A_row_counter <= 1;
  end else begin    
      matrix_A_row_counter <= switch_matrix_A_row_signal ? (matrix_A_row_counter + 1) : matrix_A_row_counter;
      matrix_B_row_repeat_counter <= switch_matrix_A_row_signal ? 1 : matrix_B_row_repeat_counter;      
  end
end



// Floating-point multiply-accumulate instance
DW_fp_mac_inst FP_MAC (
  .inst_a(mac_input_a),
  .inst_b(mac_input_b),
  .inst_c(mac_input_c),
  .inst_rnd(3'd0),
  .z_inst(sum_w),
  .status_inst()
);

endmodule


module DW_fp_mac_inst #(
  parameter inst_sig_width = 23,
  parameter inst_exp_width = 8,
  parameter inst_ieee_compliance = 0 // These need to be fixed to decrease error
) ( 
  input wire [inst_sig_width+inst_exp_width : 0] inst_a,
  input wire [inst_sig_width+inst_exp_width : 0] inst_b,
  input wire [inst_sig_width+inst_exp_width : 0] inst_c,
  input wire [2 : 0] inst_rnd,
  output wire [inst_sig_width+inst_exp_width : 0] z_inst,
  output wire [7 : 0] status_inst
);

  // Instance of DW_fp_mac
  DW_fp_mac #(inst_sig_width, inst_exp_width, inst_ieee_compliance) U1 (
    .a(inst_a),
    .b(inst_b),
    .c(inst_c),
    .rnd(inst_rnd),
    .z(z_inst),
    .status(status_inst) 
  );
endmodule
