module img2col #(
  IMG_W = 28,
  IMG_H = 28,
  K_W = 3,
  K_H = 3
) (
  input  logic clk,
  input  logic rst_n,
  input  logic enable,
  output logic [$clog2(IMG_W * IMG_H)-1:0] addr,
  output logic valid,
  output logic clear,
  output logic done
);

  localparam out_W = IMG_W - K_W + 1;
  localparam out_H = IMG_H - K_H + 1;

  logic [$clog2(K_W)-1:0]   kc;
  logic [$clog2(K_H)-1:0]   kr;
  logic [$clog2(out_W)-1:0] out_c;
  logic [$clog2(out_H)-1:0] out_r;


  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      out_r <= 0;
      out_c <= 0;
      kr    <= 0;
      kc    <= 0;
    end else if (enable) begin
      if (kr == K_H - 1) begin
        kr <= 0;
        if (kc == K_W - 1) begin
          kc <= 0;
          if (out_c == out_W - 1) begin
            out_c <= 0;
            if (out_r == out_H - 1)
              out_r <= 0;
            else
              out_r <= out_r + 1;
          end else
            out_c <= out_c + 1;
        end else
          kc <= kc + 1;
      end else
        kr <= kr + 1;
    end
  end

  assign addr  = (out_r + kr) * IMG_W + (out_c + kc);
  assign valid = enable;
  assign clear = enable && (kc == K_W - 1) && (kr == K_H - 1);
  assign done  = enable && (kc == K_W - 1) && (kr == K_H - 1)
                        && (out_c == out_W - 1) && (out_r == out_H - 1);
endmodule

