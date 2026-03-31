module weight_loader #(
  parameter DEPTH = 36
) (
  input  logic clk,
  input  logic rst_n,
  input  logic enable,
  output logic [$clog2(DEPTH)-1:0] addr,
  output logic valid,
  output logic done
);
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            addr <= DEPTH - 1; // Start at the end of the file
        end else if (enable) begin
            if (addr == 0) begin
                addr <= DEPTH - 1; // Wrap back to the end
            end else begin
                addr <= addr - 1; // Count DOWN
            end
        end
    end

    assign valid = enable;
    assign done  = (addr == 0); // Done when we finally reach the first weight

endmodule