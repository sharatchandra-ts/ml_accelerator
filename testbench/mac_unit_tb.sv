`timescale 1ns/1ps

module mac_unit_tb;

    // 1. Parameters & Signals
    parameter DATA_WIDTH = 8;
    parameter ACC_WIDTH  = 32;

    logic clk, rst_n;
    logic clear_in, clear_out;
    logic valid_in, valid_out;
    
    logic signed [DATA_WIDTH-1:0] a_in, a_out;
    logic signed [DATA_WIDTH-1:0] b_in, b_out;
    logic signed [ACC_WIDTH-1:0]  c_in;
    logic signed [ACC_WIDTH-1:0]  acc_out;

    // 2. Instantiate DUT (Device Under Test)
    mac_unit #(
        .DATA_WIDTH(DATA_WIDTH),
        .ACC_WIDTH (ACC_WIDTH)
    ) dut (.*); // Use .* to connect signals with matching names

    // 3. Clock Generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // 4. Test Script
    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, mac_unit_tb);

        // Reset Sequence
        a_in = 0; b_in = 0; c_in = 0;
        clear_in = 0; valid_in = 0;
        rst_n = 0;
        #15 rst_n = 1;

        // --- Test 1: Math Verification ---
        // Calculate: (3 * 4) + 10 = 22
        @(posedge clk);
        a_in = 8'sd3; b_in = 8'sd4; c_in = 32'sd10; valid_in = 1;

        @(posedge clk);
        valid_in = 0;
        $display("Math Test: acc_out = %d (Expected 22)", acc_out);

        // --- Test 2: Pipeline Propagation ---
        // Verify that a_in and b_in take 1 cycle to reach a_out and b_out
        @(posedge clk);
        a_in = 8'sd77; b_in = 8'sd88; 
        
        // At this specific moment, a_out should NOT be 77 yet.
        $display("Pipeline Check (Same Cycle): a_out = %d (Expected 3)", a_out);

        @(posedge clk);
        // Now a_out should be 77
        $display("Pipeline Check (Next Cycle): a_out = %d (Expected 77)", a_out);

        // --- Test 3: Clear Logic ---
        @(posedge clk);
        clear_in = 1;
        
        @(posedge clk);
        clear_in = 0;
        $display("Clear Test: acc_out = %d (Expected 0)", acc_out);
        $display("Clear Prop: clear_out = %b (Expected 1)", clear_out);

        repeat(3) @(posedge clk);
        $finish;
    end

endmodule
