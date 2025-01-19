const std = @import("std");

const gl = @import("gl");
const glfw = @import("glfw");

const renderer = @import("renderer.zig");

pub var allocator: std.mem.Allocator = undefined;

// TODO: find better place for these (global state)
pub var window: glfw.Window = undefined;
var procs: gl.ProcTable = undefined;

// deltaTimer
var last_frame_time: f64 = 0.0;
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
    allocator: std.mem.Allocator,

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

    allocator = options.allocator;

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
    const dt = glfw.getTime() - last_frame_time;
    delta_time = dt;
    last_frame_time = glfw.getTime();

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

/// Returns time in seconds since the start of the appliaction
pub fn getTime() f64 {
    return glfw.getTime();
}

var last_title_update_time: f64 = 0.0;
pub fn setWindowTitle(comptime fmt: []const u8, args: anytype) void {
    const now = glfw.getTime();
    if (now - last_title_update_time < 0.5) {
        return;
    }

    const title = std.fmt.allocPrintZ(allocator, fmt, args) catch |err| {
        std.log.err("setWindowTitle: {s}", .{@errorName(err)});
        return;
    };
    defer allocator.free(title);

    window.setTitle(title);
    last_title_update_time = glfw.getTime();
}

///////////////
//// INPUT ////
///////////////
pub const Key = glfw.Key;

pub fn isKeyPressed(key: Key) bool {
    return window.getKey(key) == .press;
}
