#include <metal_stdlib>
using namespace metal;

#define table_index_t uint16_t

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

// Round up to the closest multiple.
// If it wasn't a multiple, the "extra" is rounded off by integer division, then added back.
// If it was a multiple, it's taken down, then back up.
static uint32_t roundedUp(uint32_t number, uint32_t step)
{
    return (((number-1)/step)*step)+step;
}

enum Direction {
    closed      = 0, /// Indicates a closed border.
    up          = 1,
    topRight    = 2,
    right       = 3,
    bottomRight = 4,
    down        = 5,
    bottomLeft  = 6,
    left        = 7,
    topLeft     = 8
};

static bool isInverse(uint8_t lhs, uint8_t rhs)
{
    if ((lhs == Direction::closed) || (rhs == Direction::closed)) {
        return false;
    }
    uint8_t lhsInv = (lhs + 4) > 8
        ? (lhs - 4)
        : (lhs + 4)
        ;
    return lhsInv == rhs;
}

static PixelPoint adjust(PixelPoint point, uint8_t direction) { 
    switch (direction) {
        case Direction::up:          return PixelPoint{point.x + 0, point.y - 1};
        case Direction::topRight:    return PixelPoint{point.x + 1, point.y - 1};
        case Direction::right:       return PixelPoint{point.x + 1, point.y + 0};
        case Direction::bottomRight: return PixelPoint{point.x + 1, point.y + 1};
        case Direction::down:        return PixelPoint{point.x + 0, point.y + 1};
        case Direction::bottomLeft:  return PixelPoint{point.x - 1, point.y + 1};
        case Direction::left:        return PixelPoint{point.x - 1, point.y + 0};
        case Direction::topLeft:     return PixelPoint{point.x - 1, point.y - 1};
        
        // Programmer error, make this obvious.
        default:                     return PixelPoint{0, 0};
    }
}

kernel void matchPatterns1x1(
    texture2d<half, access::read>  tex               [[ texture(0) ]],
    device PixelPoint*             points            [[ buffer (0) ]],
    device Run*                    runs              [[ buffer (1) ]],
    device const StartRun*         startRuns         [[ buffer (2) ]],
    device const table_index_t*    startRunIndices   [[ buffer (3) ]],
    device const StartPoint*       startPoints       [[ buffer (4) ]],
    device const table_index_t*    startPointIndices [[ buffer (5) ]],
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
    device const table_index_t*    startRunIndices   [[ buffer (3) ]],
    device const StartPoint*       startPoints       [[ buffer (4) ]],
    device const table_index_t*    startPointIndices [[ buffer (5) ]],
    uint2                          gid               [[thread_position_in_grid]]
) {
    const uint32_t coreWidth = 2;
    const uint32_t coreHeight = 1;
    const uint8_t TableWidth = 6;
    const uint8_t pointsPerPixel = 3;
    
    const uint32_t texWidth = tex.get_width();
    const uint32_t texHeight = tex.get_height();
    const uint32_t roundWidth  = roundedUp(texWidth, coreWidth);
    const int32_t idx = ((roundWidth * gid.y) + gid.x) * pointsPerPixel;
    
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
    const uint32_t minCol = 0;
    const uint32_t maxCol = tex.get_width() - 1;
    const uint32_t minRow = 0;
    const uint32_t maxRow = tex.get_height() - 1;
    
    // Find the values in a 2x1 kernel, and its border.
    //  0123
    // 0+--+
    // 1|XX|
    // 2+--+
    const bool p00 = readPixel(tex, uint2(gid.x - 1, gid.y - 1), minCol, maxCol, minRow, maxRow);
    const bool p01 = readPixel(tex, uint2(gid.x + 0, gid.y - 1), minCol, maxCol, minRow, maxRow);
    const bool p02 = readPixel(tex, uint2(gid.x + 1, gid.y - 1), minCol, maxCol, minRow, maxRow);
    const bool p03 = readPixel(tex, uint2(gid.x + 2, gid.y - 1), minCol, maxCol, minRow, maxRow);
    const bool p10 = readPixel(tex, uint2(gid.x - 1, gid.y + 0), minCol, maxCol, minRow, maxRow);
    const bool p11 = readPixel(tex, uint2(gid.x + 0, gid.y + 0), minCol, maxCol, minRow, maxRow);
    const bool p12 = readPixel(tex, uint2(gid.x + 1, gid.y + 0), minCol, maxCol, minRow, maxRow);
    const bool p13 = readPixel(tex, uint2(gid.x + 2, gid.y + 0), minCol, maxCol, minRow, maxRow);
    const bool p20 = readPixel(tex, uint2(gid.x - 1, gid.y + 1), minCol, maxCol, minRow, maxRow);
    const bool p21 = readPixel(tex, uint2(gid.x + 0, gid.y + 1), minCol, maxCol, minRow, maxRow);
    const bool p22 = readPixel(tex, uint2(gid.x + 1, gid.y + 1), minCol, maxCol, minRow, maxRow);
    const bool p23 = readPixel(tex, uint2(gid.x + 2, gid.y + 1), minCol, maxCol, minRow, maxRow);
    
    // Compose the lookup table row address.
    const uint32_t rowIdx = 0
        | (p00 <<  0)
        | (p01 <<  1)
        | (p02 <<  2)
        | (p03 <<  3)
        | (p10 <<  4)
        | (p11 <<  5)
        | (p12 <<  6)
        | (p13 <<  7)
        | (p20 <<  8)
        | (p21 <<  9)
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

kernel void matchPatterns2x2(
    texture2d<half, access::read>  tex               [[ texture(0) ]],
    device PixelPoint*             points            [[ buffer (0) ]],
    device Run*                    runs              [[ buffer (1) ]],
    device const StartRun*         startRuns         [[ buffer (2) ]],
    device const table_index_t*    startRunIndices   [[ buffer (3) ]],
    device const StartPoint*       startPoints       [[ buffer (4) ]],
    device const table_index_t*    startPointIndices [[ buffer (5) ]],
    uint2                          gid               [[thread_position_in_grid]]
) {
    const uint32_t coreWidth = 2;
    const uint32_t coreHeight = 2;
    const uint8_t TableWidth = 8;
    const uint8_t pointsPerPixel = 2;
    
    const uint32_t texWidth = tex.get_width();
    const uint32_t texHeight = tex.get_height();
    const uint32_t roundWidth  = roundedUp(texWidth, coreWidth);
    
    // This is the pattern's core's top left pixel.
    // To get the column offset, multiply the pixels to the left by core height.
    const int32_t idx = ((roundWidth * gid.y) + (gid.x * coreHeight)) * pointsPerPixel;
    
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
    const uint32_t minCol = 0;
    const uint32_t maxCol = tex.get_width() - 1;
    const uint32_t minRow = 0;
    const uint32_t maxRow = tex.get_height() - 1;
    
    // Find the values in a 2x2 kernel, and its border.
    //  0123
    // 0+--+
    // 1|XX|
    // 2|XX|
    // 3+--+
    const bool p00 = readPixel(tex, uint2(gid.x - 1, gid.y - 1), minCol, maxCol, minRow, maxRow);
    const bool p01 = readPixel(tex, uint2(gid.x + 0, gid.y - 1), minCol, maxCol, minRow, maxRow);
    const bool p02 = readPixel(tex, uint2(gid.x + 1, gid.y - 1), minCol, maxCol, minRow, maxRow);
    const bool p03 = readPixel(tex, uint2(gid.x + 2, gid.y - 1), minCol, maxCol, minRow, maxRow);
    const bool p10 = readPixel(tex, uint2(gid.x - 1, gid.y + 0), minCol, maxCol, minRow, maxRow);
    const bool p11 = readPixel(tex, uint2(gid.x + 0, gid.y + 0), minCol, maxCol, minRow, maxRow);
    const bool p12 = readPixel(tex, uint2(gid.x + 1, gid.y + 0), minCol, maxCol, minRow, maxRow);
    const bool p13 = readPixel(tex, uint2(gid.x + 2, gid.y + 0), minCol, maxCol, minRow, maxRow);
    const bool p20 = readPixel(tex, uint2(gid.x - 1, gid.y + 1), minCol, maxCol, minRow, maxRow);
    const bool p21 = readPixel(tex, uint2(gid.x + 0, gid.y + 1), minCol, maxCol, minRow, maxRow);
    const bool p22 = readPixel(tex, uint2(gid.x + 1, gid.y + 1), minCol, maxCol, minRow, maxRow);
    const bool p23 = readPixel(tex, uint2(gid.x + 2, gid.y + 1), minCol, maxCol, minRow, maxRow);
    const bool p30 = readPixel(tex, uint2(gid.x - 1, gid.y + 2), minCol, maxCol, minRow, maxRow);
    const bool p31 = readPixel(tex, uint2(gid.x + 0, gid.y + 2), minCol, maxCol, minRow, maxRow);
    const bool p32 = readPixel(tex, uint2(gid.x + 1, gid.y + 2), minCol, maxCol, minRow, maxRow);
    const bool p33 = readPixel(tex, uint2(gid.x + 2, gid.y + 2), minCol, maxCol, minRow, maxRow);
    
    // Compose the lookup table row address.
    const uint32_t rowIdx = 0
        | (p00 <<  0)
        | (p01 <<  1)
        | (p02 <<  2)
        | (p03 <<  3)
        | (p10 <<  4)
        | (p11 <<  5)
        | (p12 <<  6)
        | (p13 <<  7)
        | (p20 <<  8)
        | (p21 <<  9)
        | (p22 << 10)
        | (p23 << 11)
        | (p30 << 12)
        | (p31 << 13)
        | (p32 << 14)
        | (p33 << 15)
        ;
        
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

kernel void matchPatterns4x2(
    texture2d<half, access::read>  tex               [[ texture(0) ]],
    device PixelPoint*             points            [[ buffer (0) ]],
    device Run*                    runs              [[ buffer (1) ]],
    device const StartRun*         startRuns         [[ buffer (2) ]],
    device const table_index_t*    startRunIndices   [[ buffer (3) ]],
    device const StartPoint*       startPoints       [[ buffer (4) ]],
    device const table_index_t*    startPointIndices [[ buffer (5) ]],
    uint2                          gid               [[thread_position_in_grid]]
) {
    const uint32_t coreWidth = 4;
    const uint32_t coreHeight = 2;
    const uint8_t TableWidth = 16;
    const uint8_t pointsPerPixel = 2;
    
    const uint32_t subCoreWidth = 2;
    const uint32_t subCoreHeight = 2;
    const uint8_t subTableWidth = 8;
    
    const uint32_t texWidth = tex.get_width();
    const uint32_t texHeight = tex.get_height();
    const uint32_t roundWidth = roundedUp(texWidth, coreWidth);
    
    uint32_t subX;
    uint32_t subY;
    int32_t subBase;

    // This is the pattern's core's top left pixel.
    // To get the column offset, multiply the pixels to the left by core height.
    const int32_t idx = ((roundWidth * gid.y) + (gid.x * coreHeight)) * pointsPerPixel;
    
    // Don't exit the texture.
    if ((gid.x >= texWidth) || (gid.y >= texHeight)) {
        return;
    }
    
    // Skip pixels that aren't the root of the pattern.
    if ((gid.x % coreWidth) || (gid.y % coreHeight)) {
        return;
    }
    
    // Define boundaries.
    const uint32_t minCol = 0;
    const uint32_t maxCol = tex.get_width() - 1;
    const uint32_t minRow = 0;
    const uint32_t maxRow = tex.get_height() - 1;
    
    // Find the values in a 2x2 kernel, and its border.
    //  0123
    // 0+--+
    // 1|XX|
    // 2|XX|
    // 3+--+
    subX = gid.x;
    subY = gid.y;
    bool p00 = readPixel(tex, uint2(subX - 1, subY - 1), minCol, maxCol, minRow, maxRow);
    bool p01 = readPixel(tex, uint2(subX + 0, subY - 1), minCol, maxCol, minRow, maxRow);
    bool p02 = readPixel(tex, uint2(subX + 1, subY - 1), minCol, maxCol, minRow, maxRow);
    bool p03 = readPixel(tex, uint2(subX + 2, subY - 1), minCol, maxCol, minRow, maxRow);
    bool p10 = readPixel(tex, uint2(subX - 1, subY + 0), minCol, maxCol, minRow, maxRow);
    bool p11 = readPixel(tex, uint2(subX + 0, subY + 0), minCol, maxCol, minRow, maxRow);
    bool p12 = readPixel(tex, uint2(subX + 1, subY + 0), minCol, maxCol, minRow, maxRow);
    bool p13 = readPixel(tex, uint2(subX + 2, subY + 0), minCol, maxCol, minRow, maxRow);
    bool p20 = readPixel(tex, uint2(subX - 1, subY + 1), minCol, maxCol, minRow, maxRow);
    bool p21 = readPixel(tex, uint2(subX + 0, subY + 1), minCol, maxCol, minRow, maxRow);
    bool p22 = readPixel(tex, uint2(subX + 1, subY + 1), minCol, maxCol, minRow, maxRow);
    bool p23 = readPixel(tex, uint2(subX + 2, subY + 1), minCol, maxCol, minRow, maxRow);
    bool p30 = readPixel(tex, uint2(subX - 1, subY + 2), minCol, maxCol, minRow, maxRow);
    bool p31 = readPixel(tex, uint2(subX + 0, subY + 2), minCol, maxCol, minRow, maxRow);
    bool p32 = readPixel(tex, uint2(subX + 1, subY + 2), minCol, maxCol, minRow, maxRow);
    bool p33 = readPixel(tex, uint2(subX + 2, subY + 2), minCol, maxCol, minRow, maxRow);
    
    // Compose the lookup table row address.
    uint32_t rowIdx = 0
        | (p00 <<  0) | (p01 <<  1) | (p02 <<  2) | (p03 <<  3)
        | (p10 <<  4) | (p11 <<  5) | (p12 <<  6) | (p13 <<  7)
        | (p20 <<  8) | (p21 <<  9) | (p22 << 10) | (p23 << 11)
        | (p30 << 12) | (p31 << 13) | (p32 << 14) | (p33 << 15)
        ;
        
    uint32_t runRow = startRunIndices[rowIdx];
    uint32_t pointRow = startPointIndices[rowIdx];

    // Loop over the table's columns.
    subBase = idx;
    for (uint32_t col = 0; col < subTableWidth; col++) {
        uint32_t runIdx   = runRow   * subTableWidth + col;
        uint32_t pointIdx = pointRow * subTableWidth + col;
        
        struct StartRun   startRun   = startRuns[runIdx];
        struct StartPoint startPoint = startPoints[pointIdx];
        
        points[subBase+col].x = gid.x + startPoint.x;
        points[subBase+col].y = gid.y + startPoint.y;
        if (startRun.tail != -1) {
            runs[subBase+col].oldTail = subBase + startRun.tail;
            runs[subBase+col].oldHead = subBase + startRun.head;
            runs[subBase+col].tailTriadFrom = startRun.from;
            runs[subBase+col].headTriadTo   = startRun.to;
        } else { 
            runs[subBase+col].oldTail = -1;
            runs[subBase+col].oldHead = -1;
        }
    }
    
    // ITERATION 2
    subX = gid.x + subCoreWidth;
    subY = gid.y;
    p00 = readPixel(tex, uint2(subX - 1, subY - 1), minCol, maxCol, minRow, maxRow);
    p01 = readPixel(tex, uint2(subX + 0, subY - 1), minCol, maxCol, minRow, maxRow);
    p02 = readPixel(tex, uint2(subX + 1, subY - 1), minCol, maxCol, minRow, maxRow);
    p03 = readPixel(tex, uint2(subX + 2, subY - 1), minCol, maxCol, minRow, maxRow);
    p10 = readPixel(tex, uint2(subX - 1, subY + 0), minCol, maxCol, minRow, maxRow);
    p11 = readPixel(tex, uint2(subX + 0, subY + 0), minCol, maxCol, minRow, maxRow);
    p12 = readPixel(tex, uint2(subX + 1, subY + 0), minCol, maxCol, minRow, maxRow);
    p13 = readPixel(tex, uint2(subX + 2, subY + 0), minCol, maxCol, minRow, maxRow);
    p20 = readPixel(tex, uint2(subX - 1, subY + 1), minCol, maxCol, minRow, maxRow);
    p21 = readPixel(tex, uint2(subX + 0, subY + 1), minCol, maxCol, minRow, maxRow);
    p22 = readPixel(tex, uint2(subX + 1, subY + 1), minCol, maxCol, minRow, maxRow);
    p23 = readPixel(tex, uint2(subX + 2, subY + 1), minCol, maxCol, minRow, maxRow);
    p30 = readPixel(tex, uint2(subX - 1, subY + 2), minCol, maxCol, minRow, maxRow);
    p31 = readPixel(tex, uint2(subX + 0, subY + 2), minCol, maxCol, minRow, maxRow);
    p32 = readPixel(tex, uint2(subX + 1, subY + 2), minCol, maxCol, minRow, maxRow);
    p33 = readPixel(tex, uint2(subX + 2, subY + 2), minCol, maxCol, minRow, maxRow);
    
    // Compose the lookup table row address.
    rowIdx = 0
        | (p00 <<  0) | (p01 <<  1) | (p02 <<  2) | (p03 <<  3)
        | (p10 <<  4) | (p11 <<  5) | (p12 <<  6) | (p13 <<  7)
        | (p20 <<  8) | (p21 <<  9) | (p22 << 10) | (p23 << 11)
        | (p30 << 12) | (p31 << 13) | (p32 << 14) | (p33 << 15)
        ;
    
    runRow = startRunIndices[rowIdx];
    pointRow = startPointIndices[rowIdx];

    // Loop over the table's columns.
    subBase = idx + subTableWidth;
    for (uint32_t col = 0; col < subTableWidth; col++) {
        uint32_t runIdx   = runRow   * subTableWidth + col;
        uint32_t pointIdx = pointRow * subTableWidth + col;
        
        struct StartRun   startRun   = startRuns[runIdx];
        struct StartPoint startPoint = startPoints[pointIdx];
        
        points[subBase+col].x = gid.x + startPoint.x + subCoreWidth;
        points[subBase+col].y = gid.y + startPoint.y;
        if (startRun.tail != -1) {
            runs[subBase+col].oldTail = subBase + startRun.tail;
            runs[subBase+col].oldHead = subBase + startRun.head;
            runs[subBase+col].tailTriadFrom = startRun.from;
            runs[subBase+col].headTriadTo   = startRun.to;
        } else { 
            runs[subBase+col].oldTail = -1;
            runs[subBase+col].oldHead = -1;
        }
    }
    
    return;
}

kernel void combine4x2(
    texture2d<half, access::read>  tex               [[ texture(0) ]],
    device PixelPoint*             points            [[ buffer (0) ]],
    device Run*                    runs              [[ buffer (1) ]],
    uint2                          gid               [[thread_position_in_grid]]
) {
    const uint32_t coreWidth      = 4;
    const uint32_t coreHeight     = 2;
    const uint32_t tableWidth     = 16;
    const uint32_t pointsPerPixel = 2;

    const uint32_t subCoreHeight = 2;
    const uint32_t subTableWidth = 8;

    const uint32_t texWidth  = tex.get_width();
    const uint32_t texHeight = tex.get_height();
    
    // Don't exit the texture.
    if ((gid.x >= texWidth) || (gid.y >= texHeight)) {
        return;
    }
    
    // Skip pixels that aren't the root of the pattern.
    if ((gid.x % coreWidth) || (gid.y % coreHeight)) {
        return;
    }
    
    // Let the regions be `a` and `b`.
    const uint32_t roundWidth = roundedUp(texWidth, coreWidth);
    const uint32_t aBase = ((roundWidth * gid.y) + (gid.x * subCoreHeight)) * pointsPerPixel;
    const uint32_t bBase = aBase + subTableWidth;

    // Find pairwise relationships between runs.
    // e.g. if `bTailForAHead[3] = 4`, run a[3]'s head matches run b[4]'s tail. 
    int bTailForAHead[8] = {-1, -1, -1, -1, -1, -1, -1, -1};
    int bHeadForATail[8] = {-1, -1, -1, -1, -1, -1, -1, -1};
    int aTailForBHead[8] = {-1, -1, -1, -1, -1, -1, -1, -1};
    int aHeadForBTail[8] = {-1, -1, -1, -1, -1, -1, -1, -1};

    for (size_t aOffset = 0; aOffset < subTableWidth; aOffset++) {
        Run aRun = runs[aBase + aOffset];
        for (size_t bOffset = 0; bOffset < subTableWidth; bOffset++) {
            Run bRun = runs[bBase + bOffset];

            if ((aRun.oldHead < 0) || (bRun.oldHead < 0)) {
                continue;
            }

            PixelPoint aTail = points[aRun.oldTail];
            PixelPoint aHead = points[aRun.oldHead - 1];
            PixelPoint bTail = points[bRun.oldTail];
            PixelPoint bHead = points[bRun.oldHead - 1];

            PixelPoint aTailPointee = adjust(aTail, aRun.tailTriadFrom);
            if (isInverse(aRun.tailTriadFrom, bRun.headTriadTo) && (aTailPointee.x == bHead.x) && (aTailPointee.y == bHead.y)) {
                // B head -> A tail
                aTailForBHead[bOffset] = aOffset;
                bHeadForATail[aOffset] = bOffset;
            } 
            
            PixelPoint aHeadPointee = adjust(aHead, aRun.headTriadTo);
            if (isInverse(aRun.headTriadTo, bRun.tailTriadFrom) && (aHeadPointee.x == bTail.x) && (aHeadPointee.y == bTail.y)) {
                // A head -> B tail
                bTailForAHead[aOffset] = bOffset;
                aHeadForBTail[bOffset] = aOffset;
            }
        }
    }

    // Ignore invalid runs.
    bool aDone[subTableWidth];
    bool bDone[subTableWidth];
    for (size_t offset = 0; offset < subTableWidth; offset++) {
        aDone[offset] = runs[aBase + offset].oldHead < 0;
        bDone[offset] = runs[bBase + offset].oldHead < 0;
    }

    PixelPoint newPoints[tableWidth];
    size_t newPointCount = 0;
    Run newRuns[tableWidth];
    size_t newRunCount = 0;

    /*
     * Let a "sequence" of runs be some runs joined head-to-tail.
     * Notice that they must follow a[?] -> b[?] -> a[?] -> b[?] -> ...
     *
     * Closed runs in a 4x2 region are irrevelant to our larger task, discard them.
     * Non-closed run sequences must begin with a run which can't find its tail.
     * - a sequence can be as short as 1 run
     * - a sequence ends when the run can't find its head
     * 
     * Goal: each iteration, either 
     * - start a new sequence (beginning with a tail-less run), or 
     * - continue an existing sequence (by adding the head for the previous run).
     *
     * Iteration Count: Each cycle should start or continue a run.
     * However, if all sequences start in A, and the first iteration checks B, we'd miss one run.
     * Hence, +1 iteration.
     */
    bool isA = true;
    int nextOffset = -1;
    Run newRun;
    bool isNewSequence;
    uint32_t newBase = aBase; // Where points are counted from.

    for (size_t x = 0; x < tableWidth + 1; x++) {
        isA = !isA;

        Run currRun;
        int currOffset = -1;
    
        if (isA) {
            if (nextOffset >= 0) {
                currOffset = nextOffset;
                isNewSequence = false;
            } else {
                for (size_t offset = 0; offset < subTableWidth; offset++) {
                    if (!aDone[offset] && (bHeadForATail[offset] < 0)) {
                        currOffset = offset;
                        isNewSequence = true;
                        break;
                    }
                }
            }
            if (currOffset < 0) continue;
            currRun = runs[aBase + currOffset];
        } else { 
            if (nextOffset >= 0) {
                currOffset = nextOffset;
                isNewSequence = false;
            } else { // Find a run that is not done and doesn't have a tail.
                for (size_t offset = 0; offset < subTableWidth; offset++) {
                    if (!bDone[offset] && (aHeadForBTail[offset] < 0)) {
                        currOffset = offset;
                        isNewSequence = true;
                        break;
                    }
                }
            }
            if (currOffset < 0) continue;
            currRun = runs[bBase + currOffset];        
        }         
        
        // Copy points.
        for (int32_t i = currRun.oldTail; i < currRun.oldHead; i++) { 
            newPoints[newPointCount] = points[i];
            newPointCount++;
        }
    
        if (isNewSequence) { // Start new sequence.
            newRun.oldTail = newBase;
            newRun.oldHead = newBase;
            newRun.tailTriadFrom = currRun.tailTriadFrom;
        }

        // Extend new or existing sequence.
        newRun.oldHead += currRun.oldHead - currRun.oldTail;
        newBase        += currRun.oldHead - currRun.oldTail;
        newRun.headTriadTo = currRun.headTriadTo;
        
        if (isA) {
            nextOffset = bTailForAHead[currOffset];
            aDone[currOffset] = true;
        } else {
            nextOffset = aTailForBHead[currOffset];
            bDone[currOffset] = true;
        }

        if (nextOffset < 0) { // End of sequence.
            newRuns[newRunCount] = newRun;
            newRunCount++;
        }
    }

    // Commit new points.
    for (size_t newPointIdx = 0; newPointIdx < newPointCount; newPointIdx++) {
        points[aBase + newPointIdx] = newPoints[newPointIdx];
    }

    // Commit new runs.
    for (size_t newRunIdx = 0; newRunIdx < tableWidth; newRunIdx++) {
        if (newRunIdx < newRunCount) {
            runs[aBase + newRunIdx] = newRuns[newRunIdx];
        } else { // Mark as invalid.
            runs[aBase + newRunIdx].oldHead = -1;
        }
    }
}
