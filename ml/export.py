import torch
import numpy as np
from model import TinyCNN

# load trained model
model = TinyCNN()
model.load_state_dict(torch.load('tiny_cnn.pth'))
model.eval()

# extract weights as numpy
conv_weights = model.conv1.weight.detach().numpy()  # shape: (4, 1, 3, 3)
conv_bias    = model.conv1.bias.detach().numpy()    # type: ignore # shape: (4,)
fc_weights   = model.fc.weight.detach().numpy()     # shape: (10, 676)
fc_bias      = model.fc.bias.detach().numpy()       # shape: (10,)

# quantise to Q8.8 fixed point (8 integer bits, 8 fractional bits)
SCALE = 2**8  # 256

def quantise(arr):
    return np.clip(np.round(arr * SCALE), -32768, 32767).astype(np.int16)

conv_w_q = quantise(conv_weights)
conv_b_q = quantise(conv_bias)
fc_w_q   = quantise(fc_weights)
fc_b_q   = quantise(fc_bias)

# save as hex files for BRAM init
def save_hex(arr, filename):
    flat = arr.flatten()
    with open(filename, 'w') as f:
        for val in flat:
            f.write(f"{int(val) & 0xFFFFFFFF:08X}\n")

save_hex(conv_w_q, 'conv_weights.hex')
save_hex(conv_b_q, 'conv_bias.hex')
save_hex(fc_w_q,   'fc_weights.hex')
save_hex(fc_b_q,   'fc_bias.hex')

print(f"Conv weights shape: {conv_weights.shape}")
print(f"FC weights shape:   {fc_weights.shape}")
print("Weights exported.")
