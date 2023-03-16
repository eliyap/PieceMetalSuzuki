#include <metal_stdlib>
using namespace metal;

struct GridSize { 
    uint32_t width;
    uint32_t height;
};

struct GridPosition {
    uint32_t row;
    uint32_t col;
};

