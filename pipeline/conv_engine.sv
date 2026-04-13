module conv_engine #(
    parameter DATA_WIDTH   = 8,
    parameter WEIGHT_WIDTH = 8,
    parameter IMG_W        = 28,
    parameter IMG_H        = 28,
    parameter K_W          = 3,
    parameter K_H          = 3,
    parameter ROWS         = 9,  // K_W * K_H
    parameter COLS         = 4,  // Number of Kernels
    parameter ADDR_WIDTH   = 10
)(
    input  logic clk,
    input  logic rst_n,
    
    // Control Interface
    input  logic start,
    output logic busy,
    output logic layer_done,
    
    // Weight Loading Interface
    // CHANGED: Weights are almost always signed
    input  logic signed [WEIGHT_WIDTH-1:0] weight_in, 
    input  logic                           weight_valid,
    
    // Final Output (from Systolic Array)
    // CHANGED: Explicitly signed output array
    output logic signed [COLS-1:0][(2*DATA_WIDTH)+4:0] conv_out, 
    output logic                                       out_valid
);

    localparam DEPTH     = ROWS * COLS;
    localparam ACC_WIDTH = (2 * DATA_WIDTH) + 5; 

    // --- 1. Internal Signals ---
    logic [ADDR_WIDTH-1:0]          bram_addr;
    logic [$clog2(DEPTH)-1:0]       weight_addr;
    logic signed [WEIGHT_WIDTH-1:0] weight_out;
    // CHANGED: Pixels can be signed (especially after normalization/centering)
    logic signed [DATA_WIDTH-1:0]   pixel_from_bram; 
    logic                           im2col_valid;
    
    logic                           im2col_valid_d1;
    logic                           im2col_valid_d2;
    logic                           feeder_valid_out; 

    logic                           im2col_enable;
    logic                           weight_loader_valid;
    logic                           weight_phys_done;   
    logic                           weight_assembly_done; 
    logic                           input_done; 
    logic                           input_done_sticky;

    // Weight Assembly Signals
    logic [1:0]                     col_inner_counter;
    logic [5:0]                     total_weight_counter;
    logic signed [WEIGHT_WIDTH-1:0] row_buffer [2:0]; 
    logic signed [WEIGHT_WIDTH-1:0] w_in [COLS];      
    logic                           load_en_reg;
    
    // CHANGED: Internal data wires must be signed to prevent zero-extension issues
    logic signed [ROWS-1:0][DATA_WIDTH-1:0] skewed_pixels;

    // Unpacked Array Bridges
    logic signed [DATA_WIDTH-1:0] a_in_array [ROWS];
    logic signed [ACC_WIDTH-1:0]  result_array [COLS];
    logic                         valid_in_array [COLS];
    logic                         clear_in_array [COLS];
    logic                         valid_out_array [COLS];

    // State Machine
    typedef enum logic [1:0] {
        IDLE        = 2'b00,
        LOAD_WGHT   = 2'b01,
        COMPUTE     = 2'b10,
        DONE        = 2'b11
    } state_t;
    
    state_t state, next_state;

    // --- 2. Data Mapping & Array Bridging ---
    always_comb begin
        for (int i = 0; i < ROWS; i++) begin
            a_in_array[i] = skewed_pixels[i];
        end

        for (int j = 0; j < COLS; j++) begin
            valid_in_array[j] = (state == COMPUTE) ? feeder_valid_out : (weight_valid && (state == LOAD_WGHT));
            clear_in_array[j] = (state == DONE);
            conv_out[j]       = result_array[j];
        end

        out_valid = valid_out_array[0];
    end

    // --- 3. BRAM Read Latency Compensation ---
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            im2col_valid_d1 <= 1'b0;
            im2col_valid_d2 <= 1'b0;
        end else begin
            im2col_valid_d1 <= im2col_valid;
            im2col_valid_d2 <= im2col_valid_d1;
        end
    end

    // --- 4. Module Instantiations ---
    // Note: Ensure your BRAM modules also use "logic signed" for their internal memory
    weight_loader #(.DEPTH(DEPTH)) u_weight_loader (
        .clk(clk), .rst_n(rst_n), .enable(state == LOAD_WGHT),
        .addr(weight_addr), .valid(weight_loader_valid), .done(weight_phys_done)
    );

    weight_bram #(.DEPTH(DEPTH), .DATA_WIDTH(WEIGHT_WIDTH)) u_weight_bram (
        .clk(clk), .addr(weight_addr), .data_out(weight_out)
    );

    image_bram u_image_bram (
        .clk(clk), .addr(bram_addr), .data_out(pixel_from_bram)
    );

    img2col u_img2col (
        .clk(clk), .rst_n(rst_n), .enable(im2col_enable),
        .addr(bram_addr), .valid(im2col_valid), .done(input_done)
    );

    systolic_feeder #(.DATA_WIDTH(DATA_WIDTH), .ROWS(ROWS), .COLS(COLS)) u_feeder (
        .clk(clk), .rst_n(rst_n), 
        .img_data_in(pixel_from_bram),
        .data_valid_in(im2col_valid_d1),
        .data_valid_out(feeder_valid_out),
        .systolic_out(skewed_pixels)
    );

    systolic_array #(
        .ROWS(ROWS), .COLUMNS(COLS), .DATA_WIDTH(DATA_WIDTH), .ACC_WIDTH(ACC_WIDTH)
    ) u_array (
        .clk(clk), .rst_n(rst_n), .load_en(load_en_reg),
        .a_in(a_in_array), .w_in(w_in), .result(result_array),
        .valid_in(valid_in_array), .clear_in(clear_in_array),
        .valid_out_final(valid_out_array)
    );

    // --- 5. Support Logic ---
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)             input_done_sticky <= 0;
        else if (state == IDLE) input_done_sticky <= 0;
        else if (input_done)    input_done_sticky <= 1;
    end

    // Weight Assembly FSM
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            total_weight_counter <= 0;
            col_inner_counter    <= 0;
            weight_assembly_done <= 0;
            load_en_reg          <= 0;
            for(int i=0; i<3; i++) row_buffer[i] <= 0;
        end 
        else if (state == LOAD_WGHT) begin
            if (weight_loader_valid) begin
                if (col_inner_counter == 2'd3) begin
                    load_en_reg <= 1'b1;
                    col_inner_counter <= 0;
                    if (total_weight_counter == 6'd35) weight_assembly_done <= 1'b1;
                end else begin
                    load_en_reg <= 0;
                    row_buffer[col_inner_counter] <= weight_out;
                    col_inner_counter <= col_inner_counter + 1;
                end
                total_weight_counter <= total_weight_counter + 1;
            end else begin
                load_en_reg <= 0;
            end
        end
        else if (state == IDLE) begin
            total_weight_counter <= 0;
            col_inner_counter    <= 0;
            weight_assembly_done <= 0;
            load_en_reg          <= 0;
        end
        else begin
            load_en_reg <= 0;
        end
    end

    always_comb begin
        w_in[3] = row_buffer[0];
        w_in[2] = row_buffer[1];
        w_in[1] = row_buffer[2];
        w_in[0] = weight_out;
    end

    assign im2col_enable = (state == COMPUTE) && !input_done_sticky;

    // --- 6. Main FSM ---
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) state <= IDLE;
        else        state <= next_state;
    end

    always_comb begin
        next_state = state;
        busy       = 1'b1;
        layer_done = 1'b0;

        case (state)
            IDLE: begin
                busy = 1'b0;
                if (start) next_state = LOAD_WGHT;
            end
            LOAD_WGHT: begin
                if (weight_assembly_done) next_state = COMPUTE;
            end
            COMPUTE: begin
                if (input_done_sticky) next_state = DONE;
            end
            DONE: begin
                layer_done = 1'b1;
                next_state = IDLE;
            end
            default: next_state = IDLE;
        endcase
    end

endmodule