const std = @import("std");
const builtin = @import("builtin");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const default_use_llvm = switch (target.result.os.tag) {
        .linux => false,
        else => true,
    };
    const use_llvm = b.option(bool, "llvm", "Use LLVM as backend") orelse default_use_llvm;

    // module
    const corex_mod = b.addModule("corex", .{
        .root_source_file = b.path("src/corex.zig"),
        .target = target,
        .optimize = optimize,
    });

    // dep: glfw
    const zglfw = b.dependency("zglfw", .{
        .target = target,
        .optimize = optimize,
    });
    corex_mod.addImport("glfw", zglfw.module("root"));
    if (target.result.os.tag != .emscripten) {
        corex_mod.linkLibrary(zglfw.artifact("glfw"));
    }

    // dep: gl
    const gl_bindings = @import("zigglgen").generateBindingsModule(b, .{
        .api = .gl,
        .version = if (builtin.os.tag == .macos) .@"4.1" else .@"4.3",
        .profile = .core,
        .extensions = &.{},
    });
    corex_mod.addImport("gl", gl_bindings);

    // dep: zm
    const zm = b.dependency("zm", .{
        .target = target,
        .optimize = optimize,
    });
    corex_mod.addImport("zm", zm.module("zm"));

    // dep: zigimg
    const zigimg_dependency = b.dependency("zigimg", .{});
    corex_mod.addImport("zigimg", zigimg_dependency.module("zigimg"));

    // dep: zaudio
    // TODO: crashes with master, enable when fixed
    // const zaudio = b.dependency("zaudio", .{});
    // corex_mod.addImport("zaudio", zaudio.module("root"));
    // corex_mod.linkLibrary(zaudio.artifact("miniaudio"));

    // example
    const example_mod = b.createModule(.{
        .root_source_file = b.path("example/main.zig"),
        .target = target,
        .optimize = optimize,
    });
    example_mod.addImport("corex", corex_mod);
    const example_exe = b.addExecutable(.{
        .name = "corex-example",
        .root_module = example_mod,
        .use_lld = use_llvm,
        .use_llvm = use_llvm,
    });
    b.installArtifact(example_exe);
    const run_cmd = b.addRunArtifact(example_exe);
    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("example", "Run the example");
    run_step.dependOn(&run_cmd.step);
}
