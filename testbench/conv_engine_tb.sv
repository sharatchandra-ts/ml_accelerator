`timescale 1ns/1ps

module conv_engine_tb;

    // --- Parameters ---
    parameter DATA_WIDTH   = 8;
    parameter WEIGHT_WIDTH = 8;
    parameter IMG_W        = 28;
    parameter IMG_H        = 28;
    parameter K_W          = 3;
    parameter K_H          = 3;
    parameter ROWS         = 9;  // K_W * K_H
    parameter COLS         = 4;  // Number of Kernels
    parameter ADDR_WIDTH   = 10;
    
    localparam OUT_WIDTH = (2 * DATA_WIDTH) + 5;
    localparam TOTAL_OUT = (IMG_W - K_W + 1) * (IMG_H - K_H + 1);

    // --- Signals ---
    logic clk;
    logic rst_n;
    logic start;
    logic busy;
    logic layer_done;
    logic weight_valid;
    logic signed [DATA_WIDTH-1:0] weight_in; 
    logic signed [COLS-1:0][OUT_WIDTH-1:0] conv_out;
    logic out_valid;

    // --- Instantiate DUT ---
    conv_engine #(
        .DATA_WIDTH(DATA_WIDTH), .WEIGHT_WIDTH(WEIGHT_WIDTH),
        .IMG_W(IMG_W), .IMG_H(IMG_H), .K_W(K_W), .K_H(K_H),
        .ROWS(ROWS), .COLS(COLS), .ADDR_WIDTH(ADDR_WIDTH)
    ) uut (.*);

    // --- Clock Generation ---
    initial clk = 0;
    always #5 clk = ~clk;

    // ---------------------------------------------------------
    // MONITOR TASK: Print Loaded Weights
    // ---------------------------------------------------------
    task automatic print_loaded_weights();
        $display("\n--- [STAGE 1] LOADED WEIGHT MATRIX (from BRAM) ---");
        for (int k = 0; k < COLS; k++) begin
            string row_str = $sformatf("Kernel %0d: ", k);
            for (int r = 0; r < ROWS; r++) begin
                // Accessing the weight BRAM memory directly via hierarchical path
                row_str = {row_str, $sformatf("%4d ", uut.u_weight_bram.mem[k*ROWS + r])};
            end
            $display("%s", row_str);
        end
        $display("--------------------------------------------------\n");
    endtask

    // ---------------------------------------------------------
    // MONITOR BLOCK: Input Column Staggering
    // ---------------------------------------------------------
   // ---------------------------------------------------------
    // CONSOLIDATED CYCLE-BY-CYCLE MONITOR
    // ---------------------------------------------------------
    int cycle_count = 0;

    always @(posedge clk) begin
        if (uut.state == 2'b10) begin // Only monitor during COMPUTE
            cycle_count++;
            $display("\n[CYCLE %0d] [TIME %0t]", cycle_count, $time);
            
            // 1. Show what is ENTERING athe array right now
            if (uut.feeder_valid_out) begin
                $write("  INPUT (Skewed): ");
                for (int r = 0; r < ROWS; r++) begin
                    $write("R%0d:%d ", r, uut.skewed_pixels[r]);
                end
                $write("\n");
            end else begin
                $display("  INPUT (Skewed): [Feeder Stalling/Filling]");
            end

            // 2. Show what is EXITING the array right now
            $write("  OUTPUT (Accum): ");
            if (out_valid) begin
                for (int j = 0; j < COLS; j++) begin
                    $write("K%0d:%-6d ", j, $signed(conv_out[j]));
                end
                $write(" <--- VALID");
            end else begin
                $write("Calculating...");
            end
            
            $display("\n--------------------------------------------------");
        end
    end

    // ---------------------------------------------------------
    // MAIN SIMULATION CONTROL
    // ---------------------------------------------------------
    initial begin
        // Initialize Signals
        rst_n = 0; start = 0; weight_in = 0; weight_valid = 0;
        
        $display("\n--- STARTING CONV_ENGINE FULL STAGE DEBUG ---");
        #40 rst_n = 1;
        repeat(5) @(posedge clk);

        // 1. Trigger Weight Loading [cite: 100]
        @(posedge clk);
        start = 1;
        @(posedge clk);
        start = 0;

        // 2. Wait for Weights to be assembled [cite: 101]
        wait(uut.state == 2'b10); 
        $display("[%0t] [INFO] Weight loading complete. Engine moving to COMPUTE.", $time);
        print_loaded_weights();

        // 3. Monitor First Result [cite: 72]
        wait(out_valid == 1'b1);
        $display("\n***************************************************");
        $display(" [STAGE 3] FIRST VALID CONVOLUTION RESULT DETECTED!");
        $display(" Time     : %0t", $time);
        $display(" Result K0: %d", $signed(conv_out[0]));
        $display(" Result K1: %d", $signed(conv_out[1]));
        $display(" Result K2: %d", $signed(conv_out[2]));
        $display(" Result K3: %d", $signed(conv_out[3]));
        $display("***************************************************\n");

        // 4. End Simulation
        repeat(20) @(posedge clk);
        $display("[%0t] Debug test finished. Check wave for full pipeline details.", $time);
        $finish;
    end

    

    // --- Detailed Signal Monitor ---
    always @(posedge clk) begin
        if (uut.state == 2'b10) begin
            $display("DEBUG: State=COMPUTE | Addr=%d | Pixel=%d | im2col_valid=%b", 
                    uut.bram_addr, uut.pixel_from_bram, uut.im2col_valid);
        end
    end

    // --- Waveform Export ---
    initial begin
        $dumpfile("conv_engine_full_debug.vcd");
        $dumpvars(0, conv_engine_tb);
    end

endmodule