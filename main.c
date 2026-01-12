#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <stdbool.h>
#include <string.h>

#include <glad/glad.h>
#include <GLFW/glfw3.h>

#ifdef _WIN32
__declspec(dllexport) uint32_t NvOptimusEnablement = 0x00000001;
__declspec(dllexport) int AmdPowerXpressRequestHighPerformance = 1;
#endif

static void error_callback(int error, const char *desc);
static bool gl_load_compute_file(const char *filename, GLuint *out_program);
static bool gl_load_compute_source(const char *source, GLuint *out_program);
static void BEGIN_GL_LABEL_BLOCK(const char *name);
static void END_GL_LABEL_BLOCK(void);
static void swap_buffers(GLuint *a, GLuint *b);
static char *read_entire_file(const char *path);

static void error_callback(int error, const char *desc) {
    printf("Error code %d: %s\n", error, desc);
}

int main(void) {
    glfwSetErrorCallback(error_callback);
    if (!glfwInit()) return 0;

    GLFWwindow *window = glfwCreateWindow(1280, 720, "Fast Bitonic Sort", NULL, NULL);
    if (!window) { glfwTerminate(); return 0; }

    glfwMakeContextCurrent(window);
    glfwSwapInterval(0);

    if (!gladLoadGLLoader((GLADloadproc)glfwGetProcAddress)) {
        printf("Failed to initialize GLAD\n");
        glfwDestroyWindow(window);
        glfwTerminate();
        return 0;
    }

    printf("%s\n", glGetString(GL_VENDOR));
    printf("%s\n", glGetString(GL_RENDERER));
    printf("%s\n", glGetString(GL_VERSION));

    GLuint bitonic_data[2];
    glCreateBuffers(2, bitonic_data);
    glNamedBufferData(bitonic_data[0], sizeof(uint32_t)*32768, NULL, GL_STATIC_READ);
    glNamedBufferData(bitonic_data[1], sizeof(uint32_t)*32768, NULL, GL_STATIC_READ);

    GLuint bitonic_verify_data;
    glCreateBuffers(1, &bitonic_verify_data);
    glNamedBufferData(bitonic_verify_data, 32*sizeof(uint32_t), NULL, GL_STATIC_READ);

    GLuint bitonic_init_program; if (!gl_load_compute_file("shaders/bitonic_init.glsl", &bitonic_init_program)) goto cleanup;
    GLuint bitonic_verify_program; if (!gl_load_compute_file("shaders/bitonic_verify.glsl", &bitonic_verify_program)) goto cleanup;
    GLuint bitonic_sort_program; if (!gl_load_compute_file("shaders/bitonic_sort.glsl", &bitonic_sort_program)) goto cleanup;

    uint32_t N = 32*1024;

    for (uint32_t step = 0; true; step++) {
        if ((step % 10000) == 0) printf("%d steps\n", step);
        if (glfwWindowShouldClose(window)) break;

        glfwPollEvents();
        if (glfwGetKey(window, GLFW_KEY_ESCAPE)) glfwSetWindowShouldClose(window, GLFW_TRUE);

        {
            BEGIN_GL_LABEL_BLOCK("Init");
            glUseProgram(bitonic_init_program);
            glBindBufferBase(GL_SHADER_STORAGE_BUFFER, 0, bitonic_data[0]);
            glDispatchCompute(N / 512, 1, 1);
            END_GL_LABEL_BLOCK();
        }
        {
            BEGIN_GL_LABEL_BLOCK("Sort");
            glUseProgram(bitonic_sort_program);
            glBindBufferBase(GL_SHADER_STORAGE_BUFFER, 0, bitonic_data[0]);
            glBindBufferBase(GL_SHADER_STORAGE_BUFFER, 1, bitonic_data[1]);
            glMemoryBarrier(GL_SHADER_STORAGE_BARRIER_BIT);
            glDispatchCompute(N / 1024, 1, 1);
            swap_buffers(&bitonic_data[0], &bitonic_data[1]);
            END_GL_LABEL_BLOCK();
        }
        {
            BEGIN_GL_LABEL_BLOCK("Verify");
            uint32_t clear_data = 1;
            glClearNamedBufferData(bitonic_verify_data, GL_R32UI, GL_RED_INTEGER, GL_UNSIGNED_INT, &clear_data);
            glUseProgram(bitonic_verify_program);
            glUniform1ui(0, N);
            glBindBufferBase(GL_SHADER_STORAGE_BUFFER, 0, bitonic_data[0]);
            glBindBufferBase(GL_SHADER_STORAGE_BUFFER, 1, bitonic_verify_data);
            glMemoryBarrier(GL_SHADER_STORAGE_BARRIER_BIT | GL_BUFFER_UPDATE_BARRIER_BIT);
            glDispatchCompute(N / 512, 1, 1);
            END_GL_LABEL_BLOCK();
        }
        {
            BEGIN_GL_LABEL_BLOCK("Download");
            uint32_t is_sorted[32];
            glMemoryBarrier(GL_BUFFER_UPDATE_BARRIER_BIT);
            glGetNamedBufferSubData(bitonic_verify_data, 0, sizeof(is_sorted), is_sorted);
            for (uint32_t i = 0; i < 32; i++) {
                if ((1u << i) > N) continue;
                if (!is_sorted[i]) printf("%u Not Sorted %u %u\n", step, i, 1u << i);
            }
            END_GL_LABEL_BLOCK();
        }

        glfwSwapBuffers(window);
    }

cleanup:
    glfwDestroyWindow(window);
    glfwTerminate();
    return 0;
}

static void swap_buffers(GLuint *a, GLuint *b) {
    GLuint tmp = *a;
    *a = *b;
    *b = tmp;
}

static bool gl_load_compute_file(const char *filename, GLuint *out_program) {
    char *source = read_entire_file(filename);
    if (!source) { printf("Filename: %s\n", filename); return false; }
    bool ok = gl_load_compute_source(source, out_program);
    free(source);
    return ok;
}

static bool gl_load_compute_source(const char *source, GLuint *out_program) {
    GLuint shader = glCreateShader(GL_COMPUTE_SHADER);
    glShaderSource(shader, 1, &source, NULL);
    glCompileShader(shader);
    GLint ok = 0; glGetShaderiv(shader, GL_COMPILE_STATUS, &ok);
    if (!ok) {
        GLint len = 0; glGetShaderiv(shader, GL_INFO_LOG_LENGTH, &len);
        char *log = malloc(len); glGetShaderInfoLog(shader, len, NULL, log);
        printf("Compute shader error:\n%s\n", log);
        free(log); glDeleteShader(shader); return false;
    }
    GLuint program = glCreateProgram();
    glAttachShader(program, shader);
    glLinkProgram(program);
    glGetProgramiv(program, GL_LINK_STATUS, &ok);
    if (!ok) {
        GLint len = 0; glGetProgramiv(program, GL_INFO_LOG_LENGTH, &len);
        char *log = malloc(len); glGetProgramInfoLog(program, len, NULL, log);
        printf("Program link error:\n%s\n", log);
        free(log); glDeleteProgram(program); glDeleteShader(shader); return false;
    }
    glDetachShader(program, shader); glDeleteShader(shader);
    *out_program = program;
    return true;
}

static void BEGIN_GL_LABEL_BLOCK(const char *name) {
    glPushDebugGroup(GL_DEBUG_SOURCE_APPLICATION, 0, (GLsizei)strlen(name), name);
}

static void END_GL_LABEL_BLOCK(void) {
    glPopDebugGroup();
}

static char *read_entire_file(const char *path) {
    FILE *f = fopen(path, "rb");
    if (!f) return NULL;
    fseek(f, 0, SEEK_END);
    long size = ftell(f);
    fseek(f, 0, SEEK_SET);
    char *data = malloc(size + 1);
    if (!data) { fclose(f); return NULL; }
    fread(data, 1, size, f);
    data[size] = 0;
    fclose(f);
    return data;
}
