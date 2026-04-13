import torch
import torch.nn as nn
import torch.optim as optim
from torchvision import datasets, transforms
from torch.utils.data import DataLoader
import numpy as np

class TinyCNN(nn.Module):
    def __init__(self):
       super().__init__()
       
       self.conv1 = nn.Conv2d(in_channels=1, out_channels=4, kernel_size=3)
       
       self.pool = nn.MaxPool2d(kernel_size=2)
       
       self.fc = nn.Linear(4*13*13, 10) 
       
    def forward(self, x):
        x = self.conv1(x)     # conv
        x = torch.relu(x)     # activation
        x = self.pool(x)      # downsample
        x = x.flatten(1)      # flatten everything except batch dim
        x = self.fc(x)        # classify
        return x              # raw logits — no softmax (CrossEntropyLoss handles it)

model = TinyCNN()
print(model)
print(f"Parameters: {sum(p.numel() for p in model.parameters()):,}")