`timescale 1ns/1ps

module tb_complete_systolic_feed;

    // Parameters from your BRAM setup
    localparam IMG_W = 28;
    localparam IMG_H = 28;
    localparam K_W   = 3;
    localparam K_H   = 3;
    localparam PIX_WIDTH = 8;
    localparam ROWS = 9; // 3x3 kernel = 9 rows for systolic array

    // Interconnect Signals
    logic clk, rst_n, enable;
    logic [$clog2(IMG_W*IMG_H)-1:0] addr;
    logic valid, clear, done;
    logic signed [PIX_WIDTH-1:0] pixel_out;
    
    // Systolic Output
    logic [ROWS-1:0][PIX_WIDTH-1:0] systolic_out;

    // 1. Instantiate your im2col Controller
    img2col #(
        .IMG_W(IMG_W), .IMG_H(IMG_H),
        .K_W(K_W),     .K_H(K_H)
    ) u_im2col (
        .clk(clk), .rst_n(rst_n), .enable(enable),
        .addr(addr), .valid(valid), .clear(clear), .done(done)
    );

    // 2. Instantiate your Image BRAM
    image_bram #(
        .IMG_W(IMG_W), .IMG_H(IMG_H),
        .PIX_WIDTH(PIX_WIDTH)
    ) u_bram (
        .clk(clk), .addr(addr), .data_out(pixel_out)
    );

    // 3. Instantiate the Systolic Feeder 
    // This collects the 9 pixels from one patch and skews them
    systolic_feeder #(
        .DATA_WIDTH(PIX_WIDTH),
        .ROWS(ROWS)
    ) u_feeder (
        .clk(clk),
        .rst_n(rst_n),
        .img_data_in(addr),
        .data_valid_in(valid), // Connects directly to im2col valid
        .systolic_out(systolic_out)
    );

    // Clock Generation
    initial clk = 0;
    always #5 clk = ~clk;

    // Test Sequence
    initial begin
        $dumpfile("systolic_test.vcd");
        $dumpvars(0, tb_complete_systolic_feed);

        // Reset
        rst_n = 0;
        enable = 0;
        #20 rst_n = 1;
        
        // Start Processing
        @(posedge clk);
        enable = 1;

        $display("--- Starting Systolic Feed Test ---");

        // Wait for the first full patch to be collected (9 cycles of valid)
        // Then wait for the skewing to propagate (additional cycles)
        wait(done);
        
        #100;
        $display("Simulation complete.");
        $finish;
    end

    // Waveform monitor
    initial begin
        $monitor("Time=%0t | Valid=%b | Out= %d|%d|%d|%d|%d|%d|%d|%d|%d|", 
                 $time, valid, systolic_out[0], systolic_out[1],systolic_out[2],systolic_out[3],systolic_out[4],systolic_out[5],systolic_out[6],systolic_out[7], systolic_out[8]);
    end

endmodule