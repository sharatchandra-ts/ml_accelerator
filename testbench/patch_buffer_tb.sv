`timescale 1ns/1ps

module tb_img2col_bram_skewed;

  localparam IMG_W = 28;
  localparam IMG_H = 28;
  localparam K_W   = 3;
  localparam K_H   = 3;
  localparam PIX_WIDTH = 8;
  localparam N_PATCHES = 4;
  localparam PATCH_SIZE = K_W * K_H;

  logic clk, rst_n, enable;
  logic [$clog2(IMG_W*IMG_H)-1:0] addr;
  logic valid, clear, done;
  logic signed [PIX_WIDTH-1:0] pixel_out;

  logic valid_d1;
  logic signed [PIX_WIDTH-1:0] col_out [N_PATCHES];
  logic out_valid, buf_full, system_done;

  img2col #(.IMG_W(IMG_W), .IMG_H(IMG_H), .K_W(K_W), .K_H(K_H)) 
  u_im2col (.*);

  image_bram #(.IMG_W(IMG_W), .IMG_H(IMG_H), .PIX_WIDTH(PIX_WIDTH)) 
  u_bram (.clk(clk), .addr(addr), .data_out(pixel_out));

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) valid_d1 <= 1'b0;
    else        valid_d1 <= valid;
  end

  patch_skew_buffer #(
    .N_PATCHES(N_PATCHES), 
    .PATCH_SIZE(PATCH_SIZE), 
    .PIX_WIDTH(PIX_WIDTH)
  ) u_buffer (
    .clk(clk), .rst_n(rst_n),
    .wr_en(valid_d1), .wr_data(pixel_out),
    .col_out(col_out), .out_valid(out_valid),
    .buf_full(buf_full), .done(system_done)
  );

  initial clk = 0;
  always #5 clk = ~clk;

  initial begin
      $dumpfile("dump.vcd");
      $dumpvars(0, tb_img2col_bram_skewed);

      rst_n  = 0; enable = 0;
      #20 rst_n = 1;
      @(posedge clk);
      enable = 1;

      $display("--- Loading 9 patches (81 pixels) into buffer ---");
      wait(buf_full);
      @(posedge clk);  // ← add this
      
      $display("\n--- Starting Skewed Output (9 Parallel Columns) ---");
      // Updated display header
      $display("Time | V | C0 | C1 | C2 | C3 | C4 | C5 | C6 | C7 | C8");
      
      while (!system_done) begin
        @(posedge clk);
        if (out_valid) begin
          $write("%t | %b |", $time, out_valid);
          for (int i = 0; i < N_PATCHES; i++) $write(" %3d |", col_out[i]);
          $display("");
        end
      end
      
      @(posedge clk);
      $display("--- Skew Sequence Complete ---");
      $finish;
  end
endmodule
