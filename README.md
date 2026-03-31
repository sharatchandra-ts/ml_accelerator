# FPGA-Based CNN Inference Accelerator

A hardware implementation of a Convolutional Neural Network inference engine, designed and verified in SystemVerilog and targeting the Xilinx Artix-7 FPGA. The accelerator performs end-to-end digit classification on the MNIST dataset using a trained TinyCNN model with quantized fixed-point weights.

---

## Overview

This project implements a complete CNN inference pipeline in hardware, from raw pixel input to classified digit output. The design eliminates dependency on a CPU for inference by mapping all computation — convolution, activation, pooling, and fully connected layers — directly onto reconfigurable logic.

The software-hardware co-design flow involves training a small CNN in PyTorch, quantizing the weights to Q8.8 fixed-point format, exporting them as hex initialization files, and verifying RTL output against the PyTorch reference model.

---

## Architecture

The accelerator is organized as a dataflow pipeline controlled by a central FSM. Each stage maps to a dedicated hardware module.

```
Input Image (28x28, 8-bit)
        |
   Image BRAM
        |
   im2col Address Generator
        |
   Skew Unit (wavefront alignment)
        |
   Conv Systolic Array (9x4, weight-stationary)  <-- Conv Weight BRAM
        |
   ReLU
        |
   Feature Map BRAM
        |
   MaxPool (2x2)
        |
   FC Systolic Array (9x4, output-stationary, tiled)  <-- FC Weight BRAM
        |
   Tile Accumulator (10 registers)
        |
   Argmax
        |
   Predicted Digit (0-9)
```

### Compute Units

**MAC Unit** — the fundamental compute element. Performs signed fixed-point multiply-accumulate with parameterized data and accumulator widths. Supports synchronous clear and data-valid gating to prevent accumulation of garbage values.

**Weight-Stationary Systolic Array (9x4)** — used for the convolution layer. Weights are loaded once into PE registers via a bottom-up ripple load. Input activations flow left to right in a skewed wavefront. Partial sums accumulate top to bottom. 9 rows correspond to the 9 elements of a 3x3 kernel; 4 columns correspond to the 4 convolution filters.

**Output-Stationary Systolic Array (9x4)** — used for the fully connected layer. Both weights and inputs stream through the array every cycle. Partial sums remain in PE accumulators across all 76 tiles of one column group. No weight loading phase is required between tiles.

**im2col Address Generator** — generates pixel addresses for all 676 overlapping 3x3 patches of the input image. Uses four nested counters (out_r, out_c, kr, kc) to traverse the image in column-major patch order, enabling direct compatibility with the skew unit and systolic array input format.

**Skew Unit** — a chain of 9 registers that introduces progressive one-cycle delays per row, aligning the column-major pixel stream into the diagonal wavefront pattern required by the systolic array.

**FC Tiling Controller** — manages tiled execution of the fully connected layer. Decomposes the 1x676 times 676x10 matrix multiply into 228 passes (76 input tiles times 3 output column groups) through the 9x4 FC systolic array. Accumulates partial column sums into 10 output registers across tiles.

---

## CNN Model

A minimal CNN trained in PyTorch on the MNIST dataset.

```
Input:      1 x 28 x 28
Conv2d:     4 filters, 3x3 kernel, stride 1  ->  4 x 26 x 26
ReLU
MaxPool2d:  2x2, stride 2                    ->  4 x 13 x 13
Flatten:                                     ->  676
Linear:     676 -> 10
```

Weights are quantized to Q8.8 fixed-point (8 integer bits, 8 fractional bits, scale factor 256) before export. Quantized accuracy on the MNIST test set is verified in Python prior to RTL implementation.

---

## References

Kung, H.T. (1982). Why Systolic Architectures? IEEE Computer, 15(1), 37-46.

Chen, Y. et al. (2016). Eyeriss: A Spatial Architecture for Energy-Efficient Dataflow for Convolutional Neural Networks. ISCA 2016.

Jouppi, N. et al. (2017). In-Datacenter Performance Analysis of a Tensor Processing Unit. ISCA 2017.

Yan, F., Koch, A., Sinnen, O. (2024). A Survey on FPGA-based Accelerator for ML Models. arXiv:2412.15666.

LeCun, Y., Cortes, C., Burges, C. (1998). The MNIST Database of Handwritten Digits.
