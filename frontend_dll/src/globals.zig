//! Azki IME Global Variables and Constants

const std = @import("std");
const w = @import("win32.zig");

//=============================================================================
// Azki-specific GUIDs
//=============================================================================

/// CLSID for Azki Text Input Processor
/// {7B133824-3747-4FC7-8D08-01431997AFD8}
pub const CLSID_AzkiTextService = w.GUID{
    .Data1 = 0x7B133824,
    .Data2 = 0x3747,
    .Data3 = 0x4FC7,
    .Data4 = .{ 0x8D, 0x08, 0x01, 0x43, 0x19, 0x97, 0xAF, 0xD8 },
};

/// Profile GUID for Azki
/// {F1A2B3C4-D5E6-7F89-0A1B-2C3D4E5F6A7B}
pub const GUID_AzkiProfile = w.GUID{
    .Data1 = 0xF1A2B3C4,
    .Data2 = 0xD5E6,
    .Data3 = 0x7F89,
    .Data4 = .{ 0x0A, 0x1B, 0x2C, 0x3D, 0x4E, 0x5F, 0x6A, 0x7B },
};

//=============================================================================
// TSF Category GUIDs (re-exported from win32)
//=============================================================================

pub const GUID_TFCAT_TIP_KEYBOARD = w.GUID_TFCAT_TIP_KEYBOARD;

//=============================================================================
// Language Constants
//=============================================================================

/// Language ID for Japanese (ja-JP)
pub const LANGID_JAPANESE: u16 = 0x0411;

//=============================================================================
// Display Strings
//=============================================================================

/// Display name for the IME
pub const TEXTSERVICE_DESC = "Azki";

/// Icon index in the DLL resource
pub const TEXTSERVICE_ICON_INDEX: u32 = 0;

//=============================================================================
// Global State
//=============================================================================

/// DLL module handle
pub var g_hInstance: ?w.HINSTANCE = null;

/// Count of active COM object references
pub var g_cDllRef: u32 = 0;

/// Count of server locks (from IClassFactory::LockServer)
pub var g_cServerLocks: u32 = 0;

//=============================================================================
// Utility Functions
//=============================================================================

/// Increment DLL reference count (thread-safe)
pub fn dllAddRef() void {
    _ = @atomicRmw(u32, &g_cDllRef, .Add, 1, .seq_cst);
}

/// Decrement DLL reference count (thread-safe)
pub fn dllRelease() void {
    _ = @atomicRmw(u32, &g_cDllRef, .Sub, 1, .seq_cst);
}

/// Increment server lock count (thread-safe)
pub fn serverLock() void {
    _ = @atomicRmw(u32, &g_cServerLocks, .Add, 1, .seq_cst);
}

/// Decrement server lock count (thread-safe)
pub fn serverUnlock() void {
    _ = @atomicRmw(u32, &g_cServerLocks, .Sub, 1, .seq_cst);
}
