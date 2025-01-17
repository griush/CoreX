const cx = @import("corex");

pub fn main() !void {
    try cx.init(.{
        .window_title = "CoreX Example",
        .window_width = 1920,
        .window_height = 1080,
        .start_maximized = true,
    });
    defer cx.deinit();

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

        cx.beginDraw();
        cx.drawQuad(.{ .position = .{ .x = 1.0, .y = 0.0 }, .color = cx.colors.white, .z_index = -5 });
        cx.drawQuad(.{ .position = .{ .x = 1.0, .y = 1.0 }, .color = cx.colors.yellow, .z_index = 3 });
        cx.drawQuad(.{ .position = .{ .x = x, .y = y }, .color = cx.colors.cyan, .z_index = 0 });
        cx.endDraw();
    }
}
