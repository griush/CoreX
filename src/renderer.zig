const std = @import("std");

const gl = @import("gl");
const glfw = @import("glfw");
const zm = @import("zm");

const core = @import("core.zig");

const vertex_shader_source: [:0]const u8 = @embedFile("shaders/default.glsl.vert");
const fragment_shader_source: [:0]const u8 = @embedFile("shaders/default.glsl.frag");

const glfw_log = std.log.scoped(.glfw);
const gl_log = std.log.scoped(.gl);

fn glDebugCallback(source: c_uint, t: c_uint, id: c_uint, severity: c_uint, length: c_int, message: [*:0]const u8, user_param: ?*const anyopaque) callconv(.C) void {
    _ = user_param; // autofix
    _ = length; // autofix
    _ = t; // autofix
    _ = source; // autofix
    switch (severity) {
        gl.DEBUG_SEVERITY_HIGH => gl_log.err("({d}): {s}", .{ id, message }),
        gl.DEBUG_SEVERITY_MEDIUM => gl_log.err("({d}): {s}", .{ id, message }),
        gl.DEBUG_SEVERITY_LOW => gl_log.warn("({d}): {s}", .{ id, message }),
        gl.DEBUG_SEVERITY_NOTIFICATION => gl_log.info("({d}): {s}", .{ id, message }),
        else => unreachable,
    }
}

pub fn init() !void {
    if (@import("builtin").mode == .Debug) {
        gl.Enable(gl.DEBUG_OUTPUT);
        gl.Enable(gl.DEBUG_OUTPUT_SYNCHRONOUS);
        gl.DebugMessageCallback(glDebugCallback, null);
        gl.DebugMessageControl(gl.DONT_CARE, gl.DONT_CARE, gl.DEBUG_SEVERITY_NOTIFICATION, 0, 0, gl.FALSE);
    }

    gl.Enable(gl.BLEND);
    gl.BlendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA);

    try createShaders();
    createQuad();

    const aspect = getAspectRatio();
    renderer_state.view_proj = .orthographic(-10.0 * aspect, 10.0 * aspect, -10.0, 10.0, -1.0, 1.0);
}

pub fn deinit() void {
    gl.DeleteVertexArrays(1, (&renderer_state.quad_vao)[0..1]);
    gl.DeleteBuffers(1, (&renderer_state.quad_vbo)[0..1]);
    gl.DeleteBuffers(1, (&renderer_state.quad_ibo)[0..1]);
    gl.DeleteProgram(renderer_state.default_shader_program);
}

pub fn onResize(width: i32, height: i32) void {
    gl.Viewport(0, 0, @intCast(width), @intCast(height));

    const aspect = getAspectRatio();
    renderer_state.view_proj = .orthographic(-10.0 * aspect, 10.0 * aspect, -10.0, 10.0, -1.0, 1.0);
}

const renderer_state = struct {
    var quad_vao: gl.uint = undefined;
    var quad_vbo: gl.uint = undefined;
    var quad_ibo: gl.uint = undefined;
    var default_shader_program: gl.uint = undefined;

    var view_proj: zm.Mat4f = .identity();

    // draw queue
    var draw_queue = std.ArrayList(Quad).init(core.allocator);
};

pub const Quad = struct {
    position: core.Vec2 = .{ .x = 0, .y = 0 },
    z_index: i32 = 0,
    color: core.Vec4 = .{ .x = 1.0, .y = 1.0, .z = 1.0, .w = 1.0 },
};

fn quadLessThan(ctx: void, a: Quad, b: Quad) bool {
    _ = ctx;
    return a.z_index < b.z_index;
}

pub fn beginDraw(clear_color: core.Vec4) void {
    renderer_state.draw_queue.clearRetainingCapacity();

    gl.ClearColor(clear_color.x, clear_color.y, clear_color.z, 1.0);
    gl.Clear(gl.COLOR_BUFFER_BIT);
}

pub fn endDraw() void {
    // draw queue
    std.sort.insertion(Quad, renderer_state.draw_queue.items, void{}, quadLessThan);
    for (renderer_state.draw_queue.items) |quad| {
        internalDrawQuad(quad);
    }

    core.window.swapBuffers();
}

pub fn drawQuad(q: Quad) void {
    renderer_state.draw_queue.append(q) catch |err| {
        std.log.err("drawQuad(): {s}", .{@errorName(err)});
    };
}

fn internalDrawQuad(q: Quad) void {
    gl.UseProgram(renderer_state.default_shader_program);
    defer gl.UseProgram(0);

    // camera
    gl.UniformMatrix4fv(gl.GetUniformLocation(renderer_state.default_shader_program, "u_ViewProjection"), 1, gl.TRUE, @ptrCast(&(renderer_state.view_proj)));

    // transform
    const transform = zm.Mat4f.translation(q.position.x, q.position.y, 0.0);
    gl.UniformMatrix4fv(gl.GetUniformLocation(renderer_state.default_shader_program, "u_Transform"), 1, gl.TRUE, @ptrCast(&(transform)));

    gl.Uniform4f(gl.GetUniformLocation(renderer_state.default_shader_program, "u_Color"), q.color.x, q.color.y, q.color.z, q.color.w);

    gl.BindVertexArray(renderer_state.quad_vao);
    defer gl.BindVertexArray(0);

    gl.DrawElements(gl.TRIANGLES, quad_mesh.indices.len, gl.UNSIGNED_BYTE, 0);
}

const quad_mesh = struct {
    const vertices = [_]Vertex{
        .{ .position = .{ -0.5, -0.5, 0.0 } },
        .{ .position = .{ 0.5, -0.5, 0.0 } },
        .{ .position = .{ 0.5, 0.5, 0.0 } },
        .{ .position = .{ -0.5, 0.5, 0.0 } },
    };

    const indices = [_]u8{ 0, 1, 2, 2, 3, 0 };

    const Vertex = struct {
        position: Position,
        const Position = [3]f32;
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
