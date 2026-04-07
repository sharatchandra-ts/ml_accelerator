module patch_skew_buffer #(
  parameter int N_PATCHES  = 4,    // systolic array columns
  parameter int PATCH_SIZE = 9,    // K_H * K_W
  parameter int PIX_WIDTH  = 8
)(
  input  logic                         clk,
  input  logic                         rst_n,
  // Write port — connect wr_en to valid_d1, wr_data to image_bram.data_out
  input  logic                         wr_en,
  input  logic signed [PIX_WIDTH-1:0]  wr_data,
  // 4 skewed column outputs, one per systolic column
  output logic signed [PIX_WIDTH-1:0]  col_out [N_PATCHES],
  output logic                         out_valid,   // high during skew output
  output logic                         buf_full,    // all 36 values loaded
  output logic                         done         // last skew cycle, pulse
);
  localparam int DEPTH      = N_PATCHES * PATCH_SIZE;      // 36
  localparam int TOT_CYCLES = PATCH_SIZE + N_PATCHES - 1;  // 9 + 4 - 1 = 12

  // ── Storage ──────────────────────────────────────────────────
  // Patch p, element e → mem[p * PATCH_SIZE + e]
  logic signed [PIX_WIDTH-1:0] mem [0:DEPTH-1];

  // Extra bit so wr_ptr can reach DEPTH (= 36) as a sentinel
  logic [$clog2(DEPTH+1)-1:0] wr_ptr;

  // Skew cycle counter: 0 .. TOT_CYCLES-1
  logic [$clog2(TOT_CYCLES)-1:0] t;
  logic running;

  // ── Status signals ────────────────────────────────────────────
  assign buf_full  = (int'(wr_ptr) == DEPTH);
  assign out_valid = running;
  assign done      = running && (int'(t) == TOT_CYCLES - 1);

  // ── Sequential control ────────────────────────────────────────
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      wr_ptr  <= '0;
      t       <= '0;
      running <= 1'b0;
    end else begin

      // Write incoming pixels into buffer (blocked once full)
      if (wr_en && !buf_full) begin
        mem[wr_ptr] <= wr_data;
        wr_ptr      <= wr_ptr + 1;
      end

      // Start skewing the cycle buf_full first goes high
      if (buf_full && !running)
        running <= 1'b1;

      // Advance skew counter; reset everything on done for next group
      if (running) begin
        if (done) begin
          running <= 1'b0;
          t       <= '0;
          wr_ptr  <= '0;   // ready to accept next 4 patches
        end else
          t <= t + 1;
      end

    end
  end

  // ── Skewed column outputs ─────────────────────────────────────
  // At cycle t: col c gets mem[c*PATCH_SIZE + (t-c)]
  //             if t >= c and (t-c) < PATCH_SIZE, else 0
  always_comb begin
    for (int c = 0; c < N_PATCHES; c++) begin
      if (running && (int'(t) >= c) && ((int'(t) - c) < PATCH_SIZE))
        col_out[c] = mem[c * PATCH_SIZE + (int'(t) - c)];
      else
        col_out[c] = '0;
    end
  end

endmodule
