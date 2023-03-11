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

/**
 case closed      = 0 /// Indicates a closed border.
 case up          = 1
 case topRight    = 2
 case right       = 3
 case bottomRight = 4
 case down        = 5
 case bottomLeft  = 6
 case left        = 7
 case topLeft     = 8
*/
static bool isInverse(uint8_t a, uint8_t b) {
    if ((a == 0) || (b == 0)) {
        return false;
    }
    uint8_t aInv = (a + 4) > 8 
        ? (a - 4) 
        : (a + 4)
        ;
    return aInv == b;
}

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
}

kernel void combinePatterns4x2(
    texture2d<half, access::read>  tex               [[ texture(0) ]],
    device PixelPoint*             points            [[ buffer (0) ]],
    device Run*                    runs              [[ buffer (1) ]],
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

    // ============================================
    // Join adjacent 2x2 regions into a 4x2 region.
    // ============================================
    if (gid.x % 4) {
        return;
    }
    
    // Let the regions be "a" and "b".
    const int32_t aIdx = idx;
    const int32_t bIdx = idx + (coreWidth * pointsPerPixel);
    
    // Find pairwise relationships between runs.
    // e.g. if `bTailForAHead[3] = 4`, run a[3]'s head matches run b[4]'s tail.
    int8_t bTailForAHead[TableWidth] = {-1, -1, -1, -1, -1, -1, -1, -1};
    int8_t bHeadForATail[TableWidth] = {-1, -1, -1, -1, -1, -1, -1, -1};
    int8_t aTailForBHead[TableWidth] = {-1, -1, -1, -1, -1, -1, -1, -1};
    int8_t aHeadForBTail[TableWidth] = {-1, -1, -1, -1, -1, -1, -1, -1};
    for (int aOffset = 0; aOffset < TableWidth; aOffset++) {
        Run aRun = runs[aIdx + aOffset];
        if (aRun.oldHead < 0) {
            continue;
        }
        
        for (int bOffset = 0; bOffset < TableWidth; bOffset++) {
            Run bRun = runs[bIdx + bOffset];
            if (bRun.oldHead < 0) {
                continue;
            }
            
            PixelPoint aHead = points[aRun.oldHead - 1];
            PixelPoint aTail = points[aRun.oldTail];
            PixelPoint bHead = points[bRun.oldHead - 1];
            PixelPoint bTail = points[bRun.oldTail];

            if (isInverse(aRun.tailTriadFrom, bRun.headTriadTo) && (aTail.x == bHead.x) && (aTail.y == bHead.y)) {
                // B head -> A tail
                aTailForBHead[bOffset] = aOffset;
                bHeadForATail[aOffset] = bOffset;
            } else if (isInverse(aRun.headTriadTo, bRun.tailTriadFrom) && (aHead.x == bTail.x) && (aHead.y == bTail.y)) {
                // A head -> B tail
                bTailForAHead[aOffset] = bOffset;
                aHeadForBTail[bOffset] = aOffset;
            }
        }
    }

    // Whether a run has been processed.
    bool aIsDone[TableWidth];
    bool bIsDone[TableWidth];
    for(uint8_t offset = 0; offset < TableWidth; offset++) {
        // Ignore invalid runs.
        aIsDone[offset] = runs[aIdx + offset].oldHead < 0;
        bIsDone[offset] = runs[bIdx + offset].oldHead < 0;
    }

    PixelPoint newPoints[TableWidth * 2];
    int8_t newPointCount = 0;
    Run newRuns[TableWidth * 2];
    int8_t newRunCount = 0;
    
    bool isA = true;        // Flips between A and B.
    int8_t nextOffset = -1;

    /**
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
     */

    // Iteration Count: Each cycle should start or continue a run.
    // However, if all starts are in A, and the first iteration is checks B, we'd miss one run.
    // Hence, +1 iteration.
    Run newRun;
    bool isNewSequence;
    for (int x = 0; x < TableWidth + TableWidth + 1; x++) {
        isA = !isA;
        if (isA) {
            int aOffset = -1; // Find next a offset.
            
            if (nextOffset >= 0) {
                aOffset = nextOffset;
                isNewSequence = false;
            } else { 
                for (int offset = 0; offset < TableWidth; offset++) {
                    // Find a run that is not done and doesn't have a tail.
                    if (!(aIsDone[offset]) && (bHeadForATail[offset] < 0)) {
                        aOffset = offset;
                        isNewSequence = true;
                        break;
                    }
                }
            }

            if (aOffset < 0) continue;
            
            Run aRun = runs[aIdx + aOffset];
            for (int i = aRun.oldHead; i < aRun.oldTail; i++) { // Copy points.
                newPoints[newPointCount] = points[i];
                newPointCount++;
            }

            if (isNewSequence) { // Start new run.
                newRun = aRun;
            } else {             // Extend run.
                newRun.oldTail += aRun.oldTail - aRun.oldHead;
                newRun.headTriadTo = aRun.headTriadTo;
            }
            
            nextOffset = bTailForAHead[aOffset];
            aIsDone[aOffset] = true;
        } else { 
            int bOffset = -1; // Find next b offset.
            
            if (nextOffset >= 0) {
                bOffset = nextOffset;
                isNewSequence = false;
            } else { 
                for (int offset = 0; offset < TableWidth; offset++) {
                    // Find a run that is not done and doesn't have a tail.
                    if (!(bIsDone[offset]) && (aHeadForBTail[offset] < 0)) {
                        bOffset = offset;
                        isNewSequence = true;
                        break;
                    }
                }
            }

            if (bOffset < 0) continue;
            
            Run bRun = runs[bIdx + bOffset];
            for (int i = bRun.oldHead; i < bRun.oldTail; i++) { // Copy points.
                newPoints[newPointCount] = points[i];
                newPointCount++;
            }

            if (isNewSequence) { // Start new run.
                newRun = bRun;
            } else {             // Extend run.
                newRun.oldHead += bRun.oldHead - bRun.oldTail;
                newRun.headTriadTo = bRun.headTriadTo;
            }
            
            nextOffset = aTailForBHead[bOffset];
            bIsDone[bOffset] = true;
        }

        if (nextOffset < 0) { // End of sequence.
            newRuns[newRunCount] = newRun;
            newRunCount++;
        }
    }

    // Points are already copied.
    // Write new runs.
    for (int i = 0; i < TableWidth * 2; i++) {
        if (i < newRunCount) {
            runs[idx + i] = newRuns[i];
        } else { // Mark remaining runs as invalid.
            runs[idx + i].oldHead = -1;
        }
    }
}
