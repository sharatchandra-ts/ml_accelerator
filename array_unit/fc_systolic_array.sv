module fc_systolic_array #(
parameter ROWS       = 9,
parameter COLUMNS    = 4,
parameter DATA_WIDTH = 8,
parameter ACC_WIDTH  = 32
)(
input  logic                          clk,
input  logic                          rst_n,
input  logic                          clear,
input  logic                          valid,
input  logic signed [DATA_WIDTH-1:0]  a_in [ROWS],
input  logic signed [DATA_WIDTH-1:0]  w_in [COLUMNS],
output logic signed [ACC_WIDTH-1:0]   result [ROWS][COLUMNS]
);

logic signed [DATA_WIDTH-1:0] a_wire [ROWS][COLUMNS+1];
logic signed [DATA_WIDTH-1:0] w_wire [ROWS+1][COLUMNS];

genvar r, c;

generate
  for (r = 0; r < ROWS; r++) assign a_wire[r][0] = a_in[r];
  for (c = 0; c < COLUMNS; c++) assign w_wire[0][c] = w_in[c];
endgenerate

generate
  for (r = 0; r < ROWS; r++) begin : row_gen
    for (c = 0; c < COLUMNS; c++) begin : col_gen
      mac_os #(
        .DATA_WIDTH(DATA_WIDTH),
        .ACC_WIDTH (ACC_WIDTH)
      ) pe (
        .clk    (clk),
        .rst_n  (rst_n),
        .clear  (clear),
        .valid  (valid),
        .a_in   (a_wire[r][c]),
        .a_out  (a_wire[r][c+1]),
        .w_in   (w_wire[r][c]),
        .w_out  (w_wire[r+1][c]),
        .acc_out(result[r][c])
      );
    end
  end
endgenerate

endmodule
