package fast_bitonic_sort

import "core:fmt";
import "core:os";
import "core:math/bits";
import "core:strings";
import "base:runtime";

import glfw "vendor:glfw";
import gl "vendor:OpenGL";

@(export, link_name="NvOptimusEnablement")
NvOptimusEnablement: u32 = 0x00000001;

@(export, link_name="AmdPowerXpressRequestHighPerformance")
AmdPowerXpressRequestHighPerformance: i32 = 1;

error_callback :: proc"c"(error: i32, desc: cstring) {
    context = runtime.default_context();
    fmt.printf("Error code %d: %s\n", error, desc);
}

main :: proc() {
    glfw.SetErrorCallback(error_callback);

    if !glfw.Init() do return
    defer glfw.Terminate()

    glfw.WindowHint(glfw.CONTEXT_VERSION_MAJOR, 4);
    glfw.WindowHint(glfw.CONTEXT_VERSION_MINOR, 6);
    glfw.WindowHint(glfw.OPENGL_PROFILE, glfw.OPENGL_CORE_PROFILE);

    window := glfw.CreateWindow(1280, 720, "Fast Bitonic Sort", nil, nil);
    if window == nil do return;
    defer glfw.DestroyWindow(window)

    glfw.MakeContextCurrent(window);
    glfw.SwapInterval(0);

    // OpenGL    
    gl.load_up_to(4, 6, glfw.gl_set_proc_address);

    fmt.println(gl.GetString(gl.VENDOR))
    fmt.println(gl.GetString(gl.RENDERER))
    fmt.println(gl.GetString(gl.VERSION))

	bitonic_data: [2]u32
    gl.CreateBuffers(2, &bitonic_data[0])
    gl.NamedBufferData(bitonic_data[0], size_of(u32)*32768*16, nil, gl.STATIC_READ)
    gl.NamedBufferData(bitonic_data[1], size_of(u32)*32768*16, nil, gl.STATIC_READ)

    bitonic_verify_data: u32
    gl.CreateBuffers(1, &bitonic_verify_data)
    gl.NamedBufferData(bitonic_verify_data, 32*size_of(u32), nil, gl.STATIC_READ)

    bitonic_init_program := load_compute_file("shaders/bitonic_init.glsl")
    bitonic_verify_program := load_compute_file("shaders/bitonic_verify.glsl")
    bitonic_sort_program := load_compute_file("shaders/bitonic_sort.glsl")

    N := u32(32*16*1024)
	for step := 0; true; step += 1 {
		if (step % 10000) == 0 do fmt.println(step, "steps")

    	if glfw.WindowShouldClose(window) do break
        glfw.PollEvents();
        if b32(glfw.GetKey(window, glfw.KEY_ESCAPE)) {
            glfw.SetWindowShouldClose(window, true);
        }

	    {
    		GL_LABEL_BLOCK("Init")	
	        gl.UseProgram(bitonic_init_program)
	        gl.BindBufferBase(gl.SHADER_STORAGE_BUFFER, 0, bitonic_data[0]);
	        gl.DispatchCompute(N / 512, 1, 1)
	    }
	    {
    		GL_LABEL_BLOCK("Sort")	
	    	gl.UseProgram(bitonic_sort_program)
	        gl.BindBufferBase(gl.SHADER_STORAGE_BUFFER, 0, bitonic_data[0]);
	        gl.BindBufferBase(gl.SHADER_STORAGE_BUFFER, 1, bitonic_data[1]);
	    	gl.MemoryBarrier(gl.SHADER_STORAGE_BARRIER_BIT)
	        gl.DispatchCompute(N / 1024, 1, 1)
	        bitonic_data[0], bitonic_data[1] = bitonic_data[1], bitonic_data[0]
	    }
	    {
    		GL_LABEL_BLOCK("Verify")	
	    	clear_data: b32 = true
	    	gl.ClearNamedBufferData(bitonic_verify_data, gl.R32UI, gl.RED_INTEGER, gl.UNSIGNED_INT, &clear_data)

	        gl.UseProgram(bitonic_verify_program)
	        gl.Uniform1ui(0, N);
	        gl.BindBufferBase(gl.SHADER_STORAGE_BUFFER, 0, bitonic_data[0]);
	        gl.BindBufferBase(gl.SHADER_STORAGE_BUFFER, 1, bitonic_verify_data);
	    	gl.MemoryBarrier(gl.SHADER_STORAGE_BARRIER_BIT | gl.BUFFER_UPDATE_BARRIER_BIT)
	        gl.DispatchCompute(N / 512, 1, 1)
		}
		{	
    		GL_LABEL_BLOCK("Download")	
	    	is_sorted: [32]b32
	    	gl.MemoryBarrier(gl.BUFFER_UPDATE_BARRIER_BIT)
	        gl.GetNamedBufferSubData(bitonic_verify_data, 0, 4*32, &is_sorted)
	        for i in 0..<16 {
	        	if (1<<u32(i)) > N do continue
	        	if !is_sorted[i] do fmt.println(step, "Not Sorted", i, 1<<u32(i))
	        }
	    }
        glfw.SwapBuffers(window);
    }
}

load_compute_file :: proc(filenames: string) -> u32 {
    program, success := gl.load_compute_file(filenames);
    if !success {
        fmt.println("Filename:", filenames)
        return 0;
    }
    return program;
}

load_compute_source :: proc(source: string, loc := #caller_location) -> u32 {
    program, success := gl.load_compute_source(source);
    if !success {
        fmt.println("Location:", loc)
        return 0;
    }
    return program;
}

BEGIN_GL_LABEL_BLOCK :: proc(name: string) {
    gl.PushDebugGroup(gl.DEBUG_SOURCE_APPLICATION, 0, i32(len(name)), strings.unsafe_string_to_cstring(name));
}

END_GL_LABEL_BLOCK :: proc() {
    gl.PopDebugGroup();
}

@(deferred_out=END_GL_LABEL_BLOCK)
GL_LABEL_BLOCK :: proc(name: string) {
    BEGIN_GL_LABEL_BLOCK(name);
}