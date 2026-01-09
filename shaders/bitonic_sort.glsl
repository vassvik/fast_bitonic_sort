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
    value = compare_and_select(value, shfl(value, sid^1),  sid > (sid^1));

    // layer 1
    value = compare_and_select(value, shfl(value, sid^3),  sid > (sid^3));
    value = compare_and_select(value, shfl(value, sid^1),  sid > (sid^1));

    // layer 2
    value = compare_and_select(value, shfl(value, sid^7),  sid > (sid^7));
    value = compare_and_select(value, shfl(value, sid^2),  sid > (sid^2));
    value = compare_and_select(value, shfl(value, sid^1),  sid > (sid^1));

    // layer 3
    value = compare_and_select(value, shfl(value, sid^15), sid > (sid^15));
    value = compare_and_select(value, shfl(value, sid^4),  sid > (sid^4));
    value = compare_and_select(value, shfl(value, sid^2),  sid > (sid^2));
    value = compare_and_select(value, shfl(value, sid^1),  sid > (sid^1));

    // layer 4
    value = compare_and_select(value, shfl(value, sid^31), sid > (sid^31));
    value = compare_and_select(value, shfl(value, sid^8),  sid > (sid^8));
    value = compare_and_select(value, shfl(value, sid^4),  sid > (sid^4));
    value = compare_and_select(value, shfl(value, sid^2),  sid > (sid^2));
    value = compare_and_select(value, shfl(value, sid^1),  sid > (sid^1));

#if defined(FOR_WAVE64)
    // layer 5
    value = compare_and_select(value, shfl(value, sid^63), sid > (sid^63));
    value = compare_and_select(value, shfl(value, sid^16), sid > (sid^16));
    value = compare_and_select(value, shfl(value, sid^8),  sid > (sid^8));
    value = compare_and_select(value, shfl(value, sid^4),  sid > (sid^4));
    value = compare_and_select(value, shfl(value, sid^2),  sid > (sid^2));
    value = compare_and_select(value, shfl(value, sid^1),  sid > (sid^1));
#endif

    return value;
}

T finalize_wave(T value) {
#if defined(FOR_WAVE64)
    value = compare_and_select(value, shfl(value, sid^32), sid > (sid^32));
#endif
    value = compare_and_select(value, shfl(value, sid^16), sid > (sid^16));
    value = compare_and_select(value, shfl(value, sid^8),  sid > (sid^8));
    value = compare_and_select(value, shfl(value, sid^4),  sid > (sid^4));
    value = compare_and_select(value, shfl(value, sid^2),  sid > (sid^2));
    value = compare_and_select(value, shfl(value, sid^1),  sid > (sid^1));

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
    for (int i = 0; i < 2; i++) {sorted[i] = b_values_in[idx[i]];  } barrier();
    for (int i = 0; i < 1; i++) {sorted[i] = compare_and_select(sorted[i], sorted[i+1], (gid&1024) != 0);  } barrier();

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
    for (int i = 0; i < 4; i++) {sorted[i] = b_values_in[idx[i]];  } barrier();
    for (int i = 0; i < 2; i++) {sorted[i] = compare_and_select(sorted[i], sorted[i+2], (gid&2048) != 0);  } barrier();
    for (int i = 0; i < 1; i++) {sorted[i] = compare_and_select(sorted[i], sorted[i+1], (gid&1024) != 0);  } barrier();

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
    for (int i = 0; i < 8; i++) {sorted[i] = b_values_in[idx[i]];  } barrier();
    for (int i = 0; i < 4; i++) {sorted[i] = compare_and_select(sorted[i], sorted[i+4], (gid&4096) != 0);  } barrier();
    for (int i = 0; i < 2; i++) {sorted[i] = compare_and_select(sorted[i], sorted[i+2], (gid&2048) != 0);  } barrier();
    for (int i = 0; i < 1; i++) {sorted[i] = compare_and_select(sorted[i], sorted[i+1], (gid&1024) != 0);  } barrier();

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
    for (int i = 0; i < 16; i++) {sorted[i] = b_values_in[idx[i]];  } barrier();
    for (int i = 0; i < 8;  i++) {sorted[i] = compare_and_select(sorted[i], sorted[i+8], (gid&8192) != 0);  } barrier();
    for (int i = 0; i < 4;  i++) {sorted[i] = compare_and_select(sorted[i], sorted[i+4], (gid&4096) != 0);  } barrier();
    for (int i = 0; i < 2;  i++) {sorted[i] = compare_and_select(sorted[i], sorted[i+2], (gid&2048) != 0);  } barrier();
    for (int i = 0; i < 1;  i++) {sorted[i] = compare_and_select(sorted[i], sorted[i+1], (gid&1024) != 0);  } barrier();

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
    for (int i = 0; i < 32; i++) {sorted[i] = b_values_in[idx[i]];  } barrier();
    for (int i = 0; i < 16; i++) {sorted[i] = compare_and_select(sorted[i], sorted[i+16], (gid&16384) != 0);  } barrier();
    for (int i = 0; i < 8;  i++) {sorted[i] = compare_and_select(sorted[i], sorted[i+8],  (gid&8192) != 0);   } barrier();
    for (int i = 0; i < 4;  i++) {sorted[i] = compare_and_select(sorted[i], sorted[i+4],  (gid&4096) != 0);   } barrier();
    for (int i = 0; i < 2;  i++) {sorted[i] = compare_and_select(sorted[i], sorted[i+2],  (gid&2048) != 0);   } barrier();
    for (int i = 0; i < 1;  i++) {sorted[i] = compare_and_select(sorted[i], sorted[i+1],  (gid&1024) != 0);   } barrier();

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
    for (int i = 0; i < 64; i++) {sorted[i] = b_values_in[idx[i]]; barrier(); }
    for (int i = 0; i < 32; i++) {sorted[i] = compare_and_select(sorted[i], sorted[i+32], (gid&32768) != 0); barrier(); }
    for (int i = 0; i < 16; i++) {sorted[i] = compare_and_select(sorted[i], sorted[i+16], (gid&16384) != 0); barrier(); }
    for (int i = 0; i < 8;  i++) {sorted[i] = compare_and_select(sorted[i], sorted[i+8],  (gid&8192) != 0);  barrier(); }
    for (int i = 0; i < 4;  i++) {sorted[i] = compare_and_select(sorted[i], sorted[i+4],  (gid&4096) != 0);  barrier(); }
    for (int i = 0; i < 2;  i++) {sorted[i] = compare_and_select(sorted[i], sorted[i+2],  (gid&2048) != 0);  barrier(); }
    for (int i = 0; i < 1;  i++) {sorted[i] = compare_and_select(sorted[i], sorted[i+1],  (gid&1024) != 0);  barrier(); }

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