module mac_os #(
  parameter DATA_WIDTH = 8,
  parameter ACC_WIDTH  = 32
)(
  input  logic                          clk,
  input  logic                          rst_n,
  input  logic                          clear,
  input  logic                          valid,
  input  logic signed [DATA_WIDTH-1:0]  a_in,
  output logic signed [DATA_WIDTH-1:0]  a_out,
  input  logic signed [DATA_WIDTH-1:0]  w_in,
  output logic signed [DATA_WIDTH-1:0]  w_out,
  output logic signed [ACC_WIDTH-1:0]   acc_out
);
  logic signed [2*DATA_WIDTH-1:0] product;
  assign product = a_in * w_in;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      acc_out <= '0;
      a_out   <= '0;
      w_out   <= '0;
    end else if (clear) begin
      acc_out <= '0;
      a_out   <= a_in;
      w_out   <= w_in;
    end else if (valid) begin
      acc_out <= acc_out + ACC_WIDTH'(product);
      a_out   <= a_in;
      w_out   <= w_in;
    end
  end

endmodule
