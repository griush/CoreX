const core = @import("core.zig");
const renderer = @import("renderer.zig");

// Constants
pub const colors = struct {
    pub const white = Vec4{ .x = 1.0, .y = 1.0, .z = 1.0, .w = 1.0 };
    pub const black = Vec4{ .x = 0.0, .y = 0.0, .z = 0.0, .w = 1.0 };

    pub const red = Vec4{ .x = 1.0, .y = 0.0, .z = 0.0, .w = 1.0 };
    pub const green = Vec4{ .x = 0.0, .y = 1.0, .z = 0.0, .w = 1.0 };
    pub const blue = Vec4{ .x = 0.0, .y = 0.0, .z = 1.0, .w = 1.0 };

    pub const yellow = Vec4{ .x = 1.0, .y = 1.0, .z = 0.0, .w = 1.0 };
    pub const cyan = Vec4{ .x = 0.0, .y = 1.0, .z = 1.0, .w = 1.0 };
};

// Core
pub const Vec2 = core.Vec2;
pub const Vec4 = core.Vec4;
pub const InitOptions = core.InitOptions;
pub const init = core.init;
pub const deinit = core.deinit;
pub const update = core.update;
pub const deltaTime = core.deltaTime;
pub const deltaTimef = core.deltaTimef;
pub const windowShouldClose = core.windowShouldClose;
pub const quit = core.quit;
pub const setWindowTitle = core.setWindowTitle;

// Input
pub const Key = core.Key;
pub const isKeyPressed = core.isKeyPressed;

// Renderer
pub const Quad = renderer.Quad;

pub const beginDraw = renderer.beginDraw;
pub const endDraw = renderer.endDraw;

pub const drawQuad = renderer.drawQuad;
