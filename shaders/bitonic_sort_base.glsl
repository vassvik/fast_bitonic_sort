#version 460 core

layout (location = 0) uniform uint u_mask;

layout (binding = 0, std430) buffer buffer_0 {
  uint[] b_values_in;
};

layout (binding = 1, std430) buffer buffer_1 {
  uint[] b_values_out;
};

layout (local_size_x = 256, local_size_y = 1, local_size_z = 1) in ;

uint compare_and_select(uint a, uint b, bool select_max) {
    //return mix(min(a, b), max(a, b), select_max);
    //return min(a, b) + (max(a, b) - min(a, b)) * T(select_max);  
    //return min(a, b) * (1 - T(select_max)) + max(a, b) * T(select_max); 
    return select_max ? max(a, b) : min(a, b);
}

void main() {
    uint gid1 = gl_GlobalInvocationID.x;
    uint gid2 = gid1 ^ u_mask;

    uint x1 = b_values_in[gid1];
    uint x2 = b_values_in[gid2];
    b_values_out[gid1] = compare_and_select(x1, x2, gid1 > gid2);
}