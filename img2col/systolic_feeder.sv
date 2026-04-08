module systolic_feeder #(
    parameter DATA_WIDTH = 8,
    parameter ROWS = 9,
    parameter COLS = 4
)(
    input  logic                   clk,
    input  logic                   rst_n,
    input  logic [DATA_WIDTH-1:0]  img_data_in,
    input  logic                   data_valid_in, 
    output logic [ROWS-1:0][DATA_WIDTH-1:0] systolic_out
);

    // --- 1. Dual Storage (Ping-Pong) ---
    // Added a 3rd dimension [2] to act as two separate banks
    logic [DATA_WIDTH-1:0] mem [0:1][0:COLS-1][0:ROWS-1];
    
    logic [5:0] write_cnt;
    logic [1:0] burst_cnt;
    logic is_bursting;
    logic full_pulse;
    
    logic write_bank; // Which bank we are loading
    logic read_bank;  // Which bank we are bursting from

    // --- 2. Input Logic (Loading Bank A while Bank B might be reading) ---
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            write_cnt  <= 0;
            full_pulse <= 0;
            write_bank <= 0;
        end else if (data_valid_in) begin
            mem[write_bank][write_cnt / ROWS][write_cnt % ROWS] <= img_data_in;
            
            if (write_cnt == (ROWS * COLS) - 1) begin
                write_cnt  <= 0;
                full_pulse <= 1;        // Signal that a bank is ready
                write_bank <= ~write_bank; // Swap to the other bank for next data
            end else begin
                write_cnt  <= write_cnt + 1;
                full_pulse <= 0;
            end
        end else begin
            full_pulse <= 0;
        end
    end

    // --- 3. Burst Control ---
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            is_bursting <= 0;
            burst_cnt   <= 0;
            read_bank   <= 0;
        end else if (full_pulse) begin
            is_bursting <= 1;
            burst_cnt   <= 0;
            read_bank   <= ~write_bank; // Read the bank that was JUST filled
        end else if (is_bursting) begin
            if (burst_cnt == COLS - 1) 
                is_bursting <= 0;
            else 
                burst_cnt <= burst_cnt + 1;
        end
    end

    // --- 4. Skewing Logic ---
    generate
        for (genvar r = 0; r < ROWS; r++) begin : skew_row
            logic [DATA_WIDTH-1:0] pipe [0:r];

            always_ff @(posedge clk or negedge rst_n) begin
                if (!rst_n) begin
                    for (int j = 0; j <= r; j++) pipe[j] <= '0;
                end else begin
                    // Read from the stable 'read_bank'
                    if (is_bursting) 
                        pipe[0] <= mem[read_bank][burst_cnt][r];
                    else 
                        pipe[0] <= '0;
                    
                    for (int j = 1; j <= r; j++) begin
                        pipe[j] <= pipe[j-1];
                    end
                end
            end
            assign systolic_out[r] = pipe[r];
        end
    endgenerate

endmodule