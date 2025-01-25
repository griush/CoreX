// TODO: temp audio engine, for sure revisit
const zaudio = @import("zaudio");

const core = @import("core.zig");

pub const Sound = @import("audio/Sound.zig");

pub var engine: ?*zaudio.Engine = null;

pub fn init() !void {
    zaudio.init(core.allocator);
    engine = try zaudio.Engine.create(null);
}

pub fn deinit() void {
    engine.?.destroy();
    zaudio.deinit();
}
