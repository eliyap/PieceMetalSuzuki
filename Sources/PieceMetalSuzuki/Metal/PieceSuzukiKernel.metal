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

struct ChainFragments {
    device PixelPoint* points;
    device Run* runs;
};

struct MyArguments
{
    float widgetTolerance;
    uint32_t widgetHeight;
};

// Compute kernel
kernel void rosyEffect(
    texture2d<half, access::read>  inputTexture  [[ texture(0) ]],
    texture2d<half, access::write> outputTexture [[ texture(1) ]],
    device MyArguments*         fragments     [[ buffer (0) ]],
    uint2                          gid           [[thread_position_in_grid]]
) {
    if (fragments[0].widgetHeight != 0) {
        outputTexture.write(half4(0.5, 0.0, 1.0, 1.0), gid);
        fragments[0].widgetHeight = 1000;
        return;
    }

    // Don't read or write outside of the texture.
    if ((gid.x >= inputTexture.get_width()) || (gid.y >= inputTexture.get_height())) {
        return;
    }

    half4 black = half4(0.0, 0.0, 0.0, 1.0);
    
    // Write black to frame.
    if ((gid.x == 0) || (gid.y == 0) || (gid.x == inputTexture.get_width() - 1) || (gid.y == inputTexture.get_height() - 1)) {
        outputTexture.write(black, gid);
        return;
    }
    
    // Check if is edge pixel (is 1, 0 in cross positions).
    half4 center = inputTexture.read(gid);
    if (center.r == 0.0) {
        outputTexture.write(black, gid);
        return;
    }
    half4 up    = inputTexture.read(uint2(gid.x, gid.y - 1));
    half4 down  = inputTexture.read(uint2(gid.x, gid.y + 1));
    half4 left  = inputTexture.read(uint2(gid.x - 1, gid.y));
    half4 right = inputTexture.read(uint2(gid.x + 1, gid.y));
    if (up.r != 0.0 && down.r != 0.0 && left.r != 0.0 && right.r != 0.0) {
        outputTexture.write(black, gid);
        return;
    }
    
    half luminosity = (center.r * 0.2126) + (center.g * 0.7152) + (center.b * 0.0722);
    // Set the output color to the input color, excluding the green component.
    half4 outputColor = half4(luminosity, luminosity, luminosity, 1.0);
    
    outputTexture.write(outputColor, gid);
}
