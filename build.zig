const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "gsettings-gui",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    // Enable libc for C allocator and system libraries
    exe.linkLibC();

    // Enlazar con las bibliotecas del sistema GTK4 y GIO
    exe.linkSystemLibrary("gtk4");
    exe.linkSystemLibrary("glib-2.0");
    exe.linkSystemLibrary("gio-2.0");
    exe.linkSystemLibrary("gobject-2.0");
    exe.linkSystemLibrary("cairo");
    exe.linkSystemLibrary("pango");
    exe.linkSystemLibrary("pangocairo");

    b.installArtifact(exe);

    // Comando de ejecución
    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Ejecutar la aplicación GUI");
    run_step.dependOn(&run_cmd.step);
}
