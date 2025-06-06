const std = @import("std");

const gl = @import("gl");
const glfw = @import("glfw");

const renderer = @import("renderer.zig");
// const audio = @import("audio.zig");

pub var allocator: std.mem.Allocator = undefined;

// TODO: find better place for these (global state)
pub var window: *glfw.Window = undefined;

// deltaTime
var last_frame_time: f64 = 0.0;
var delta_time: f64 = 0.0;

const glfw_log = std.log.scoped(.glfw);

fn logGLFWError(error_code: glfw.ErrorCode, description: [*c]const u8) callconv(.c) void {
    glfw_log.err("{}: {s}\n", .{ error_code, description });
}

fn glfwSizeCallback(win: *glfw.Window, width: c_int, height: c_int) callconv(.c) void {
    _ = win;
    renderer.onResize(width, height);
}

pub const InitOptions = struct {
    allocator: std.mem.Allocator,

    window_width: u32 = 1280,
    window_height: u32 = 720,
    window_title: [:0]const u8 = "CoreX App",

    /// Ignores `window_width` and `window_height`
    /// as it will be overwritten when the resize happens
    start_maximized: bool = false,
    vsync: bool = true,
};

pub fn init(options: InitOptions) !void {
    if (@import("builtin").mode == .Debug) {
        _ = glfw.setErrorCallback(logGLFWError);
    }

    allocator = options.allocator;

    glfw.init() catch return error.glfw_error;

    window = glfw.Window.create(@intCast(options.window_width), @intCast(options.window_height), options.window_title, null) catch return error.glfw_error;
    _ = window.setSizeCallback(glfwSizeCallback);

    glfw.makeContextCurrent(window);

    glfw.swapInterval(if (options.vsync) 1 else 0);

    try renderer.init();

    // needs to happen after renderer.init() to triger a resize
    // TODO: do this
    // if (options.start_maximized) {}

    // TODO: uncomment
    // try audio.init();
}

pub fn deinit() void {
    // audio.deinit();
    renderer.deinit();

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
