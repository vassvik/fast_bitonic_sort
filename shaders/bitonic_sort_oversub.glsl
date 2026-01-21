#version 460 core

#extension GL_KHR_shader_subgroup_basic : require
#extension GL_KHR_shader_subgroup_shuffle : require

layout (binding = 0, std430) coherent buffer buffer_0 {
  uint[] b_values1;
};

layout (binding = 1, std430) coherent buffer buffer_1 {
  uint[] b_values2;
};

layout (binding = 2, std430) buffer buffer_2 {
  uint b_counters[32];
};

layout (location = 0) uniform uint u_workgroups_per_pass;


layout (local_size_x = 1024, local_size_y = 1, local_size_z = 1) in ;

#define T uint

T compare_and_select(T a, T b, bool select_max) {
    //return mix(min(a, b), max(a, b), select_max);
    //return min(a, b) + (max(a, b) - min(a, b)) * T(select_max);  
    //return min(a, b) * (1 - T(select_max)) + max(a, b) * T(select_max); 
    return select_max ? max(a, b) : min(a, b);
}

#define sid gl_SubgroupInvocationID 
#define shfl(v, i) subgroupShuffleXor(v, i)

T sort_wave(T value) {
    // layer 0
    value = compare_and_select(value, shfl(value, 1),  (sid&1) != 0);

    // layer 1
    value = compare_and_select(value, shfl(value, 3),  (sid&2) != 0);
    value = compare_and_select(value, shfl(value, 1),  (sid&1) != 0);

    // layer 2
    value = compare_and_select(value, shfl(value, 7),  (sid&4) != 0);
    value = compare_and_select(value, shfl(value, 2),  (sid&2) != 0);
    value = compare_and_select(value, shfl(value, 1),  (sid&1) != 0);

    // layer 3
    value = compare_and_select(value, shfl(value, 15), (sid&8) != 0);
    value = compare_and_select(value, shfl(value, 4),  (sid&4) != 0);
    value = compare_and_select(value, shfl(value, 2),  (sid&2) != 0);
    value = compare_and_select(value, shfl(value, 1),  (sid&1) != 0);

    // layer 4
    value = compare_and_select(value, shfl(value, 31), (sid&16) != 0);
    value = compare_and_select(value, shfl(value, 8),  (sid&8) != 0);
    value = compare_and_select(value, shfl(value, 4),  (sid&4) != 0);
    value = compare_and_select(value, shfl(value, 2),  (sid&2) != 0);
    value = compare_and_select(value, shfl(value, 1),  (sid&1) != 0);

    return value;
}

T finalize_wave(T value) {
    value = compare_and_select(value, shfl(value, 16), (sid&16) != 0);
    value = compare_and_select(value, shfl(value, 8),  (sid&8) != 0);
    value = compare_and_select(value, shfl(value, 4),  (sid&4) != 0);
    value = compare_and_select(value, shfl(value, 2),  (sid&2) != 0);
    value = compare_and_select(value, shfl(value, 1),  (sid&1) != 0);

    return value;
}

shared T s_partially_sorted[1024];
shared T s_partially_sorted2[1024];

T finalize_512(uint lindex, T sorted0) {
    T sorted[4];
    sorted[0] = sorted0;

    /// sort512
    s_partially_sorted[lindex] = sorted[0];
    barrier();

    sorted[1] = s_partially_sorted[lindex^(1*128)];
    sorted[2] = s_partially_sorted[lindex^(2*128)];
    sorted[3] = s_partially_sorted[lindex^(3*128)];

    sorted[0] = compare_and_select(sorted[0], sorted[2], (lindex&256) != 0);
    sorted[1] = compare_and_select(sorted[1], sorted[3], (lindex&256) != 0);

    sorted[0] = compare_and_select(sorted[0], sorted[1], (lindex&128) != 0); 

    s_partially_sorted2[(lindex)] = sorted[0];
    barrier();

    sorted[1] = s_partially_sorted2[lindex^(1*32)];
    sorted[2] = s_partially_sorted2[lindex^(2*32)];
    sorted[3] = s_partially_sorted2[lindex^(3*32)];

    sorted[0] = compare_and_select(sorted[0], sorted[2], (lindex&64) != 0); 
    sorted[1] = compare_and_select(sorted[1], sorted[3], (lindex&64) != 0); 

    sorted[0] = compare_and_select(sorted[0], sorted[1], (lindex&32) != 0); 

    sorted[0] = finalize_wave(sorted[0]);

    return sorted[0];
}

T finalize_1024(uint lindex, T sorted0) {
    T sorted[8];
    sorted[0] = sorted0;

    /// sort1024
    s_partially_sorted[lindex] = sorted[0];
    barrier();

    sorted[1] = s_partially_sorted[lindex^(1*128)];
    sorted[2] = s_partially_sorted[lindex^(2*128)];
    sorted[3] = s_partially_sorted[lindex^(3*128)];
    sorted[4] = s_partially_sorted[lindex^(4*128)];
    sorted[5] = s_partially_sorted[lindex^(5*128)];
    sorted[6] = s_partially_sorted[lindex^(6*128)];
    sorted[7] = s_partially_sorted[lindex^(7*128)];

    sorted[0] = compare_and_select(sorted[0], sorted[4], (lindex&512) != 0);
    sorted[1] = compare_and_select(sorted[1], sorted[5], (lindex&512) != 0);
    sorted[2] = compare_and_select(sorted[2], sorted[6], (lindex&512) != 0);
    sorted[3] = compare_and_select(sorted[3], sorted[7], (lindex&512) != 0);

    sorted[0] = compare_and_select(sorted[0], sorted[2], (lindex&256) != 0);
    sorted[1] = compare_and_select(sorted[1], sorted[3], (lindex&256) != 0);

    sorted[0] = compare_and_select(sorted[0], sorted[1], (lindex&128) != 0); 

    s_partially_sorted2[(lindex)] = sorted[0];
    barrier();

    sorted[1] = s_partially_sorted2[lindex^(1*32)];
    sorted[2] = s_partially_sorted2[lindex^(2*32)];
    sorted[3] = s_partially_sorted2[lindex^(3*32)];

    sorted[0] = compare_and_select(sorted[0], sorted[2], (lindex&64) != 0); 
    sorted[1] = compare_and_select(sorted[1], sorted[3], (lindex&64) != 0); 

    sorted[0] = compare_and_select(sorted[0], sorted[1], (lindex&32) != 0); 

    sorted[0] = finalize_wave(sorted[0]);

    return sorted[0];
}

void sort_1_to_1024(uint group) {
    uint lindex = gl_LocalInvocationIndex;
    uint gid = 1024 * group + lindex;

    T sorted1, sorted2, sorted3, sorted4, sorted5, sorted6, sorted7;
    T sorted0 = b_values1[gid];

    /// sort32
    sorted0 = sort_wave(sorted0);

    /// sort64
    s_partially_sorted[(lindex)] = sorted0;
    barrier();

    sorted1 = s_partially_sorted[(lindex^63)];
    
    sorted0 = compare_and_select(sorted0, sorted1, (lindex&32) != 0); 

    sorted0 = finalize_wave(sorted0);

    /// sort128
    s_partially_sorted2[(lindex)] = sorted0;
    barrier();

    sorted1 = s_partially_sorted2[(lindex^(1*32))];
    sorted2 = s_partially_sorted2[(lindex^(0*32)^127)];
    sorted3 = s_partially_sorted2[(lindex^(1*32)^127)];

    sorted0 = compare_and_select(sorted0, sorted2, (lindex&64) != 0); 
    sorted1 = compare_and_select(sorted1, sorted3, (lindex&64) != 0); 

    sorted0 = compare_and_select(sorted0, sorted1, (lindex&32) != 0);

    sorted0 = finalize_wave(sorted0);

    /// sort256
    s_partially_sorted[(lindex)] = sorted0;
    barrier();

    sorted1 = s_partially_sorted[(lindex^(1*32))];
    sorted2 = s_partially_sorted[(lindex^(2*32))];
    sorted3 = s_partially_sorted[(lindex^(3*32))];
    sorted4 = s_partially_sorted[(lindex^(0*32)^255)];
    sorted5 = s_partially_sorted[(lindex^(1*32)^255)];
    sorted6 = s_partially_sorted[(lindex^(2*32)^255)];
    sorted7 = s_partially_sorted[(lindex^(3*32)^255)];

    sorted0 = compare_and_select(sorted0, sorted4, (lindex&128) != 0); 
    sorted1 = compare_and_select(sorted1, sorted5, (lindex&128) != 0); 
    sorted2 = compare_and_select(sorted2, sorted6, (lindex&128) != 0); 
    sorted3 = compare_and_select(sorted3, sorted7, (lindex&128) != 0); 

    sorted0 = compare_and_select(sorted0, sorted2, (lindex&64) != 0); 
    sorted1 = compare_and_select(sorted1, sorted3, (lindex&64) != 0); 

    sorted0 = compare_and_select(sorted0, sorted1, (lindex&32) != 0); 

    sorted0 = finalize_wave(sorted0);

    /// sort512
    s_partially_sorted2[(lindex)] = sorted0;
    barrier();

    sorted1 = s_partially_sorted2[(lindex^(1*128))];
    sorted2 = s_partially_sorted2[(lindex^(0*128)^511)];
    sorted3 = s_partially_sorted2[(lindex^(1*128)^511)];

    sorted0 = compare_and_select(sorted0, sorted2, (lindex&256) != 0); 
    sorted1 = compare_and_select(sorted1, sorted3, (lindex&256) != 0); 

    sorted0 = compare_and_select(sorted0, sorted1, (lindex&128) != 0); 

    s_partially_sorted[(lindex)] = sorted0;
    barrier();

    sorted1 = s_partially_sorted[(lindex^(1*32))];
    sorted2 = s_partially_sorted[(lindex^(0*32)^64)];
    sorted3 = s_partially_sorted[(lindex^(1*32)^64)];

    sorted0 = compare_and_select(sorted0, sorted2, (lindex&64) != 0); 
    sorted1 = compare_and_select(sorted1, sorted3, (lindex&64) != 0); 

    sorted0 = compare_and_select(sorted0, sorted1, (lindex&32) != 0); 

    sorted0 = finalize_wave(sorted0);

    /// sort1024
    s_partially_sorted2[(lindex)] = sorted0;
    barrier();

    sorted1 = s_partially_sorted2[(lindex^(1*256))];
    sorted2 = s_partially_sorted2[(lindex^(0*256)^1023)];
    sorted3 = s_partially_sorted2[(lindex^(1*256)^1023)];

    sorted0 = compare_and_select(sorted0, sorted2, (lindex&512) != 0); 
    sorted1 = compare_and_select(sorted1, sorted3, (lindex&512) != 0); 

    sorted0 = compare_and_select(sorted0, sorted1, (lindex&256) != 0); 

    s_partially_sorted[(lindex)] = sorted0;
    barrier();

    sorted1 = s_partially_sorted[(lindex^(1*32))];
    sorted2 = s_partially_sorted[(lindex^(2*32))];
    sorted3 = s_partially_sorted[(lindex^(3*32))];
    sorted4 = s_partially_sorted[(lindex^(0*32)^128)];
    sorted5 = s_partially_sorted[(lindex^(1*32)^128)];
    sorted6 = s_partially_sorted[(lindex^(2*32)^128)];
    sorted7 = s_partially_sorted[(lindex^(3*32)^128)];

    sorted0 = compare_and_select(sorted0, sorted4, (lindex&128) != 0); 
    sorted1 = compare_and_select(sorted1, sorted5, (lindex&128) != 0); 
    sorted2 = compare_and_select(sorted2, sorted6, (lindex&128) != 0); 
    sorted3 = compare_and_select(sorted3, sorted7, (lindex&128) != 0); 

    sorted0 = compare_and_select(sorted0, sorted2, (lindex&64) != 0); 
    sorted1 = compare_and_select(sorted1, sorted3, (lindex&64) != 0); 

    sorted0 = compare_and_select(sorted0, sorted1, (lindex&32) != 0); 

    sorted0 = finalize_wave(sorted0);

    b_values2[gid] = sorted0; 
} 

void sort_1024_to_2048(uint group) {
    uint lindex = gl_LocalInvocationIndex;
    uint gid = 1024 * group + lindex;

    T sorted[4];
    for (uint i = 0; i < 2; i++) {
        uint idx = gid^(i*512);
        sorted[i] = b_values2[idx];
        sorted[i+2] = b_values2[idx^2047];
    }

    for (uint i = 0; i < 2; i++) sorted[i] = compare_and_select(sorted[i], sorted[i+2], (gid&1024) != 0);
    for (uint i = 0; i < 1; i++) sorted[i] = compare_and_select(sorted[i], sorted[i+1], (gid&512) != 0);

    b_values1[gid] = finalize_512(lindex, sorted[0]);
} 

void sort_2048_to_4096(uint group) {
    uint lindex = gl_LocalInvocationIndex;
    uint gid = 1024 * group + lindex;

    T sorted[4];
    for (uint i = 0; i < 2; i++) {
        uint idx = gid^(i*1024);
        sorted[i] = b_values1[idx];
        sorted[i+2] = b_values1[idx^4095];
    }

    for (uint i = 0; i < 2; i++) sorted[i] = compare_and_select(sorted[i], sorted[i+2], (gid&2048) != 0);
    for (uint i = 0; i < 1; i++) sorted[i] = compare_and_select(sorted[i], sorted[i+1], (gid&1024) != 0);

    b_values2[gid] = finalize_1024(lindex, sorted[0]);
} 

void sort_4096_to_8192(uint group) {
    uint lindex = gl_LocalInvocationIndex;
    uint gid = 1024 * group + lindex;

    T sorted[8];
    for (uint i = 0; i < 4; i++) {
        uint idx = gid^(i*1024);
        sorted[i] = b_values2[idx];
        sorted[i+4] = b_values2[idx^8191];
    }

    for (uint i = 0; i < 4; i++) sorted[i] = compare_and_select(sorted[i], sorted[i+4], (gid&4096) != 0);
    for (uint i = 0; i < 2; i++) sorted[i] = compare_and_select(sorted[i], sorted[i+2], (gid&2048) != 0);
    for (uint i = 0; i < 1; i++) sorted[i] = compare_and_select(sorted[i], sorted[i+1], (gid&1024) != 0);

    b_values1[gid] = finalize_1024(lindex, sorted[0]);
} 

void sort_8192_to_16384(uint group) {
    uint lindex = gl_LocalInvocationIndex;
    uint gid = 1024 * group + lindex;

    T sorted[16];
    for (uint i = 0; i < 8; i++) {
        uint idx = gid^(i*1024);
        sorted[i] = b_values1[idx];
        sorted[i+8] = b_values1[idx^16383];
    }

    for (uint i = 0; i < 8;  i++) sorted[i] = compare_and_select(sorted[i], sorted[i+8], (gid&8192) != 0);
    for (uint i = 0; i < 4;  i++) sorted[i] = compare_and_select(sorted[i], sorted[i+4], (gid&4096) != 0);
    for (uint i = 0; i < 2;  i++) sorted[i] = compare_and_select(sorted[i], sorted[i+2], (gid&2048) != 0);
    for (uint i = 0; i < 1;  i++) sorted[i] = compare_and_select(sorted[i], sorted[i+1], (gid&1024) != 0);

    b_values2[gid] = finalize_1024(lindex, sorted[0]);
} 

void sort_16384_to_32768(uint group) {
    uint lindex = gl_LocalInvocationIndex;
    uint gid = 1024 * group + lindex;

    T sorted[32];
    for (uint i = 0; i < 16; i++) {
        uint idx  = gid^(i*1024);
        sorted[i] = b_values1[idx];
        sorted[i+16] = b_values1[idx^32767];
    }

    for (uint i = 0; i < 16; i++) sorted[i] = compare_and_select(sorted[i], sorted[i+16], (gid&16384) != 0);
    for (uint i = 0; i < 8;  i++) sorted[i] = compare_and_select(sorted[i], sorted[i+8],  (gid&8192) != 0);
    for (uint i = 0; i < 4;  i++) sorted[i] = compare_and_select(sorted[i], sorted[i+4],  (gid&4096) != 0);
    for (uint i = 0; i < 2;  i++) sorted[i] = compare_and_select(sorted[i], sorted[i+2],  (gid&2048) != 0);
    for (uint i = 0; i < 1;  i++) sorted[i] = compare_and_select(sorted[i], sorted[i+1],  (gid&1024) != 0);

    b_values2[gid] = finalize_1024(lindex, sorted[0]);
} 

void sort_16384_to_32768_1(uint group) {
    uint lindex = gl_LocalInvocationIndex;
    uint gid = 1024 * group + lindex;

    T sorted[8];
    for (uint i = 0; i < 4; i++) {
        uint idx = gid^(i*4096);
        sorted[i] = b_values2[idx];
        sorted[4+i] = b_values2[idx^32767];
    }

    for (uint i = 0; i < 4; i++) sorted[i] = compare_and_select(sorted[i], sorted[i+4],  (gid&16384) != 0); 
    for (uint i = 0; i < 2; i++) sorted[i] = compare_and_select(sorted[i], sorted[i+2],  (gid&8192) != 0); 
    for (uint i = 0; i < 1; i++) sorted[i] = compare_and_select(sorted[i], sorted[i+1],  (gid&4096) != 0); 

    b_values1[gid] = sorted[0];
} 

void sort_16384_to_32768_2(uint group) {
    uint lindex = gl_LocalInvocationIndex;
    uint gid = 1024 * group + lindex;

    T sorted[4];
    for (uint i = 0; i < 2; i++) {
        uint idx = gid^(i*1024);
        sorted[i] = b_values1[idx];
        sorted[2+i] = b_values1[idx^2048];
    }

    for (uint i = 0; i < 2; i++) sorted[i] = compare_and_select(sorted[i], sorted[i+2],  (gid&2048) != 0);  // 4096
    for (uint i = 0; i < 1; i++) sorted[i] = compare_and_select(sorted[i], sorted[i+1],  (gid&1024) != 0);  // 2048

    b_values2[gid] = finalize_1024(lindex, sorted[0]);
} 

void sort_32768_to_65536(uint group) {
    uint lindex = gl_LocalInvocationIndex;
    uint gid = 1024 * group + lindex;

    T sorted[64];
    for (uint i = 0; i < 32; i++) {
        uint idx = gid^(i*1024);
        sorted[i] = b_values1[idx];
        sorted[i+32] = b_values1[idx^65535];
    }

    for (uint i = 0; i < 32; i++) sorted[i] = compare_and_select(sorted[i], sorted[i+32], (gid&32768) != 0);
    for (uint i = 0; i < 16; i++) sorted[i] = compare_and_select(sorted[i], sorted[i+16], (gid&16384) != 0);
    for (uint i = 0; i < 8;  i++) sorted[i] = compare_and_select(sorted[i], sorted[i+8],  (gid&8192) != 0);
    for (uint i = 0; i < 4;  i++) sorted[i] = compare_and_select(sorted[i], sorted[i+4],  (gid&4096) != 0);
    for (uint i = 0; i < 2;  i++) sorted[i] = compare_and_select(sorted[i], sorted[i+2],  (gid&2048) != 0);
    for (uint i = 0; i < 1;  i++) sorted[i] = compare_and_select(sorted[i], sorted[i+1],  (gid&1024) != 0);

    b_values2[gid] = finalize_1024(lindex, sorted[0]);
} 

void sort_32768_to_65536_1(uint group) {
    uint lindex = gl_LocalInvocationIndex;
    uint gid = 1024 * group + lindex;

    T sorted[8];
    for (uint i = 0; i < 4; i++) {
        uint idx = gid^(i*8192);
        sorted[i] = b_values2[idx];
        sorted[4+i] = b_values2[idx^65535];
    }

    for (uint i = 0; i < 4; i++) sorted[i] = compare_and_select(sorted[i], sorted[i+4],  (gid&32768) != 0); 
    for (uint i = 0; i < 2; i++) sorted[i] = compare_and_select(sorted[i], sorted[i+2],  (gid&16384) != 0); 
    for (uint i = 0; i < 1; i++) sorted[i] = compare_and_select(sorted[i], sorted[i+1],  (gid&8192) != 0); 

    b_values1[gid] = sorted[0];
} 

void sort_32768_to_65536_2(uint group) {
    uint lindex = gl_LocalInvocationIndex;
    uint gid = 1024 * group + lindex;

    T sorted[8];
    for (uint i = 0; i < 4; i++) {
        uint idx = gid^(i*1024);
        sorted[i] = b_values1[idx];
        sorted[4+i] = b_values1[idx^4096];
    }

    for (uint i = 0; i < 4; i++) sorted[i] = compare_and_select(sorted[i], sorted[i+4],  (gid&4096) != 0);  // 8192
    for (uint i = 0; i < 2; i++) sorted[i] = compare_and_select(sorted[i], sorted[i+2],  (gid&2048) != 0);  // 4096
    for (uint i = 0; i < 1; i++) sorted[i] = compare_and_select(sorted[i], sorted[i+1],  (gid&1024) != 0);  // 2048

    b_values2[gid] = finalize_1024(lindex, sorted[0]);
} 

void sort_65536_to_131072(uint group) {
    uint lindex = gl_LocalInvocationIndex;
    uint gid = 1024 * group + lindex;


    T sorted2[16];
    for (uint j = 0; j < 16; j++) {
        T sorted[8];
        for (uint i = 0; i < 4; i++) sorted[i]    = b_values1[gid^(j*1024)^(i*16384)];
        for (uint i = 0; i < 4; i++) sorted[4+i] = b_values1[gid^(j*1024)^(i*16384)^131071];

        for (uint i = 0; i < 4; i++) sorted[i] = compare_and_select(sorted[i], sorted[i+4], (gid&65536) != 0); // 131072 
        for (uint i = 0; i < 2; i++) sorted[i] = compare_and_select(sorted[i], sorted[i+2], (gid&32768) != 0); // 65536 
        for (uint i = 0; i < 1; i++) sorted[i] = compare_and_select(sorted[i], sorted[i+1], (gid&16384) != 0); // 32768 
        sorted2[j] = sorted[0];
    }

    for (uint i = 0; i < 8;   i++) sorted2[i] = compare_and_select(sorted2[i], sorted2[i+8],  (gid&8192) != 0);  // 4096 
    for (uint i = 0; i < 4;   i++) sorted2[i] = compare_and_select(sorted2[i], sorted2[i+4],  (gid&4096) != 0);  // 4096 
    for (uint i = 0; i < 2;   i++) sorted2[i] = compare_and_select(sorted2[i], sorted2[i+2],  (gid&2048) != 0);  // 4096 
    for (uint i = 0; i < 1;   i++) sorted2[i] = compare_and_select(sorted2[i], sorted2[i+1],  (gid&1024) != 0);  // 2048 

    b_values2[gid] = finalize_1024(lindex, sorted2[0]);
}

void sort_65536_to_131072_1(uint group) {
    uint lindex = gl_LocalInvocationIndex;
    uint gid = 1024 * group + lindex;

    T sorted[8];
    for (uint i = 0; i < 4; i++) sorted[i] = b_values2[gid^(i*16384)];
    for (uint i = 0; i < 4; i++) sorted[4+i] = b_values2[gid^(i*16384)^131071];

    for (uint i = 0; i < 4; i++) sorted[i] = compare_and_select(sorted[i], sorted[i+4],  (gid&65536) != 0); 
    for (uint i = 0; i < 2; i++) sorted[i] = compare_and_select(sorted[i], sorted[i+2],  (gid&32768) != 0); 
    for (uint i = 0; i < 1; i++) sorted[i] = compare_and_select(sorted[i], sorted[i+1],  (gid&16384) != 0); 

    b_values1[gid] = sorted[0];
} 

void sort_65536_to_131072_2(uint group) {
    uint lindex = gl_LocalInvocationIndex;
    uint gid = 1024 * group + lindex;

    T sorted[16];
    for (uint i = 0; i < 8; i++) sorted[i] = b_values1[gid^(i*1024)];
    for (uint i = 0; i < 8; i++) sorted[8+i] = b_values1[gid^(i*1024)^8192];

    for (uint i = 0; i < 8; i++) sorted[i] = compare_and_select(sorted[i], sorted[i+8],  (gid&8192) != 0);  // 8192
    for (uint i = 0; i < 4; i++) sorted[i] = compare_and_select(sorted[i], sorted[i+4],  (gid&4096) != 0);  // 8192
    for (uint i = 0; i < 2; i++) sorted[i] = compare_and_select(sorted[i], sorted[i+2],  (gid&2048) != 0);  // 4096
    for (uint i = 0; i < 1; i++) sorted[i] = compare_and_select(sorted[i], sorted[i+1],  (gid&1024) != 0);  // 2048

    b_values2[gid] = finalize_1024(lindex, sorted[0]);
} 

void sort_131072_to_262144(uint group) {
    uint lindex = gl_LocalInvocationIndex;
    uint gid = 1024 * group + lindex;

    T sorted2[16];
    for (uint j = 0; j < 16; j++) {
        T sorted[16];
        for (uint i = 0; i < 8; i++) sorted[i]    = b_values1[gid^(j*1024)^(i*16384)];
        for (uint i = 0; i < 8; i++) sorted[8+i] = b_values1[gid^(j*1024)^(i*16384)^262144];

        for (uint i = 0; i < 8; i++) sorted[i] = compare_and_select(sorted[i], sorted[i+8], (gid&131072) != 0); // 131072 
        for (uint i = 0; i < 4; i++) sorted[i] = compare_and_select(sorted[i], sorted[i+4], (gid&65536) != 0); // 131072 
        for (uint i = 0; i < 2; i++) sorted[i] = compare_and_select(sorted[i], sorted[i+2], (gid&32768) != 0); // 65536 
        for (uint i = 0; i < 1; i++) sorted[i] = compare_and_select(sorted[i], sorted[i+1], (gid&16384) != 0); // 32768 
        sorted2[j] = sorted[0];
    }

    for (uint i = 0; i < 8;   i++) sorted2[i] = compare_and_select(sorted2[i], sorted2[i+8],  (gid&8192) != 0);  // 4096 
    for (uint i = 0; i < 4;   i++) sorted2[i] = compare_and_select(sorted2[i], sorted2[i+4],  (gid&4096) != 0);  // 4096 
    for (uint i = 0; i < 2;   i++) sorted2[i] = compare_and_select(sorted2[i], sorted2[i+2],  (gid&2048) != 0);  // 4096 
    for (uint i = 0; i < 1;   i++) sorted2[i] = compare_and_select(sorted2[i], sorted2[i+1],  (gid&1024) != 0);  // 2048 

    b_values2[gid] = finalize_1024(lindex, sorted2[0]);
}

void sort_131072_to_262144_1(uint group) {
    uint lindex = gl_LocalInvocationIndex;
    uint gid = 1024 * group + lindex;

    T sorted[16];
    for (uint i = 0; i < 8; i++) sorted[i] = b_values2[gid^(i*16384)];
    for (uint i = 0; i < 8; i++) sorted[8+i] = b_values2[gid^(i*16384)^262143];

    for (uint i = 0; i < 8; i++) sorted[i] = compare_and_select(sorted[i], sorted[i+8],  (gid&131072) != 0); 
    for (uint i = 0; i < 4; i++) sorted[i] = compare_and_select(sorted[i], sorted[i+4],  (gid&65536) != 0); 
    for (uint i = 0; i < 2; i++) sorted[i] = compare_and_select(sorted[i], sorted[i+2],  (gid&32768) != 0); 
    for (uint i = 0; i < 1; i++) sorted[i] = compare_and_select(sorted[i], sorted[i+1],  (gid&16384) != 0); 

    b_values1[gid] = sorted[0];
} 

void sort_131072_to_262144_2(uint group) {
    uint lindex = gl_LocalInvocationIndex;
    uint gid = 1024 * group + lindex;

    T sorted[16];
    for (uint i = 0; i < 8; i++) sorted[i] = b_values1[gid^(i*1024)];
    for (uint i = 0; i < 8; i++) sorted[8+i] = b_values1[gid^(i*1024)^8192];

    for (uint i = 0; i < 8; i++) sorted[i] = compare_and_select(sorted[i], sorted[i+8],  (gid&8192) != 0);  // 8192
    for (uint i = 0; i < 4; i++) sorted[i] = compare_and_select(sorted[i], sorted[i+4],  (gid&4096) != 0);  // 8192
    for (uint i = 0; i < 2; i++) sorted[i] = compare_and_select(sorted[i], sorted[i+2],  (gid&2048) != 0);  // 4096
    for (uint i = 0; i < 1; i++) sorted[i] = compare_and_select(sorted[i], sorted[i+1],  (gid&1024) != 0);  // 2048

    b_values2[gid] = finalize_1024(lindex, sorted[0]);
} 

shared uint s_ticket;

void main() {
    if (gl_LocalInvocationIndex == 0) {
        s_ticket = atomicAdd(b_counters[0], 1);
    }
    barrier();

    if (s_ticket < u_workgroups_per_pass) {
        uint group = s_ticket;
        sort_1_to_1024(group);
        atomicAdd(b_counters[1], 1);
    } else if (s_ticket < 2*u_workgroups_per_pass) {
        bool waiting;
        do {
            uint done = atomicAdd(b_counters[1], 0);
            waiting = (done != 1024*u_workgroups_per_pass);            
        } while (waiting);
        
        uint group = s_ticket - u_workgroups_per_pass;
        memoryBarrierBuffer();
        sort_1024_to_2048(group);
        atomicAdd(b_counters[2], 1);
    } else if (s_ticket < 3*u_workgroups_per_pass) {
        bool waiting;
        do {
            uint done = atomicAdd(b_counters[2], 0);
            waiting = (done != 1024*u_workgroups_per_pass);            
        } while (waiting);
        
        uint group = s_ticket - 2*u_workgroups_per_pass;
        memoryBarrierBuffer();
        sort_2048_to_4096(group);
        atomicAdd(b_counters[3], 1);
    } else if (s_ticket < 4*u_workgroups_per_pass) {
        bool waiting;
        do {
            uint done = atomicAdd(b_counters[3], 0);
            waiting = (done != 1024*u_workgroups_per_pass);            
        } while (waiting);
        
        uint group = s_ticket - 3*u_workgroups_per_pass;
        memoryBarrierBuffer();
        sort_4096_to_8192(group);
        atomicAdd(b_counters[4], 1);
    } else if (s_ticket < 5*u_workgroups_per_pass) {
        bool waiting;
        do {
            uint done = atomicAdd(b_counters[4], 0);
            waiting = (done != 1024*u_workgroups_per_pass);
        } while (waiting);

        uint group = s_ticket - 4*u_workgroups_per_pass;
        memoryBarrierBuffer();
        sort_8192_to_16384(group);
        atomicAdd(b_counters[5], 1);
    } else if (s_ticket < 6*u_workgroups_per_pass) {
        bool waiting;
        do {
            uint done = atomicAdd(b_counters[5], 0);
            waiting = (done != 1024*u_workgroups_per_pass);
        } while (waiting);

        uint group = s_ticket - 5*u_workgroups_per_pass;
        memoryBarrierBuffer();
        sort_16384_to_32768_1(group);
        atomicAdd(b_counters[6], 1);
    } else if (s_ticket < 7*u_workgroups_per_pass) {
        bool waiting;
        do {
            uint done = atomicAdd(b_counters[6], 0);
            waiting = (done != 1024*u_workgroups_per_pass);
        } while (waiting);

        uint group = s_ticket - 6*u_workgroups_per_pass;
        memoryBarrierBuffer();
        sort_16384_to_32768_2(group);
        atomicAdd(b_counters[7], 1);
    } else if (s_ticket < 8*u_workgroups_per_pass) {
        bool waiting;
        do {
            uint done = atomicAdd(b_counters[7], 0);
            waiting = (done != 1024*u_workgroups_per_pass);
        } while (waiting);

        uint group = s_ticket - 7*u_workgroups_per_pass;
        memoryBarrierBuffer();
        sort_32768_to_65536_1(group);
        atomicAdd(b_counters[8], 1);
    } else if (s_ticket < 9*u_workgroups_per_pass) {
        bool waiting;
        do {
            uint done = atomicAdd(b_counters[8], 0);
            waiting = (done != 1024*u_workgroups_per_pass);
        } while (waiting);

        uint group = s_ticket - 8*u_workgroups_per_pass;
        memoryBarrierBuffer();
        sort_32768_to_65536_2(group);
        atomicAdd(b_counters[9], 1);
    } else if (s_ticket < 10*u_workgroups_per_pass) {
        bool waiting;
        do {
            uint done = atomicAdd(b_counters[9], 0);
            waiting = (done != 1024*u_workgroups_per_pass);
        } while (waiting);

        uint group = s_ticket - 9*u_workgroups_per_pass;
        memoryBarrierBuffer();
        sort_65536_to_131072_1(group);
        atomicAdd(b_counters[10], 1);
    } else if (s_ticket < 11*u_workgroups_per_pass) {
        bool waiting;
        do {
            uint done = atomicAdd(b_counters[10], 0);
            waiting = (done != 1024*u_workgroups_per_pass);
        } while (waiting);

        uint group = s_ticket - 10*u_workgroups_per_pass;
        memoryBarrierBuffer();
        sort_65536_to_131072_2(group);
        atomicAdd(b_counters[11], 1);
    } else if (s_ticket < 12*u_workgroups_per_pass) {
        bool waiting;
        do {
            uint done = atomicAdd(b_counters[11], 0);
            waiting = (done != 1024*u_workgroups_per_pass);
        } while (waiting);

        uint group = s_ticket - 11*u_workgroups_per_pass;
        memoryBarrierBuffer();
        sort_131072_to_262144_1(group);
        atomicAdd(b_counters[12], 1);
    } else if (s_ticket < 13*u_workgroups_per_pass) {
        bool waiting;
        do {
            uint done = atomicAdd(b_counters[12], 0);
            waiting = (done != 1024*u_workgroups_per_pass);
        } while (waiting);

        uint group = s_ticket - 12*u_workgroups_per_pass;
        memoryBarrierBuffer();
        sort_131072_to_262144_2(group);
        //atomicAdd(b_counters[13], 1);
    }
}