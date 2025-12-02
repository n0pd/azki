//! Windows Registry Operations for TSF Registration
//!
//! Uses ITfInputProcessorProfiles COM interface for proper TIP registration.

const std = @import("std");
const w = @import("win32.zig");
const globals = @import("globals.zig");

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
    const clsidStr = globals.CLSID_AzkiTextService.format(&guidStr) orelse return w.E_FAIL;

    var dllPath: [w.MAX_PATH]u8 = undefined;
    const path = getDllPath(&dllPath) orelse return w.E_FAIL;

    // Create null-terminated version
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
    const clsidStr = globals.CLSID_AzkiTextService.format(&guidStr) orelse return w.E_FAIL;

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
    // Initialize COM - S_OK means initialized, S_FALSE means already initialized (both OK)
    const initHr = w.CoInitializeEx(null, w.COINIT_APARTMENTTHREADED);
    if (w.FAILED(initHr)) {
        return initHr;
    }
    const shouldUninit = initHr == w.S_OK;
    defer if (shouldUninit) w.CoUninitialize();

    // Create ITfInputProcessorProfiles instance
    var pProfiles: ?*w.ITfInputProcessorProfiles = null;
    var hr = w.CoCreateInstance(
        &w.CLSID_TF_InputProcessorProfiles,
        null,
        w.CLSCTX_INPROC_SERVER,
        &w.IID_ITfInputProcessorProfiles,
        @ptrCast(&pProfiles),
    );

    if (w.FAILED(hr) or pProfiles == null) {
        return if (w.FAILED(hr)) hr else w.E_FAIL;
    }
    defer _ = pProfiles.?.release();

    // Register the TIP
    hr = pProfiles.?.register(&globals.CLSID_AzkiTextService);
    if (w.FAILED(hr)) {
        return hr;
    }

    // Get DLL path for icon
    var dllPathW: [w.MAX_PATH]u16 = undefined;
    const pathW = getDllPathW(&dllPathW) orelse {
        // Cleanup on failure
        _ = pProfiles.?.unregister(&globals.CLSID_AzkiTextService);
        return w.E_FAIL;
    };
    dllPathW[pathW.len] = 0; // Null terminate

    // Add language profile for Japanese (0x0411)
    hr = pProfiles.?.addLanguageProfile(
        &globals.CLSID_AzkiTextService,
        globals.LANGID_JAPANESE,
        &globals.GUID_AzkiProfile,
        TEXTSERVICE_DESC_W,
        @intCast(std.mem.len(TEXTSERVICE_DESC_W)),
        @ptrCast(&dllPathW),
        @intCast(pathW.len),
        0,
    );

    if (w.FAILED(hr)) {
        // Cleanup on failure
        _ = pProfiles.?.unregister(&globals.CLSID_AzkiTextService);
        return hr;
    }

    return w.S_OK;
}

/// Unregister TIP using ITfInputProcessorProfiles
pub fn unregisterTIP() w.HRESULT {
    // Initialize COM - S_OK means initialized, S_FALSE means already initialized (both OK)
    const initHr = w.CoInitializeEx(null, w.COINIT_APARTMENTTHREADED);
    if (w.FAILED(initHr)) {
        return initHr;
    }
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

    if (w.FAILED(hr) or pProfiles == null) {
        return if (w.FAILED(hr)) hr else w.E_FAIL;
    }
    defer _ = pProfiles.?.release();

    // Unregister the TIP (this also removes all language profiles)
    _ = pProfiles.?.unregister(&globals.CLSID_AzkiTextService);

    return w.S_OK;
}

//=============================================================================
// Category Registration
//=============================================================================

/// Register TSF categories using ITfCategoryMgr
pub fn registerCategories() w.HRESULT {
    // Initialize COM - S_OK means initialized, S_FALSE means already initialized (both OK)
    const initHr = w.CoInitializeEx(null, w.COINIT_APARTMENTTHREADED);
    if (w.FAILED(initHr) and initHr != w.RPC_E_CHANGED_MODE) {
        return initHr;
    }
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

    if (w.FAILED(hr) or pCategoryMgr == null) {
        return if (w.FAILED(hr)) hr else w.E_FAIL;
    }
    defer _ = pCategoryMgr.?.release();

    // Register as keyboard TIP
    hr = pCategoryMgr.?.registerCategory(
        &globals.CLSID_AzkiTextService,
        &w.GUID_TFCAT_TIP_KEYBOARD,
        &globals.CLSID_AzkiTextService,
    );

    return hr;
}

/// Unregister TSF categories
pub fn unregisterCategories() w.HRESULT {
    // Initialize COM - S_OK means initialized, S_FALSE means already initialized (both OK)
    const initHr = w.CoInitializeEx(null, w.COINIT_APARTMENTTHREADED);
    if (w.FAILED(initHr)) {
        return initHr;
    }
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

    if (w.FAILED(hr) or pCategoryMgr == null) {
        return if (w.FAILED(hr)) hr else w.E_FAIL;
    }
    defer _ = pCategoryMgr.?.release();

    // Unregister keyboard category
    _ = pCategoryMgr.?.unregisterCategory(
        &globals.CLSID_AzkiTextService,
        &w.GUID_TFCAT_TIP_KEYBOARD,
        &globals.CLSID_AzkiTextService,
    );

    return w.S_OK;
}
