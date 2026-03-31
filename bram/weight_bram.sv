module weight_bram #(
  parameter DEPTH     = 36,
  parameter DATA_WIDTH = 8
)(
  input  logic                        clk,
  input  logic [$clog2(DEPTH)-1:0]   addr,
  output logic signed [DATA_WIDTH-1:0] data_out
);
  logic signed [DATA_WIDTH-1:0] mem [DEPTH];

  initial $readmemh("/Users/sharat/Development/system-verilog/ml_accelerator/weights/conv_weights.hex", mem);

  always_ff @(posedge clk)
    data_out <= mem[addr];

endmodule
