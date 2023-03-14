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

kernel void combine(
    texture2d<half, access::read>  tex    [[ texture(0) ]],
    device PixelPoint*             points [[ buffer (0) ]],
    device Run*                    runs   [[ buffer (1) ]],
    uint2                          gid    [[thread_position_in_grid]]
) {

}