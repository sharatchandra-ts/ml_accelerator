`timescale 1ns/1ps

module img2col_tb;

  localparam IMG_W = 28;
  localparam IMG_H = 28;
  localparam K_W   = 3;
  localparam K_H   = 3;

  logic clk, rst_n, enable;
  logic [$clog2(IMG_W * IMG_H)-1:0] addr;
  logic valid, clear, done;

  img2col #(
    .IMG_W(IMG_W),
    .IMG_H(IMG_H),
    .K_W(K_W),
    .K_H(K_H)
  ) dut (
    .clk    (clk),
    .rst_n  (rst_n),
    .enable (enable),
    .addr   (addr),
    .valid  (valid),
    .clear  (clear),
    .done   (done)
  );

  initial clk = 0;
  always #5 clk = ~clk;

  initial begin
    $dumpfile("dump.vcd");
    $dumpvars(0, img2col_tb);

    rst_n  = 0;
    enable = 0;
    #20 rst_n = 1;

    // -----------------------------------------------
    // Test 1: verify first 9 addresses (patch 0)
    // expected: 0,1,2,28,29,30,56,57,58
    // -----------------------------------------------
    $display("Patch 0 (expect 0,1,2,28,29,30,56,57,58):");
    enable = 1;
    repeat(9) begin
      $display("  addr = %0d | clear = %b | done = %b", addr, clear, done);
      @(posedge clk); #1;
    end

    // -----------------------------------------------
    // Test 2: verify first address of patch 1
    // expected: 1
    // -----------------------------------------------
    $display("Patch 1 first pixel (expect 1):");
    @(posedge clk); #1;
    $display("  addr = %0d | clear = %b | done = %b", addr, clear, done);

    // -----------------------------------------------
    // Test 3: enable=0 freezes counters
    // -----------------------------------------------
    enable = 0;
    @(posedge clk); #1;
    $display("Frozen (expect same addr as above): addr = %0d", addr);
    enable = 1;

    // -----------------------------------------------
    // Test 4: run to done signal
    // total cycles = 26*26*9 = 6084
    // -----------------------------------------------
    $display("Running to done...");
    repeat(6084) begin
      @(posedge clk); #1;
      if (done) begin
        $display("Done fired at addr = %0d", addr);
        //disable;
      end
    end

    $display("Simulation complete.");
    $finish;
  end

endmodule
