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

struct PixelPoint {
    uint32_t x;
    uint32_t y;
};

struct StartPoint {
    uint8_t x;
    uint8_t y;
};

struct StartRun {
    // Invalid negative values signal absence of a run.
    int8_t tail;
    int8_t head;
    
    uint8_t from;
    uint8_t to;
};

static bool readPixel(
    texture2d<half, access::read>  tex,
    uint2                          coords,
    uint32_t                       minCol,
    uint32_t                       maxCol,
    uint32_t                       minRow,
    uint32_t                       maxRow
) {
    return (coords.x >= minCol) && (coords.x <= maxCol) && (coords.y >= minRow) && (coords.y <= maxRow) && (tex.read(coords).r != 0.0);
}

kernel void matchPatterns1x1(
    texture2d<half, access::read>  tex               [[ texture(0) ]],
    device PixelPoint*             points            [[ buffer (0) ]],
    device Run*                    runs              [[ buffer (1) ]],
    device const StartRun*         startRuns         [[ buffer (2) ]],
    device const uint16_t*         startRunIndices   [[ buffer (3) ]],
    device const StartPoint*       startPoints       [[ buffer (4) ]],
    device const uint16_t*         startPointIndices [[ buffer (5) ]],
    uint2                          gid               [[thread_position_in_grid]]
) {
    uint8_t TableWidth = 4;
    int32_t idx = ((tex.get_width() * gid.y) + gid.x) * TableWidth;
    uint32_t texWidth = tex.get_width();
    uint32_t texHeight = tex.get_height();
    
    // Don't exit the texture.
    if ((gid.x >= texWidth) || (gid.y >= texHeight)) {
        return;
    }
    
    // Setting invalid array indices signals a NULL value.
    // Set before early exit checks.
    for (int i = 0; i < TableWidth; i++) {
        runs[idx+i].oldHead = -1;
        runs[idx+i].oldTail = -1;
        runs[idx+i].newHead = -1;
        runs[idx+i].newTail = -1;
    }
    
    // Define boundaries.
    uint32_t minCol = 0;
    uint32_t maxCol = tex.get_width() - 1;
    uint32_t minRow = 0;
    uint32_t maxRow = tex.get_height() - 1;
    
    // Find the values in a 2x1 kernel, and its border.
    //  012
    // 0+-+
    // 1|X|
    // 2+-+
    bool p00 = readPixel(tex, uint2(gid.x - 1, gid.y - 1), minCol, maxCol, minRow, maxRow);
    bool p01 = readPixel(tex, uint2(gid.x + 0, gid.y - 1), minCol, maxCol, minRow, maxRow);
    bool p02 = readPixel(tex, uint2(gid.x + 1, gid.y - 1), minCol, maxCol, minRow, maxRow);
    bool p10 = readPixel(tex, uint2(gid.x - 1, gid.y + 0), minCol, maxCol, minRow, maxRow);
    bool p11 = readPixel(tex, uint2(gid.x + 0, gid.y + 0), minCol, maxCol, minRow, maxRow);
    bool p12 = readPixel(tex, uint2(gid.x + 1, gid.y + 0), minCol, maxCol, minRow, maxRow);
    bool p20 = readPixel(tex, uint2(gid.x - 1, gid.y + 1), minCol, maxCol, minRow, maxRow);
    bool p21 = readPixel(tex, uint2(gid.x + 0, gid.y + 1), minCol, maxCol, minRow, maxRow);
    bool p22 = readPixel(tex, uint2(gid.x + 1, gid.y + 1), minCol, maxCol, minRow, maxRow);
    
    // Compose the lookup table row address.
    uint32_t rowIdx = 0
        | (p00 << 0)
        | (p01 << 1)
        | (p02 << 2)
        | (p10 << 3)
        | (p11 << 4)
        | (p12 << 5)
        | (p20 << 6)
        | (p21 << 7)
        | (p22 << 8);
        
    uint32_t runRow = startRunIndices[rowIdx];
    uint32_t pointRow = startPointIndices[rowIdx];

    // Loop over the table's columns.
    for (uint32_t i = 0; i < TableWidth; i++) {
        uint32_t runIdx = runRow * TableWidth + i;
        uint32_t pointIdx = pointRow * TableWidth + i;
        struct StartRun startRun = startRuns[runIdx];
        struct StartPoint startPoint = startPoints[pointIdx];
        if (startRun.tail != -1) {
            points[idx+i].x = gid.x + startPoint.x;
            points[idx+i].y = gid.y + startPoint.y;
            runs[idx+i].oldTail = idx + startRun.tail;
            runs[idx+i].oldHead = idx + startRun.head;
            runs[idx+i].tailTriadFrom = startRun.from;
            runs[idx+i].headTriadTo   = startRun.to;
        }
    }    
    return;
}

kernel void matchPatterns2x1(
    texture2d<half, access::read>  tex               [[ texture(0) ]],
    device PixelPoint*             points            [[ buffer (0) ]],
    device Run*                    runs              [[ buffer (1) ]],
    device const StartRun*         startRuns         [[ buffer (2) ]],
    device const uint16_t*         startRunIndices   [[ buffer (3) ]],
    device const StartPoint*       startPoints       [[ buffer (4) ]],
    device const uint16_t*         startPointIndices [[ buffer (5) ]],
    uint2                          gid               [[thread_position_in_grid]]
) {
    uint32_t coreWidth = 2;
    uint32_t coreHeight = 1;
    uint8_t TableWidth = 6;
    uint8_t pointsPerPixel = 3;
    
    uint32_t texWidth = tex.get_width();
    uint32_t texHeight = tex.get_height();
    uint32_t roundWidth  = (((texWidth -1)/coreWidth )*coreWidth )+coreWidth;
    uint32_t roundHeight = (((texHeight-1)/coreHeight)*coreHeight)+coreHeight;
    int32_t idx = ((roundWidth * gid.y) + gid.x) * pointsPerPixel;
    
    // Don't exit the texture.
    if ((gid.x >= texWidth) || (gid.y >= texHeight)) {
        return;
    }
    
    // Skip pixels that aren't the root of the pattern.
    if ((gid.x % coreWidth) || (gid.y % coreHeight)) {
        return;
    }
    
    // Setting invalid array indices signals a NULL value.
    // Set before early exit checks.
    for (int i = 0; i < TableWidth; i++) {
        runs[idx+i].oldHead = -1;
        runs[idx+i].oldTail = -1;
        runs[idx+i].newHead = -1;
        runs[idx+i].newTail = -1;
    }
    
    // Define boundaries.
    uint32_t minCol = 0;
    uint32_t maxCol = tex.get_width() - 1;
    uint32_t minRow = 0;
    uint32_t maxRow = tex.get_height() - 1;
    
    // Find the values in a 2x1 kernel, and its border.
    //  0124
    // 0+--+
    // 1|XX|
    // 2+--+
    bool p00 = readPixel(tex, uint2(gid.x - 1, gid.y - 1), minCol, maxCol, minRow, maxRow);
    bool p01 = readPixel(tex, uint2(gid.x + 0, gid.y - 1), minCol, maxCol, minRow, maxRow);
    bool p02 = readPixel(tex, uint2(gid.x + 1, gid.y - 1), minCol, maxCol, minRow, maxRow);
    bool p03 = readPixel(tex, uint2(gid.x + 2, gid.y - 1), minCol, maxCol, minRow, maxRow);
    bool p10 = readPixel(tex, uint2(gid.x - 1, gid.y + 0), minCol, maxCol, minRow, maxRow);
    bool p11 = readPixel(tex, uint2(gid.x + 0, gid.y + 0), minCol, maxCol, minRow, maxRow);
    bool p12 = readPixel(tex, uint2(gid.x + 1, gid.y + 0), minCol, maxCol, minRow, maxRow);
    bool p13 = readPixel(tex, uint2(gid.x + 2, gid.y + 0), minCol, maxCol, minRow, maxRow);
    bool p20 = readPixel(tex, uint2(gid.x - 1, gid.y + 1), minCol, maxCol, minRow, maxRow);
    bool p21 = readPixel(tex, uint2(gid.x + 0, gid.y + 1), minCol, maxCol, minRow, maxRow);
    bool p22 = readPixel(tex, uint2(gid.x + 1, gid.y + 1), minCol, maxCol, minRow, maxRow);
    bool p23 = readPixel(tex, uint2(gid.x + 2, gid.y + 1), minCol, maxCol, minRow, maxRow);
    
    // Compose the lookup table row address.
    uint32_t rowIdx = 0
        | (p00 << 0)
        | (p01 << 1)
        | (p02 << 2)
        | (p03 << 3)
        | (p10 << 4)
        | (p11 << 5)
        | (p12 << 6)
        | (p13 << 7)
        | (p20 << 8)
        | (p21 << 9)
        | (p22 << 10)
        | (p23 << 11);
        
    uint32_t runRow = startRunIndices[rowIdx];
    uint32_t pointRow = startPointIndices[rowIdx];

    // Loop over the table's columns.
    for (uint32_t i = 0; i < TableWidth; i++) {
        uint32_t runIdx = runRow * TableWidth + i;
        uint32_t pointIdx = pointRow * TableWidth + i;
        struct StartRun startRun = startRuns[runIdx];
        struct StartPoint startPoint = startPoints[pointIdx];
        points[idx+i].x = gid.x + startPoint.x;
        points[idx+i].y = gid.y + startPoint.y;
        if (startRun.tail != -1) {
            runs[idx+i].oldTail = idx + startRun.tail;
            runs[idx+i].oldHead = idx + startRun.head;
            runs[idx+i].tailTriadFrom = startRun.from;
            runs[idx+i].headTriadTo   = startRun.to;
        }
    }
    return;
}
