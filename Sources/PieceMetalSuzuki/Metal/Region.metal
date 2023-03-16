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

struct GridSize { 
    uint32_t width;
    uint32_t height;
};

struct GridPosition {
    uint32_t row;
    uint32_t col;
};

struct PixelSize {
    uint32_t width;
    uint32_t height;
};

