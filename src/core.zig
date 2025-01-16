const std = @import("std");

const gl = @import("gl");
const glfw = @import("glfw");

const renderer = @import("renderer.zig");

// TODO: some better memory management
pub const allocator = std.heap.page_allocator;

// TODO: find better place for these (global state)
pub var window: glfw.Window = undefined;
var procs: gl.ProcTable = undefined;

// deltaTimer
var dt_timer: std.time.Timer = undefined;
var delta_time: f64 = 0.0;

const glfw_log = std.log.scoped(.glfw);
const gl_log = std.log.scoped(.gl);

fn logGLFWError(error_code: glfw.ErrorCode, description: [:0]const u8) void {
    glfw_log.err("{}: {s}\n", .{ error_code, description });
}

fn glfwSizeCallback(win: glfw.Window, width: i32, height: i32) void {
    _ = win;
    renderer.onResize(width, height);
}

// TODO: move math
pub const Vec2 = struct {
    x: f32,
    y: f32,
};

pub const Vec4 = struct {
    x: f32,
    y: f32,
    z: f32,
    w: f32,
};

pub const InitOptions = struct {
    window_width: u32 = 1280,
    window_height: u32 = 720,
    window_title: [*:0]const u8 = "CoreX App",

    /// Ignores `window_width` and `window_height`
    /// as it will be overwritten when the resize happens
    start_maximized: bool = false,
    vsync: bool = true,
};

pub fn init(options: InitOptions) !void {
    if (@import("builtin").mode == .Debug) {
        glfw.setErrorCallback(logGLFWError);
    }

    if (!glfw.init(.{})) {
        return error.GLFWerror;
    }

    window = glfw.Window.create(options.window_width, options.window_height, options.window_title, null, null, .{
        .context_version_major = gl.info.version_major,
        .context_version_minor = gl.info.version_minor,
        .opengl_profile = .opengl_core_profile,
    }) orelse return error.GLFWerror;
    window.setSizeCallback(glfwSizeCallback);

    glfw.makeContextCurrent(window);

    if (!procs.init(glfw.getProcAddress)) return error.GLerror;
    gl.makeProcTableCurrent(&procs);

    glfw.swapInterval(if (options.vsync) 1 else 0);

    try renderer.init();

    // needs to happen after renderer.init()
    if (options.start_maximized) {
        window.maximize();
    }

    dt_timer = try std.time.Timer.start();
}

pub fn deinit() void {
    renderer.deinit();

    gl.makeProcTableCurrent(null);
    glfw.makeContextCurrent(null);
    window.destroy();
    glfw.terminate();
}

/// Should be the first thing called on each frame
pub fn update() void {
    const t = dt_timer.lap();
    delta_time = @as(f64, @floatFromInt(t)) / @as(f64, @floatFromInt(std.time.ns_per_s));

    glfw.pollEvents();
}

pub fn deltaTime() f64 {
    return delta_time;
}

/// Returns deltaTime but as an `f32`
pub fn deltaTimef() f32 {
    // TODO: think if this is what we want
    return @floatCast(delta_time);
}

pub fn windowShouldClose() bool {
    return window.shouldClose();
}

pub fn quit() void {
    window.setShouldClose(true);
}

pub fn setWindowTitle(comptime fmt: []const u8, args: anytype) void {
    const title = std.fmt.allocPrintZ(allocator, fmt, args) catch |err| {
        std.log.err("setWindowTitle: {s}", .{@errorName(err)});
        return;
    };
    window.setTitle(title);
}

///////////////
//// INPUT ////
///////////////
pub const Key = glfw.Key;

pub fn isKeyPressed(key: Key) bool {
    return window.getKey(key) == .press;
}