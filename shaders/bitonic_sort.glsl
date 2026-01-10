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

shared T s_partially_sorted[2*1024];

T finalize_1024(uint lindex, T sorted0) {

    for (uint m = 512; m > 0; m >>= 1) {
        lindex ^= 1024;
        s_partially_sorted[lindex] = sorted0;
        barrier();
        T partner = s_partially_sorted[lindex^m];
        sorted0 = (lindex&m) != 0 ? max(sorted0, partner) : min(sorted0, partner);
    }

    return sorted0;
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
    if ((gid&32768) != 0) {
        sorted[0] = max(sorted[0], sorted[32]);
        sorted[1] = max(sorted[1], sorted[33]);
        sorted[2] = max(sorted[2], sorted[34]);
        sorted[3] = max(sorted[3], sorted[35]);
        sorted[4] = max(sorted[4], sorted[36]);
        sorted[5] = max(sorted[5], sorted[37]);
        sorted[6] = max(sorted[6], sorted[38]);
        sorted[7] = max(sorted[7], sorted[39]);
        sorted[8] = max(sorted[8], sorted[40]);
        sorted[9] = max(sorted[9], sorted[41]);
        sorted[10] = max(sorted[10], sorted[42]);
        sorted[11] = max(sorted[11], sorted[43]);
        sorted[12] = max(sorted[12], sorted[44]);
        sorted[13] = max(sorted[13], sorted[45]);
        sorted[14] = max(sorted[14], sorted[46]);
        sorted[15] = max(sorted[15], sorted[47]);
        sorted[16] = max(sorted[16], sorted[48]);
        sorted[17] = max(sorted[17], sorted[49]);
        sorted[18] = max(sorted[18], sorted[50]);
        sorted[19] = max(sorted[19], sorted[51]);
        sorted[20] = max(sorted[20], sorted[52]);
        sorted[21] = max(sorted[21], sorted[53]);
        sorted[22] = max(sorted[22], sorted[54]);
        sorted[23] = max(sorted[23], sorted[55]);
        sorted[24] = max(sorted[24], sorted[56]);
        sorted[25] = max(sorted[25], sorted[57]);
        sorted[26] = max(sorted[26], sorted[58]);
        sorted[27] = max(sorted[27], sorted[59]);
        sorted[28] = max(sorted[28], sorted[60]);
        sorted[29] = max(sorted[29], sorted[61]);
        sorted[30] = max(sorted[30], sorted[62]);
        sorted[31] = max(sorted[31], sorted[63]);
    } else {
        sorted[0] = min(sorted[0], sorted[32]);
        sorted[1] = min(sorted[1], sorted[33]);
        sorted[2] = min(sorted[2], sorted[34]);
        sorted[3] = min(sorted[3], sorted[35]);
        sorted[4] = min(sorted[4], sorted[36]);
        sorted[5] = min(sorted[5], sorted[37]);
        sorted[6] = min(sorted[6], sorted[38]);
        sorted[7] = min(sorted[7], sorted[39]);
        sorted[8] = min(sorted[8], sorted[40]);
        sorted[9] = min(sorted[9], sorted[41]);
        sorted[10] = min(sorted[10], sorted[42]);
        sorted[11] = min(sorted[11], sorted[43]);
        sorted[12] = min(sorted[12], sorted[44]);
        sorted[13] = min(sorted[13], sorted[45]);
        sorted[14] = min(sorted[14], sorted[46]);
        sorted[15] = min(sorted[15], sorted[47]);
        sorted[16] = min(sorted[16], sorted[48]);
        sorted[17] = min(sorted[17], sorted[49]);
        sorted[18] = min(sorted[18], sorted[50]);
        sorted[19] = min(sorted[19], sorted[51]);
        sorted[20] = min(sorted[20], sorted[52]);
        sorted[21] = min(sorted[21], sorted[53]);
        sorted[22] = min(sorted[22], sorted[54]);
        sorted[23] = min(sorted[23], sorted[55]);
        sorted[24] = min(sorted[24], sorted[56]);
        sorted[25] = min(sorted[25], sorted[57]);
        sorted[26] = min(sorted[26], sorted[58]);
        sorted[27] = min(sorted[27], sorted[59]);
        sorted[28] = min(sorted[28], sorted[60]);
        sorted[29] = min(sorted[29], sorted[61]);
        sorted[30] = min(sorted[30], sorted[62]);
        sorted[31] = min(sorted[31], sorted[63]);
    }

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
    sort_32768_to_65536();
}