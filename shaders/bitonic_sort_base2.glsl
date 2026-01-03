#version 460 core

layout (location = 0) uniform uint u_mask1;
layout (location = 1) uniform uint u_mask2;

layout (binding = 0, std430) buffer buffer_0 {
  uint[] b_values_in;
};

layout (binding = 1, std430) buffer buffer_1 {
  uint[] b_values_out;
};

layout (local_size_x = 256, local_size_y = 1, local_size_z = 1) in ;

void main() {
    uint k = gl_GlobalInvocationID.x;
    uint k1 = k + (k & u_mask1);
    uint k2 = k1 ^ u_mask2;

    uint x1 = b_values_in[k1];
    uint x2 = b_values_in[k2];
    b_values_out[k1] = min(x1, x2);
    b_values_out[k2] = max(x1, x2);
}