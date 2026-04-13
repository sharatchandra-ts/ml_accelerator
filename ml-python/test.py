import numpy as np

kernels = np.array([
    [ 63, -41,  85, 104, -105,  98,  64,  -6,  96],
    [ 88, 101, 118, 109,   22, 101, 100, -121,  86],
    [ 10,-102, 106, -79,  -46,  42, -98,  -18,  52],
    [112,  79,-106, -30,  104,  89,  62,   32, -73],
]).reshape(4, 3, 3)

# Load your actual test image here
image = ...  # shape (H, W)

# First patch (top-left 3x3)
patch = image[0:3, 0:3].flatten()

for i, k in enumerate(kernels):
    print(f"K{i} expected: {np.dot(k.flatten(), patch)}")