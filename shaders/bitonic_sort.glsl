#version 460 core

#extension GL_KHR_shader_subgroup_basic : require
#extension GL_KHR_shader_subgroup_shuffle : require

layout (binding = 0, std430) buffer buffer_0 {
  uint[] b_values_in;
};

layout (binding = 1, std430) buffer buffer_1 {
  uint[] b_values_out;
};

layout (local_size_x = 1024, local_size_y = 1, local_size_z = 1) in ;

#define T uint

#define USE<stage>
#define FOR_WAVE32

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
    value = compare_and_select(value, shfl(value, sid^1),  (sid&1) != 0);

    // layer 1
    value = compare_and_select(value, shfl(value, sid^3),  (sid&2) != 0);
    value = compare_and_select(value, shfl(value, sid^1),  (sid&1) != 0);

    // layer 2
    value = compare_and_select(value, shfl(value, sid^7),  (sid&4) != 0);
    value = compare_and_select(value, shfl(value, sid^2),  (sid&2) != 0);
    value = compare_and_select(value, shfl(value, sid^1),  (sid&1) != 0);

    // layer 3
    value = compare_and_select(value, shfl(value, sid^15), (sid&8) != 0);
    value = compare_and_select(value, shfl(value, sid^4),  (sid&4) != 0);
    value = compare_and_select(value, shfl(value, sid^2),  (sid&2) != 0);
    value = compare_and_select(value, shfl(value, sid^1),  (sid&1) != 0);

    // layer 4
    value = compare_and_select(value, shfl(value, sid^31), (sid&16) != 0);
    value = compare_and_select(value, shfl(value, sid^8),  (sid&8) != 0);
    value = compare_and_select(value, shfl(value, sid^4),  (sid&4) != 0);
    value = compare_and_select(value, shfl(value, sid^2),  (sid&2) != 0);
    value = compare_and_select(value, shfl(value, sid^1),  (sid&1) != 0);

#if defined(FOR_WAVE64)
    // layer 5
    value = compare_and_select(value, shfl(value, sid^63), (sid&32) != 0);
    value = compare_and_select(value, shfl(value, sid^16), (sid&16) != 0);
    value = compare_and_select(value, shfl(value, sid^8),  (sid&8) != 0);
    value = compare_and_select(value, shfl(value, sid^4),  (sid&4) != 0);
    value = compare_and_select(value, shfl(value, sid^2),  (sid&2) != 0);
    value = compare_and_select(value, shfl(value, sid^1),  (sid&1) != 0);
#endif

    return value;
}

T finalize_wave(T value) {
#if defined(FOR_WAVE64)
    value = compare_and_select(value, shfl(value, sid^32), (sid&32) != 0);
#endif
    value = compare_and_select(value, shfl(value, sid^16), (sid&16) != 0);
    value = compare_and_select(value, shfl(value, sid^8),  (sid&8) != 0);
    value = compare_and_select(value, shfl(value, sid^4),  (sid&4) != 0);
    value = compare_and_select(value, shfl(value, sid^2),  (sid&2) != 0);
    value = compare_and_select(value, shfl(value, sid^1),  (sid&1) != 0);

    return value;
}

shared T s_partially_sorted[2*1024];

T finalize_1024(uint lindex, T sorted0) {
    /// sort1024
    s_partially_sorted[lindex] = sorted0;
    barrier();
    T sorted1 = s_partially_sorted[lindex^(1*128)];
    T sorted2 = s_partially_sorted[lindex^(2*128)];
    T sorted3 = s_partially_sorted[lindex^(3*128)];
    T sorted4 = s_partially_sorted[lindex^(4*128)];
    T sorted5 = s_partially_sorted[lindex^(5*128)];
    T sorted6 = s_partially_sorted[lindex^(6*128)];
    T sorted7 = s_partially_sorted[lindex^(7*128)];

    sorted0 = compare_and_select(sorted0, sorted4, (lindex^(0*128)) > (lindex^(4*128)));
    sorted1 = compare_and_select(sorted1, sorted5, (lindex^(1*128)) > (lindex^(5*128)));
    sorted2 = compare_and_select(sorted2, sorted6, (lindex^(2*128)) > (lindex^(6*128)));
    sorted3 = compare_and_select(sorted3, sorted7, (lindex^(3*128)) > (lindex^(7*128)));

    sorted0 = compare_and_select(sorted0, sorted2, (lindex^(0*128)) > (lindex^(2*128)));
    sorted1 = compare_and_select(sorted1, sorted3, (lindex^(1*128)) > (lindex^(3*128)));

    sorted0 = compare_and_select(sorted0, sorted1, (lindex^(0*128)) > (lindex^(1*128)));

    lindex = lindex^1024;
    s_partially_sorted[(lindex)] = sorted0;
    barrier();

#if defined(FOR_WAVE32)
    sorted1 = s_partially_sorted[lindex^(1*32)];
    sorted2 = s_partially_sorted[lindex^(2*32)];
    sorted3 = s_partially_sorted[lindex^(3*32)];

    sorted0 = compare_and_select(sorted0, sorted2, (lindex^(0*32)) > (lindex^(2*32)));
    sorted1 = compare_and_select(sorted1, sorted3, (lindex^(1*32)) > (lindex^(3*32)));

    sorted0 = compare_and_select(sorted0, sorted1, (lindex^(0*32)) > (lindex^(1*32)));
#else
    sorted1 = s_partially_sorted[lindex^(1*64)];

    sorted0 = compare_and_select(sorted0, sorted1, (lindex^(0*64)) > (lindex^(1*64)));
#endif
    sorted0 = finalize_wave(sorted0);

    return sorted0;
}

void sort_1_to_1024() {
    uint lindex = gl_LocalInvocationIndex;
    uint gid = 1024 * gl_WorkGroupID.x + lindex;

    T sorted1, sorted2, sorted3, sorted4, sorted5, sorted6, sorted7;
    T sorted0 = b_values_in[gid];

#if defined(FOR_WAVE32)
    /// sort32
    sorted0 = sort_wave(sorted0);

    /// sort64
    lindex = lindex^1024;
    s_partially_sorted[(lindex)] = sorted0;
    barrier();
    sorted1 = s_partially_sorted[(lindex^63)];
    sorted0 = compare_and_select(sorted0, sorted1, lindex > (lindex^63));

    sorted0 = finalize_wave(sorted0);
#else
    /// sort64
    sorted0 = sort_wave(sorted0);
#endif

    /// sort128
    lindex = lindex^1024;
    s_partially_sorted[(lindex)] = sorted0;
    barrier();

#if defined(FOR_WAVE32)
    sorted1 = s_partially_sorted[(lindex^(1*32))];
    sorted2 = s_partially_sorted[(lindex^(2*32))];
    sorted3 = s_partially_sorted[(lindex^(3*32))];
    sorted4 = s_partially_sorted[(lindex^(0*32)^127)];
    sorted5 = s_partially_sorted[(lindex^(1*32)^127)];
    sorted6 = s_partially_sorted[(lindex^(2*32)^127)];
    sorted7 = s_partially_sorted[(lindex^(3*32)^127)];

    sorted0 = compare_and_select(sorted0, sorted4, (lindex^(0*32)) > (lindex^(0*32)^127));
    sorted1 = compare_and_select(sorted1, sorted5, (lindex^(1*32)) > (lindex^(1*32)^127));
    sorted2 = compare_and_select(sorted2, sorted6, (lindex^(2*32)) > (lindex^(2*32)^127));
    sorted3 = compare_and_select(sorted3, sorted7, (lindex^(3*32)) > (lindex^(3*32)^127));

    sorted0 = compare_and_select(sorted0, sorted2, (lindex^(0*32)) > (lindex^(2*32)));
    sorted1 = compare_and_select(sorted1, sorted3, (lindex^(1*32)) > (lindex^(3*32)));

    sorted0 = compare_and_select(sorted0, sorted1, (lindex^(0*32)) > (lindex^(1*32)));
#else
    sorted1 = s_partially_sorted[(lindex^(1*64))];
    sorted2 = s_partially_sorted[(lindex^(0*64)^127)];
    sorted3 = s_partially_sorted[(lindex^(1*64)^127)];

    sorted0 = compare_and_select(sorted0, sorted2, (lindex^(0*64)) > (lindex^(0*64)^127));
    sorted1 = compare_and_select(sorted1, sorted3, (lindex^(1*64)) > (lindex^(1*64)^127));

    sorted0 = compare_and_select(sorted0, sorted1, (lindex^(0*64)) > (lindex^(1*64)));
#endif
    sorted0 = finalize_wave(sorted0);

    /// sort256
    lindex = lindex^1024;
    s_partially_sorted[(lindex)] = sorted0;
    barrier();

#if defined(FOR_WAVE32)
    sorted1 = s_partially_sorted[(lindex^(1*32))];
    sorted2 = s_partially_sorted[(lindex^(2*32))];
    sorted3 = s_partially_sorted[(lindex^(3*32))];
    sorted4 = s_partially_sorted[(lindex^(0*32)^255)];
    sorted5 = s_partially_sorted[(lindex^(1*32)^255)];
    sorted6 = s_partially_sorted[(lindex^(2*32)^255)];
    sorted7 = s_partially_sorted[(lindex^(3*32)^255)];

    sorted0 = compare_and_select(sorted0, sorted4, (lindex^(0*32)) > (lindex^(0*32)^255));
    sorted1 = compare_and_select(sorted1, sorted5, (lindex^(1*32)) > (lindex^(1*32)^255));
    sorted2 = compare_and_select(sorted2, sorted6, (lindex^(2*32)) > (lindex^(2*32)^255));
    sorted3 = compare_and_select(sorted3, sorted7, (lindex^(3*32)) > (lindex^(3*32)^255));

    sorted0 = compare_and_select(sorted0, sorted2, (lindex^(0*32)) > (lindex^(2*32)));
    sorted1 = compare_and_select(sorted1, sorted3, (lindex^(1*32)) > (lindex^(3*32)));

    sorted0 = compare_and_select(sorted0, sorted1, (lindex^(0*32)) > (lindex^(1*32)));

    sorted0 = finalize_wave(sorted0);
#else 
    sorted1 = s_partially_sorted[(lindex^(1*64))];
    sorted2 = s_partially_sorted[(lindex^(0*64)^255)];
    sorted3 = s_partially_sorted[(lindex^(1*64)^255)];

    sorted0 = compare_and_select(sorted0, sorted2, (lindex^(0*64)) > (lindex^(0*64)^255));
    sorted1 = compare_and_select(sorted1, sorted3, (lindex^(1*64)) > (lindex^(1*64)^255));

    sorted0 = compare_and_select(sorted0, sorted1, (lindex^(0*64)) > (lindex^(1*64)));

    sorted0 = finalize_wave(sorted0);
#endif

    /// sort512
    lindex = lindex^1024;
    s_partially_sorted[(lindex)] = sorted0;
    barrier();

    sorted1 = s_partially_sorted[(lindex^(1*128))];
    sorted2 = s_partially_sorted[(lindex^(0*128)^511)];
    sorted3 = s_partially_sorted[(lindex^(1*128)^511)];

    sorted0 = compare_and_select(sorted0, sorted2, (lindex^(0*128)) > (lindex^(0*128)^511));
    sorted1 = compare_and_select(sorted1, sorted3, (lindex^(1*128)) > (lindex^(1*128)^511));

    sorted0 = compare_and_select(sorted0, sorted1, (lindex^(0*128)) > (lindex^(1*128)));

    lindex = lindex^1024;
    s_partially_sorted[(lindex)] = sorted0;
    barrier();

#if defined(FOR_WAVE32)
    sorted1 = s_partially_sorted[(lindex^(1*32))];
    sorted2 = s_partially_sorted[(lindex^(0*32)^64)];
    sorted3 = s_partially_sorted[(lindex^(1*32)^64)];

    sorted0 = compare_and_select(sorted0, sorted2, (lindex^(0*32)) > (lindex^(0*32)^64));
    sorted1 = compare_and_select(sorted1, sorted3, (lindex^(1*32)) > (lindex^(1*32)^64));

    sorted0 = compare_and_select(sorted0, sorted1, (lindex^(0*32)) > (lindex^(1*32)));

    sorted0 = finalize_wave(sorted0);
#else 
    sorted1 = s_partially_sorted[(lindex^(0*64)^64)];

    sorted0 = compare_and_select(sorted0, sorted1, (lindex^(0*64)) > (lindex^(0*64)^64));

    sorted0 = finalize_wave(sorted0);
#endif

    /// sort1024
    lindex = lindex^1024;
    s_partially_sorted[(lindex)] = sorted0;
    barrier();
    sorted1 = s_partially_sorted[(lindex^(1*256))];
    sorted2 = s_partially_sorted[(lindex^(0*256)^1023)];
    sorted3 = s_partially_sorted[(lindex^(1*256)^1023)];

    sorted0 = compare_and_select(sorted0, sorted2, (lindex^(0*256)) > (lindex^(0*256)^1023));
    sorted1 = compare_and_select(sorted1, sorted3, (lindex^(1*256)) > (lindex^(1*256)^1023));

    sorted0 = compare_and_select(sorted0, sorted1, (lindex^(0*256)) > (lindex^(1*256)));

    lindex = lindex^1024;
    s_partially_sorted[(lindex)] = sorted0;
    barrier();

#if defined(FOR_WAVE32)
    sorted1 = s_partially_sorted[(lindex^(1*32))];
    sorted2 = s_partially_sorted[(lindex^(2*32))];
    sorted3 = s_partially_sorted[(lindex^(3*32))];
    sorted4 = s_partially_sorted[(lindex^(0*32)^128)];
    sorted5 = s_partially_sorted[(lindex^(1*32)^128)];
    sorted6 = s_partially_sorted[(lindex^(2*32)^128)];
    sorted7 = s_partially_sorted[(lindex^(3*32)^128)];

    sorted0 = compare_and_select(sorted0, sorted4, (lindex^(0*32)) > (lindex^(0*32)^128));
    sorted1 = compare_and_select(sorted1, sorted5, (lindex^(1*32)) > (lindex^(1*32)^128));
    sorted2 = compare_and_select(sorted2, sorted6, (lindex^(2*32)) > (lindex^(2*32)^128));
    sorted3 = compare_and_select(sorted3, sorted7, (lindex^(3*32)) > (lindex^(3*32)^128));

    sorted0 = compare_and_select(sorted0, sorted2, (lindex^(0*32)) > (lindex^(2*32)));
    sorted1 = compare_and_select(sorted1, sorted3, (lindex^(1*32)) > (lindex^(3*32)));

    sorted0 = compare_and_select(sorted0, sorted1, (lindex^(0*32)) > (lindex^(1*32)));
#else
    sorted1 = s_partially_sorted[(lindex^(1*64))];
    sorted2 = s_partially_sorted[(lindex^(0*64)^128)];
    sorted3 = s_partially_sorted[(lindex^(1*64)^128)];

    sorted0 = compare_and_select(sorted0, sorted2, (lindex^(0*64)) > (lindex^(0*64)^128));
    sorted1 = compare_and_select(sorted1, sorted3, (lindex^(1*64)) > (lindex^(1*64)^128));

    sorted0 = compare_and_select(sorted0, sorted1, (lindex^(0*64)) > (lindex^(1*64)));
#endif
    sorted0 = finalize_wave(sorted0);

    ///
    b_values_out[gid] = sorted0; 
} 

void sort_1024_to_2048() {
    uint lindex = gl_LocalInvocationIndex;
    uint gid = 1024 * gl_WorkGroupID.x + lindex;

    uint idx[2];
    for (int i = 0; i < 1; i++) {
        idx[i]   = gid^(i*1024);
        idx[1+i] = idx[i]^(2*1024-1);
    }

    T sorted[2];
    for (int i = 0; i < 2; i++) {sorted[i] = b_values_in[idx[i]];  } //barrier();
    for (int i = 0; i < 1; i++) {sorted[i] = compare_and_select(sorted[i], sorted[i+1], (gid&1024) != 0);  } //barrier();
    barrier();
    b_values_out[gid] = finalize_1024(lindex, sorted[0]);
} 

void sort_2048_to_4096() {
    uint lindex = gl_LocalInvocationIndex;
    uint gid = 1024 * gl_WorkGroupID.x + lindex;

    uint idx[4];
    for (int i = 0; i < 2; i++) {
        idx[i]   = gid^(i*1024);
        idx[2+i] = idx[i]^(4*1024-1);
    }

    T sorted[4];
    for (int i = 0; i < 4; i++) {sorted[i] = b_values_in[idx[i]];  } //barrier();
    for (int i = 0; i < 2; i++) {sorted[i] = compare_and_select(sorted[i], sorted[i+2], (gid&2048) != 0);  } //barrier();
    for (int i = 0; i < 1; i++) {sorted[i] = compare_and_select(sorted[i], sorted[i+1], (gid&1024) != 0);  } //barrier();
    barrier();
    b_values_out[gid] = finalize_1024(lindex, sorted[0]);
} 

void sort_4096_to_8192() {
    uint lindex = gl_LocalInvocationIndex;
    uint gid = 1024 * gl_WorkGroupID.x + lindex;

    uint idx[8];
    for (int i = 0; i < 4; i++) {
        idx[i]   = gid^(i*1024);
        idx[4+i] = idx[i]^(8*1024-1);
    }

    T sorted[8];
    for (int i = 0; i < 8; i++) {sorted[i] = b_values_in[idx[i]];  } //barrier();
    for (int i = 0; i < 4; i++) {sorted[i] = compare_and_select(sorted[i], sorted[i+4], (gid&4096) != 0);  } //barrier();
    for (int i = 0; i < 2; i++) {sorted[i] = compare_and_select(sorted[i], sorted[i+2], (gid&2048) != 0);  } //barrier();
    for (int i = 0; i < 1; i++) {sorted[i] = compare_and_select(sorted[i], sorted[i+1], (gid&1024) != 0);  } //barrier();
    barrier();
    b_values_out[gid] = finalize_1024(lindex, sorted[0]);
} 

void sort_8192_to_16384() {
    uint lindex = gl_LocalInvocationIndex;
    uint gid = 1024 * gl_WorkGroupID.x + lindex;

    uint idx[16];
    for (int i = 0; i < 8; i++) {
        idx[i]   = gid^(i*1024);
        idx[8+i] = idx[i]^(16*1024-1);
    }

    T sorted[16];
    for (int i = 0; i < 16; i++) {sorted[i] = b_values_in[idx[i]];  } //barrier();
    for (int i = 0; i < 8;  i++) {sorted[i] = compare_and_select(sorted[i], sorted[i+8], (gid&8192) != 0);  } //barrier();
    for (int i = 0; i < 4;  i++) {sorted[i] = compare_and_select(sorted[i], sorted[i+4], (gid&4096) != 0);  } //barrier();
    for (int i = 0; i < 2;  i++) {sorted[i] = compare_and_select(sorted[i], sorted[i+2], (gid&2048) != 0);  } //barrier();
    for (int i = 0; i < 1;  i++) {sorted[i] = compare_and_select(sorted[i], sorted[i+1], (gid&1024) != 0);  } //barrier();
    barrier();
    b_values_out[gid] = finalize_1024(lindex, sorted[0]);
} 

void sort_16384_to_32768() {
    uint lindex = gl_LocalInvocationIndex;
    uint gid = 1024 * gl_WorkGroupID.x + lindex;

    uint idx[32];
    for (int i = 0; i < 16; i++) {
        idx[i]    = gid^(i*1024);
        idx[16+i] = idx[i]^(32*1024-1);
    }

    T sorted[32];
    for (int i = 0; i < 32; i++) {sorted[i] = b_values_in[idx[i]];  } //barrier();
    for (int i = 0; i < 16; i++) {sorted[i] = compare_and_select(sorted[i], sorted[i+16], (gid&16384) != 0);  } //barrier();
    for (int i = 0; i < 8;  i++) {sorted[i] = compare_and_select(sorted[i], sorted[i+8],  (gid&8192) != 0);   } //barrier();
    for (int i = 0; i < 4;  i++) {sorted[i] = compare_and_select(sorted[i], sorted[i+4],  (gid&4096) != 0);   } //barrier();
    for (int i = 0; i < 2;  i++) {sorted[i] = compare_and_select(sorted[i], sorted[i+2],  (gid&2048) != 0);   } //barrier();
    for (int i = 0; i < 1;  i++) {sorted[i] = compare_and_select(sorted[i], sorted[i+1],  (gid&1024) != 0);   } //barrier();
    barrier();
    b_values_out[gid] = finalize_1024(lindex, sorted[0]);
} 

void sort_32768_to_65536() {
    uint lindex = gl_LocalInvocationIndex;
    uint gid = 1024 * gl_WorkGroupID.x + lindex;

    uint idx[64];
    for (int i = 0; i < 32; i++) {
        idx[i]    = gid^(i*1024);
        idx[32+i] = idx[i]^(64*1024-1);
    }

    T sorted[64];
    //for (int i = 0; i < 64; i++) {sorted[i] = b_values_in[idx[i]]; } //barrier();
    //for (int i = 0; i < 32; i++) {sorted[i] = compare_and_select(sorted[i], sorted[i+32], (gid&32768) != 0); } //barrier();
    //for (int i = 0; i < 16; i++) {sorted[i] = compare_and_select(sorted[i], sorted[i+16], (gid&16384) != 0); } //barrier();
    //for (int i = 0; i < 8;  i++) {sorted[i] = compare_and_select(sorted[i], sorted[i+8],  (gid&8192) != 0);  } //barrier();
    //for (int i = 0; i < 4;  i++) {sorted[i] = compare_and_select(sorted[i], sorted[i+4],  (gid&4096) != 0);  } //barrier();
    //for (int i = 0; i < 2;  i++) {sorted[i] = compare_and_select(sorted[i], sorted[i+2],  (gid&2048) != 0);  } //barrier();
    //for (int i = 0; i < 1;  i++) {sorted[i] = compare_and_select(sorted[i], sorted[i+1],  (gid&1024) != 0);  } //barrier();

    sorted[0] = b_values_in[idx[0]];
    sorted[1] = b_values_in[idx[1]];
    sorted[2] = b_values_in[idx[2]];
    sorted[3] = b_values_in[idx[3]];
    sorted[4] = b_values_in[idx[4]];
    sorted[5] = b_values_in[idx[5]];
    sorted[6] = b_values_in[idx[6]];
    sorted[7] = b_values_in[idx[7]];
    sorted[8] = b_values_in[idx[8]];
    sorted[9] = b_values_in[idx[9]];
    sorted[10] = b_values_in[idx[10]];
    sorted[11] = b_values_in[idx[11]];
    sorted[12] = b_values_in[idx[12]];
    sorted[13] = b_values_in[idx[13]];
    sorted[14] = b_values_in[idx[14]];
    sorted[15] = b_values_in[idx[15]];
    sorted[16] = b_values_in[idx[16]];
    sorted[17] = b_values_in[idx[17]];
    sorted[18] = b_values_in[idx[18]];
    sorted[19] = b_values_in[idx[19]];
    sorted[20] = b_values_in[idx[20]];
    sorted[21] = b_values_in[idx[21]];
    sorted[22] = b_values_in[idx[22]];
    sorted[23] = b_values_in[idx[23]];
    sorted[24] = b_values_in[idx[24]];
    sorted[25] = b_values_in[idx[25]];
    sorted[26] = b_values_in[idx[26]];
    sorted[27] = b_values_in[idx[27]];
    sorted[28] = b_values_in[idx[28]];
    sorted[29] = b_values_in[idx[29]];
    sorted[30] = b_values_in[idx[30]];
    sorted[31] = b_values_in[idx[31]];
    sorted[32] = b_values_in[idx[32]];
    sorted[33] = b_values_in[idx[33]];
    sorted[34] = b_values_in[idx[34]];
    sorted[35] = b_values_in[idx[35]];
    sorted[36] = b_values_in[idx[36]];
    sorted[37] = b_values_in[idx[37]];
    sorted[38] = b_values_in[idx[38]];
    sorted[39] = b_values_in[idx[39]];
    sorted[40] = b_values_in[idx[40]];
    sorted[41] = b_values_in[idx[41]];
    sorted[42] = b_values_in[idx[42]];
    sorted[43] = b_values_in[idx[43]];
    sorted[44] = b_values_in[idx[44]];
    sorted[45] = b_values_in[idx[45]];
    sorted[46] = b_values_in[idx[46]];
    sorted[47] = b_values_in[idx[47]];
    sorted[48] = b_values_in[idx[48]];
    sorted[49] = b_values_in[idx[49]];
    sorted[50] = b_values_in[idx[50]];
    sorted[51] = b_values_in[idx[51]];
    sorted[52] = b_values_in[idx[52]];
    sorted[53] = b_values_in[idx[53]];
    sorted[54] = b_values_in[idx[54]];
    sorted[55] = b_values_in[idx[55]];
    sorted[56] = b_values_in[idx[56]];
    sorted[57] = b_values_in[idx[57]];
    sorted[58] = b_values_in[idx[58]];
    sorted[59] = b_values_in[idx[59]];
    sorted[60] = b_values_in[idx[60]];
    sorted[61] = b_values_in[idx[61]];
    sorted[62] = b_values_in[idx[62]];
    sorted[63] = b_values_in[idx[63]];
    sorted[0] = compare_and_select(sorted[0], sorted[32], (gid&32768) != 0);
    sorted[1] = compare_and_select(sorted[1], sorted[33], (gid&32768) != 0);
    sorted[2] = compare_and_select(sorted[2], sorted[34], (gid&32768) != 0);
    sorted[3] = compare_and_select(sorted[3], sorted[35], (gid&32768) != 0);
    sorted[4] = compare_and_select(sorted[4], sorted[36], (gid&32768) != 0);
    sorted[5] = compare_and_select(sorted[5], sorted[37], (gid&32768) != 0);
    sorted[6] = compare_and_select(sorted[6], sorted[38], (gid&32768) != 0);
    sorted[7] = compare_and_select(sorted[7], sorted[39], (gid&32768) != 0);
    sorted[8] = compare_and_select(sorted[8], sorted[40], (gid&32768) != 0);
    sorted[9] = compare_and_select(sorted[9], sorted[41], (gid&32768) != 0);
    sorted[10] = compare_and_select(sorted[10], sorted[42], (gid&32768) != 0);
    sorted[11] = compare_and_select(sorted[11], sorted[43], (gid&32768) != 0);
    sorted[12] = compare_and_select(sorted[12], sorted[44], (gid&32768) != 0);
    sorted[13] = compare_and_select(sorted[13], sorted[45], (gid&32768) != 0);
    sorted[14] = compare_and_select(sorted[14], sorted[46], (gid&32768) != 0);
    sorted[15] = compare_and_select(sorted[15], sorted[47], (gid&32768) != 0);
    sorted[16] = compare_and_select(sorted[16], sorted[48], (gid&32768) != 0);
    sorted[17] = compare_and_select(sorted[17], sorted[49], (gid&32768) != 0);
    sorted[18] = compare_and_select(sorted[18], sorted[50], (gid&32768) != 0);
    sorted[19] = compare_and_select(sorted[19], sorted[51], (gid&32768) != 0);
    sorted[20] = compare_and_select(sorted[20], sorted[52], (gid&32768) != 0);
    sorted[21] = compare_and_select(sorted[21], sorted[53], (gid&32768) != 0);
    sorted[22] = compare_and_select(sorted[22], sorted[54], (gid&32768) != 0);
    sorted[23] = compare_and_select(sorted[23], sorted[55], (gid&32768) != 0);
    sorted[24] = compare_and_select(sorted[24], sorted[56], (gid&32768) != 0);
    sorted[25] = compare_and_select(sorted[25], sorted[57], (gid&32768) != 0);
    sorted[26] = compare_and_select(sorted[26], sorted[58], (gid&32768) != 0);
    sorted[27] = compare_and_select(sorted[27], sorted[59], (gid&32768) != 0);
    sorted[28] = compare_and_select(sorted[28], sorted[60], (gid&32768) != 0);
    sorted[29] = compare_and_select(sorted[29], sorted[61], (gid&32768) != 0);
    sorted[30] = compare_and_select(sorted[30], sorted[62], (gid&32768) != 0);
    sorted[31] = compare_and_select(sorted[31], sorted[63], (gid&32768) != 0);
    sorted[0] = compare_and_select(sorted[0], sorted[16], (gid&16384) != 0);
    sorted[1] = compare_and_select(sorted[1], sorted[17], (gid&16384) != 0);
    sorted[2] = compare_and_select(sorted[2], sorted[18], (gid&16384) != 0);
    sorted[3] = compare_and_select(sorted[3], sorted[19], (gid&16384) != 0);
    sorted[4] = compare_and_select(sorted[4], sorted[20], (gid&16384) != 0);
    sorted[5] = compare_and_select(sorted[5], sorted[21], (gid&16384) != 0);
    sorted[6] = compare_and_select(sorted[6], sorted[22], (gid&16384) != 0);
    sorted[7] = compare_and_select(sorted[7], sorted[23], (gid&16384) != 0);
    sorted[8] = compare_and_select(sorted[8], sorted[24], (gid&16384) != 0);
    sorted[9] = compare_and_select(sorted[9], sorted[25], (gid&16384) != 0);
    sorted[10] = compare_and_select(sorted[10], sorted[26], (gid&16384) != 0);
    sorted[11] = compare_and_select(sorted[11], sorted[27], (gid&16384) != 0);
    sorted[12] = compare_and_select(sorted[12], sorted[28], (gid&16384) != 0);
    sorted[13] = compare_and_select(sorted[13], sorted[29], (gid&16384) != 0);
    sorted[14] = compare_and_select(sorted[14], sorted[30], (gid&16384) != 0);
    sorted[15] = compare_and_select(sorted[15], sorted[31], (gid&16384) != 0);
    sorted[0] = compare_and_select(sorted[0], sorted[8],  (gid&8192) != 0);
    sorted[1] = compare_and_select(sorted[1], sorted[9],  (gid&8192) != 0);
    sorted[2] = compare_and_select(sorted[2], sorted[10],  (gid&8192) != 0);
    sorted[3] = compare_and_select(sorted[3], sorted[11],  (gid&8192) != 0);
    sorted[4] = compare_and_select(sorted[4], sorted[12],  (gid&8192) != 0);
    sorted[5] = compare_and_select(sorted[5], sorted[13],  (gid&8192) != 0);
    sorted[6] = compare_and_select(sorted[6], sorted[14],  (gid&8192) != 0);
    sorted[7] = compare_and_select(sorted[7], sorted[15],  (gid&8192) != 0);
    sorted[0] = compare_and_select(sorted[0], sorted[4],  (gid&4096) != 0);
    sorted[1] = compare_and_select(sorted[1], sorted[5],  (gid&4096) != 0);
    sorted[2] = compare_and_select(sorted[2], sorted[6],  (gid&4096) != 0);
    sorted[3] = compare_and_select(sorted[3], sorted[7],  (gid&4096) != 0);
    sorted[0] = compare_and_select(sorted[0], sorted[2],  (gid&2048) != 0);
    sorted[1] = compare_and_select(sorted[1], sorted[3],  (gid&2048) != 0);
    sorted[0] = compare_and_select(sorted[0], sorted[1],  (gid&1024) != 0);

    //barrier();
    b_values_out[gid] = finalize_1024(lindex, sorted[0]);
} 

void main() {
#if defined(USE_1024)
    sort_1_to_1024();
#elif defined(USE_2048)
    sort_1024_to_2048();
#elif defined(USE_4096)
    sort_2048_to_4096();
#elif defined(USE_8192)
    sort_4096_to_8192();
#elif defined(USE_16384)
    sort_8192_to_16384();
#elif defined(USE_32768)
    sort_16384_to_32768();
#elif defined(USE_65536)
    sort_32768_to_65536();
#endif
}