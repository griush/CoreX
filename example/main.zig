const std = @import("std");

const cx = @import("corex");

pub fn main() !void {
    // init CoreX
    try cx.init(.{
        .allocator = std.heap.page_allocator,
        .window_title = "CoreX Example",
        .window_width = 1280,
        .window_height = 720,
    });
    defer cx.deinit();

    // load assets
    var checkerboard = try cx.Texture.init(.{
        .filepath = "example/assets/textures/checkerboard.png",
        .filter_mode = .nearest,
    });
    defer checkerboard.deinit();

    // var swan_lake = try cx.Sound.init(.{
    //     .filepath = "example/assets/audio/swan_lake.mp3",
    //     .loop = false,
    //     .volume = 0.5,
    // });
    // defer swan_lake.deinit();

    // setup game state
    var playing = false;
    // TODO: make input helper for this
    var s_key_handled = false; // trick for single press check
    var camera_dir = cx.Vec2{ 0.0, 0.0 };
    var rotation: f32 = 0.0;
    const camera_speed = 10.0;
    var main_camera = cx.Camera2D{
        .size = 7.5,
    };

    // game loop
    while (!cx.windowShouldClose()) {
        cx.update(); // first thing called on each frame

        cx.setWindowTitle("CoreX Example | FPS: {d:.3}", .{1.0 / cx.deltaTime()});

        // handle user input and update state
        if (cx.isKeyPressed(.escape)) {
            cx.quit();
        }

        if (cx.isKeyPressed(.left)) {
            camera_dir[0] += -1.0;
        }
        if (cx.isKeyPressed(.right)) {
            camera_dir[0] += 1.0;
        }
        if (cx.isKeyPressed(.up)) {
            camera_dir[1] += 1.0;
        }
        if (cx.isKeyPressed(.down)) {
            camera_dir[1] += -1.0;
        }
        if (cx.isKeyPressed(.q)) {
            rotation += 180.0 * cx.deltaTimef();
        }
        if (cx.isKeyPressed(.e)) {
            rotation -= 180.0 * cx.deltaTimef();
        }
        if (cx.isKeyPressed(.s)) {
            // TODO: input: change to isKeyDown and add isKeyPressed
            if (!s_key_handled) {
                s_key_handled = true;
                if (playing) {
                    playing = false;
                    // try swan_lake.stop();
                } else {
                    playing = true;
                    // try swan_lake.start();
                }
            }
        } else {
            s_key_handled = false;
        }

        // normalize camera speed
        const dir_magnitude = cx.math.magnitude(camera_dir);
        if (dir_magnitude > 0.0) {
            main_camera.position[0] += (camera_dir[0] / dir_magnitude) * camera_speed * cx.deltaTimef();
            main_camera.position[1] += (camera_dir[1] / dir_magnitude) * camera_speed * cx.deltaTimef();
        }
        main_camera.rotation = rotation;
        camera_dir = cx.Vec2{ 0.0, 0.0 };

        cx.beginFrame(cx.color.black);
        // render 2D scene
        cx.beginScene2D(&main_camera);

        cx.drawQuad(.{ .scale = .{ 7.0, 7.0 }, .z_index = -1, .color = cx.color.blue, .texture = checkerboard, .tiling = 7.0 });

        if (cx.isMouseButtonPressed(.right)) {
            cx.drawQuad(.{ .position = .{ 0.0, @floatCast(std.math.sin(cx.getTime())) }, .color = cx.color.orange, .z_index = 1, .texture = checkerboard });
        } else {
            cx.drawQuad(.{ .position = .{ 0.0, @floatCast(std.math.sin(cx.getTime())) }, .color = cx.color.red, .z_index = 1, .texture = checkerboard });
        }

        cx.drawQuad(.{ .position = .{ 1.0, 1.0 }, .color = cx.color.dark_gray });
        cx.drawQuad(.{ .position = .{ 1.0, 0.0 }, .color = cx.color.gray });
        cx.drawQuad(.{ .position = .{ 1.0, -1.0 }, .color = cx.color.light_gray });

        cx.drawQuad(.{ .position = .{ 0.0, 2.0 }, .texture = checkerboard });

        cx.drawQuad(.{ .position = .{ -1.5, -2.0 }, .rotation = @floatCast(cx.getTime() * 180.0), .scale = .{ 2.0, 2.0 }, .tiling = 2.0, .texture = checkerboard });

        cx.endScene2D();

        // then, render UI
        cx.beginUI();
        cx.drawQuad(.{
            .position = .{ 125.0, 50.0 },
            .scale = .{ 250.0, 100.0 },
            .color = cx.color.yellow,
        });
        cx.drawQuad(.{
            .position = .{ 50.0, 150.0 },
            .scale = .{ 100.0, 100.0 },
            .color = if (playing) cx.color.green else cx.color.red,
        });
        cx.endUI();

        cx.endFrame();
    }
}
