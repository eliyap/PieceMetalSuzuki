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
    texture2d<half, access::read>  inputTexture  [[ texture(0) ]],
    texture2d<half, access::write> outputTexture [[ texture(1) ]],
    device ChainStarter*           starter       [[ buffer (0) ]],
    device const uint8_t*          starterLUT    [[ buffer (1) ]],
    uint2                          gid           [[thread_position_in_grid]]
) {
    // 4 elements per pixel, since each pixel can hold 4 triads.
    uint32_t idx = ((inputTexture.get_width() * gid.y) + gid.x) * 4;
    
    // Don't exit the texture.
    if ((gid.x >= inputTexture.get_width()) || (gid.y >= inputTexture.get_height())) {
        return;
    }

    outputTexture.write(inputTexture.read(gid), gid);

    // Don't touch frame.
    if ((gid.x == 0) || (gid.y == 0) || (gid.x == inputTexture.get_width() - 1) || (gid.y == inputTexture.get_height() - 1)) {
        return;
    }
    
    half4 upL = inputTexture.read(uint2(gid.x - 1, gid.y - 1));
    half4 up_ = inputTexture.read(uint2(gid.x    , gid.y - 1));
    half4 upR = inputTexture.read(uint2(gid.x + 1, gid.y - 1));
    half4 _L_ = inputTexture.read(uint2(gid.x - 1, gid.y    ));
    half4 _R_ = inputTexture.read(uint2(gid.x + 1, gid.y    ));
    half4 dnL = inputTexture.read(uint2(gid.x - 1, gid.y + 1));
    half4 dn_ = inputTexture.read(uint2(gid.x    , gid.y + 1));
    half4 dnR = inputTexture.read(uint2(gid.x + 1, gid.y + 1));
    
    // Compose the lookup table address.
    // Bit order inverted due I think to an endianess issue.
    uint32_t lutAddr = 0
        | ((upL.r != 0.0) << 0)
        | ((up_.r != 0.0) << 1)
        | ((upR.r != 0.0) << 2)
        | ((_L_.r != 0.0) << 3)
        | ((_R_.r != 0.0) << 4)
        | ((dnL.r != 0.0) << 5)
        | ((dn_.r != 0.0) << 6)
        | ((dnR.r != 0.0) << 7);
    
    // Loop over the lookup table's 4 columns of 2 values each.
    for (int i = 0; i < 4; i++) {
        uint8_t from = starterLUT[(lutAddr*8)+(i*2)+0];
        if (from != 0) {
            uint8_t to = starterLUT[(lutAddr*8)+(i*2)+1];
            starter[idx+i].isSet = true;
            starter[idx+i].tailTriadFrom = from;
            starter[idx+i].headTriadTo = to;
            starter[idx+i].point.x = gid.x;
            starter[idx+i].point.y = gid.y;
        } else {
            starter[idx+i].isSet = false;
        }
    }    
    return;
}
