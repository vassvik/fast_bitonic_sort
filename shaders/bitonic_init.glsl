#version 460 core

layout(local_size_x=512, local_size_y=1, local_size_z=1) in;

layout (location = 0) uniform uint u_max_count;

layout (binding = 0, std430) buffer buffer_0 {
  uint[] b_values;
};

uvec4 pcg4d(uvec4 v) {
    v = v * 1664525u + 1013904223u;
    v.x += v.y*v.w;
    v.y += v.z*v.x;
    v.z += v.x*v.y;
    v.w += v.y*v.z;
    v = v ^ (v >> 16u);
    v.x += v.y*v.w;
    v.y += v.z*v.x;
    v.z += v.x*v.y;
    v.w += v.y*v.z;
    return v;
}

void main() {
    uint gid = gl_GlobalInvocationID.x;
    b_values[gid] = gid < u_max_count ? (pcg4d(uvec4(gid, 0, 0, 0)).x % 100000) : -2;
}

