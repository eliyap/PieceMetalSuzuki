# Script for converting ASCII art to PNG
import matplotlib.pyplot as plt
import numpy as np

# Convert "_XX_" to [0, 255, 255, 0]
def strToRow(string: str) -> np.array:
    return np.array([255 if char == 'X' else 0 for char in string])

if __name__ == "__main__":
    img = np.array([
        strToRow("______________"),
        strToRow("_XXXXXXXXXXXX_"),
        strToRow("_XXXXXXXXXXXX_"),
        strToRow("_XX________XX_"),
        strToRow("_XX________XX_"),
        strToRow("_XX________XX_"),
        strToRow("_XX________XX_"),
        strToRow("_XX________XX_"),
        strToRow("_XX________XX_"),
        strToRow("_XX________XX_"),
        strToRow("_XX________XX_"),
        strToRow("_XXXXXXXXXXXX_"),
        strToRow("_XXXXXXXXXXXX_"),
        strToRow("______________"),
    ])
    plt.imsave('pixel_art.png', img, cmap='gray')