const std = @import("std");

const gl = @import("gl");
const glfw = @import("glfw");
const zigimg = @import("zigimg");
const zm = @import("zm");

const core = @import("core.zig");
const math = @import("math.zig");
pub const Texture = @import("renderer/Texture.zig");

const vertex_shader_source: [:0]const u8 = @embedFile("shaders/default.glsl.vert");
const fragment_shader_source: [:0]const u8 = @embedFile("shaders/default.glsl.frag");

var procs: gl.ProcTable = undefined;

const gl_log = std.log.scoped(.gl);

////////////////
//// Public ////
////////////////

/// Orthographic camera
pub const Camera2D = struct {
    position: math.Vec2 = .{ 0.0, 0.0 },

    /// in degrees
    rotation: f32 = 0.0,
    size: f32 = 5.0,
};

pub const Quad = struct {
    position: math.Vec2 = .{ 0, 0 },

    /// in degrees
    rotation: f32 = 0.0,
    scale: math.Vec2 = .{ 1.0, 1.0 },
    z_index: i32 = 0,

    texture: ?Texture = null,
    color: math.Vec4 = .{ 1.0, 1.0, 1.0, 1.0 },
    tiling: f32 = 1.0,
};

pub fn init() !void {
    if (!procs.init(glfw.getProcAddress)) return error.GLerror;
    gl.makeProcTableCurrent(&procs);

    if (@import("builtin").mode == .Debug) {
        gl.Enable(gl.DEBUG_OUTPUT);
        gl.Enable(gl.DEBUG_OUTPUT_SYNCHRONOUS);
        gl.DebugMessageCallback(glDebugCallback, null);
        gl.DebugMessageControl(gl.DONT_CARE, gl.DONT_CARE, gl.DEBUG_SEVERITY_NOTIFICATION, 0, 0, gl.FALSE);
    }

    gl.Enable(gl.BLEND);
    gl.BlendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA);

    renderer_state.draw_queue = std.ArrayList(Quad).init(core.allocator);

    try createShaders();
    createQuad();

    var white_texture_data = [1]u32{0xffffffff};
    renderer_state.white_texture = Texture.initRaw(.{
        .data = &white_texture_data,
        .width = 1,
        .height = 1,
    });

    renderer_state.view_proj = .identity();
}

pub fn deinit() void {
    renderer_state.white_texture.deinit();

    gl.DeleteVertexArrays(1, (&renderer_state.quad_vao)[0..1]);
    gl.DeleteBuffers(1, (&renderer_state.quad_vbo)[0..1]);
    gl.DeleteBuffers(1, (&renderer_state.quad_ibo)[0..1]);
    gl.DeleteProgram(renderer_state.default_shader_program);

    gl.makeProcTableCurrent(null);
}

pub fn onResize(width: i32, height: i32) void {
    gl.Viewport(0, 0, @intCast(width), @intCast(height));
}

pub fn beginFrame(clear_color: math.Vec4) void {
    gl.ClearColor(clear_color[0], clear_color[1], clear_color[2], 1.0);
    gl.Clear(gl.COLOR_BUFFER_BIT);
}

pub fn endFrame() void {
    core.window.swapBuffers();
}

/////////////////////
//// 2D Renderer ////
/////////////////////
pub fn beginScene2D(camera: *const Camera2D) void {
    const aspect = getAspectRatio();
    const projection = zm.Mat4f.orthographic(-camera.size * aspect, camera.size * aspect, -camera.size, camera.size, -1.0, 1.0);
    const transform = zm.Mat4f.translation(camera.position[0], camera.position[1], 0.0);
    const view = transform.multiply(zm.Mat4f.rotation(.{ 0.0, 0.0, 1.0 }, std.math.degreesToRadians(camera.rotation)));
    renderer_state.view_proj = projection.multiply(view.inverse());
}

pub fn endScene2D() void {
    flush();
    renderer_state.view_proj = .identity();
}

pub fn drawQuad(q: Quad) void {
    renderer_state.draw_queue.append(q) catch |err| {
        std.log.err("drawQuad(): {s}", .{@errorName(err)});
    };
}

/////////////////////
//// UI Renderer ////
/////////////////////
pub fn beginUI() void {
    const fb_size = core.window.getFramebufferSize();
    renderer_state.view_proj = zm.Mat4f.orthographic(0.0, @floatFromInt(fb_size.width), @floatFromInt(fb_size.height), 0.0, -1.0, 1.0);
}

pub fn endUI() void {
    flush();
    renderer_state.view_proj = .identity();
}

/////////////////
//// Private ////
/////////////////
const renderer_state = struct {
    var quad_vao: gl.uint = undefined;
    var quad_vbo: gl.uint = undefined;
    var quad_ibo: gl.uint = undefined;
    var default_shader_program: gl.uint = undefined;

    var white_texture: Texture = undefined;

    var view_proj: zm.Mat4f = .identity();

    // draw queue
    var draw_queue: std.ArrayList(Quad) = undefined;
};

fn glDebugCallback(source: c_uint, t: c_uint, id: c_uint, severity: c_uint, length: c_int, message: [*:0]const u8, user_param: ?*const anyopaque) callconv(.C) void {
    _ = user_param;
    _ = length;
    _ = t;
    _ = source;
    switch (severity) {
        gl.DEBUG_SEVERITY_HIGH => gl_log.err("({d}): {s}", .{ id, message }),
        gl.DEBUG_SEVERITY_MEDIUM => gl_log.err("({d}): {s}", .{ id, message }),
        gl.DEBUG_SEVERITY_LOW => gl_log.warn("({d}): {s}", .{ id, message }),
        gl.DEBUG_SEVERITY_NOTIFICATION => gl_log.info("({d}): {s}", .{ id, message }),
        else => unreachable,
    }
}

fn quadLessThan(ctx: void, a: Quad, b: Quad) bool {
    _ = ctx;
    return a.z_index < b.z_index;
}

fn internalDrawQuad(q: Quad) void {
    gl.UseProgram(renderer_state.default_shader_program);
    defer gl.UseProgram(0);

    // camera
    // TODO: move to uniform buffer
    gl.UniformMatrix4fv(gl.GetUniformLocation(renderer_state.default_shader_program, "u_ViewProjection"), 1, gl.TRUE, @ptrCast(&(renderer_state.view_proj)));

    // transform
    const transform = zm.Mat4f.translation(q.position[0], q.position[1], 0.0).multiply(zm.Mat4f.rotation(.{ 0.0, 0.0, 1.0 }, std.math.degreesToRadians(q.rotation))).multiply(zm.Mat4f.scaling(q.scale[0], q.scale[1], 0.0));
    gl.UniformMatrix4fv(gl.GetUniformLocation(renderer_state.default_shader_program, "u_Transform"), 1, gl.TRUE, @ptrCast(&(transform)));

    // texture
    if (q.texture) |t| {
        gl.BindTexture(gl.TEXTURE_2D, t.id);
    } else {
        gl.BindTexture(gl.TEXTURE_2D, renderer_state.white_texture.id);
    }
    gl.Uniform1f(gl.GetUniformLocation(renderer_state.default_shader_program, "u_TilingFactor"), q.tiling);

    // color
    gl.Uniform4f(gl.GetUniformLocation(renderer_state.default_shader_program, "u_Color"), q.color[0], q.color[1], q.color[2], q.color[3]);

    gl.BindVertexArray(renderer_state.quad_vao);
    defer gl.BindVertexArray(0);

    gl.DrawElements(gl.TRIANGLES, quad_mesh.indices.len, gl.UNSIGNED_BYTE, 0);
}

const quad_mesh = struct {
    const vertices = [_]Vertex{
        .{ .position = .{ -0.5, -0.5, 0.0 }, .uv = .{ 0.0, 1.0 } },
        .{ .position = .{ 0.5, -0.5, 0.0 }, .uv = .{ 1.0, 1.0 } },
        .{ .position = .{ 0.5, 0.5, 0.0 }, .uv = .{ 1.0, 0.0 } },
        .{ .position = .{ -0.5, 0.5, 0.0 }, .uv = .{ 0.0, 0.0 } },
    };

    const indices = [_]u8{ 0, 1, 2, 2, 3, 0 };

    const Vertex = struct {
        position: Position,
        uv: UV,

        const Position = math.Vec3;
        const UV = math.Vec2;
    };
};

fn getAspectRatio() f32 {
    const fb = core.window.getFramebufferSize();
    return @as(f32, @floatFromInt(fb.width)) / @as(f32, @floatFromInt(fb.height));
}

fn createShaders() !void {
    renderer_state.default_shader_program = create_program: {
        var success: c_int = undefined;
        var info_log_buf: [512:0]u8 = undefined;

        const vertex_shader = gl.CreateShader(gl.VERTEX_SHADER);
        if (vertex_shader == 0) return error.CreateVertexShaderFailed;
        defer gl.DeleteShader(vertex_shader);

        gl.ShaderSource(
            vertex_shader,
            1,
            (&vertex_shader_source.ptr)[0..1],
            (&@as(c_int, @intCast(vertex_shader_source.len)))[0..1],
        );
        gl.CompileShader(vertex_shader);
        gl.GetShaderiv(vertex_shader, gl.COMPILE_STATUS, &success);
        if (success == gl.FALSE) {
            gl.GetShaderInfoLog(vertex_shader, info_log_buf.len, null, &info_log_buf);
            gl_log.err("{s}", .{std.mem.sliceTo(&info_log_buf, 0)});
            return error.CompileVertexShaderFailed;
        }

        const fragment_shader = gl.CreateShader(gl.FRAGMENT_SHADER);
        if (fragment_shader == 0) return error.CreateFragmentShaderFailed;
        defer gl.DeleteShader(fragment_shader);

        gl.ShaderSource(
            fragment_shader,
            1,
            (&fragment_shader_source.ptr)[0..1],
            (&@as(c_int, @intCast(fragment_shader_source.len)))[0..1],
        );
        gl.CompileShader(fragment_shader);
        gl.GetShaderiv(fragment_shader, gl.COMPILE_STATUS, &success);
        if (success == gl.FALSE) {
            gl.GetShaderInfoLog(fragment_shader, info_log_buf.len, null, &info_log_buf);
            gl_log.err("{s}", .{std.mem.sliceTo(&info_log_buf, 0)});
            return error.CompileFragmentShaderFailed;
        }

        const prg = gl.CreateProgram();
        if (prg == 0) return error.CreateProgramFailed;
        errdefer gl.DeleteProgram(prg);

        gl.AttachShader(prg, vertex_shader);
        gl.AttachShader(prg, fragment_shader);
        gl.LinkProgram(prg);
        gl.GetProgramiv(prg, gl.LINK_STATUS, &success);
        if (success == gl.FALSE) {
            gl.GetProgramInfoLog(prg, info_log_buf.len, null, &info_log_buf);
            gl_log.err("{s}", .{std.mem.sliceTo(&info_log_buf, 0)});
            return error.LinkProgramFailed;
        }

        break :create_program prg;
    };
}

fn createQuad() void {
    gl.GenVertexArrays(1, (&renderer_state.quad_vao)[0..1]);
    gl.GenBuffers(1, (&renderer_state.quad_vbo)[0..1]);
    gl.GenBuffers(1, (&renderer_state.quad_ibo)[0..1]);

    {
        // Make our VAO the current global VAO, but unbind it when we're done so we don't end up
        // inadvertently modifying it later.
        gl.BindVertexArray(renderer_state.quad_vao);
        defer gl.BindVertexArray(0);

        {
            // Make our VBO the current global VBO and unbind it when we're done.
            gl.BindBuffer(gl.ARRAY_BUFFER, renderer_state.quad_vbo);
            defer gl.BindBuffer(gl.ARRAY_BUFFER, 0);

            // Upload vertex data to the VBO.
            gl.BufferData(
                gl.ARRAY_BUFFER,
                @sizeOf(@TypeOf(quad_mesh.vertices)),
                &quad_mesh.vertices,
                gl.STATIC_DRAW,
            );

            const position_attrib: c_uint = @intCast(gl.GetAttribLocation(renderer_state.default_shader_program, "a_Position"));
            gl.EnableVertexAttribArray(position_attrib);
            gl.VertexAttribPointer(
                position_attrib,
                @typeInfo(quad_mesh.Vertex.Position).array.len,
                gl.FLOAT,
                gl.FALSE,
                @sizeOf(quad_mesh.Vertex),
                @offsetOf(quad_mesh.Vertex, "position"),
            );

            const uv_attrib: c_uint = @intCast(gl.GetAttribLocation(renderer_state.default_shader_program, "a_TexCoord"));
            gl.EnableVertexAttribArray(uv_attrib);
            gl.VertexAttribPointer(
                uv_attrib,
                @typeInfo(quad_mesh.Vertex.UV).array.len,
                gl.FLOAT,
                gl.FALSE,
                @sizeOf(quad_mesh.Vertex),
                @offsetOf(quad_mesh.Vertex, "uv"),
            );
        }

        gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, renderer_state.quad_ibo);
        gl.BufferData(
            gl.ELEMENT_ARRAY_BUFFER,
            @sizeOf(@TypeOf(quad_mesh.indices)),
            &quad_mesh.indices,
            gl.STATIC_DRAW,
        );
    }
}

fn flush() void {
    std.sort.insertion(Quad, renderer_state.draw_queue.items, void{}, quadLessThan);
    for (renderer_state.draw_queue.items) |quad| {
        internalDrawQuad(quad);
    }

    renderer_state.draw_queue.clearRetainingCapacity();
}
