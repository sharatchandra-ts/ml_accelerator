module image_bram #(
  parameter IMG_W    = 28,
  parameter IMG_H    = 28,
  parameter PIX_WIDTH = 8
)(
  input  logic                              clk,
  input  logic [$clog2(IMG_W*IMG_H)-1:0]   addr,
  output logic signed [PIX_WIDTH-1:0]       data_out
);
  localparam DEPTH = IMG_W * IMG_H;

  logic signed [PIX_WIDTH-1:0] mem [DEPTH];

  initial $readmemh("/Users/sharat/Development/system-verilog/ml_accelerator/weights/image.hex", mem);

  always_ff @(posedge clk)
    data_out <= mem[addr];

endmodule
