
// vlog -sv +incdir+../rtl/common ../rtl/dut.sv

`include "./common/common.vh"

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
  input  wire [`SRAM_DATA_RANGE] tb__dut__sram_result_read_data
);


reg [`SRAM_DATA_RANGE/2] matrixAColumns;       // register to number of memory locations to be read from Sram A and B
reg [`SRAM_DATA_RANGE/2] matrixARows;          // register to number of memory locations to be read from Sram A and B

reg [`SRAM_DATA_RANGE/2 ] matrixBColumns;       // register to number of memory locations to be read from Sram A and B
reg [`SRAM_DATA_RANGE/2] matrixBRows;          // register to number of memory locations to be read from Sram A and B

reg clear_mac_signal;

// Declare intermediate registers  to store the address of values to be read from SRAM A and B.
reg [`SRAM_ADDR_RANGE] dut__tb__sram_input_read_address_reg;
reg [`SRAM_ADDR_RANGE] dut__tb__sram_weight_read_address_reg;
reg [`SRAM_ADDR_RANGE] dut__tb__sram_result_write_address_reg;
reg [`SRAM_DATA_RANGE] dut__tb__sram_result_write_data_reg;
reg [`SRAM_DATA_RANGE] sram_result_write_address_reg;



  reg                           get_array_size            ;
  reg [1:0]                     read_addr_sel             ;
  reg                           compute_accumulation      ;
  reg                           save_array_size           ;
  reg                           write_enable_sel          ;
  wire  [31:0] accumulator_ouput;   // Result from FP_add
  reg   [31:0] accumulator_addend;   // Input A of the FP_add 

reg dut_ready_reg; // register to store current DUT state
reg write_enable;
reg compute_complete;
reg read_cycle_complete;

reg all_write_complete;

reg dut__tb__sram_result_write_enable_reg;
reg dut__tb__sram_weight_write_enable_reg;
reg dut__tb__sram_input_write_enable_reg;

wire [`SRAM_DATA_RANGE] mac_input_a;
wire [`SRAM_DATA_RANGE] mac_input_b;
wire [`SRAM_DATA_RANGE] mac_input_c;



reg [`SRAM_DATA_RANGE] matrixAColumnCounter;
reg [`SRAM_DATA_RANGE] matrixARowCounter;
reg [`SRAM_DATA_RANGE] matrixBCounter;

reg [`SRAM_DATA_RANGE] globalReadCounter;

reg matrixBReadCompleteCycleCompleteSignal;
reg matrixAReadCompleteCycleCompleteSignal;
reg [`SRAM_DATA_RANGE] read_cycle_counter;
reg [`SRAM_DATA_RANGE] currentWriteCount;


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



always @(posedge clk) begin : proc_next_state
// Synchronous active low reset.
if(!reset_n) begin
  // If reset stay in the idle state.
  dut_ready_reg <= 1'b1;
  current_state <= IDLE;

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
        save_array_size     = 1'b0;
        write_enable_sel    = 1'b0;
        clear_mac_signal    = 1'b0;   
        matrixAReadCompleteCycleCompleteSignal = 0;
        matrixBReadCompleteCycleCompleteSignal = 0;
        next_state          = READ_SRAM_ZERO_ADDR;
      end
      else begin
        dut_ready_reg       = 1'b1;
        get_array_size      = 1'b0;
        read_addr_sel       = 2'b00;
        compute_accumulation= 1'b0;
        write_enable_sel    = 1'b0;
        save_array_size     = 1'b0;
        clear_mac_signal    = 1'b0;
        matrixAReadCompleteCycleCompleteSignal = 0;
        matrixBReadCompleteCycleCompleteSignal = 0;
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
      write_enable_sel      = 1'b0;
      matrixAReadCompleteCycleCompleteSignal = 0;
      matrixBReadCompleteCycleCompleteSignal = 0;
      next_state            = READ_SRAM_FIRST_ARRAY_ELEMENT;
    end 

    READ_SRAM_FIRST_ARRAY_ELEMENT: begin
      dut_ready_reg         = 1'b0;
      get_array_size        = 1'b0;
      read_addr_sel         = 2'b01;  // Increment the read addr
      compute_accumulation  = 1'b0;
      save_array_size       = 1'b1; 
      clear_mac_signal      = 1'b0;      
      write_enable_sel      = 1'b0;
      matrixAReadCompleteCycleCompleteSignal = 0;
      matrixBReadCompleteCycleCompleteSignal = 0;
      next_state            = READ_A_COL_ELEMENTS;    
    end

    READ_A_COL_ELEMENTS     : begin
      dut_ready_reg         = 1'b0;
      get_array_size        = 1'b0;
      read_addr_sel         = read_cycle_complete ? 2'b10 : 2'b01;  // Keep incrementing the read addr
      compute_accumulation  = 1'b1;
      clear_mac_signal      = 0;
      save_array_size       = 1'b1;
      write_enable_sel      = 0;
      matrixBReadCompleteCycleCompleteSignal = (matrixBCounter == matrixBColumns * matrixBRows ) ? 1: 0;
      matrixAReadCompleteCycleCompleteSignal = (matrixAColumnCounter == matrixAColumns ) ? 1 : 0;      
      next_state            = read_cycle_complete ? WRITE_ACCUMULATED_VALUE : READ_A_COL_ELEMENTS;
    end 

    WRITE_ACCUMULATED_VALUE : begin
      dut_ready_reg         = 1'b0;
      get_array_size        = 1'b0;
      read_addr_sel         = 2'b10;  // Hold the address
      compute_accumulation  = 1'b1;
      save_array_size       = 1'b1;
      write_enable_sel      = 1'b1;      
      clear_mac_signal      = 0;
      matrixAReadCompleteCycleCompleteSignal = 0;
      matrixBReadCompleteCycleCompleteSignal = 0;
      next_state            = MAC_CLEAR;
    end

    MAC_CLEAR : begin
      dut_ready_reg         = 1'b0;
      get_array_size        = 1'b0;
      read_addr_sel         = 2'b01;  // increment
      compute_accumulation  = 1'b1;
      save_array_size       = 1'b1;
      write_enable_sel      = 1'b0;      
      clear_mac_signal      = 1'b1;
      matrixAReadCompleteCycleCompleteSignal = 0;
      matrixBReadCompleteCycleCompleteSignal = 0;
      next_state            = all_write_complete ? COMPUTE_COMPLETE :  READ_A_COL_ELEMENTS;  
    end

    COMPUTE_COMPLETE        : begin
      dut_ready_reg         = 1'b1;
      get_array_size        = 1'b0;
      read_addr_sel         = 2'b00;  
      compute_accumulation  = 1'b0;            
      clear_mac_signal      = 1'b0;
      matrixAReadCompleteCycleCompleteSignal = 0;
      matrixBReadCompleteCycleCompleteSignal = 0;
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
      clear_mac_signal      = 0;
      matrixAReadCompleteCycleCompleteSignal = 0;
      matrixBReadCompleteCycleCompleteSignal = 0;
      write_enable_sel      = 1'b0;      
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
    matrixAColumns  <= `SRAM_ADDR_WIDTH'b0;
    matrixARows     <= `SRAM_ADDR_WIDTH'b0;
    matrixBColumns  <= `SRAM_ADDR_WIDTH'b0;
    matrixBRows     <= `SRAM_ADDR_WIDTH'b0;
    sram_result_write_address_reg <= `SRAM_ADDR_WIDTH'b0;
    matrixBCounter <= 0;
    matrixAColumnCounter <= 0;
    matrixBReadCompleteCycleCompleteSignal <= 0;
    matrixAReadCompleteCycleCompleteSignal <= 0;
    dut__tb__sram_result_write_enable_reg <= 1'b0;
    dut__tb__sram_input_write_enable_reg <= 1'b0;
    dut__tb__sram_weight_write_enable_reg <= 1'b0;
  end else begin
    // If get_array_size is enabled in state, assign teh read data from sram to this register if not     
    matrixARows    <= get_array_size ? tb__dut__sram_input_read_data[31:16] : (save_array_size ? matrixARows : `SRAM_ADDR_WIDTH'b0);
    matrixAColumns <= get_array_size ? tb__dut__sram_input_read_data[15:0] : (save_array_size ? matrixAColumns : `SRAM_ADDR_WIDTH'b0);

    matrixBRows    <= get_array_size ? tb__dut__sram_weight_read_data[31:16] : (save_array_size ? matrixBRows : `SRAM_ADDR_WIDTH'b0);
    matrixBColumns <= get_array_size ? tb__dut__sram_weight_read_data[15:0] : (save_array_size ? matrixBColumns : `SRAM_ADDR_WIDTH'b0);
  end
end


// SRAM read address generator
always @(posedge clk) begin : proc_matrices_read
    if (!reset_n) begin
      dut__tb__sram_input_read_address_reg  <= 0;
      dut__tb__sram_weight_read_address_reg  <= 0;
      
      globalReadCounter <= 0;
    end
    else begin

      case(read_addr_sel)

      2'b00 :begin 
                  dut__tb__sram_input_read_address_reg <= `SRAM_ADDR_WIDTH'b0;
                  dut__tb__sram_weight_read_address_reg <= `SRAM_ADDR_WIDTH'b0;
      end

      2'b01: begin

        globalReadCounter <= globalReadCounter + 1;
        dut__tb__sram_weight_read_address_reg <= matrixBReadCompleteCycleCompleteSignal ? 1 : dut__tb__sram_weight_read_address_reg + 1;
        matrixBCounter <= matrixBReadCompleteCycleCompleteSignal ? 1: matrixBCounter + 1;

        dut__tb__sram_input_read_address_reg <= matrixAReadCompleteCycleCompleteSignal ? ( matrixBReadCompleteCycleCompleteSignal ? dut__tb__sram_input_read_address_reg + 1 : (( matrixARowCounter - 1) *matrixAColumns + 1) ) : dut__tb__sram_input_read_address_reg  + 1;
        matrixAColumnCounter <= matrixAReadCompleteCycleCompleteSignal ? 1 : matrixAColumnCounter + 1;
        matrixARowCounter <= matrixBReadCompleteCycleCompleteSignal ? matrixARowCounter + 1 : matrixARowCounter;  

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

            // Matrix B Address generator
always@(posedge clk) begin : proc_matrix_B_read
if (!reset_n) begin
    read_cycle_counter  <= `SRAM_DATA_WIDTH'b0;
end
else if(read_addr_sel == 2'b01)begin
  
    dut__tb__sram_weight_read_address_reg <= matrixBReadCompleteCycleCompleteSignal ? 1 : dut__tb__sram_weight_read_address_reg + 1;
    matrixBCounter <= matrixBReadCompleteCycleCompleteSignal ? 1: matrixBCounter + 1;    
end

end


assign dut__tb__sram_weight_read_address = dut__tb__sram_weight_read_address_reg;


always@(posedge clk) begin : proc_matrix_A_read
if (!reset_n) begin
    sram_result_write_address_reg <= `SRAM_DATA_WIDTH'b0;
    matrixARowCounter <= 1;
end
else if(read_addr_sel == 2'b01)begin : proc_matrix_A_read

    dut__tb__sram_input_read_address_reg <= matrixAReadCompleteCycleCompleteSignal ? ( matrixBReadCompleteCycleCompleteSignal ? dut__tb__sram_input_read_address_reg + 1 : (( matrixARowCounter - 1) *matrixAColumns + 1) ) : dut__tb__sram_input_read_address_reg  + 1;
    matrixAColumnCounter <= matrixAReadCompleteCycleCompleteSignal ? 1 : matrixAColumnCounter + 1;
    matrixARowCounter <= matrixBReadCompleteCycleCompleteSignal ? matrixARowCounter + 1 : matrixARowCounter;
  end
end


assign dut__tb__sram_input_read_address = dut__tb__sram_input_read_address_reg;

// READ N-elements in SRAM 
always @(posedge clk) begin : proc_read_cycle_computation
  if(!reset_n) begin    
    read_cycle_complete <= 1'b0;
  end else begin
    read_cycle_complete <= ( globalReadCounter == (currentWriteCount ? (matrixAColumns* ( 1 + currentWriteCount))  : matrixAColumns ) ) ? 1'b1 : 1'b0;    
  end
end

// READ N-elements in SRAM 
always @(posedge clk) begin : proc_write_completion
  if(!reset_n) begin    
    all_write_complete <= 1'b0;
  end else begin
    all_write_complete <= (((matrixARows * matrixBColumns) - 1) == currentWriteCount) ? 1'b1 : 1'b0;
  end
end



// READ N-elements in SRAM 
always @(posedge clk) begin : proc_write_address_increment
  if(!reset_n) begin  
    currentWriteCount <= 0;
  end else begin
      currentWriteCount <= write_enable_sel ? currentWriteCount + 1 : currentWriteCount;
  end
end

assign dut__tb__sram_result_write_enable = write_enable_sel;
assign dut__tb__sram_input_write_enable  = dut__tb__sram_input_write_enable_reg;
assign dut__tb__sram_weight_write_enable = dut__tb__sram_weight_write_enable_reg;


// SRAM write address logic
always @(posedge clk) begin : proc_sram_write_address_r
  if(!reset_n) begin
    dut__tb__sram_result_write_address_reg <= 1'b0;
  end else begin
    dut__tb__sram_result_write_address_reg <= (write_enable_sel) ? dut__tb__sram_result_write_address_reg + 1 : dut__tb__sram_result_write_address_reg ; 
  end
end

assign dut__tb__sram_result_write_address = dut__tb__sram_result_write_address_reg;


// SRAM write data logic
always @(posedge clk) begin : proc_sram_write_data_r
  if(!reset_n) begin
    dut__tb__sram_result_write_data_reg <= `SRAM_DATA_WIDTH'b0;
  end else begin
    dut__tb__sram_result_write_data_reg <= (read_cycle_complete) ? accumulator_ouput : `SRAM_DATA_WIDTH'b0;
  end
end

assign dut__tb__sram_result_write_data = dut__tb__sram_result_write_data_reg;

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



assign mac_input_a = (clear_mac_signal)  ? 0 : tb__dut__sram_input_read_data;
assign mac_input_b = (clear_mac_signal)  ? 0 : tb__dut__sram_weight_read_data;
assign mac_input_c = (clear_mac_signal)  ? 0 : accumulator_addend;




// Floating-point multiply-accumulate instance
DW_fp_mac_inst FP_MAC (
  .inst_a(mac_input_a),
  .inst_b(mac_input_b),
  .inst_c(mac_input_c),
  .inst_rnd(3'd0),
  .z_inst(accumulator_ouput),
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
