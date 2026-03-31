module feature_map_bram #(
  parameter DEPTH      = 676,
  parameter N_FILTERS  = 4,
  parameter WIDTH      = 32
)(
  input  logic                        clk,
  input  logic                        wr_en,
  input  logic [$clog2(DEPTH)-1:0]    wr_addr,
  input  logic signed [WIDTH-1:0]     wr_data [N_FILTERS],
  input  logic [$clog2(DEPTH)-1:0]    rd_addr,
  output logic signed [WIDTH-1:0]     rd_data [N_FILTERS]
);
  logic signed [WIDTH-1:0] mem [DEPTH][N_FILTERS];

  always_ff @(posedge clk) begin
    if (wr_en)
      mem[wr_addr] <= wr_data;
    rd_data <= mem[rd_addr];
  end

endmodule
