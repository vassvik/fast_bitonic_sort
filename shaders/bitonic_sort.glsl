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

T compare_and_select(T a, T b, bool select_max) {
    return select_max ? max(a, b) : min(a, b);
}

#define sid gl_SubgroupInvocationID
#define shfl(v, i) subgroupShuffleXor(v, i)

T finalize_wave(T value) {
    value = compare_and_select(value, shfl(value, 16), (sid&16) != 0);
    value = compare_and_select(value, shfl(value, 8),  (sid&8) != 0);
    value = compare_and_select(value, shfl(value, 4),  (sid&4) != 0);
    value = compare_and_select(value, shfl(value, 2),  (sid&2) != 0);
    value = compare_and_select(value, shfl(value, 1),  (sid&1) != 0);

    return value;
}

shared T s_partially_sorted[2*1024];

T finalize_1024(uint lindex, T sorted0) {
    /// sort1024
    s_partially_sorted[lindex] = sorted0;
    barrier();

    T sorted[32];
    sorted[0] = sorted0;
    sorted[1] = s_partially_sorted[lindex^(1*32)];
    sorted[2] = s_partially_sorted[lindex^(2*32)];
    sorted[3] = s_partially_sorted[lindex^(3*32)];
    sorted[4] = s_partially_sorted[lindex^(4*32)];
    sorted[5] = s_partially_sorted[lindex^(5*32)];
    sorted[6] = s_partially_sorted[lindex^(6*32)];
    sorted[7] = s_partially_sorted[lindex^(7*32)];
    sorted[8] = s_partially_sorted[lindex^(8*32)];
    sorted[9] = s_partially_sorted[lindex^(9*32)];
    sorted[10] = s_partially_sorted[lindex^(10*32)];
    sorted[11] = s_partially_sorted[lindex^(11*32)];
    sorted[12] = s_partially_sorted[lindex^(12*32)];
    sorted[13] = s_partially_sorted[lindex^(13*32)];
    sorted[14] = s_partially_sorted[lindex^(14*32)];
    sorted[15] = s_partially_sorted[lindex^(15*32)];
    sorted[16] = s_partially_sorted[lindex^(16*32)];
    sorted[17] = s_partially_sorted[lindex^(17*32)];
    sorted[18] = s_partially_sorted[lindex^(18*32)];
    sorted[19] = s_partially_sorted[lindex^(19*32)];
    sorted[20] = s_partially_sorted[lindex^(20*32)];
    sorted[21] = s_partially_sorted[lindex^(21*32)];
    sorted[22] = s_partially_sorted[lindex^(22*32)];
    sorted[23] = s_partially_sorted[lindex^(23*32)];
    sorted[24] = s_partially_sorted[lindex^(24*32)];
    sorted[25] = s_partially_sorted[lindex^(25*32)];
    sorted[26] = s_partially_sorted[lindex^(26*32)];
    sorted[27] = s_partially_sorted[lindex^(27*32)];
    sorted[28] = s_partially_sorted[lindex^(28*32)];
    sorted[29] = s_partially_sorted[lindex^(29*32)];
    sorted[30] = s_partially_sorted[lindex^(30*32)];
    sorted[31] = s_partially_sorted[lindex^(31*32)];

    sorted[0]  = compare_and_select(sorted[0],  sorted[16], (lindex^(0*32))  > (lindex^(16*32)));
    sorted[1]  = compare_and_select(sorted[1],  sorted[17], (lindex^(1*32))  > (lindex^(17*32)));
    sorted[2]  = compare_and_select(sorted[2],  sorted[18], (lindex^(2*32))  > (lindex^(18*32)));
    sorted[3]  = compare_and_select(sorted[3],  sorted[19], (lindex^(3*32))  > (lindex^(19*32)));
    sorted[4]  = compare_and_select(sorted[4],  sorted[20], (lindex^(4*32))  > (lindex^(20*32)));
    sorted[5]  = compare_and_select(sorted[5],  sorted[21], (lindex^(5*32))  > (lindex^(21*32)));
    sorted[6]  = compare_and_select(sorted[6],  sorted[22], (lindex^(6*32))  > (lindex^(22*32)));
    sorted[7]  = compare_and_select(sorted[7],  sorted[23], (lindex^(7*32))  > (lindex^(23*32)));
    sorted[8]  = compare_and_select(sorted[8],  sorted[24], (lindex^(8*32))  > (lindex^(24*32)));
    sorted[9]  = compare_and_select(sorted[9],  sorted[25], (lindex^(9*32))  > (lindex^(25*32)));
    sorted[10] = compare_and_select(sorted[10], sorted[26], (lindex^(10*32)) > (lindex^(26*32)));
    sorted[11] = compare_and_select(sorted[11], sorted[27], (lindex^(11*32)) > (lindex^(27*32)));
    sorted[12] = compare_and_select(sorted[12], sorted[28], (lindex^(12*32)) > (lindex^(28*32)));
    sorted[13] = compare_and_select(sorted[13], sorted[29], (lindex^(13*32)) > (lindex^(29*32)));
    sorted[14] = compare_and_select(sorted[14], sorted[30], (lindex^(14*32)) > (lindex^(30*32)));
    sorted[15] = compare_and_select(sorted[15], sorted[31], (lindex^(15*32)) > (lindex^(31*32)));

    sorted[0]  = compare_and_select(sorted[0],  sorted[8],  (lindex^(0*32))  > (lindex^(8*32)));
    sorted[1]  = compare_and_select(sorted[1],  sorted[9],  (lindex^(1*32))  > (lindex^(9*32)));
    sorted[2]  = compare_and_select(sorted[2],  sorted[10], (lindex^(2*32))  > (lindex^(10*32)));
    sorted[3]  = compare_and_select(sorted[3],  sorted[11], (lindex^(3*32))  > (lindex^(11*32)));
    sorted[4]  = compare_and_select(sorted[4],  sorted[12], (lindex^(4*32))  > (lindex^(12*32)));
    sorted[5]  = compare_and_select(sorted[5],  sorted[13], (lindex^(5*32))  > (lindex^(13*32)));
    sorted[6]  = compare_and_select(sorted[6],  sorted[14], (lindex^(6*32))  > (lindex^(14*32)));
    sorted[7]  = compare_and_select(sorted[7],  sorted[15], (lindex^(7*32))  > (lindex^(15*32)));

    sorted[0]  = compare_and_select(sorted[0],  sorted[4],  (lindex^(0*32))  > (lindex^(4*32)));
    sorted[1]  = compare_and_select(sorted[1],  sorted[5],  (lindex^(1*32))  > (lindex^(5*32)));
    sorted[2]  = compare_and_select(sorted[2],  sorted[6],  (lindex^(2*32))  > (lindex^(6*32)));
    sorted[3]  = compare_and_select(sorted[3],  sorted[7],  (lindex^(3*32))  > (lindex^(7*32)));
    
    sorted[0]  = compare_and_select(sorted[0],  sorted[2],  (lindex^(0*32))  > (lindex^(2*32)));
    sorted[1]  = compare_and_select(sorted[1],  sorted[3],  (lindex^(1*32))  > (lindex^(3*32)));

    sorted[0]  = compare_and_select(sorted[0],  sorted[1],  (lindex^(0*32))  > (lindex^(1*32)));

    sorted[0] = finalize_wave(sorted[0]);

    return sorted[0];
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
    //for (int i = 0; i < 32; i++) {sorted[i] = b_values_in[idx[i]]; } //barrier();
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

    if ((gid&16384) != 0) {
        sorted[0] = max(sorted[0], sorted[16]);
        sorted[1] = max(sorted[1], sorted[17]);
        sorted[2] = max(sorted[2], sorted[18]);
        sorted[3] = max(sorted[3], sorted[19]);
        sorted[4] = max(sorted[4], sorted[20]);
        sorted[5] = max(sorted[5], sorted[21]);
        sorted[6] = max(sorted[6], sorted[22]);
        sorted[7] = max(sorted[7], sorted[23]);
        sorted[8] = max(sorted[8], sorted[24]);
        sorted[9] = max(sorted[9], sorted[25]);
        sorted[10] = max(sorted[10], sorted[26]);
        sorted[11] = max(sorted[11], sorted[27]);
        sorted[12] = max(sorted[12], sorted[28]);
        sorted[13] = max(sorted[13], sorted[29]);
        sorted[14] = max(sorted[14], sorted[30]);
        sorted[15] = max(sorted[15], sorted[31]);
    } else {
        sorted[0] = min(sorted[0], sorted[16]);
        sorted[1] = min(sorted[1], sorted[17]);
        sorted[2] = min(sorted[2], sorted[18]);
        sorted[3] = min(sorted[3], sorted[19]);
        sorted[4] = min(sorted[4], sorted[20]);
        sorted[5] = min(sorted[5], sorted[21]);
        sorted[6] = min(sorted[6], sorted[22]);
        sorted[7] = min(sorted[7], sorted[23]);
        sorted[8] = min(sorted[8], sorted[24]);
        sorted[9] = min(sorted[9], sorted[25]);
        sorted[10] = min(sorted[10], sorted[26]);
        sorted[11] = min(sorted[11], sorted[27]);
        sorted[12] = min(sorted[12], sorted[28]);
        sorted[13] = min(sorted[13], sorted[29]);
        sorted[14] = min(sorted[14], sorted[30]);
        sorted[15] = min(sorted[15], sorted[31]);
    }

    if ((gid&8192) != 0) {
        sorted[0] = max(sorted[0], sorted[8]);
        sorted[1] = max(sorted[1], sorted[9]);
        sorted[2] = max(sorted[2], sorted[10]);
        sorted[3] = max(sorted[3], sorted[11]);
        sorted[4] = max(sorted[4], sorted[12]);
        sorted[5] = max(sorted[5], sorted[13]);
        sorted[6] = max(sorted[6], sorted[14]);
        sorted[7] = max(sorted[7], sorted[15]);
    } else {
        sorted[0] = min(sorted[0], sorted[8]);
        sorted[1] = min(sorted[1], sorted[9]);
        sorted[2] = min(sorted[2], sorted[10]);
        sorted[3] = min(sorted[3], sorted[11]);
        sorted[4] = min(sorted[4], sorted[12]);
        sorted[5] = min(sorted[5], sorted[13]);
        sorted[6] = min(sorted[6], sorted[14]);
        sorted[7] = min(sorted[7], sorted[15]);
    }
    if ((gid&4096) != 0) {
        sorted[0] = max(sorted[0], sorted[4]);
        sorted[1] = max(sorted[1], sorted[5]);
        sorted[2] = max(sorted[2], sorted[6]);
        sorted[3] = max(sorted[3], sorted[7]);
    } else {
        sorted[0] = min(sorted[0], sorted[4]);
        sorted[1] = min(sorted[1], sorted[5]);
        sorted[2] = min(sorted[2], sorted[6]);
        sorted[3] = min(sorted[3], sorted[7]);
    }
    if ((gid&2048) != 0) {
        sorted[0] = max(sorted[0], sorted[2]);
        sorted[1] = max(sorted[1], sorted[3]);
    } else {
        sorted[0] = min(sorted[0], sorted[2]);
        sorted[1] = min(sorted[1], sorted[3]);
    }
    if ((gid&1024) != 0) {
        sorted[0] = max(sorted[0], sorted[1]);
    } else {
        sorted[0] = min(sorted[0], sorted[1]);
    }

    //barrier();
    b_values_out[gid] = finalize_1024(lindex, sorted[0]);
} 

void main() {
    sort_16384_to_32768();
}