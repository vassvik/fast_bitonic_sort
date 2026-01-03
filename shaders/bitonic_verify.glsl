#version 460 core

layout (location = 0) uniform uint u_max_count;

layout (binding = 0, std430) buffer buffer_0 {
	uint[] b_values;
};
layout (binding = 1, std430) buffer buffer_1 {
	uint b_is_sorted[32];
};
layout (local_size_x = 512, local_size_y = 1, local_size_z = 1) in ;
void main() {
	uint gid = gl_GlobalInvocationID.x;
	if (gid >= u_max_count-1) return;

	uint x1 = b_values[gid];
	uint x2 = b_values[gid + 1u];
	
	for (uint i = 0; i < 32; i++) {
		uint m = (1 << i) - 1;
		uint idx = gid & m;
		if (idx < m && x1 > x2) {
			b_is_sorted[i] = 0u;
		}
	}
}
