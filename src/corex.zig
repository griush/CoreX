const core = @import("core.zig");
pub const math = @import("math.zig");
const input = @import("input.zig");
const renderer = @import("renderer.zig");
const audio = @import("audio.zig");

// Constants
pub const color = struct {
    pub const white = Vec4{ 1.0, 1.0, 1.0, 1.0 };
    pub const black = Vec4{ 0.0, 0.0, 0.0, 1.0 };

    pub const gray = Vec4{ 0.5, 0.5, 0.5, 1.0 };
    pub const dark_gray = Vec4{ 0.15, 0.15, 0.15, 1.0 };
    pub const light_gray = Vec4{ 0.85, 0.85, 0.85, 1.0 };

    pub const red = Vec4{ 1.0, 0.0, 0.0, 1.0 };
    pub const green = Vec4{ 0.0, 1.0, 0.0, 1.0 };
    pub const blue = Vec4{ 0.0, 0.0, 1.0, 1.0 };

    pub const yellow = Vec4{ 1.0, 1.0, 0.0, 1.0 };
    pub const pink = Vec4{ 1.0, 0.0, 1.0, 1.0 };
    pub const cyan = Vec4{ 0.0, 1.0, 1.0, 1.0 };

    pub const orange = Vec4{ 0.9, 0.4, 0.05, 1.0 };
};

// Core
pub const InitOptions = core.InitOptions;

pub const init = core.init;
pub const deinit = core.deinit;
pub const update = core.update;
pub const deltaTime = core.deltaTime;
pub const deltaTimef = core.deltaTimef;
pub const windowShouldClose = core.windowShouldClose;
pub const quit = core.quit;
pub const setWindowTitle = core.setWindowTitle;
pub const getTime = core.getTime;

// Math
pub const Vec2 = math.Vec2;
pub const Vec3 = math.Vec3;
pub const Vec4 = math.Vec4;

// Input
pub const Key = input.Key;

pub const isKeyPressed = input.isKeyPressed;
pub const isMouseButtonPressed = input.isMouseButtonPressed;
pub const getMousePos = input.getMousePos;

// Renderer
pub const Camera2D = renderer.Camera2D;
pub const Quad = renderer.Quad;
pub const Texture = renderer.Texture;

pub const beginFrame = renderer.beginFrame;
pub const endFrame = renderer.endFrame;

pub const beginScene2D = renderer.beginScene2D;
pub const endScene2D = renderer.endScene2D;
pub const beginUI = renderer.beginUI;
pub const endUI = renderer.endUI;

pub const drawQuad = renderer.drawQuad;

// Audio
pub const Sound = audio.Sound;
