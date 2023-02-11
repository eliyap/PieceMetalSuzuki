//
//  PieceSuzukiKernel.metal
//  PieceSuzukiKernel
//
//  Created by Secret Asian Man Dev on 9/2/23.
//

#include <metal_stdlib>
using namespace metal;

struct Run {
    int32_t oldHead;
    int32_t oldTail;
    int32_t newHead;
    int32_t newTail;
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
    texture2d<half, access::write> outputTexture [[ texture(1) ]],
    device PixelPoint*             points        [[ buffer (0) ]],
    device Run*                    runs          [[ buffer (1) ]],
    device const uint8_t*          starterLUT    [[ buffer (2) ]],
    uint2                          gid           [[thread_position_in_grid]]
) {
    // 4 elements per pixel, since each pixel can hold 4 triads.
    uint32_t idx = ((tex.get_width() * gid.y) + gid.x) * 4;
    
    // Don't exit the texture.
    if ((gid.x >= tex.get_width()) || (gid.y >= tex.get_height())) {
        return;
    }

    outputTexture.write(tex.read(gid), gid);

    // Setting invalid array indices signals a NULL value.
    // Set before early exit checks.
    for (int i = 0; i < 4; i++) {
        runs[idx+i].oldHead = -1;
        runs[idx+i].oldTail = -1;
        runs[idx+i].newHead = -1;
        runs[idx+i].newTail = -1;
    }
    
    // Don't touch frame.
    if ((gid.x == 0) || (gid.y == 0) || (gid.x == tex.get_width() - 1) || (gid.y == tex.get_height() - 1)) {
        return;
    }
    if (tex.read(gid).r == 0) {
        return;
    }
    
    bool upL = (gid.x != 0) && (tex.read(uint2(gid.x - 1, gid.y - 1)).r != 0.0);
    bool up_ = (tex.read(uint2(gid.x    , gid.y - 1)).r != 0.0);
    bool upR = (tex.read(uint2(gid.x + 1, gid.y - 1)).r != 0.0);
    bool _L_ = (tex.read(uint2(gid.x - 1, gid.y    )).r != 0.0);
    bool _R_ = (tex.read(uint2(gid.x + 1, gid.y    )).r != 0.0);
    bool dnL = (tex.read(uint2(gid.x - 1, gid.y + 1)).r != 0.0);
    bool dn_ = (tex.read(uint2(gid.x    , gid.y + 1)).r != 0.0);
    bool dnR = (tex.read(uint2(gid.x + 1, gid.y + 1)).r != 0.0);
    
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
            
            // Set indices to match 1-element array.
            runs[idx+i].oldHead = 0;
            runs[idx+i].oldTail = 0;
            runs[idx+i].newHead = 0;
            runs[idx+i].newTail = 0;
        }
    }    
    return;
}
