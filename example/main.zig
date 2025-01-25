const std = @import("std");

const cx = @import("corex");

pub fn main() !void {
    try cx.init(.{
        .allocator = std.heap.page_allocator,
        .window_title = "CoreX Example",
        .window_width = 1280,
        .window_height = 720,
    });
    defer cx.deinit();

    var checkerboard = try cx.Texture.init(.{
        .filepath = "example/textures/checkerboard.png",
        .filter_mode = .nearest,
    });
    defer checkerboard.deinit();

    var x: f32 = 0.0;
    var y: f32 = 0.0;
    var rotation: f32 = 0.0;
    var main_camera = cx.Camera2D{
        .size = 7.5,
    };
    while (!cx.windowShouldClose()) {
        cx.update();

        cx.setWindowTitle("CoreX Example | FPS: {d:.3}", .{1.0 / cx.deltaTime()});

        if (cx.isKeyPressed(.escape)) {
            cx.quit();
        }

        if (cx.isKeyPressed(.left)) {
            x -= 10.0 * cx.deltaTimef();
        }
        if (cx.isKeyPressed(.right)) {
            x += 10.0 * cx.deltaTimef();
        }
        if (cx.isKeyPressed(.up)) {
            y += 10.0 * cx.deltaTimef();
        }
        if (cx.isKeyPressed(.down)) {
            y -= 10.0 * cx.deltaTimef();
        }
        if (cx.isKeyPressed(.q)) {
            rotation -= 90.0 * cx.deltaTimef();
        }
        if (cx.isKeyPressed(.e)) {
            rotation += 90.0 * cx.deltaTimef();
        }

        main_camera.position.x = x;
        main_camera.position.y = y;
        main_camera.rotation = rotation;

        cx.beginFrame(cx.color.black);
        cx.beginScene2D(&main_camera);

        cx.drawQuad(.{ .size = .{ .x = 7.0, .y = 7.0 }, .z_index = -1, .color = cx.color.blue, .texture = checkerboard, .tiling = 7.0 });

        if (cx.isMouseButtonPressed(.right)) {
            cx.drawQuad(.{ .position = .{ .x = 0.0, .y = @floatCast(std.math.sin(cx.getTime())) }, .color = cx.color.green, .z_index = 1, .texture = checkerboard });
        } else {
            cx.drawQuad(.{ .position = .{ .x = 0.0, .y = @floatCast(std.math.sin(cx.getTime())) }, .color = cx.color.red, .z_index = 1, .texture = checkerboard });
        }

        cx.drawQuad(.{ .position = .{ .x = 1.0, .y = 0.0 }, .color = cx.color.gray });
        cx.drawQuad(.{ .position = .{ .x = 1.0, .y = 1.0 }, .color = cx.color.dark_gray });
        cx.drawQuad(.{ .position = .{ .x = 1.0, .y = -1.0 }, .color = cx.color.light_gray });

        cx.drawQuad(.{ .position = .{ .x = 0.0, .y = 2.0 }, .texture = checkerboard });

        cx.endScene2D();

        cx.beginUI();
        cx.drawQuad(.{
            .position = .{ .x = 125.0, .y = 50.0 },
            .size = .{ .x = 250.0, .y = 100.0 },
            .color = cx.color.yellow,
        });
        cx.endUI();

        cx.endFrame();
    }
}
