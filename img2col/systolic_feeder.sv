module systolic_feeder #(
    parameter DATA_WIDTH = 8,
    parameter ROWS = 9,
    parameter COLS = 4
)(
    input  logic                   clk,
    input  logic                   rst_n,
    // CHANGED: Input data can be signed
    input  logic signed [DATA_WIDTH-1:0]  img_data_in,
    input  logic                          data_valid_in, 
    output logic                          data_valid_out,
    // CHANGED: Output array must be signed
    output logic signed [ROWS-1:0][DATA_WIDTH-1:0] systolic_out
);

    // CHANGED: Internal memory storage must be signed
    logic signed [DATA_WIDTH-1:0] mem [0:1][0:COLS-1][0:ROWS-1];
    
    logic [5:0] write_cnt;
    logic is_bursting;
    logic [1:0] burst_cnt;
    logic full_pulse;
    logic write_bank; 
    logic read_bank;  

    // --- 1. Input Logic ---
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            write_cnt  <= 0;
            full_pulse <= 0;
            write_bank <= 0;
        end else if (data_valid_in) begin
            mem[write_bank][write_cnt / ROWS][write_cnt % ROWS] <= img_data_in;
            if (write_cnt == (ROWS * COLS) - 1) begin
                write_cnt  <= 0;
                full_pulse <= 1;        
                write_bank <= ~write_bank;
            end else begin
                write_cnt  <= write_cnt + 1;
                full_pulse <= 0;
            end
        end else begin
            full_pulse <= 0;
        end
    end

    // --- 2. Burst Control ---
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            is_bursting <= 0;
            burst_cnt   <= 0;
            read_bank   <= 0;
        end else if (full_pulse) begin
            is_bursting <= 1;
            burst_cnt   <= 0;
            read_bank   <= ~write_bank; 
        end else if (is_bursting) begin
            if (burst_cnt == COLS - 1) is_bursting <= 0;
            else                       burst_cnt <= burst_cnt + 1;
        end
    end

    // --- 3. Skewing Logic & Valid Generation ---
    logic [ROWS-1:0] pipe_valid;

    generate
        for (genvar r = 0; r < ROWS; r++) begin : skew_row
            // CHANGED: Pipeline registers must be signed to prevent unsigned extension
            logic signed [DATA_WIDTH-1:0] pipe [0:r];
            logic v_pipe [0:r];

            always_ff @(posedge clk or negedge rst_n) begin
                if (!rst_n) begin
                    for (int j = 0; j <= r; j++) begin 
                        pipe[j] <= '0; 
                        v_pipe[j] <= 0; 
                    end
                end else begin
                    // When is_bursting is false, we feed '0 to keep the pipe clean
                    pipe[0]   <= (is_bursting) ? mem[read_bank][burst_cnt][r] : '0;
                    v_pipe[0] <= is_bursting;
                    
                    for (int j = 1; j <= r; j++) begin
                        pipe[j]   <= pipe[j-1];
                        v_pipe[j] <= v_pipe[j-1];
                    end
                end
            end
            assign systolic_out[r] = pipe[r];
            assign pipe_valid[r]   = v_pipe[r];
        end
    endgenerate

    assign data_valid_out = |pipe_valid;

endmodule