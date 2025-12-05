//! TSF (Text Services Framework) COM Interface Definitions
//!
//! Definitions for ITfInputProcessorProfiles, ITfCategoryMgr, etc.

const base = @import("base.zig");
const GUID = base.GUID;
const HRESULT = base.HRESULT;
const WINAPI = base.WINAPI;

//=============================================================================
// ITfInputProcessorProfiles
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
};

pub const ITfInputProcessorProfiles = extern struct {
    vtable: *const ITfInputProcessorProfilesVtbl,

    pub inline fn release(self: *ITfInputProcessorProfiles) u32 {
        return self.vtable.Release(self);
    }

    pub inline fn register(self: *ITfInputProcessorProfiles, clsid: *const GUID) HRESULT {
        return self.vtable.Register(self, clsid);
    }

    pub inline fn unregister(self: *ITfInputProcessorProfiles, clsid: *const GUID) HRESULT {
        return self.vtable.Unregister(self, clsid);
    }

    pub inline fn addLanguageProfile(
        self: *ITfInputProcessorProfiles,
        clsid: *const GUID,
        langid: u16,
        profile: *const GUID,
        desc: [*:0]const u16,
        desc_len: u32,
        icon_file: [*:0]const u16,
        icon_file_len: u32,
        icon_index: u32,
    ) HRESULT {
        return self.vtable.AddLanguageProfile(
            self,
            clsid,
            langid,
            profile,
            desc,
            desc_len,
            icon_file,
            icon_file_len,
            icon_index,
        );
    }
};

//=============================================================================
// ITfCategoryMgr
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

pub const ITfCategoryMgrVtbl = extern struct {
    // IUnknown
    QueryInterface: *const fn (*anyopaque, *const GUID, *?*anyopaque) callconv(WINAPI) HRESULT,
    AddRef: *const fn (*anyopaque) callconv(WINAPI) u32,
    Release: *const fn (*anyopaque) callconv(WINAPI) u32,
    // ITfCategoryMgr
    RegisterCategory: *const fn (*anyopaque, *const GUID, *const GUID, *const GUID) callconv(WINAPI) HRESULT,
    UnregisterCategory: *const fn (*anyopaque, *const GUID, *const GUID, *const GUID) callconv(WINAPI) HRESULT,
};

pub const ITfCategoryMgr = extern struct {
    vtable: *const ITfCategoryMgrVtbl,

    pub inline fn release(self: *ITfCategoryMgr) u32 {
        return self.vtable.Release(self);
    }

    pub inline fn registerCategory(
        self: *ITfCategoryMgr,
        clsid: *const GUID,
        catid: *const GUID,
        guid: *const GUID,
    ) HRESULT {
        return self.vtable.RegisterCategory(self, clsid, catid, guid);
    }

    pub inline fn unregisterCategory(
        self: *ITfCategoryMgr,
        clsid: *const GUID,
        catid: *const GUID,
        guid: *const GUID,
    ) HRESULT {
        return self.vtable.UnregisterCategory(self, clsid, catid, guid);
    }
};

//=============================================================================
// TSF Category GUIDs
//=============================================================================

/// GUID_TFCAT_TIP_KEYBOARD - Keyboard TIP category
pub const GUID_TFCAT_TIP_KEYBOARD = GUID{
    .Data1 = 0x34745C63,
    .Data2 = 0xB2F0,
    .Data3 = 0x4784,
    .Data4 = .{ 0x8B, 0x67, 0x5E, 0x12, 0xC8, 0x70, 0x1A, 0x31 },
};
