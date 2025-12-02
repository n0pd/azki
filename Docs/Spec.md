# Project Specification: MySKK (Zig/Rust Hybrid IME)

**Version:** 1.0.0
**Language:** Zig (Frontend), Rust (Backend)
**Architecture:** Windows TSF Process Isolation Model
**Input Method:** SKK (Simple Kana-Kanji) + AZIK (Extended Romaji Layout)

## 1\. Project Overview

This project aims to build a custom Input Method Editor (IME) for Windows 10/11 x64 from scratch.
The system adopts a **Process Isolation Architecture** to ensure stability and ease of development.

  - **Frontend (DLL):** A lightweight TSF wrapper written in **Zig**. It runs inside the host application (e.g., Notepad) and forwards key events to the backend.
  - **Backend (EXE):** A standalone process written in **Rust**. It handles all logic (AZIK, SKK state machine), manages dictionary lookups (Internal & Mozc), and renders the candidate UI.

-----

## 2\. System Architecture

```mermaid
graph TD
    subgraph "Host Process (Notepad.exe)"
        TSF[TSF Manager]
        DLL[**Azki.dll** (Zig)]
        TSF <-->|COM (VTable)| DLL
    end

    subgraph "Backend Process (Azki_Server.exe / Rust)"
        Core[**Core Logic**]
        AZIK[**AZIK Engine**]
        Dict[**Dict Engine**]
        MozcCli[**Mozc Client**]
        GUI[**Candidate UI**]

        Core <--> AZIK
        Core <--> Dict
        Core <--> MozcCli
        Core --> GUI
    end

    subgraph "External Resources"
        File[(**SKK-JISYO.L**)]
        MozcSrv[**GoogleMozcServer**]
    end

    DLL <==>|Named Pipe (IPC)| Core
    Dict <--Load-- File
    MozcCli <==>|Named Pipe| MozcSrv
```

-----

## 3\. Component Specifications

### 3.1. Frontend: `Azki.dll` (Zig)

  * **Role:** The "Sensor" and "Actuator". No business logic.
  * **Dependencies:** `zigwin32` (for Win32 API / COM definitions).
  * **Key Responsibilities:**
    1.  **COM Server Registration:** Export `DllRegisterServer` / `DllGetClassObject`.
    2.  **TSF Implementation:**
          * `ITfTextInputProcessor`: Manage Activate/Deactivate.
          * `ITfKeystrokeSink`: Hook `OnKeyDown` / `OnKeyUp`.
    3.  **IPC Client:**
          * Connect to Named Pipe `\\.\pipe\azki_ipc`.
          * Send `KeyEvent`.
          * Receive `DrawCommand`.
    4.  **Text Composition:**
          * Execute `ITfComposition::StartComposition` / `EndComposition` based on backend commands.
          * Get caret position (`GetCaretPos` / `ITfContextView::GetTextExt`) and send to backend.

### 3.2. Backend: `MyIME_Server.exe` (Rust)

  * **Role:** The "Brain". Handles input, conversion, and UI.
  * **Dependencies:** `windows` (Win32 API), `tokio` (Async Runtime), `prost` (Protobuf), `encoding_rs` (EUC-JP support).
  * **Key Responsibilities:**
    1.  **IPC Server:** Async Named Pipe server (`tokio::net::windows::named_pipe`).
    2.  **Input Buffer & AZIK Engine:**
          * Buffer keystrokes (e.g., `k`, `z`).
          * Convert using AZIK table (e.g., `k`+`z` -\> `かん`, `;` -\> `っ`).
    3.  **SKK State Machine:**
          * Modes: `Direct`, `Hiragana` (▽), `Katakana` (▽), `OkrInput` (▽\*), `Conversion` (▼).
    4.  **Dictionary Engine (Internal):**
          * Load `SKK-JISYO.L` (EUC-JP) at startup.
          * Convert to UTF-8 in memory.
          * Store in `HashMap<String, Vec<String>>` or `fst`.
    5.  **Mozc Client:**
          * Connect to Google Japanese Input's pipe.
          * Serialize/Deserialize Protobuf messages (`mozc_commands.proto`).
    6.  **GUI Renderer:**
          * Draw a Top-Most, No-Activate overlay window (`WS_EX_TOPMOST`, `WS_EX_NOACTIVATE`) at the caret position.

-----

## 4\. Logic & Data Flow

### 4.1. AZIK Processing

The backend must maintain a pre-conversion buffer.

  * **Rule:**
      * Input: `k` -\> Buffer: `k` -\> Output: None (Pending)
      * Input: `z` -\> Buffer: `kz` -\> Match AZIK Table -\> Output: `かん`
      * Input: `;` -\> Match AZIK Table -\> Output: `っ`

### 4.2. Hybrid Conversion Strategy (Space Key)

When the user requests conversion (Space key):

1.  **Step 1:** Query **Mozc Server** via IPC. Get high-context candidates.
2.  **Step 2:** Query **Internal SKK Dictionary**. Get static dictionary candidates.
3.  **Step 3:** Merge results (Dedup).
4.  **Step 4:** Display in Candidate Window.

### 4.3. IPC Protocol (Binary Structure)

**Request (DLL -\> EXE):**

```c
// Packed struct (align(1))
struct ImeRequest {
    u8 msg_type;      // 0: KeyDown, 1: KeyUp, 2: Focus
    u16 vkey;         // Virtual Key Code
    u8 modifiers;     // Shift=1, Ctrl=2, Alt=4
    i32 caret_x;      // Screen X
    i32 caret_y;      // Screen Y
}
```

**Response (EXE -\> DLL):**

```c
struct ImeResponse {
    bool handled;     // true = Eats key (no output to app)
    u8 action;        // 0: None, 1: UpdateComp, 2: Commit
    u8 text_len;      // Length of UTF-8 text
    u8 text_bytes[128]; // The text (e.g., "▽かん")
}
```

-----

## 5\. Implementation Roadmap

### Phase 1: The "Hollow" DLL (Zig)

  * **Goal:** Register the DLL as a valid Text Input Processor (TIP) in Windows Registry.
  * **Task:** Implement `DllRegisterServer` and `ITfTextInputProcessor` stubs.
  * **Success Criteria:** Notepad opens without crashing, and "Azki" appears in the language bar.

### Phase 2: The Pipeline (IPC)

  * **Goal:** Establish communication.
  * **Task:** Implement Named Pipe Client in Zig and Server in Rust.
  * **Success Criteria:** Typing in Notepad sends logs to the Rust console.

### Phase 3: The Logic (AZIK & SKK)

  * **Goal:** Display Hiragana.
  * **Task:** Implement AZIK table and SKK "Hiragana Mode" in Rust.
  * **Success Criteria:** Typing `k` `z` in Notepad displays `▽かん` (using `ITfComposition`).

### Phase 4: The Brain (Dictionaries)

  * **Goal:** Conversion.
  * **Task:**
    1.  Implement SKK-JISYO loader (EUC-JP -\> UTF-8).
    2.  Implement Mozc Protobuf client.
  * **Success Criteria:** Pressing Space converts `▽かん` to `▼漢` / `▼勘`.

### Phase 5: The Face (GUI)

  * **Goal:** Candidate Window.
  * **Task:** Create a pure Win32 window in Rust that floats near the cursor.
  * **Success Criteria:** Candidate list is visible and selectable.

-----

## 6\. Directory Structure (Suggested)

```
/Azki
  /frontend_dll (Zig)
    build.zig
    src/
      main.zig      (Exports)
      tsf.zig       (COM Implementation)
      ipc.zig       (Named Pipe Client)
  
  /backend_core (Rust)
    Cargo.toml
    src/
      main.rs       (Entry point)
      ipc.rs        (Named Pipe Server)
      azik.rs       (Romaji Engine)
      skk.rs        (State Machine)
      dict/
        mod.rs
        internal.rs (SKK-JISYO Loader)
        mozc.rs     (Protobuf Client)
      gui/
        window.rs   (Win32 Renderer)
  
  /proto
    mozc_commands.proto
  
  /assets
    SKK-JISYO.L
```

-----

## 7\. Developer Notes (Prompting Tips)

  * **For Zig VTables:** Remember that Zig requires manual definition of VTables for COM. Use `zigwin32` types but ensure `Self` casting is done correctly in `callconv(.Stdcall)` methods.
  * **For Rust Async:** The IPC server handles multiple connections but the SKK logic is stateful per connection. Ensure the `State` struct is wrapped in `Arc<Mutex<State>>` or processed in a dedicated loop per connection.
  * **For Mozc:** Mozc's named pipe on Windows usually follows the format `\\.\pipe\google_japanese_input.<SessionID>`. You need to resolve the correct pipe name dynamically.