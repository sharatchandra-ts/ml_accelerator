module cnn_fsm #(
  parameter IMG_W     = 28,
  parameter IMG_H     = 28,
  parameter K_W       = 3,
  parameter K_H       = 3,
  parameter N_FILTERS = 4,
  parameter FC_IN     = 676,
  parameter FC_OUT    = 10
)(
  input  logic clk,
  input  logic rst_n,
  input  logic start,
  input  logic im2col_done,
  input  logic conv_weight_load_done,
  input  logic fc_weight_load_done,
  input  logic maxpool_done,
  input  logic fc_done,
  output logic load_en,
  output logic im2col_en,
  output logic relu_en,
  output logic maxpool_en,
  output logic fc_en,
  output logic add_bias_en,
  output logic conv_weight_sel,
  output logic fc_weight_sel,
  output logic [3:0] digit_out,
  output logic valid_out
);
  typedef enum logic [3:0] {
    IDLE              = 4'd0,
    LOAD_CONV_WEIGHTS = 4'd1,
    LOAD_CONV_BIAS    = 4'd2,
    CONV_COMPUTE      = 4'd3,
    ADD_CONV_BIAS     = 4'd4,
    RELU              = 4'd5,
    MAXPOOL           = 4'd6,
    FC_COMPUTE        = 4'd7,
    ADD_FC_BIAS       = 4'd8,
    ARGMAX            = 4'd9,
    OUTPUT            = 4'd10
  } state_t;

  state_t curr_state, next_state;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) curr_state <= IDLE;
    else        curr_state <= next_state;
  end

  always_comb begin
    next_state = curr_state;
    case (curr_state)
      IDLE:              if (start)                 next_state = LOAD_CONV_WEIGHTS;
      LOAD_CONV_WEIGHTS: if (conv_weight_load_done) next_state = LOAD_CONV_BIAS;
      LOAD_CONV_BIAS:                               next_state = CONV_COMPUTE;
      CONV_COMPUTE:      if (im2col_done)           next_state = ADD_CONV_BIAS;
      ADD_CONV_BIAS:                                next_state = RELU;
      RELU:                                         next_state = MAXPOOL;
      MAXPOOL:           if (maxpool_done &&
                             fc_weight_load_done)   next_state = FC_COMPUTE;
      FC_COMPUTE:        if (fc_done)               next_state = ADD_FC_BIAS;
      ADD_FC_BIAS:                                  next_state = ARGMAX;
      ARGMAX:                                       next_state = OUTPUT;
      OUTPUT:                                       next_state = IDLE;
      default:                                      next_state = IDLE;
    endcase
  end

  always_comb begin
    load_en         = 0;
    im2col_en       = 0;
    relu_en         = 0;
    maxpool_en      = 0;
    fc_en           = 0;
    add_bias_en     = 0;
    conv_weight_sel = 0;
    fc_weight_sel   = 0;
    valid_out       = 0;
    case (curr_state)
      IDLE:              begin end
      LOAD_CONV_WEIGHTS: begin load_en = 1; conv_weight_sel = 1; end
      LOAD_CONV_BIAS:    begin add_bias_en = 1; conv_weight_sel = 1; end
      CONV_COMPUTE:      begin im2col_en = 1; end
      ADD_CONV_BIAS:     begin add_bias_en = 1; load_en = 1; fc_weight_sel = 1; end
      RELU:              begin relu_en = 1;     load_en = 1; fc_weight_sel = 1; end
      MAXPOOL:           begin maxpool_en = 1;  load_en = 1; fc_weight_sel = 1; end
      FC_COMPUTE:        begin fc_en = 1; end
      ADD_FC_BIAS:       begin add_bias_en = 1; end
      ARGMAX:            begin end
      OUTPUT:            begin valid_out = 1; end
      default:           begin end
    endcase
  end

endmodule
