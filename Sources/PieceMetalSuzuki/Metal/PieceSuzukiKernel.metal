//
//  PieceSuzukiKernel.metal
//  PieceSuzukiKernel
//
//  Created by Secret Asian Man Dev on 9/2/23.
//

#include <metal_stdlib>
using namespace metal;

#define lutRowWidth 4
#define pointsPerPixel 4

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

// Compute kernel
kernel void startChain(
    texture2d<half, access::read>  tex  [[ texture(0) ]],
    device PixelPoint*             points        [[ buffer (0) ]],
    device Run*                    runs          [[ buffer (1) ]],
    device const Run*              runLUT        [[ buffer (2) ]],
    device const PixelPoint*       pointLUT      [[ buffer (3) ]],
    uint2                          gid           [[thread_position_in_grid]]
) {
    // 4 elements per pixel, since each pixel can hold 4 triads.
    int32_t idx = ((tex.get_width() * gid.y) + gid.x) * pointsPerPixel;
    
    // Don't exit the texture.
    if ((gid.x >= tex.get_width()) || (gid.y >= tex.get_height())) {
        return;
    }

    // Setting invalid array indices signals a NULL value.
    // Set before early exit checks.
    for (int i = 0; i < 4; i++) {
        runs[idx+i].oldHead = -1;
        runs[idx+i].oldTail = -1;
        runs[idx+i].newHead = -1;
        runs[idx+i].newTail = -1;
    }
    
    // Region outside of image bounds is treated as black border.
    // However, do not attempt to read out of bounds.
    uint32_t minCol = 0;
    uint32_t maxCol = tex.get_width() - 1;
    uint32_t minRow = 0;
    uint32_t maxRow = tex.get_height() - 1;
    if (tex.read(gid).r == 0) {
        return;
    }
    
    bool upL = readPixel(tex, uint2(gid.x - 1, gid.y - 1), minCol, maxCol, minRow, maxRow);
    bool up_ = readPixel(tex, uint2(gid.x    , gid.y - 1), minCol, maxCol, minRow, maxRow);
    bool upR = readPixel(tex, uint2(gid.x + 1, gid.y - 1), minCol, maxCol, minRow, maxRow);
    bool _L_ = readPixel(tex, uint2(gid.x - 1, gid.y    ), minCol, maxCol, minRow, maxRow);
    bool _R_ = readPixel(tex, uint2(gid.x + 1, gid.y    ), minCol, maxCol, minRow, maxRow);
    bool dnL = readPixel(tex, uint2(gid.x - 1, gid.y + 1), minCol, maxCol, minRow, maxRow);
    bool dn_ = readPixel(tex, uint2(gid.x    , gid.y + 1), minCol, maxCol, minRow, maxRow);
    bool dnR = readPixel(tex, uint2(gid.x + 1, gid.y + 1), minCol, maxCol, minRow, maxRow);
    
    // Compose the lookup table row address.
    // Bit order inverted due I think to an endianess issue.
    uint32_t lutRow = 0
        | (upL << 0)
        | (up_ << 1)
        | (upR << 2)
        | (_L_ << 3)
        | (_R_ << 4)
        | (dnL << 5)
        | (dn_ << 6)
        | (dnR << 7);
    
    // Loop over the lookup table's columns.
    for (uint32_t i = 0; i < lutRowWidth; i++) {
        uint32_t lutIdx = lutRow * lutRowWidth + i;
        struct Run lutRun = runLUT[lutIdx];
        struct PixelPoint lutPoint = pointLUT[lutIdx];
        if (lutRun.oldTail != -1) {
            points[idx+i].x = lutPoint.x + gid.x;
            points[idx+i].y = lutPoint.y + gid.y;
            runs[idx+i].oldTail = idx + lutRun.oldTail;
            runs[idx+i].oldHead = idx + lutRun.oldHead;
            runs[idx+i].tailTriadFrom = lutRun.tailTriadFrom;
            runs[idx+i].headTriadTo   = lutRun.headTriadTo;
        }
    }    
    return;
}
