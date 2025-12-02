//! Windows Registry operations for TSF registration
//!
//! Uses ITfInputProcessorProfiles COM interface for proper TIP registration.

const std = @import("std");
const w = @import("win32.zig");
const globals = @import("globals.zig");
const com = @import("com.zig");

//=============================================================================
// Helper Functions
//=============================================================================

/// Get the full path to this DLL (Wide string version)
fn getDllPathW(buf: []u16) ?[]const u16 {
    const len = w.GetModuleFileNameW(globals.g_hInstance, buf.ptr, @intCast(buf.len));
    if (len == 0 or len >= buf.len) return null;
    return buf[0..len];
}

/// Get the full path to this DLL (ANSI version)
fn getDllPath(buf: []u8) ?[]const u8 {
    const len = w.GetModuleFileNameA(globals.g_hInstance, buf.ptr, @intCast(buf.len));
    if (len == 0 or len >= buf.len) return null;
    return buf[0..len];
}

/// Format GUID as string "{xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx}"
fn formatGuid(guid: *const w.GUID, buf: []u8) ?[:0]const u8 {
    const result = std.fmt.bufPrintZ(buf, "{{{X:0>8}-{X:0>4}-{X:0>4}-{X:0>2}{X:0>2}-{X:0>2}{X:0>2}{X:0>2}{X:0>2}{X:0>2}{X:0>2}}}", .{
        guid.Data1,
        guid.Data2,
        guid.Data3,
        guid.Data4[0],
        guid.Data4[1],
        guid.Data4[2],
        guid.Data4[3],
        guid.Data4[4],
        guid.Data4[5],
        guid.Data4[6],
        guid.Data4[7],
    }) catch return null;
    return result;
}

/// Create a registry key and set its default value
fn createKeyWithValue(hKeyParent: w.HKEY, subKey: [*:0]const u8, value: ?[*:0]const u8) w.HRESULT {
    var hKey: w.HKEY = undefined;
    if (w.RegCreateKeyExA(hKeyParent, subKey, 0, null, 0, w.KEY_ALL_ACCESS, null, &hKey, null) != w.ERROR_SUCCESS) {
        return w.E_FAIL;
    }
    defer _ = w.RegCloseKey(hKey);

    if (value) |val| {
        const len: w.DWORD = @intCast(std.mem.len(val) + 1);
        if (w.RegSetValueExA(hKey, null, 0, w.REG_SZ, @ptrCast(val), len) != w.ERROR_SUCCESS) {
            return w.E_FAIL;
        }
    }

    return w.S_OK;
}

//=============================================================================
// CLSID Registration (Registry-based, still needed)
//=============================================================================

/// Register COM CLSID in HKEY_CLASSES_ROOT\CLSID
pub fn registerCLSID() w.HRESULT {
    var guidStr: [64]u8 = undefined;
    const clsidStr = formatGuid(&globals.CLSID_AzkiTextService, &guidStr) orelse return w.E_FAIL;

    var dllPath: [w.MAX_PATH]u8 = undefined;
    const path = getDllPath(&dllPath) orelse return w.E_FAIL;

    // Create path-terminated version
    var pathZ: [w.MAX_PATH]u8 = undefined;
    @memcpy(pathZ[0..path.len], path);
    pathZ[path.len] = 0;

    // CLSID\{guid}
    var keyPath: [128]u8 = undefined;
    const clsidKey = std.fmt.bufPrintZ(&keyPath, "CLSID\\{s}", .{clsidStr}) catch return w.E_FAIL;

    // Create CLSID key with description
    if (createKeyWithValue(w.HKEY_CLASSES_ROOT, clsidKey, "Azki Text Service") != w.S_OK) {
        return w.E_FAIL;
    }

    // CLSID\{guid}\InprocServer32
    var serverKeyPath: [160]u8 = undefined;
    const serverKey = std.fmt.bufPrintZ(&serverKeyPath, "CLSID\\{s}\\InprocServer32", .{clsidStr}) catch return w.E_FAIL;

    var hKey: w.HKEY = undefined;
    if (w.RegCreateKeyExA(w.HKEY_CLASSES_ROOT, serverKey, 0, null, 0, w.KEY_ALL_ACCESS, null, &hKey, null) != w.ERROR_SUCCESS) {
        return w.E_FAIL;
    }
    defer _ = w.RegCloseKey(hKey);

    // Set default value (DLL path)
    if (w.RegSetValueExA(hKey, null, 0, w.REG_SZ, @ptrCast(&pathZ), @intCast(path.len + 1)) != w.ERROR_SUCCESS) {
        return w.E_FAIL;
    }

    // Set ThreadingModel
    const threadModel = "Apartment";
    if (w.RegSetValueExA(hKey, "ThreadingModel", 0, w.REG_SZ, threadModel, @intCast(threadModel.len + 1)) != w.ERROR_SUCCESS) {
        return w.E_FAIL;
    }

    return w.S_OK;
}

/// Unregister COM CLSID
pub fn unregisterCLSID() w.HRESULT {
    var guidStr: [64]u8 = undefined;
    const clsidStr = formatGuid(&globals.CLSID_AzkiTextService, &guidStr) orelse return w.E_FAIL;

    var keyPath: [128]u8 = undefined;
    const clsidKey = std.fmt.bufPrintZ(&keyPath, "CLSID\\{s}", .{clsidStr}) catch return w.E_FAIL;

    _ = w.RegDeleteTreeA(w.HKEY_CLASSES_ROOT, clsidKey);

    return w.S_OK;
}

//=============================================================================
// TIP Registration using COM interfaces
//=============================================================================

/// Wide string for "Azki"
const TEXTSERVICE_DESC_W: [*:0]const u16 = std.unicode.utf8ToUtf16LeStringLiteral("Azki");

/// Register as Text Input Processor using ITfInputProcessorProfiles
pub fn registerTIP() w.HRESULT {
    // Initialize COM
    _ = w.CoInitializeEx(null, w.COINIT_APARTMENTTHREADED);
    defer w.CoUninitialize();

    // Create ITfInputProcessorProfiles instance
    var pProfiles: ?*w.ITfInputProcessorProfiles = null;
    var hr = w.CoCreateInstance(
        &w.CLSID_TF_InputProcessorProfiles,
        null,
        w.CLSCTX_INPROC_SERVER,
        &w.IID_ITfInputProcessorProfiles,
        @ptrCast(&pProfiles),
    );

    if (hr != w.S_OK or pProfiles == null) {
        return w.E_FAIL;
    }
    defer _ = pProfiles.?.vtable.Release(pProfiles.?);

    // Register the TIP
    hr = pProfiles.?.vtable.Register(pProfiles.?, &globals.CLSID_AzkiTextService);
    if (hr != w.S_OK) {
        return hr;
    }

    // Get DLL path for icon
    var dllPathW: [w.MAX_PATH]u16 = undefined;
    const pathW = getDllPathW(&dllPathW) orelse return w.E_FAIL;
    dllPathW[pathW.len] = 0; // Null terminate

    // Add language profile for Japanese (0x0411)
    hr = pProfiles.?.vtable.AddLanguageProfile(
        pProfiles.?,
        &globals.CLSID_AzkiTextService, // rclsid
        globals.LANGID_JAPANESE, // langid
        &globals.GUID_AzkiProfile, // guidProfile
        TEXTSERVICE_DESC_W, // pchDesc
        @intCast(std.mem.len(TEXTSERVICE_DESC_W)), // cchDesc
        @ptrCast(&dllPathW), // pchIconFile
        @intCast(pathW.len), // cchFile
        0, // uIconIndex
    );

    if (hr != w.S_OK) {
        // Cleanup on failure
        _ = pProfiles.?.vtable.Unregister(pProfiles.?, &globals.CLSID_AzkiTextService);
        return hr;
    }

    return w.S_OK;
}

/// Unregister TIP using ITfInputProcessorProfiles
pub fn unregisterTIP() w.HRESULT {
    // Initialize COM
    _ = w.CoInitializeEx(null, w.COINIT_APARTMENTTHREADED);
    defer w.CoUninitialize();

    // Create ITfInputProcessorProfiles instance
    var pProfiles: ?*w.ITfInputProcessorProfiles = null;
    const hr = w.CoCreateInstance(
        &w.CLSID_TF_InputProcessorProfiles,
        null,
        w.CLSCTX_INPROC_SERVER,
        &w.IID_ITfInputProcessorProfiles,
        @ptrCast(&pProfiles),
    );

    if (hr != w.S_OK or pProfiles == null) {
        return w.E_FAIL;
    }
    defer _ = pProfiles.?.vtable.Release(pProfiles.?);

    // Unregister the TIP (this also removes all language profiles)
    _ = pProfiles.?.vtable.Unregister(pProfiles.?, &globals.CLSID_AzkiTextService);

    return w.S_OK;
}

//=============================================================================
// Category Registration
//=============================================================================

/// Register TSF categories using ITfCategoryMgr
pub fn registerCategories() w.HRESULT {
    // Initialize COM
    _ = w.CoInitializeEx(null, w.COINIT_APARTMENTTHREADED);
    defer w.CoUninitialize();

    // Create ITfCategoryMgr instance
    var pCategoryMgr: ?*w.ITfCategoryMgr = null;
    var hr = w.CoCreateInstance(
        &w.CLSID_TF_CategoryMgr,
        null,
        w.CLSCTX_INPROC_SERVER,
        &w.IID_ITfCategoryMgr,
        @ptrCast(&pCategoryMgr),
    );

    if (hr != w.S_OK or pCategoryMgr == null) {
        return w.E_FAIL;
    }
    defer _ = pCategoryMgr.?.vtable.Release(pCategoryMgr.?);

    // Register as keyboard TIP
    hr = pCategoryMgr.?.vtable.RegisterCategory(
        pCategoryMgr.?,
        &globals.CLSID_AzkiTextService, // rclsid (our CLSID)
        &w.GUID_TFCAT_TIP_KEYBOARD, // rcatid (keyboard category)
        &globals.CLSID_AzkiTextService, // rguid (what we're registering)
    );

    return hr;
}

/// Unregister TSF categories
pub fn unregisterCategories() w.HRESULT {
    // Initialize COM
    _ = w.CoInitializeEx(null, w.COINIT_APARTMENTTHREADED);
    defer w.CoUninitialize();

    // Create ITfCategoryMgr instance
    var pCategoryMgr: ?*w.ITfCategoryMgr = null;
    const hr = w.CoCreateInstance(
        &w.CLSID_TF_CategoryMgr,
        null,
        w.CLSCTX_INPROC_SERVER,
        &w.IID_ITfCategoryMgr,
        @ptrCast(&pCategoryMgr),
    );

    if (hr != w.S_OK or pCategoryMgr == null) {
        return w.E_FAIL;
    }
    defer _ = pCategoryMgr.?.vtable.Release(pCategoryMgr.?);

    // Unregister keyboard category
    _ = pCategoryMgr.?.vtable.UnregisterCategory(
        pCategoryMgr.?,
        &globals.CLSID_AzkiTextService,
        &w.GUID_TFCAT_TIP_KEYBOARD,
        &globals.CLSID_AzkiTextService,
    );

    return w.S_OK;
}
