import itertools
import random
from typing import Dict, List, Tuple


class Marker:

    bits: List[List[bool]] = []

    def __init__(self, bits: List[List[bool]]):
        self.bits = bits

    def __str__(self):
        def char(bit: bool):
            return "X" if bit else "_"
        return "\n".join([
            f"{char(self.bits[0][0])}{char(self.bits[0][1])}{char(self.bits[0][2])}",
            f"{char(self.bits[1][0])}{char(self.bits[1][1])}{char(self.bits[1][2])}",
            f"{char(self.bits[2][0])}{char(self.bits[2][1])}{char(self.bits[2][2])}",
        ])

    def __eq__(self, other):
        return self.bits == other.bits

    def copy(self):
        return Marker([
            [self.bits[0][0], self.bits[0][1], self.bits[0][2]],
            [self.bits[1][0], self.bits[1][1], self.bits[1][2]],
            [self.bits[2][0], self.bits[2][1], self.bits[2][2]],
        ])

def rotate(marker: Marker) -> Marker:
    return Marker([
        [marker.bits[2][0], marker.bits[1][0], marker.bits[0][0]],
        [marker.bits[2][1], marker.bits[1][1], marker.bits[0][1]],
        [marker.bits[2][2], marker.bits[1][2], marker.bits[0][2]],
    ])

def generate() -> List[Marker]:
    markers: List[Marker] = []
    for bit1 in [True, False]:
        # for bit2 in [True, False]:
        for bit2 in [False]:
            for bit3 in [True, False]:
                # for bit4 in [True, False]:
                for bit4 in [False]:
                    for bit5 in [True, False]:
                        # for bit6 in [True, False]:
                        for bit6 in [False]:
                            for bit7 in [True, False]:
                                for bit8 in [True, False]:
                                    for bit9 in [True, False]:
                                        markers.append(Marker([
                                            [bit1, bit2, bit3], 
                                            [bit4, bit5, bit6], 
                                            [bit7, bit8, bit9]
                                        ]))
    return markers

# Coordinates at which to try flipping bits
one_bit_flips: List[Tuple[int, int]] = [
    (0, 0), (0, 1), (0, 2),
    (1, 0), (1, 1), (1, 2),
    (2, 0), (2, 1), (2, 2),
]

two_bit_flips: List[Tuple[Tuple[int, int], Tuple[int, int]]] = [
    ((0, 0), (0, 1)), ((0, 0), (0, 2)), ((0, 0), (1, 0)), ((0, 0), (1, 1)), ((0, 0), (1, 2)), ((0, 0), (2, 0)), ((0, 0), (2, 1)), ((0, 0), (2, 2)),
                      ((0, 1), (0, 2)), ((0, 1), (1, 0)), ((0, 1), (1, 1)), ((0, 1), (1, 2)), ((0, 1), (2, 0)), ((0, 1), (2, 1)), ((0, 1), (2, 2)),
                                        ((0, 2), (1, 0)), ((0, 2), (1, 1)), ((0, 2), (1, 2)), ((0, 2), (2, 0)), ((0, 2), (2, 1)), ((0, 2), (2, 2)),
                                                          ((1, 0), (1, 1)), ((1, 0), (1, 2)), ((1, 0), (2, 0)), ((1, 0), (2, 1)), ((1, 0), (2, 2)),
                                                                            ((1, 1), (1, 2)), ((1, 1), (2, 0)), ((1, 1), (2, 1)), ((1, 1), (2, 2)),
                                                                                              ((1, 2), (2, 0)), ((1, 2), (2, 1)), ((1, 2), (2, 2)),
                                                                                                                ((2, 0), (2, 1)), ((2, 0), (2, 2)),
                                                                                                                                  ((2, 1), (2, 2)),
]

def one_flipped(marker: Marker) -> List[Marker]:
    flipped: List[Marker] = []
    for x, y in one_bit_flips:
        new_marker = marker.copy()
        new_marker.bits[x][y] = not new_marker.bits[x][y]
        flipped.append(new_marker)
    return flipped

def two_flipped(marker: Marker) -> List[Marker]:
    flipped: List[Marker] = []
    for (x1, y1), (x2, y2) in two_bit_flips:
        new_marker = marker.copy()
        new_marker.bits[x1][y1] = not new_marker.bits[x1][y1]
        new_marker.bits[x2][y2] = not new_marker.bits[x2][y2]
        flipped.append(new_marker)
    return flipped

# Find the minimum number of bit flips required to transform any marker in group A into a marker in group B
def inter_group_distance(A: List[List[Marker]], B: List[List[Marker]]) -> int:
    
    def char(bit: bool):
            return "X" if bit else "_"

    for a in A:
        for a1 in one_flipped(a):
            for b in B:
                if a1 == b:
                    # print("\n".join([
                    #     f"1 bit match found:",
                    #     f"  {char(a.bits[0][0])}{char(a.bits[0][1])}{char(a.bits[0][2])}    {char(b.bits[0][0])}{char(b.bits[0][1])}{char(b.bits[0][2])}",
                    #     f"  {char(a.bits[1][0])}{char(a.bits[1][1])}{char(a.bits[1][2])} -> {char(b.bits[1][0])}{char(b.bits[1][1])}{char(b.bits[1][2])}",
                    #     f"  {char(a.bits[2][0])}{char(a.bits[2][1])}{char(a.bits[2][2])}    {char(b.bits[2][0])}{char(b.bits[2][1])}{char(b.bits[2][2])}",
                    # ]))
                    return 1
        for a2 in two_flipped(a):
            for b in B:
                if a2 == b:
                    # print("\n".join([
                    #     f"2 bit match found:",
                    #     f"  {char(a.bits[0][0])}{char(a.bits[0][1])}{char(a.bits[0][2])}    {char(b.bits[0][0])}{char(b.bits[0][1])}{char(b.bits[0][2])}",
                    #     f"  {char(a.bits[1][0])}{char(a.bits[1][1])}{char(a.bits[1][2])} -> {char(b.bits[1][0])}{char(b.bits[1][1])}{char(b.bits[1][2])}",
                    #     f"  {char(a.bits[2][0])}{char(a.bits[2][1])}{char(a.bits[2][2])}    {char(b.bits[2][0])}{char(b.bits[2][1])}{char(b.bits[2][2])}",
                    # ]))
                    return 2
        # Stop counting here
        return 1337

def output_solution(markers: List[Marker]):
    with open("solution.txt", "w") as f:
        for marker in markers:
            f.write(f"{marker}\n\n")

if __name__ == "__main__":
    markers = generate()
    groups: List[List[Marker]] = []
    for marker in markers:
        
        r1 = rotate(marker)
        r2 = rotate(r1)
        r3 = rotate(r2)
        rotations = [marker, r1, r2, r3]
        
        for group in groups:
            if group[0] in rotations:
                group.append(marker)
                break
        else:
            groups.append([marker])
    
    print(f"Found {len(groups)} groups")
    
    # Find intergroup distances
    distances: Dict[Tuple[int, int], int] = {}
    for group_idx in range(len(groups)):
        for other_idx in range(group_idx + 1, len(groups)):
            group = groups[group_idx]
            other = groups[other_idx]
            distance = inter_group_distance(group, other)
            distances[(group_idx, other_idx)] = distance
    
    # Partition the groups into two halves for computing combinations
    group_indices: List[int] = list(range(len(groups)))
    top_half = group_indices[:len(group_indices) // 2]
    top_half_set = set()
    bottom_half = group_indices[len(group_indices) // 2:]
    bottom_half_set = set()

    # Find a set of groups that are far enough apart
    # https://docs.python.org/3/library/itertools.html#itertools.combinations
    NUM_GROUPS = 11
    for subset in itertools.combinations(top_half, NUM_GROUPS):
        for (idx_a, idx_b) in itertools.combinations(subset, 2):
            if distances[(idx_a, idx_b)] < 2:
                break
        else:
            top_half_set.add(subset)
    
    for subset in itertools.combinations(bottom_half, NUM_GROUPS):
        for (idx_a, idx_b) in itertools.combinations(subset, 2):
            if distances[(idx_a, idx_b)] < 2:
                break
        else:
            bottom_half_set.add(subset)

    # Try to combine the two sets of groups
    print(f"Found {len(top_half_set)} top half sets")
    print(f"Found {len(bottom_half_set)} bottom half sets")
    for top_set in top_half_set:
        for bottom_set in bottom_half_set:
            too_close = False
            for top_idx in top_set:
                for bottom_idx in bottom_set:
                    if distances[(top_idx, bottom_idx)] < 2:
                        too_close = True
                        break
                if too_close:
                    break
            
            if not too_close:
                solution = list(top_set + bottom_set)
                solution = [groups[idx][0] for idx in solution]
                output_solution(solution)
                exit(0)