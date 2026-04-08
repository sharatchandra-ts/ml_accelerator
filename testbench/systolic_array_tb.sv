`timescale 1ns/1ps

// module tb_systolic_array();
//     parameter ROWS = 2, COLUMNS = 2, DATA_WIDTH = 8, ACC_WIDTH = 32;
//     logic clk, rst_n, load_en;
//     logic signed [DATA_WIDTH-1:0] a_in [ROWS];
//     logic signed [DATA_WIDTH-1:0] w_in [COLUMNS];
//     logic valid_in [COLUMNS], clear_in [COLUMNS];
//     logic signed [ACC_WIDTH-1:0] result [COLUMNS];
//     logic valid_out_final [COLUMNS];

//     // Instantiate 2x2 systolic array
//     systolic_array #(ROWS, COLUMNS, DATA_WIDTH, ACC_WIDTH) dut (.*);

//     // Clock generation
//     initial clk = 0;
//     always #5 clk = ~clk;

//     task clear_inputs();
//         for (int i=0; i<ROWS; i++) a_in[i] = 0;
//         for (int i=0; i<COLUMNS; i++) begin
//             w_in[i] = 0; valid_in[i] = 0; clear_in[i] = 0;
//         end
//     endtask

//     initial begin
//         $dumpfile("dump.vcd"); $dumpvars(0, tb_systolic_array);
//         rst_n = 0; load_en = 0;
//         clear_inputs(); 
//         #20 rst_n = 1;

//         // --- Step 1: Load Weights ---
//         load_en = 1;   @(posedge clk);
//         w_in[0] = -2; w_in[1] = 7; @(posedge clk); // Row0 weights
//         w_in[0] = 4; w_in[1] = 0; @(posedge clk); // Row1 weights
//         load_en = 0; @(posedge clk);

//         // Clear
//         clear_in[0] = 1; clear_in[1] = 1; @(posedge clk);
//         clear_in[0] = 0; clear_in[1] = 0;

//         // Feed A in wavefront
//         // Cycle 1
//         a_in[0] = 2; a_in[1] = 0; valid_in[0]=1; valid_in[1]=1; @(posedge clk);
//         // Cycle 2
//         a_in[0] = 5; a_in[1] = -1; @(posedge clk);
//         // Cycle 3
//         a_in[0] = 0; a_in[1] = 3; @(posedge clk);
//         // Cycle 4
//         a_in[0] = 0; a_in[1] = 0; valid_in[0]=0; valid_in[1]=0; @(posedge clk);

//         // Wait tail
//         repeat(03) @(posedge clk);

//                 $display("Final Results:");
//                 $display("C[0][0] = %0d", result[0]);
//                 $display("C[0][1] = %0d", result[1]);

//                 $finish;
//     end

//     // Optional: display intermediate results every cycle
//     initial begin
//         $display("\nTime | C0 | C1 | Vout");
//         $display("------------------------");
//         forever @(posedge clk) begin
//             if (valid_out_final[0] || valid_out_final[1])
//                 $display("%4t | %3d | %3d | %b%b", 
//                          $time, result[0], result[1], 
//                          valid_out_final[0], valid_out_final[1]);
//         end
//     end

// endmodule


// module tb_systolic_array();
//     // Updated parameters for 3x3
//     parameter ROWS = 3, COLUMNS = 3, DATA_WIDTH = 8, ACC_WIDTH = 32;
    
//     logic clk, rst_n, load_en;
//     logic signed [DATA_WIDTH-1:0] a_in [ROWS];
//     logic signed [DATA_WIDTH-1:0] w_in [COLUMNS];
//     logic valid_in [COLUMNS], clear_in [COLUMNS];
//     logic signed [ACC_WIDTH-1:0] result [COLUMNS];
//     logic valid_out_final [COLUMNS];

//     // Instantiate 3x3 systolic array
//     systolic_array #(ROWS, COLUMNS, DATA_WIDTH, ACC_WIDTH) dut (.*);

//     // Clock generation
//     initial clk = 0;
//     always #5 clk = ~clk;

//     task clear_inputs();
//         for (int i=0; i<ROWS; i++) a_in[i] = 0;
//         for (int i=0; i<COLUMNS; i++) begin
//             w_in[i] = 0; valid_in[i] = 0; clear_in[i] = 0;
//         end
//     endtask

//     initial begin
//         $dumpfile("dump.vcd"); 
//         $dumpvars(0, tb_systolic_array);
        
//         rst_n = 0; load_en = 0;
//         clear_inputs(); 
//         #20 rst_n = 1;

//         // --- Step 1: Load Weights (1-9) ---
//         // Assuming weights are shifted in row by row
//         load_en = 1;   @(posedge clk);
//         w_in[0] = 7; w_in[1] = 8; w_in[2] = 9; @(posedge clk); // Row 2
//         w_in[0] = 4; w_in[1] = 5; w_in[2] = 6; @(posedge clk); // Row 1
//         w_in[0] = 1; w_in[1] = 2; w_in[2] = 3; @(posedge clk); // Row 0
//         load_en = 0; 

//         // --- Step 2: Clear Accumulators ---
//         clear_in[0] = 1; clear_in[1] = 1; clear_in[2] = 1; @(posedge clk);
//         clear_in[0] = 0; clear_in[1] = 0; clear_in[2] = 0;

//         // --- Step 3: Feed A in Wavefront (10, 20, ... 90) ---
//         // Data must be skewed: Row 0 starts @ T1, Row 1 @ T2, Row 2 @ T3
//         valid_in[0]=1; valid_in[1]=1; valid_in[2]=1;

//         // Cycle 1: Row 0 starts
//         a_in[0] = 10; a_in[1] = 0;  a_in[2] = 0;  @(posedge clk);
//         // Cycle 2: Row 0 contines, Row 1 starts
//         a_in[0] = 40; a_in[1] = 20; a_in[2] = 0;  @(posedge clk);
//         // Cycle 3: Row 0 ends, Row 1 continues, Row 2 starts
//         a_in[0] = 70; a_in[1] = 50; a_in[2] = 30; @(posedge clk);
//         // Cycle 4: Row 1 ends, Row 2 continues
//         a_in[0] = 0;  a_in[1] = 80; a_in[2] = 60; @(posedge clk);
//         // Cycle 5: Row 2 ends
//         a_in[0] = 0;  a_in[1] = 0;  a_in[2] = 90; @(posedge clk);

//         // Terminate inputs
//         a_in[2] = 0; valid_in[0]=0; valid_in[1]=0; valid_in[2]=0;

//         // Wait for pipeline to flush (Tail)
//         repeat(10) @(posedge clk);

//         $display("\nFinal Column Results:");
//         $display("Col 0: %0d", result[0]);
//         $display("Col 1: %0d", result[1]);
//         $display("Col 2: %0d", result[2]);

//         $finish;
//     end

//     // Monitor for results
//     initial begin
//         $display("\nTime | Col0 | Col1 | Col2 | Vout");
//         $display("------------------------------------");
//         forever @(posedge clk) begin
//         if (valid_out_final[0] || valid_out_final[1] || valid_out_final[2])
//                 $display("%4t | %4d | %4d | %4d | %b%b%b", 
//                          $time, result[0], result[1], result[2],
//                          valid_out_final[0], valid_out_final[1], valid_out_final[2]);
//         end
//     end

// endmodule

module tb_systolic_array();
    // Updated parameters for 4x4
    parameter ROWS = 4, COLUMNS = 4, DATA_WIDTH = 9, ACC_WIDTH = 32;
    
    logic clk, rst_n, load_en;
    logic signed [DATA_WIDTH-1:0] a_in [ROWS];
    logic signed [DATA_WIDTH-1:0] w_in [COLUMNS];
    logic valid_in [COLUMNS], clear_in [COLUMNS];
    logic signed [ACC_WIDTH-1:0] result [COLUMNS];
    logic valid_out_final [COLUMNS];

    // Instantiate 4x4 systolic array
    systolic_array #(ROWS, COLUMNS, DATA_WIDTH, ACC_WIDTH) dut (.*);

    // Clock generation
    initial clk = 0;
    always #5 clk = ~clk;

    task clear_inputs();
        for (int i=0; i<ROWS; i++) a_in[i] = 0;
        for (int i=0; i<COLUMNS; i++) begin
            w_in[i] = 0; valid_in[i] = 0; clear_in[i] = 0;
        end
    endtask

    initial begin
        $dumpfile("dump.vcd"); 
        $dumpvars(0, tb_systolic_array);
        
        rst_n = 0; load_en = 0;
        clear_inputs(); 
        #20 rst_n = 1;

        // --- Step 1: Load Weights (A 4x4: 1..16) ---
        load_en = 1;   @(posedge clk);
        w_in[0] = 13; w_in[1] = 14; w_in[2] = 15; w_in[3] = 16; @(posedge clk); // Row 3
        w_in[0] = 9;  w_in[1] = 10; w_in[2] = 11; w_in[3] = 12; @(posedge clk); // Row 2
        w_in[0] = 5;  w_in[1] = 6;  w_in[2] = 7;  w_in[3] = 8;  @(posedge clk); // Row 1
        w_in[0] = 1;  w_in[1] = 2;  w_in[2] = 3;  w_in[3] = 4;  @(posedge clk); // Row 0
        load_en = 0; 

        // --- Step 2: Clear Accumulators ---
        for (int i=0; i<COLUMNS; i++) clear_in[i] = 1; @(posedge clk);
        for (int i=0; i<COLUMNS; i++) clear_in[i] = 0;

        // --- Step 3: Feed A (B transposed) in Wavefront ---
        for (int i=0; i<COLUMNS; i++) valid_in[i]=1;

        // Cycle 1: Row 0 starts
        a_in[0] = 10; a_in[1] = 0;  a_in[2] = 0;  a_in[3] = 0; @(posedge clk);
        // Cycle 2: Row 0 continues, Row 1 starts
        a_in[0] = 50; a_in[1] = 20; a_in[2] = 0;  a_in[3] = 0; @(posedge clk);
        // Cycle 3: Row 0 continues, Row 1 continues, Row 2 starts
        a_in[0] = 90; a_in[1] = 60; a_in[2] = 30; a_in[3] = 0; @(posedge clk);
        // Cycle 4: Row 1 continues, Row 2 continues, Row 3 starts
        a_in[0] = 130; a_in[1] = 100; a_in[2] = 70; a_in[3] = 40; @(posedge clk);
        // Cycle 5: Row 2 continues, Row 3 continues
        a_in[0] = 0;   a_in[1] = 140; a_in[2] = 110; a_in[3] = 80; @(posedge clk);
        // Cycle 6: Row 3 continues
        a_in[0] = 0;   a_in[1] = 0;   a_in[2] = 150; a_in[3] = 120; @(posedge clk);
        // Cycle 7: Row 3 ends
        a_in[0] = 0;   a_in[1] = 0;   a_in[2] = 0;   a_in[3] = 160; @(posedge clk);

        // Terminate inputs
        for (int i=0; i<ROWS; i++) a_in[i] = 0;
        for (int i=0; i<COLUMNS; i++) valid_in[i] = 0;

        // Wait for pipeline to flush
        repeat(12) @(posedge clk);

        $display("\nFinal Column Results:");
        $display("Col 0: %0d", result[0]);
        $display("Col 1: %0d", result[1]);
        $display("Col 2: %0d", result[2]);
        $display("Col 3: %0d", result[3]);

        $finish;
    end

    // Monitor for results
    initial begin
        $display("\nTime | Col0 | Col1 | Col2 | Col3 | Vout");
        $display("--------------------------------------------");
        forever @(posedge clk) begin
            if (valid_out_final[0] || valid_out_final[1] || valid_out_final[2] || valid_out_final[3])
                $display("%4t | %4d | %4d | %4d | %4d | %b%b%b%b", 
                         $time, result[0], result[1], result[2], result[3],
                         valid_out_final[0], valid_out_final[1],
                         valid_out_final[2], valid_out_final[3]);
        end
    end

endmodule
