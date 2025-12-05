//! Azki Frontend DLL - Windows TSF Text Input Processor
//!
//! Phase 1: "Hollow" DLL - Register as a valid TIP in Windows.
//! Goal: DLL appears in language bar, host apps don't crash.

const std = @import("std");
const w = @import("win32.zig");

// Re-export modules
pub const tsf = @import("tsf.zig");
pub const com = @import("com.zig");
pub const globals = @import("globals.zig");

//=============================================================================
// DLL Exports
//=============================================================================

/// DLL Entry Point
pub export fn DllMain(
    hinstDLL: w.HINSTANCE,
    fdwReason: w.DWORD,
    _: ?*anyopaque,
) w.BOOL {
    switch (fdwReason) {
        w.DLL_PROCESS_ATTACH => {
            globals.g_hInstance = hinstDLL;
        },
        w.DLL_PROCESS_DETACH => {
            globals.g_hInstance = null;
        },
        else => {},
    }
    return w.TRUE;
}

/// Check if DLL can be unloaded
pub export fn DllCanUnloadNow() callconv(w.WINAPI) w.HRESULT {
    // Use atomic loads for consistency with atomic operations in dllAddRef/dllRelease
    const dllRef = @atomicLoad(u32, &globals.g_cDllRef, .seq_cst);
    const serverLocks = @atomicLoad(u32, &globals.g_cServerLocks, .seq_cst);
    return if (dllRef == 0 and serverLocks == 0)
        w.S_OK
    else
        w.S_FALSE;
}

/// Get class factory for creating COM objects
pub export fn DllGetClassObject(
    rclsid: ?*const w.GUID,
    riid: ?*const w.GUID,
    ppv: ?*?*anyopaque,
) callconv(w.WINAPI) w.HRESULT {
    if (ppv == null) return w.E_INVALIDARG;
    ppv.?.* = null;

    if (rclsid == null or riid == null) return w.E_INVALIDARG;

    // Check if requesting our CLSID
    if (!com.isEqualGUID(rclsid.?, &globals.CLSID_AzkiTextService)) {
        return w.CLASS_E_CLASSNOTAVAILABLE;
    }

    // Create class factory
    const factory = com.ClassFactory.create() catch return w.E_OUTOFMEMORY;

    // QueryInterface through VTable (COM style: pass pointer to vtable pointer)
    const vtable_ptr: **const com.ClassFactory.VTable = @ptrCast(&factory.vtable);
    const hr = factory.vtable.QueryInterface(vtable_ptr, riid.?, ppv.?);

    // Release our reference (caller now holds reference if QueryInterface succeeded)
    _ = factory.vtable.Release(vtable_ptr);

    return hr;
}

/// Register the DLL as a Text Input Processor
pub export fn DllRegisterServer() callconv(w.WINAPI) w.HRESULT {
    return tsf.registerServer();
}

/// Unregister the DLL
pub export fn DllUnregisterServer() callconv(w.WINAPI) w.HRESULT {
    return tsf.unregisterServer();
}

//=============================================================================
// Tests
//=============================================================================

test "GUID constants are valid" {
    try std.testing.expect(globals.CLSID_AzkiTextService.Data1 == 0x7B133824);
    try std.testing.expect(globals.GUID_AzkiProfile.Data1 == 0xF1A2B3C4);
}
