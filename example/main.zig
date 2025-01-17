const cx = @import("corex");
const std = @import("std");

pub fn main() !void {
    try cx.init(.{
        .allocator = std.heap.page_allocator,
        .window_title = "CoreX Example",
        .window_width = 1280,
        .window_height = 720,
        .start_maximized = false,
    });
    defer cx.deinit();

    var checkerboard = try cx.Texture.init(.{
        .filepath = "example/textures/checkerboard.png",
        .filter_mode = .nearest,
    });
    defer checkerboard.deinit();

    var x: f32 = 0.0;
    var y: f32 = 0.0;
    while (!cx.windowShouldClose()) {
        cx.update();

        cx.setWindowTitle("CoreX Example | FPS: {d:.3}", .{1.0 / cx.deltaTime()});

        if (cx.isKeyPressed(.escape)) {
            cx.quit();
        }

        if (cx.isKeyPressed(.left)) {
            x -= 10.0 * cx.deltaTimef(); // 10 m/s
        }
        if (cx.isKeyPressed(.right)) {
            x += 10.0 * cx.deltaTimef(); // 10 m/s
        }
        if (cx.isKeyPressed(.up)) {
            y += 10.0 * cx.deltaTimef(); // 10 m/s
        }
        if (cx.isKeyPressed(.down)) {
            y -= 10.0 * cx.deltaTimef(); // 10 m/s
        }

        cx.beginDraw(cx.colors.black);

        cx.drawQuad(.{ .position = .{ .x = x, .y = y }, .color = cx.colors.red, .z_index = 1, .texture = checkerboard });

        cx.drawQuad(.{ .position = .{ .x = 1.0, .y = 0.0 }, .color = cx.colors.gray });
        cx.drawQuad(.{ .position = .{ .x = 1.0, .y = 1.0 }, .color = cx.colors.dark_gray });
        cx.drawQuad(.{ .position = .{ .x = 1.0, .y = -1.0 }, .color = cx.colors.light_gray });

        cx.drawQuad(.{ .position = .{ .x = 0.0, .y = 3.0 }, .texture = checkerboard });
        cx.endDraw();
    }
}
