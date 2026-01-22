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

layout (local_size_x = 1024, local_size_y = 1, local_size_z = 1) in ;

#define T uint

#define WORKGROUPS_PER_PASS <num1>

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
        uint ticket = atomicAdd(b_counters[0], 1);
        s_ticket = ticket;
        uint pass = ticket / WORKGROUPS_PER_PASS;
        if (pass > 0) {
            uint done = atomicAdd(b_counters[pass], 0);
            while (done != WORKGROUPS_PER_PASS) {
                done = atomicAdd(b_counters[pass], 0);
            } 
        }
    }
    barrier();

    uint ticket = s_ticket;
    uint pass = ticket / WORKGROUPS_PER_PASS;
    uint group = ticket % WORKGROUPS_PER_PASS;

    //if (pass > 0) memoryBarrierBuffer();

    switch (pass) {
    case 0:  sort_1_to_1024(group); break;
    case 1:  sort_1024_to_2048(group); break;
    case 2:  sort_2048_to_4096(group); break;
    case 3:  sort_4096_to_8192(group); break;
    case 4:  sort_8192_to_16384(group); break;
    case 5:  sort_16384_to_32768_1(group); break;
    case 6:  sort_16384_to_32768_2(group); break;
    case 7:  sort_32768_to_65536_1(group); break;
    case 8:  sort_32768_to_65536_2(group); break;
    case 9:  sort_65536_to_131072_1(group); break;
    case 10: sort_65536_to_131072_2(group); break;
    case 11: sort_131072_to_262144_1(group); break;
    case 12: sort_131072_to_262144_2(group); 
    default:
        return;
    }

    barrier();

    if (gl_LocalInvocationIndex == 0) {
        atomicAdd(b_counters[1+pass], 1);
    }
}