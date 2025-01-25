const glfw = @import("glfw");
pub const Key = glfw.Key;
pub const MouseButton = glfw.MouseButton;

const core = @import("core.zig");

pub fn isKeyPressed(key: Key) bool {
    return core.window.getKey(key) == .press;
}

pub fn isMouseButtonPressed(button: MouseButton) bool {
    return core.window.getMouseButton(button) == .press;
}

pub fn getMousePos() core.Vec2 {
    const pos = core.window.getCursorPos();
    return core.Vec2{
        .x = @floatCast(pos.xpos),
        .y = @floatCast(pos.ypos),
    };
}
