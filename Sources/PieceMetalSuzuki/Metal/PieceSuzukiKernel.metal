//
//  PieceSuzukiKernel.metal
//  PieceSuzukiKernel
//
//  Created by Secret Asian Man Dev on 9/2/23.
//

#include <metal_stdlib>
using namespace metal;

// Compute kernel
kernel void rosyEffect(texture2d<half, access::read>  inputTexture  [[ texture(0) ]],
                       texture2d<half, access::write> outputTexture [[ texture(1) ]],
                       uint2 gid [[thread_position_in_grid]])
{
    // Don't read or write outside of the texture.
    if ((gid.x >= inputTexture.get_width()) || (gid.y >= inputTexture.get_height())) {
        return;
    }
    
    half4 inputColor = inputTexture.read(gid);
    
    half luminosity = (inputColor.r * 0.2126) + (inputColor.g * 0.7152) + (inputColor.b * 0.0722);
    // Set the output color to the input color, excluding the green component.
    half4 outputColor = half4(luminosity, luminosity, luminosity, 1.0);
    
    outputTexture.write(outputColor, gid);
}
