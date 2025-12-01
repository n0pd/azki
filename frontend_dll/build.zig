const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // 1. 先にモジュールを作成します (ここにソースやターゲット設定を入れます)
    const dll_module = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    // 2. 作成したモジュールを使ってライブラリ(DLL)を定義します
    const lib = b.addLibrary(.{
        .linkage = .dynamic, // DLLを指定
        .name = "Azki",
        .root_module = dll_module, // ★ここでモジュールを渡します
    });

    b.installArtifact(lib);
}