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
    sorted[0]  = sorted0;
    sorted[1]  = s_partially_sorted[lindex^(1*32)];
    sorted[2]  = s_partially_sorted[lindex^(2*32)];
    sorted[3]  = s_partially_sorted[lindex^(3*32)];
    sorted[4]  = s_partially_sorted[lindex^(4*32)];
    sorted[5]  = s_partially_sorted[lindex^(5*32)];
    sorted[6]  = s_partially_sorted[lindex^(6*32)];
    sorted[7]  = s_partially_sorted[lindex^(7*32)];
    sorted[8]  = s_partially_sorted[lindex^(8*32)];
    sorted[9]  = s_partially_sorted[lindex^(9*32)];
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

    T sorted[32];
    sorted[0]  = b_values_in[gid^(0*1024)];
    sorted[1]  = b_values_in[gid^(1*1024)];
    sorted[2]  = b_values_in[gid^(2*1024)];
    sorted[3]  = b_values_in[gid^(3*1024)];
    sorted[4]  = b_values_in[gid^(4*1024)];
    sorted[5]  = b_values_in[gid^(5*1024)];
    sorted[6]  = b_values_in[gid^(6*1024)];
    sorted[7]  = b_values_in[gid^(7*1024)];
    sorted[8]  = b_values_in[gid^(8*1024)];
    sorted[9]  = b_values_in[gid^(9*1024)];
    sorted[10] = b_values_in[gid^(10*1024)];
    sorted[11] = b_values_in[gid^(11*1024)];
    sorted[12] = b_values_in[gid^(12*1024)];
    sorted[13] = b_values_in[gid^(13*1024)];
    sorted[14] = b_values_in[gid^(14*1024)];
    sorted[15] = b_values_in[gid^(15*1024)];
    sorted[16] = b_values_in[gid^(0*1024)^32767];
    sorted[17] = b_values_in[gid^(1*1024)^32767];
    sorted[18] = b_values_in[gid^(2*1024)^32767];
    sorted[19] = b_values_in[gid^(3*1024)^32767];
    sorted[20] = b_values_in[gid^(4*1024)^32767];
    sorted[21] = b_values_in[gid^(5*1024)^32767];
    sorted[22] = b_values_in[gid^(6*1024)^32767];
    sorted[23] = b_values_in[gid^(7*1024)^32767];
    sorted[24] = b_values_in[gid^(8*1024)^32767];
    sorted[25] = b_values_in[gid^(9*1024)^32767];
    sorted[26] = b_values_in[gid^(10*1024)^32767];
    sorted[27] = b_values_in[gid^(11*1024)^32767];
    sorted[28] = b_values_in[gid^(12*1024)^32767];
    sorted[29] = b_values_in[gid^(13*1024)^32767];
    sorted[30] = b_values_in[gid^(14*1024)^32767];
    sorted[31] = b_values_in[gid^(15*1024)^32767];

    sorted[0]  = compare_and_select(sorted[0],  sorted[16], (gid&16384) != 0);
    sorted[1]  = compare_and_select(sorted[1],  sorted[17], (gid&16384) != 0);
    sorted[2]  = compare_and_select(sorted[2],  sorted[18], (gid&16384) != 0);
    sorted[3]  = compare_and_select(sorted[3],  sorted[19], (gid&16384) != 0);
    sorted[4]  = compare_and_select(sorted[4],  sorted[20], (gid&16384) != 0);
    sorted[5]  = compare_and_select(sorted[5],  sorted[21], (gid&16384) != 0);
    sorted[6]  = compare_and_select(sorted[6],  sorted[22], (gid&16384) != 0);
    sorted[7]  = compare_and_select(sorted[7],  sorted[23], (gid&16384) != 0);
    sorted[8]  = compare_and_select(sorted[8],  sorted[24], (gid&16384) != 0);
    sorted[9]  = compare_and_select(sorted[9],  sorted[25], (gid&16384) != 0);
    sorted[10] = compare_and_select(sorted[10], sorted[26], (gid&16384) != 0);
    sorted[11] = compare_and_select(sorted[11], sorted[27], (gid&16384) != 0);
    sorted[12] = compare_and_select(sorted[12], sorted[28], (gid&16384) != 0);
    sorted[13] = compare_and_select(sorted[13], sorted[29], (gid&16384) != 0);
    sorted[14] = compare_and_select(sorted[14], sorted[30], (gid&16384) != 0);
    sorted[15] = compare_and_select(sorted[15], sorted[31], (gid&16384) != 0);

    sorted[0]  = compare_and_select(sorted[0],  sorted[8],  (gid&8192)  != 0);
    sorted[1]  = compare_and_select(sorted[1],  sorted[9],  (gid&8192)  != 0);
    sorted[2]  = compare_and_select(sorted[2],  sorted[10], (gid&8192)  != 0);
    sorted[3]  = compare_and_select(sorted[3],  sorted[11], (gid&8192)  != 0);
    sorted[4]  = compare_and_select(sorted[4],  sorted[12], (gid&8192)  != 0);
    sorted[5]  = compare_and_select(sorted[5],  sorted[13], (gid&8192)  != 0);
    sorted[6]  = compare_and_select(sorted[6],  sorted[14], (gid&8192)  != 0);
    sorted[7]  = compare_and_select(sorted[7],  sorted[15], (gid&8192)  != 0);

    sorted[0]  = compare_and_select(sorted[0],  sorted[4],  (gid&4096)  != 0);
    sorted[1]  = compare_and_select(sorted[1],  sorted[5],  (gid&4096)  != 0);
    sorted[2]  = compare_and_select(sorted[2],  sorted[6],  (gid&4096)  != 0);
    sorted[3]  = compare_and_select(sorted[3],  sorted[7],  (gid&4096)  != 0);

    sorted[0]  = compare_and_select(sorted[0],  sorted[2],  (gid&2048)  != 0);
    sorted[1]  = compare_and_select(sorted[1],  sorted[3],  (gid&2048)  != 0);

    sorted[0]  = compare_and_select(sorted[0],  sorted[1],  (gid&1024)  != 0);

    //barrier();
    b_values_out[gid] = finalize_1024(lindex, sorted[0]);
} 

void main() {
    sort_16384_to_32768();
}