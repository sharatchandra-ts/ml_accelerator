`timescale 1ns/1ps

module weight_loading_tb;

  localparam W_WIDTH = 8;
  localparam DEPTH = 36;
  localparam ROWS = 9;
  localparam COLS = 4;

  logic clk, rst_n, enable;
  logic [$clog2(DEPTH)-1:0] addr;
  logic valid, done, load_en;
  logic signed [W_WIDTH-1:0] weight_out;

  // Wires for the array inputs
  logic signed [W_WIDTH-1:0] a_in_tb [ROWS];
  logic signed [W_WIDTH-1:0] w_in_tb [COLS];
  logic valid_in_tb [COLS];
  logic clear_in_tb [COLS];

  // Temporary buffer for the first 3 weights of each row
  logic signed [W_WIDTH-1:0] row_buffer [0:2];

  // Clock Generation
  initial clk = 0;
  always #5 clk = ~clk;

  // Standard Instantiations
  weight_loader #(.DEPTH(DEPTH)) u_loader (
    .clk(clk), .rst_n(rst_n), .enable(enable),
    .addr(addr), .valid(valid), .done(done)
  );

  weight_bram #(.DEPTH(DEPTH), .DATA_WIDTH(W_WIDTH)) u_bram (
    .clk(clk), .addr(addr), .data_out(weight_out)
  );

  systolic_array #(.ROWS(ROWS), .COLUMNS(COLS), .DATA_WIDTH(W_WIDTH)) u_array (
    .clk(clk), .rst_n(rst_n), .load_en(load_en),
    .a_in(), .w_in(w_in_tb),
    .valid_in(valid_in_tb), .clear_in(clear_in_tb),
    .result(), .valid_out_final()
  );

  initial begin
    // Initialize everything to zero to avoid 'X'
    for(int i=0; i<ROWS; i++) a_in_tb[i] = 0;
    for(int i=0; i<COLS; i++) begin
      w_in_tb[i] = 0;
      valid_in_tb[i] = 0;
      clear_in_tb[i] = 0;
    end

    rst_n = 0; enable = 0; load_en = 0;
    #20 rst_n = 1;

    $display("--- Starting Hardware-Strict Weight Load ---");

    for (int r = 0; r < ROWS; r++) begin
        // Collect weights for Col 0, 1, and 2
        for (int c = 0; c < 3; c++) begin
            enable = 1;
            @(posedge clk);
            enable = 0; // Turn off to ensure single-step
            @(posedge clk);
            row_buffer[c] = weight_out;
        end

        // The 4th Weight (Col 3): Direct Pass-through
        enable = 1;
        @(posedge clk);
        enable = 0;
        @(posedge clk);

        load_en = 1;
        w_in_tb[3] = row_buffer[0];
        w_in_tb[2] = row_buffer[1];
        w_in_tb[1] = row_buffer[2];
        w_in_tb[0] = weight_out;

        @(posedge clk);
        load_en = 0;
        for(int i=0; i<COLS; i++) w_in_tb[i] = 0;
        $display("Row %0d loaded into Array Interface...", r);
    end

    $display("--- Weight Loading Complete ---");
    #20;

    // Display Map logic (Your 8-to-0 block)
    $display("\n--- FINAL SYSTOLIC ARRAY WEIGHT MAP (Bottom to Top) ---");
    $display("Row 0: | %d | %d | %d | %d |", u_array.row_gen[0].column_gen[0].pe_inst.w_reg, u_array.row_gen[0].column_gen[1].pe_inst.w_reg, u_array.row_gen[0].column_gen[2].pe_inst.w_reg, u_array.row_gen[0].column_gen[3].pe_inst.w_reg);
    $display("Row 1: | %d | %d | %d | %d |", u_array.row_gen[1].column_gen[0].pe_inst.w_reg, u_array.row_gen[1].column_gen[1].pe_inst.w_reg, u_array.row_gen[1].column_gen[2].pe_inst.w_reg, u_array.row_gen[1].column_gen[3].pe_inst.w_reg);
    $display("Row 2: | %d | %d | %d | %d |", u_array.row_gen[2].column_gen[0].pe_inst.w_reg, u_array.row_gen[2].column_gen[1].pe_inst.w_reg, u_array.row_gen[2].column_gen[2].pe_inst.w_reg, u_array.row_gen[2].column_gen[3].pe_inst.w_reg);
    $display("Row 3: | %d | %d | %d | %d |", u_array.row_gen[3].column_gen[0].pe_inst.w_reg, u_array.row_gen[3].column_gen[1].pe_inst.w_reg, u_array.row_gen[3].column_gen[2].pe_inst.w_reg, u_array.row_gen[3].column_gen[3].pe_inst.w_reg);
    $display("Row 4: | %d | %d | %d | %d |", u_array.row_gen[4].column_gen[0].pe_inst.w_reg, u_array.row_gen[4].column_gen[1].pe_inst.w_reg, u_array.row_gen[4].column_gen[2].pe_inst.w_reg, u_array.row_gen[4].column_gen[3].pe_inst.w_reg);
    $display("Row 5: | %d | %d | %d | %d |", u_array.row_gen[5].column_gen[0].pe_inst.w_reg, u_array.row_gen[5].column_gen[1].pe_inst.w_reg, u_array.row_gen[5].column_gen[2].pe_inst.w_reg, u_array.row_gen[5].column_gen[3].pe_inst.w_reg);
    $display("Row 6: | %d | %d | %d | %d |", u_array.row_gen[6].column_gen[0].pe_inst.w_reg, u_array.row_gen[6].column_gen[1].pe_inst.w_reg, u_array.row_gen[6].column_gen[2].pe_inst.w_reg, u_array.row_gen[6].column_gen[3].pe_inst.w_reg);
    $display("Row 7: | %d | %d | %d | %d |", u_array.row_gen[7].column_gen[0].pe_inst.w_reg, u_array.row_gen[7].column_gen[1].pe_inst.w_reg, u_array.row_gen[7].column_gen[2].pe_inst.w_reg, u_array.row_gen[7].column_gen[3].pe_inst.w_reg);
    $display("Row 8: | %d | %d | %d | %d |", u_array.row_gen[8].column_gen[0].pe_inst.w_reg, u_array.row_gen[8].column_gen[1].pe_inst.w_reg, u_array.row_gen[8].column_gen[2].pe_inst.w_reg, u_array.row_gen[8].column_gen[3].pe_inst.w_reg);
    // [Explicit $display lines for Row 8 down to 0 here...]
    $display("------------------------------------------------------------\n");

    #100 $finish;
  end

endmodule
