//! Win32 type definitions for Zig 0.15+
//!
//! Manual definitions since std.os.windows doesn't expose all needed types

const std = @import("std");

//=============================================================================
// Basic Types - Use std.os.windows types where available
//=============================================================================

pub const WINAPI = std.builtin.CallingConvention.winapi;
pub const BOOL = c_int;
pub const DWORD = c_ulong;
pub const LONG = c_long;
pub const HRESULT = LONG;
pub const HINSTANCE = std.os.windows.HINSTANCE;
pub const HKEY = *opaque {};
pub const LPVOID = ?*anyopaque;

//=============================================================================
// Constants
//=============================================================================

pub const TRUE: BOOL = 1;
pub const FALSE: BOOL = 0;

// DLL reasons
pub const DLL_PROCESS_ATTACH: DWORD = 1;
pub const DLL_THREAD_ATTACH: DWORD = 2;
pub const DLL_THREAD_DETACH: DWORD = 3;
pub const DLL_PROCESS_DETACH: DWORD = 0;

// HRESULT values
pub const S_OK: HRESULT = 0;
pub const S_FALSE: HRESULT = 1;
pub const E_FAIL: HRESULT = @bitCast(@as(u32, 0x80004005));
pub const E_INVALIDARG: HRESULT = @bitCast(@as(u32, 0x80070057));
pub const E_NOINTERFACE: HRESULT = @bitCast(@as(u32, 0x80004002));
pub const E_OUTOFMEMORY: HRESULT = @bitCast(@as(u32, 0x8007000E));
pub const CLASS_E_CLASSNOTAVAILABLE: HRESULT = @bitCast(@as(u32, 0x80040111));
pub const CLASS_E_NOAGGREGATION: HRESULT = @bitCast(@as(u32, 0x80040110));
pub const SELFREG_E_CLASS: HRESULT = @bitCast(@as(u32, 0x80040201));

// Registry
pub const HKEY_CLASSES_ROOT: HKEY = @ptrFromInt(0x80000000);
pub const HKEY_LOCAL_MACHINE: HKEY = @ptrFromInt(0x80000002);
pub const KEY_ALL_ACCESS: DWORD = 0xF003F;
pub const REG_SZ: DWORD = 1;
pub const ERROR_SUCCESS: LONG = 0;

pub const MAX_PATH: usize = 260;

//=============================================================================
// GUID
//=============================================================================

pub const GUID = extern struct {
    Data1: u32,
    Data2: u16,
    Data3: u16,
    Data4: [8]u8,
};

//=============================================================================
// External Functions
//=============================================================================

pub extern "advapi32" fn RegCreateKeyExA(
    hKey: HKEY,
    lpSubKey: [*:0]const u8,
    Reserved: DWORD,
    lpClass: ?[*:0]const u8,
    dwOptions: DWORD,
    samDesired: DWORD,
    lpSecurityAttributes: ?*anyopaque,
    phkResult: *HKEY,
    lpdwDisposition: ?*DWORD,
) callconv(WINAPI) LONG;

pub extern "advapi32" fn RegSetValueExA(
    hKey: HKEY,
    lpValueName: ?[*:0]const u8,
    Reserved: DWORD,
    dwType: DWORD,
    lpData: [*]const u8,
    cbData: DWORD,
) callconv(WINAPI) LONG;

pub extern "advapi32" fn RegCloseKey(
    hKey: HKEY,
) callconv(WINAPI) LONG;

pub extern "advapi32" fn RegDeleteTreeA(
    hKey: HKEY,
    lpSubKey: ?[*:0]const u8,
) callconv(WINAPI) LONG;

pub extern "kernel32" fn GetModuleFileNameA(
    hModule: ?HINSTANCE,
    lpFilename: [*]u8,
    nSize: DWORD,
) callconv(WINAPI) DWORD;

pub extern "kernel32" fn GetModuleFileNameW(
    hModule: ?HINSTANCE,
    lpFilename: [*]u16,
    nSize: DWORD,
) callconv(WINAPI) DWORD;

//=============================================================================
// COM Functions
//=============================================================================

pub extern "ole32" fn CoCreateInstance(
    rclsid: *const GUID,
    pUnkOuter: ?*anyopaque,
    dwClsContext: DWORD,
    riid: *const GUID,
    ppv: *?*anyopaque,
) callconv(WINAPI) HRESULT;

pub extern "ole32" fn CoInitializeEx(
    pvReserved: ?*anyopaque,
    dwCoInit: DWORD,
) callconv(WINAPI) HRESULT;

pub extern "ole32" fn CoUninitialize() callconv(WINAPI) void;

// CoInit flags
pub const COINIT_APARTMENTTHREADED: DWORD = 0x2;

// CLSCTX
pub const CLSCTX_INPROC_SERVER: DWORD = 0x1;

//=============================================================================
// ITfInputProcessorProfiles Interface
//=============================================================================

/// CLSID_TF_InputProcessorProfiles {33C53A50-F456-4884-B049-85FD643ECFED}
pub const CLSID_TF_InputProcessorProfiles = GUID{
    .Data1 = 0x33C53A50,
    .Data2 = 0xF456,
    .Data3 = 0x4884,
    .Data4 = .{ 0xB0, 0x49, 0x85, 0xFD, 0x64, 0x3E, 0xCF, 0xED },
};

/// IID_ITfInputProcessorProfiles {1F02B6C5-7842-4EE6-8A0B-9A24183A95CA}
pub const IID_ITfInputProcessorProfiles = GUID{
    .Data1 = 0x1F02B6C5,
    .Data2 = 0x7842,
    .Data3 = 0x4EE6,
    .Data4 = .{ 0x8A, 0x0B, 0x9A, 0x24, 0x18, 0x3A, 0x95, 0xCA },
};

/// IID_ITfInputProcessorProfileMgr {71C6E74C-0F28-11D8-A82A-00065B84435C}
pub const IID_ITfInputProcessorProfileMgr = GUID{
    .Data1 = 0x71C6E74C,
    .Data2 = 0x0F28,
    .Data3 = 0x11D8,
    .Data4 = .{ 0xA8, 0x2A, 0x00, 0x06, 0x5B, 0x84, 0x43, 0x5C },
};

/// ITfInputProcessorProfiles VTable
pub const ITfInputProcessorProfilesVtbl = extern struct {
    // IUnknown
    QueryInterface: *const fn (*anyopaque, *const GUID, *?*anyopaque) callconv(WINAPI) HRESULT,
    AddRef: *const fn (*anyopaque) callconv(WINAPI) u32,
    Release: *const fn (*anyopaque) callconv(WINAPI) u32,
    // ITfInputProcessorProfiles
    Register: *const fn (*anyopaque, *const GUID) callconv(WINAPI) HRESULT,
    Unregister: *const fn (*anyopaque, *const GUID) callconv(WINAPI) HRESULT,
    AddLanguageProfile: *const fn (
        *anyopaque,
        *const GUID, // rclsid
        u16, // langid
        *const GUID, // guidProfile
        [*:0]const u16, // pchDesc
        u32, // cchDesc
        [*:0]const u16, // pchIconFile
        u32, // cchFile
        u32, // uIconIndex
    ) callconv(WINAPI) HRESULT,
    RemoveLanguageProfile: *const fn (*anyopaque, *const GUID, u16, *const GUID) callconv(WINAPI) HRESULT,
    // ... other methods not needed for registration
};

pub const ITfInputProcessorProfiles = extern struct {
    vtable: *const ITfInputProcessorProfilesVtbl,
};

//=============================================================================
// ITfCategoryMgr Interface
//=============================================================================

/// CLSID_TF_CategoryMgr {A4B544A1-438D-4B41-9325-869523E2D6C7}
pub const CLSID_TF_CategoryMgr = GUID{
    .Data1 = 0xA4B544A1,
    .Data2 = 0x438D,
    .Data3 = 0x4B41,
    .Data4 = .{ 0x93, 0x25, 0x86, 0x95, 0x23, 0xE2, 0xD6, 0xC7 },
};

/// IID_ITfCategoryMgr {C3ACEFB5-F69D-4905-938F-FCADCF4BE830}
pub const IID_ITfCategoryMgr = GUID{
    .Data1 = 0xC3ACEFB5,
    .Data2 = 0xF69D,
    .Data3 = 0x4905,
    .Data4 = .{ 0x93, 0x8F, 0xFC, 0xAD, 0xCF, 0x4B, 0xE8, 0x30 },
};

/// GUID_TFCAT_TIP_KEYBOARD {34745C63-B2F0-4784-8B67-5E12C8701A31}
pub const GUID_TFCAT_TIP_KEYBOARD = GUID{
    .Data1 = 0x34745C63,
    .Data2 = 0xB2F0,
    .Data3 = 0x4784,
    .Data4 = .{ 0x8B, 0x67, 0x5E, 0x12, 0xC8, 0x70, 0x1A, 0x31 },
};

/// ITfCategoryMgr VTable
pub const ITfCategoryMgrVtbl = extern struct {
    // IUnknown
    QueryInterface: *const fn (*anyopaque, *const GUID, *?*anyopaque) callconv(WINAPI) HRESULT,
    AddRef: *const fn (*anyopaque) callconv(WINAPI) u32,
    Release: *const fn (*anyopaque) callconv(WINAPI) u32,
    // ITfCategoryMgr
    RegisterCategory: *const fn (*anyopaque, *const GUID, *const GUID, *const GUID) callconv(WINAPI) HRESULT,
    UnregisterCategory: *const fn (*anyopaque, *const GUID, *const GUID, *const GUID) callconv(WINAPI) HRESULT,
    // ... other methods
};

pub const ITfCategoryMgr = extern struct {
    vtable: *const ITfCategoryMgrVtbl,
};
