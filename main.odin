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

Program :: u32


Bitonic_Sorting_Stages :: enum u32 {
	_1024 = 1024,
	_2048 = 2048,
	_4096 = 4096,
	_8192 = 8192,
	_16384 = 16384,
	//_32768 = 32768,
	_32768_1 = 32768+1,
	_32768_2 = 32768+2,
	//_65536 = 65536,
	_65536_1 = 65536+1,
	_65536_2 = 65536+2,
	//_131072 = 131072,
	_131072_1 = 131072+1,
	_131072_2 = 131072+2,
	//_262144 = 262144,
	_262144_1 = 262144+1,
	_262144_2 = 262144+2,
}


bitonic_sort_programs: #sparse [Bitonic_Sorting_Stages]Program
bitonic_sort2_programs: #sparse [Bitonic_Sorting_Stages]Program

bitonic_data: [2]u32

bitonic_sort_base_program: Program
bitonic_sort_base2_program: Program
bitonic_sort_base3_program: Program

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

    replace_placeholder :: proc(str, placeholder, replacement: string, allocator := context.allocator) -> string {
        found := strings.index(str, placeholder)
        if found == -1 do return ""

        return strings.concatenate({
            str[:found], 
            replacement, 
            str[found+len(placeholder):]
        }, allocator)
    }


    gl.CreateBuffers(2, &bitonic_data[0])
    gl.NamedBufferData(bitonic_data[0], size_of(u32)*262144, nil, gl.STATIC_READ)
    gl.NamedBufferData(bitonic_data[1], size_of(u32)*262144, nil, gl.STATIC_READ)

    bitonic_verify_data: u32
    gl.CreateBuffers(1, &bitonic_verify_data)
    gl.NamedBufferData(bitonic_verify_data, 32*size_of(u32), nil, gl.STATIC_READ)

    bitonic_init_program := load_compute_file("shaders/bitonic_init.glsl")
    bitonic_verify_program := load_compute_file("shaders/bitonic_verify.glsl")
    bitonic_sort_base_program = load_compute_file("shaders/bitonic_sort_base.glsl")
    bitonic_sort_base2_program = load_compute_file("shaders/bitonic_sort_base2.glsl")
    bitonic_sort_base3_program = load_compute_file("shaders/bitonic_sort_base3.glsl")

    {
        filename := "shaders/bitonic_sort.glsl"
        source, ok := os.read_entire_file(filename, context.temp_allocator)
        if ok {
            for stage in Bitonic_Sorting_Stages {
                replacement := fmt.tprintf("%v", stage)
                replaced_source := replace_placeholder(string(source), "<stage>", replacement, context.temp_allocator)

                //fmt.println(replaced_source)
                program := load_compute_source(replaced_source)
                if program == 0 do break
                bitonic_sort_programs[stage] = program
            }
        }
    }

    {
        filename := "shaders/bitonic_sort2.glsl"
        source, ok := os.read_entire_file(filename, context.temp_allocator)
        if ok {
            for stage in Bitonic_Sorting_Stages {
                replacement := fmt.tprintf("%v", stage)
                replaced_source := replace_placeholder(string(source), "<stage>", replacement, context.temp_allocator)

                //fmt.println(replaced_source)
                program := load_compute_source(replaced_source)
                if program == 0 do break
                bitonic_sort2_programs[stage] = program
            }
        }
    }

    init_query_pool()
    
    N := u32(256*1024)
    step := 0
    outer: 
    //for N := u32(1024); N <= 32768 + 0*256*1024; N *= 2 {
    for stage in Bitonic_Sorting_Stages {
    	if stage > ._262144_2 do continue
    	N := (u32(stage)/1024) * 1024

    	fmt.println("N =", N)
	    for M := u32(0); M < 1 + 0*bits.log2(N); M += 1 {
	    	fmt.println("M =", M)
	    	for step := 0; step < 400; step += 1 {
		    	if glfw.WindowShouldClose(window) do break

		    	process_active_queries(step)

		        glfw.PollEvents();

		        if b32(glfw.GetKey(window, glfw.KEY_ESCAPE)) {
		            glfw.SetWindowShouldClose(window, true);
		        }

		        if b32(glfw.GetKey(window, glfw.KEY_P)) {
		        	fmt.println("PRINT")
		            print_finished_queries()
		        }

		        {
		        	GL_LABEL_BLOCK("Bitonic Sort")	
				    {
		        		GL_LABEL_BLOCK("Init Sort")	
				        gl.UseProgram(bitonic_init_program)
				        gl.Uniform1ui(0, N);
				        gl.BindBufferBase(gl.SHADER_STORAGE_BUFFER, 0, bitonic_data[0]);

		    			block_query("Init", step)
				        gl.DispatchCompute(N / 512, 1, 1)
				    }

				    sort_pass :: proc(N: u32, stage: Bitonic_Sorting_Stages) {
				    	//GL_LABEL_BLOCK(fmt.tprintf("Sort Stage: %v", stage))	
				    	gl.UseProgram(bitonic_sort_programs[stage])
				        gl.BindBufferBase(gl.SHADER_STORAGE_BUFFER, 0, bitonic_data[0]);
				        gl.BindBufferBase(gl.SHADER_STORAGE_BUFFER, 1, bitonic_data[1]);

				    	gl.MemoryBarrier(gl.SHADER_STORAGE_BARRIER_BIT)
						//block_query(fmt.tprintf("Sort %v", stage), step)
				        gl.DispatchCompute(N / 1024, 1, 1)

				        bitonic_data[0], bitonic_data[1] = bitonic_data[1], bitonic_data[0]
				    }

				    sort2_pass :: proc(N, mul: u32, stage: Bitonic_Sorting_Stages) {
				    	//GL_LABEL_BLOCK(fmt.tprintf("Sort Stage: %v", stage))	
				    	gl.UseProgram(bitonic_sort2_programs[stage])
				        gl.BindBufferBase(gl.SHADER_STORAGE_BUFFER, 0, bitonic_data[0]);
				        gl.BindBufferBase(gl.SHADER_STORAGE_BUFFER, 1, bitonic_data[1]);

				    	gl.MemoryBarrier(gl.SHADER_STORAGE_BARRIER_BIT)
						//block_query(fmt.tprintf("Sort %v", stage), step)
				        gl.DispatchCompute(N / 512 / mul, 1, 1)

				        bitonic_data[0], bitonic_data[1] = bitonic_data[1], bitonic_data[0]
				    }


				    sort_pass_base :: proc(N: u32, mask1, mask2: u32) {
				    	//GL_LABEL_BLOCK(fmt.tprintf("Sort Stage: %v", stage))	
				    	gl.UseProgram(bitonic_sort_base_program)
				        gl.BindBufferBase(gl.SHADER_STORAGE_BUFFER, 0, bitonic_data[0]);
				        gl.BindBufferBase(gl.SHADER_STORAGE_BUFFER, 1, bitonic_data[1]);

				        gl.Uniform1ui(0, mask1);
				        gl.Uniform1ui(1, mask2);

				    	gl.MemoryBarrier(gl.SHADER_STORAGE_BARRIER_BIT)
						//block_query(fmt.tprintf("Sort %v", stage), step)
				        gl.DispatchCompute(N / 256, 1, 1)

				        bitonic_data[0], bitonic_data[1] = bitonic_data[1], bitonic_data[0]
				    }

				    sort_pass_base2 :: proc(N: u32, mask1, mask2: u32) {
				    	//GL_LABEL_BLOCK(fmt.tprintf("Sort Stage: %v", stage))	
				    	gl.UseProgram(bitonic_sort_base2_program)
				        gl.BindBufferBase(gl.SHADER_STORAGE_BUFFER, 0, bitonic_data[0]);
				        gl.BindBufferBase(gl.SHADER_STORAGE_BUFFER, 1, bitonic_data[1]);

				        gl.Uniform1ui(0, mask1);
				        gl.Uniform1ui(1, mask2);

				    	gl.MemoryBarrier(gl.SHADER_STORAGE_BARRIER_BIT)
						//block_query(fmt.tprintf("Sort %v", stage), step)
				        gl.DispatchCompute(N / 256 / 2, 1, 1)

				        bitonic_data[0], bitonic_data[1] = bitonic_data[1], bitonic_data[0]
				    }

				    sort_pass_base3 :: proc(N: u32, mask1, mask2: u32) {
				    	//GL_LABEL_BLOCK(fmt.tprintf("Sort Stage: %v", stage))	
				    	gl.UseProgram(bitonic_sort_base3_program)
				        gl.BindBufferBase(gl.SHADER_STORAGE_BUFFER, 0, bitonic_data[0]);

				        gl.Uniform1ui(0, mask1);
				        gl.Uniform1ui(1, mask2);

				    	gl.MemoryBarrier(gl.SHADER_STORAGE_BARRIER_BIT)
						//block_query(fmt.tprintf("Sort %v", stage), step)
				        gl.DispatchCompute(N / 256 / 2, 1, 1)
				    }
				    {
		        		GL_LABEL_BLOCK("Sort")	
						//block_query(fmt.tprintf("Sort_N%d_%d", N, M), step)
						block_query(fmt.tprintf("Sort_N%d%v", N, stage), step)

						if false {
							for i in u32(0)..<u32(1+M) {
								sort_pass_base(N, (2 << i) - 1, 1 << i)
								for j in 0..<i {
									sort_pass_base(N, 1 << (i - j - 1), 1 << (i - j - 1))
								}
							}
						} else if false {
							for i in u32(0)..<u32(1+M) {
								a := u32(1)<<i
								//fmt.println(i, a+(a-1))
								sort_pass_base2(N, ~(a-1), a+(a-1))
								for j in 0..<i {
									a := u32(1)<<(i - j - 1)
									//fmt.println(a)
									sort_pass_base2(N, ~(a-1), a)
								}
								//fmt.println()
							}
						} else if false {
							for i in u32(0)..<u32(1+M) {
								a := u32(1)<<i
								//fmt.println(i, a+(a-1))
								sort_pass_base3(N, ~(a-1), a+(a-1))
								for j in 0..<i {
									a := u32(1)<<(i - j - 1)
									//fmt.println(a)
									sort_pass_base3(N, ~(a-1), a)
								}
								//fmt.println()
							}
						} else if true {
							if stage >= ._1024 do sort_pass(N, ._1024)
							if stage >= ._2048 do sort_pass(N, ._2048)
							if stage >= ._4096 do sort_pass(N, ._4096)
							if stage >= ._8192 do sort_pass(N, ._8192)
							if stage >= ._16384 do sort_pass(N, ._16384)
							//if N >  16*1024 do sort_pass(N, ._32768)
							if stage >= ._32768_1 do sort_pass(N, ._32768_1)
							if stage >= ._32768_2 do sort_pass(N, ._32768_2)
							//if N >  32*1024 do sort_pass(N, ._65536)
							if stage >= ._65536_1 do sort_pass(N, ._65536_1)
							if stage >= ._65536_2 do sort_pass(N, ._65536_2)
							//if N >  64*1024 do sort_pass(N, ._131072)
							if stage >= ._131072_1 do sort_pass(N, ._131072_1)
							if stage >= ._131072_2 do sort_pass(N, ._131072_2)
							//if N > 128*1024 do sort_pass(N, ._262144)
							if stage >= ._262144_1 do sort_pass(N, ._262144_1)
							if stage >= ._262144_2 do sort_pass(N, ._262144_2)
						} else {
							if stage >= ._1024 do sort2_pass(N, 2, ._1024)
							if stage >= ._2048 do sort2_pass(N, 1, ._2048)
							if stage >= ._4096 do sort2_pass(N, 1, ._4096)
							if stage >= ._8192 do sort2_pass(N, 1, ._8192)
							if stage >= ._16384 do sort2_pass(N, 1, ._16384)
							////if N >  16*1024 do sort2_pass(N, ._32768)
							if stage >= ._32768_1 do sort2_pass(N, 2, ._32768_1)
							if stage >= ._32768_2 do sort2_pass(N, 1, ._32768_2)
							////if N >  32*1024 do sort2_pass(N, ._65536)
							if stage >= ._65536_1 do sort2_pass(N, 2, ._65536_1)
							if stage >= ._65536_2 do sort2_pass(N, 1, ._65536_2)
							////if N >  64*1024 do sort2_pass(N, ._131072)
							//if N >  64*1024 do sort2_pass(N, ._131072_1)
							//if N >  64*1024 do sort2_pass(N, ._131072_2)
							////if N > 128*1024 do sort2_pass(N, ._262144)
							//if N > 128*1024 do sort2_pass(N, ._262144_1)
							//if N > 128*1024 do sort2_pass(N, ._262144_2)
						}

				    }

				    {
		        		GL_LABEL_BLOCK("Verify Sort")	
				    	clear_data: b32 = true
				    	gl.ClearNamedBufferData(bitonic_verify_data, gl.R32UI, gl.RED_INTEGER, gl.UNSIGNED_INT, &clear_data)
				    	gl.MemoryBarrier(gl.BUFFER_UPDATE_BARRIER_BIT)

				        gl.UseProgram(bitonic_verify_program)
				        gl.Uniform1ui(0, N);
				        gl.BindBufferBase(gl.SHADER_STORAGE_BUFFER, 0, bitonic_data[0]);
				        gl.BindBufferBase(gl.SHADER_STORAGE_BUFFER, 1, bitonic_verify_data);

				    	gl.MemoryBarrier(gl.SHADER_STORAGE_BARRIER_BIT)
		    			block_query("Verify", step)
				        gl.DispatchCompute(N / 512, 1, 1)
		    		}
		    		if stage != ._32768_1 && stage != ._65536_1 && stage != ._131072_1 && stage != ._262144_1 {	
		        		//GL_LABEL_BLOCK("Download Result")	

				    	is_sorted: [32]b32
				    	gl.MemoryBarrier(gl.BUFFER_UPDATE_BARRIER_BIT)
		    			block_query("Verify", step)
				        gl.GetNamedBufferSubData(bitonic_verify_data, 0, 4*32, &is_sorted)
				        //fmt.println(is_sorted)
				        for i in 0..<32 {
				        	if (1<<u32(i)) > N do continue
				        	if !is_sorted[i] do fmt.println(step, "Not Sorted", i, 1<<u32(i))
				        }
				    }
		        }
		        glfw.SwapBuffers(window);
		    }
	    }
	}

    print_finished_queries()
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