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

        cx.beginDraw();
        cx.drawQuad(.{ .x = 1.0, .y = 0.0 }, cx.colors.green);
        cx.drawQuad(.{ .x = 1.0, .y = 1.0 }, cx.colors.cyan);
        cx.drawQuad(.{ .x = x, .y = 0.0 }, cx.colors.red);
        cx.endDraw();
    }
}
