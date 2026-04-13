import torch
import torch.nn as nn
import torch.optim as optim
from data_loader import train_loader, test_loader, test_data
from model import model

criterion = nn.CrossEntropyLoss()   # softmax + negative log likelihood
optimizer = optim.Adam(model.parameters(), lr=0.001)

def train(epochs=5):
    for epoch in range(epochs):
        model.train()
        total_loss = 0

        for batch_idx, (images, labels) in enumerate(train_loader):
            optimizer.zero_grad()          # clear gradients from last step
            output = model(images)         # forward pass
            loss   = criterion(output, labels)  # compute loss
            loss.backward()                # backprop
            optimizer.step()              # update weights
            total_loss += loss.item()

        # evaluate on test set after each epoch
        acc = evaluate()
        print(f"Epoch {epoch+1}/5 | Loss: {total_loss/len(train_loader):.4f} | Test Accuracy: {acc:.2f}%")

def evaluate():
    model.eval()
    correct = 0
    with torch.no_grad():                  # no gradient tracking needed
        for images, labels in test_loader:
            output     = model(images)
            predicted  = output.argmax(1)  # index of highest logit = predicted digit
            correct   += (predicted == labels).sum().item()
    return 100 * correct / len(test_data)

train(epochs=5)

torch.save(model.state_dict(), 'tiny_cnn.pth')
print("Model saved.")