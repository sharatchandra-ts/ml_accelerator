`timescale 1ns/1ps

module tb_img2col_bram;

  localparam IMG_W = 28;
  localparam IMG_H = 28;
  localparam K_W   = 3;
  localparam K_H   = 3;
  localparam PIX_WIDTH = 8;


  logic clk, rst_n, enable;
  logic [$clog2(IMG_W*IMG_H)-1:0] addr;
  logic valid, clear, done;
  logic signed [PIX_WIDTH-1:0] pixel_out;

  // instantiate im2col
  img2col #(
    .IMG_W(IMG_W), .IMG_H(IMG_H),
    .K_W(K_W),     .K_H(K_H)
  ) u_im2col (
    .clk    (clk),
    .rst_n  (rst_n),
    .enable (enable),
    .addr   (addr),
    .valid  (valid),
    .clear  (clear),
    .done   (done)
  );

  // instantiate image bram
  image_bram #(
    .IMG_W(IMG_W), .IMG_H(IMG_H),
    .PIX_WIDTH(PIX_WIDTH)
  ) u_bram (
    .clk     (clk),
    .addr    (addr),
    .data_out(pixel_out)
  );

  initial clk = 0;
  always #5 clk = ~clk;

  initial begin
      $dumpfile("dump.vcd");
      $dumpvars(0, tb_img2col_bram);

      // Initial State
      rst_n  = 0;
      enable = 0;
      #20 rst_n = 1;
      
      // Synchronize with clock
      @(posedge clk);
      enable = 1;

      // -----------------------------------------------
      // Test 1: Print first 9 pixels (Patch 0)
      // -----------------------------------------------
      $display("Patch 0 pixels:");
      // We wait for 'valid' to go high, then account for 1 cycle BRAM latency
      wait(valid); 
      @(posedge clk); // Align with the first valid data out

      repeat(9) begin
        $display("Pixel: %d (at time %t)", pixel_out, $time);
        @(posedge clk);
      end

      // -----------------------------------------------
      // Test 2: Print first pixel of patch 1
      // -----------------------------------------------
      $display("Patch 1 first pixel:");
      // After 9 cycles of Patch 0, the next cycle is the start of Patch 1
      $display("Pixel: %d", pixel_out); 

      // -----------------------------------------------
      // Test 3: Check clear fires at end of each patch
      // -----------------------------------------------
      $display("Clear signal check:");
      // Let's wait for the next 'clear' pulse
      @(posedge clear);
      $display("Clear signal detected high at %t", $time);
      @(negedge clear);

      // -----------------------------------------------
      // Test 4: Run full image, count clear pulses
      // Expected: (28-3+1) * (28-3+1) = 26 * 26 = 676 patches
      // -----------------------------------------------
      $display("Full image clear count:");
      
      // 1. STOP and RESET the hardware so counters go back to 0,0,0,0
      enable = 0;
      rst_n  = 0; 
      #20 rst_n = 1;
      @(posedge clk);
      
      // 2. Start fresh
      enable = 1;
      begin : count_patches
        int clear_count = 0;
        
        // 3. Loop until 'done' is reached
        while (1) begin
          @(posedge clk);
          if (clear) clear_count++;
          if (done) break; 
        end
        
        $display("Full image clear count: %d", clear_count);
        
        if (clear_count == 676) 
          $display("SUCCESS: 676 patches detected!");
        else 
          $display("FAILURE: Still got %d. Check if reset worked.", clear_count);
      end
      $display("Simulation complete.");
      $finish;
    end
endmodule
