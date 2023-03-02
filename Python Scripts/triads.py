# The source code for generating the triads for the 3x3 kernel.

from typing import List
from enum import Enum

Direction = Enum("Direction", ["UP", "TOP_RIGHT", "RIGHT", "BOTTOM_RIGHT", "DOWN", "BOTTOM_LEFT", "LEFT", "TOP_LEFT"])

def idx(direction: Direction):
    if direction == Direction.UP:
        return 1
    elif direction == Direction.TOP_RIGHT:
        return 2
    elif direction == Direction.RIGHT:
        return 4
    elif direction == Direction.BOTTOM_RIGHT:
        return 7
    elif direction == Direction.DOWN:
        return 6
    elif direction == Direction.BOTTOM_LEFT:
        return 5
    elif direction == Direction.LEFT:
        return 3
    elif direction == Direction.TOP_LEFT:
        return 0

def clockwise(direction: Direction):
    if direction == Direction.UP:
        return Direction.TOP_RIGHT
    elif direction == Direction.TOP_RIGHT:
        return Direction.RIGHT
    elif direction == Direction.RIGHT:
        return Direction.BOTTOM_RIGHT
    elif direction == Direction.BOTTOM_RIGHT:
        return Direction.DOWN
    elif direction == Direction.DOWN:
        return Direction.BOTTOM_LEFT
    elif direction == Direction.BOTTOM_LEFT:
        return Direction.LEFT
    elif direction == Direction.LEFT:
        return Direction.TOP_LEFT
    elif direction == Direction.TOP_LEFT:
        return Direction.UP

def value(direction: Direction):
    if direction == Direction.UP:
        return "ChainDirection.up.rawValue"
    elif direction == Direction.TOP_RIGHT:
        return "ChainDirection.topRight.rawValue"
    elif direction == Direction.RIGHT:
        return "ChainDirection.right.rawValue"
    elif direction == Direction.BOTTOM_RIGHT:
        return "ChainDirection.bottomRight.rawValue"
    elif direction == Direction.DOWN:
        return "ChainDirection.down.rawValue"
    elif direction == Direction.BOTTOM_LEFT:
        return "ChainDirection.bottomLeft.rawValue"
    elif direction == Direction.LEFT:
        return "ChainDirection.left.rawValue"
    elif direction == Direction.TOP_LEFT:
        return "ChainDirection.topLeft.rawValue"
    

class Kernel: 
    kernel: List[bool]

    def __init__(self, kernel: List[bool]):
        self.kernel = kernel

    def triads(self, useValue: bool = False):
        dxn = Direction.UP
        result = []
        for _ in range(8):
            dxn = clockwise(dxn)
            if self.kernel[idx(dxn)]:
                break
        else:
            # All directions are open, no triads.
            # return ["Run.invalid", "Run.invalid", "Run.invalid", "Run.invalid"]
            return ["PixelPoint.invalid", "PixelPoint.invalid", "PixelPoint.invalid", "PixelPoint.invalid"]
        
        didCrossCardinal = False
        for _ in range(8):
            next = clockwise(dxn)
            
            if self.kernel[idx(dxn)] and not self.kernel[idx(next)]:
                start = dxn
                didCrossCardinal = False

            if not self.kernel[idx(dxn)] and (dxn == Direction.UP or dxn == Direction.RIGHT or dxn == Direction.DOWN or dxn == Direction.LEFT):
                didCrossCardinal = True

            if not self.kernel[idx(dxn)] and self.kernel[idx(next)]:
                end = next
                if didCrossCardinal:
                    if useValue:
                        # result.append(f"Run(t: {0}, h: {1}, from: {value(start)}, to: {value(end)})")
                        result.append(f"PixelPoint(x: {0}, y: {0})")
                    else:
                        result.append(start)
                        result.append(end)
                
            dxn = next
        
        # Pad with 0's
        # result += ["Run.invalid", "Run.invalid", "Run.invalid", "Run.invalid"]
        result += ["PixelPoint.invalid", "PixelPoint.invalid", "PixelPoint.invalid", "PixelPoint.invalid"]
        result = result[:4]
        return result


if __name__ == "__main__":
    # kernel = Kernel([
    #     0, 0, 0, 
    #     0,    1, 
    #     0, 1, 0,
    # ])
    # print(kernel.triads())
    
    # Generate all possible 3x3 kernels
    with open ("triads.txt", "w") as f:
        for a7 in [0, 1]:
            for a6 in [0, 1]:
                for a5 in [0, 1]:
                    for a4 in [0, 1]:
                        for a3 in [0, 1]:
                            for a2 in [0, 1]:
                                for a1 in [0, 1]:
                                    for a0 in [0, 1]:
                                        kernel = Kernel([a0, a1, a2, a3, a4, a5, a6, a7])
                                        f.write(f"// {a0}{a1}{a2}\n")
                                        f.write(f"// {a3} {a4}\n")
                                        f.write(f"// {a5}{a6}{a7}\n")
                                        f.write(",\n".join(kernel.triads(useValue=True)))
                                        f.write(",\n\n")
