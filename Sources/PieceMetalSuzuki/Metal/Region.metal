#include <metal_stdlib>
using namespace metal;

struct Run {
    int32_t oldTail;
    int32_t oldHead;
    int32_t newTail;
    int32_t newHead;
    uint8_t tailTriadFrom;
    uint8_t headTriadTo;
};

struct GridSize { 
    uint32_t width;
    uint32_t height;
};

struct GridPosition {
    uint32_t row;
    uint32_t col;
};

struct PixelSize {
    uint32_t width;
    uint32_t height;
};

struct PatternSize {
    PixelSize coreSize;
    uint8_t tableWidth;
    uint32_t pointsPerPixel;
};

struct Region { 
    GridPosition gridPos;
    uint32_t runsCount;
};

kernel void initializeRegions(
    constant      GridSize&    gridSize    [[ buffer (0) ]],
    constant      PatternSize& patternSize [[ buffer (1) ]],
    device const  Run*         runs        [[ buffer (2) ]],
    device        Region*      regions     [[ buffer (3) ]],
             uint2        gid         [[thread_position_in_grid]]
) { 
    if (gid.x >= gridSize.width || gid.y >= gridSize.height) {
        return;
    }
    
    int idx = (gid.y * gridSize.width) + gid.x;

    // Count valid elements in each region.
    int bufferBase = idx * patternSize.tableWidth;
    uint32_t validCount = 0;
    for (int offset = 0; offset < patternSize.tableWidth; offset++) {
        if (runs[bufferBase + offset].oldHead >= 0) {
            validCount += 1;
        } else {
            break;
        }
    }

    Region region = {
        .gridPos = { .row = gid.y, .col = gid.x },
        .runsCount = validCount,
    };
    regions[idx] = region;
}
