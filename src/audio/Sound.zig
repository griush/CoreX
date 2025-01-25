const zaudio = @import("zaudio");

const audio = @import("../audio.zig");

const Sound = @This();

pub const Options = struct {
    filepath: [:0]const u8,
    volume: f32 = 1.0,

    /// `-1.0` for left, `1.0` for right, `0.0` is middle
    pan: f32 = 0.0,
    loop: bool = false,
};

handle: *zaudio.Sound,

pub fn init(options: Options) !Sound {
    const sound = try audio.engine.?.createSoundFromFile(options.filepath, .{ .flags = .{ .stream = true } });
    sound.setLooping(options.loop);
    sound.setVolume(options.volume);
    sound.setPan(options.pan);
    return Sound{
        .handle = sound,
    };
}

pub fn deinit(sound: *Sound) void {
    sound.handle.destroy();
}

// TODO: maybe start/stop should not error
pub fn start(sound: *Sound) !void {
    try sound.handle.start();
}

pub fn stop(sound: *Sound) !void {
    try sound.handle.stop();
}
