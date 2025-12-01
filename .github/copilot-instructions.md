# Azki - Windows IME (Zig/Rust Hybrid)

## Architecture Overview

This is a Windows Input Method Editor (IME) implementing SKK + AZIK input methods using a **Process Isolation Model**:

- **Frontend (`frontend_dll/`)**: Zig DLL that runs inside host apps (e.g., Notepad). Lightweight TSF wrapper with zero business logic - only handles COM/TSF interfaces and IPC.
- **Backend (`backend_core/`)**: Rust EXE that handles all conversion logic, dictionary lookups, and candidate UI rendering.

Communication flows: `Host App ↔ TSF ↔ Azki.dll ↔ Named Pipe ↔ MyIME_Server.exe`

## Key Technical Constraints

### Zig Frontend (DLL)
- Uses `zigwin32` for Win32/COM definitions
- Must manually define COM VTables - ensure `Self` casting is correct in `callconv(.Stdcall)` methods
- Implements: `ITfTextInputProcessor`, `ITfKeystrokeSink`
- Exports: `DllRegisterServer`, `DllGetClassObject`
- IPC client connects to `\\.\pipe\azki_ipc`

### Rust Backend (EXE)
- Async runtime via `tokio` with `tokio::net::windows::named_pipe`
- SKK state is **per-connection** - wrap state in `Arc<Mutex<State>>` or use dedicated loop per connection
- Dictionary: `SKK-JISYO.L` (EUC-JP) loaded into `HashMap<String, Vec<String>>` or `fst`
- Mozc integration: Pipe name is dynamic `\\.\pipe\google_japanese_input.<SessionID>` - resolve at runtime

## IPC Protocol

Binary packed structs (align 1):

```
Request (DLL→EXE): msg_type:u8, vkey:u16, modifiers:u8, caret_x:i32, caret_y:i32
Response (EXE→DLL): handled:bool, action:u8, text_len:u8, text_bytes:[u8;128]
```

Actions: `0=None, 1=UpdateComp, 2=Commit`

## SKK State Machine

Modes: `Direct` → `Hiragana (▽)` → `Conversion (▼)`
- AZIK converts romaji buffered input (e.g., `kz` → `かん`, `;` → `っ`)
- Space triggers hybrid conversion: Mozc first (contextual), then SKK dictionary, merged/deduped

## Directory Structure

```
frontend_dll/     # Zig - TSF wrapper, IPC client
  src/main.zig, tsf.zig, ipc.zig
backend_core/     # Rust - Core logic, dictionaries, GUI
  src/main.rs, ipc.rs, azik.rs, skk.rs, dict/, gui/
proto/            # mozc_commands.proto
assets/           # SKK-JISYO.L dictionary
```

## Build & Development

- Zig frontend: `zig build` in `frontend_dll/`
- Rust backend: `cargo build` in `backend_core/`
- Register DLL: `regsvr32 Azki.dll` (requires admin)

## Implementation Phases

Current roadmap priority:
1. Phase 1: DLL registration (TIP appears in language bar)
2. Phase 2: IPC pipeline (keys forwarded to Rust console)
3. Phase 3: AZIK/SKK logic (hiragana display)
4. Phase 4: Dictionary integration (conversion works)
5. Phase 5: Candidate UI (floating window)

See `Docs/Spec.md` for complete specification.

## Notes

- If you generate git commit messages, please write them in English and use gitmoji style.