//
//  PieceSuzukiKernel.metal
//  PieceSuzukiKernel
//
//  Created by Secret Asian Man Dev on 9/2/23.
//

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

// Compute kernel
kernel void startChain(
    texture2d<half, access::read>  tex  [[ texture(0) ]],
    device PixelPoint*             points        [[ buffer (0) ]],
    device Run*                    runs          [[ buffer (1) ]],
    device const uint8_t*          starterLUT    [[ buffer (2) ]],
    uint2                          gid           [[thread_position_in_grid]]
) {
    // 4 elements per pixel, since each pixel can hold 4 triads.
    int32_t idx = ((tex.get_width() * gid.y) + gid.x) * 4;
    
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
    
    // Don't touch frame.
    uint32_t minCol = 0;
    uint32_t maxCol = tex.get_width() - 1;
    uint32_t minRow = 0;
    uint32_t maxRow = tex.get_height() - 1;
    if (tex.read(gid).r == 0) {
        return;
    }
    
    bool upL = (gid.x != minCol) && (gid.y != minRow) && (tex.read(uint2(gid.x - 1, gid.y - 1)).r != 0.0);
    bool up_ =                      (gid.y != minRow) && (tex.read(uint2(gid.x    , gid.y - 1)).r != 0.0);
    bool upR = (gid.x != maxCol) && (gid.y != minRow) && (tex.read(uint2(gid.x + 1, gid.y - 1)).r != 0.0);
    bool _L_ = (gid.x != minCol) &&                      (tex.read(uint2(gid.x - 1, gid.y    )).r != 0.0);
    bool _R_ = (gid.x != maxCol) &&                      (tex.read(uint2(gid.x + 1, gid.y    )).r != 0.0);
    bool dnL = (gid.x != minCol) && (gid.y != maxRow) && (tex.read(uint2(gid.x - 1, gid.y + 1)).r != 0.0);
    bool dn_ =                      (gid.y != maxRow) && (tex.read(uint2(gid.x    , gid.y + 1)).r != 0.0);
    bool dnR = (gid.x != maxCol) && (gid.y != maxRow) && (tex.read(uint2(gid.x + 1, gid.y + 1)).r != 0.0);
    
    // Compose the lookup table address.
    // Bit order inverted due I think to an endianess issue.
    uint32_t lutAddr = 0
        | (upL << 0)
        | (up_ << 1)
        | (upR << 2)
        | (_L_ << 3)
        | (_R_ << 4)
        | (dnL << 5)
        | (dn_ << 6)
        | (dnR << 7);
    
    // Loop over the lookup table's 4 columns of 2 values each.
    for (int i = 0; i < 4; i++) {
        uint8_t from = starterLUT[(lutAddr*8)+(i*2)+0];
        if (from != 0) {
            uint8_t to = starterLUT[(lutAddr*8)+(i*2)+1];
            runs[idx+i].tailTriadFrom = from;
            runs[idx+i].headTriadTo = to;
            points[idx+i].x = gid.x;
            points[idx+i].y = gid.y;
            
            // Index to current buffer position.
            runs[idx+i].oldTail = idx+i;
            runs[idx+i].oldHead = idx+i+1;
            runs[idx+i].newTail = idx+i;
            runs[idx+i].newHead = idx+i+1;
        }
    }    
    return;
}
