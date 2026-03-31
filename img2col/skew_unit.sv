module skew_unit #(
    parameter R = 3,
    parameter C = 3,
    parameter AW = $clog2(R*C)
)(
    input  logic clk,
    input  logic rst_n,
    input  logic en,

    output logic [AW-1:0] addr,
    output logic valid,
    output logic done
);

    logic [$clog2(R+C):0] d;
    logic [$clog2(R)-1:0] i;

    logic [$clog2(R)-1:0] i_start, i_end;

    always_comb begin
        i_start = (d < C) ? 0 : (d - (C-1));
        i_end   = (d < R) ? d : (R-1);
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            d     <= 0;
            i     <= 0;
            valid <= 0;
            done  <= 0;
        end 
        else if (en && !done) begin
            valid <= 1;

            // linear address
            addr <= i*C + (d - i);

            // traversal
            if (i == i_end) begin
                if (d == R + C - 2) begin
                    done <= 1;
                end else begin
                    d <= d + 1;
                    i <= ((d + 1) < C) ? 0 : (d + 1 - (C-1));
                end
            end else begin
                i <= i + 1; // increment → RIGHT TO LEFT
            end
        end
    end

endmodule
