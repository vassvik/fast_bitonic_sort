#version 460 core

layout (location = 0) uniform uint u_mask1;
layout (location = 1) uniform uint u_mask2;

layout (binding = 0, std430) buffer buffer_0 {
  uint[] b_values;
};

layout (local_size_x = 256, local_size_y = 1, local_size_z = 1) in ;

uint compare_and_select(uint a, uint b, bool select_max) {
    //return mix(min(a, b), max(a, b), select_max);
    //return min(a, b) + (max(a, b) - min(a, b)) * T(select_max);  
    //return min(a, b) * (1 - T(select_max)) + max(a, b) * T(select_max); 
    return select_max ? max(a, b) : min(a, b);
}

void main() {
    uint k = gl_GlobalInvocationID.x;
    uint k1 = k + (k & u_mask1);
    uint k2 = k1 ^ u_mask2;

    uint x1 = b_values[k1];
    uint x2 = b_values[k2];
    b_values[k1] = min(x1, x2);
    b_values[k2] = max(x1, x2);
}