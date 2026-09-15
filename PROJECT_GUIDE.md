# time-sharing-system 教學與研究指南

Copyright (C) 2026 YUNG-EN KU / XiaoKu1022  
SPDX-License-Identifier: GPL-3.0-or-later

本文件說明 `time-sharing-system` 的設計、啟動流程與研究方向。專案刻意維持在小型、可讀、容易追蹤的範圍，適合用來學習作業系統最早期的啟動階段：從 BIOS 載入第一段程式，到 CPU 進入 32-bit protected mode，再由核心直接操作 VGA 文字記憶體。

目前的程式不是完整的作業系統，也不是可以執行一般應用程式的 Unix-like 系統。它是一個可啟動的核心原型，後續可在此基礎上研究中斷、多工、記憶體管理與系統呼叫。

## 1. 學習目標

本專案目前涵蓋以下幾個作業系統基礎概念：

1. **Boot sector 與 BIOS**
   - 了解 BIOS 如何將磁碟第一個 sector 載入 `0x7C00`。
   - 使用 BIOS `INT 0x13` 服務讀取後續磁區。
   - 理解 boot signature `0xAA55` 的用途。
2. **x86 real mode**
   - 使用 16-bit 暫存器與 segment:offset 位址。
   - 使用 BIOS `INT 0x10` 顯示開機訊息。
3. **Protected mode**
   - 啟用 A20 位址線。
   - 建立 Global Descriptor Table（GDT）。
   - 設定 `CR0.PE` 並透過 far jump 重新載入 code segment。
4. **Freestanding kernel**
   - 在沒有作業系統與標準 C runtime 的環境中編譯 C 程式。
   - 直接使用記憶體映射 I/O 與 x86 port I/O。
5. **核心分層**
   - 以 boot、kernel、driver、lib 分離不同責任。
   - 使用 linker script 決定 kernel 的載入位址與 section 順序。

## 2. 系統整體架構

```text
BIOS
  │
  ├─ 載入 Sector 1
  ▼
bootsect.S  (16-bit real mode, 0x7C00)
  │
  ├─ BIOS INT 0x13 載入 setup.bin
  ├─ BIOS INT 0x13 載入 kernel.bin
  ▼
setup.s     (先以 16-bit 執行，再切換至 32-bit)
  │
  ├─ 啟用 A20
  ├─ 載入 GDT
  ├─ 設定 CR0.PE
  ├─ far jump 至 protected mode
  └─ 呼叫 0x10000
  ▼
kernel_main()
  │
  ├─ 初始化 VGA driver
  ├─ 顯示 Hello World
  └─ hlt 無限迴圈
```

目前核心沒有 scheduler，因此 `kernel_main` 是唯一執行中的程式。`hlt` 迴圈只是讓 CPU 在沒有工作時停止執行，不代表已經具備多工能力。

## 3. 磁碟映像與記憶體配置

`Makefile` 將下列檔案依序合併為 `os.img`：

| 磁碟區段 | 大小 | 內容 | 目的地 |
|---|---:|---|---|
| Sector 1 | 512 bytes | `bootsect.bin` | `0x0000:0x7C00` |
| Sector 2–5 | 2048 bytes | `setup.bin` | `0x0000:0x7E00` |
| Sector 6–15 | 5120 bytes | `kernel.bin` | `0x1000:0x0000` |
| 其餘空間 | 補零 | 磁碟映像填充 | — |

### 3.1 Segment:offset 位址

在 real mode 中，實體位址大致以以下公式計算：

```text
physical_address = segment * 16 + offset
```

因此：

```text
0x0000:0x7C00 = 0x07C00
0x0000:0x7E00 = 0x07E00
0x1000:0x0000 = 0x10000
```

kernel 在磁碟上的位置與 linker script 的設定必須一致。bootloader 將 kernel 載入線性位址 `0x10000`，而 [kernel.ld](my_os/kernel.ld) 也將 linker location counter 設為 `0x10000`。

## 4. Boot sector：從 BIOS 開始

檔案：[bootsect.S](my_os/boot/bootsect.S)

### 4.1 初始化 real mode

BIOS 載入 boot sector 後，CPU 仍處於 real mode。bootloader 會：

- 關閉中斷，避免初始化期間被非預期中斷打斷。
- 將 `DS`、`ES`、`SS` 設為零。
- 將 stack 設在 `0x7C00`，並向低位址成長。
- 保存 BIOS 放在 `DL` 的 boot drive 編號。

保存磁碟機編號很重要，因為系統可能由硬碟、軟碟或 QEMU 虛擬磁碟啟動，不能假設固定使用某個 drive number。

### 4.2 使用 BIOS 讀取磁碟

程式使用 BIOS `INT 0x13`、`AH=0x02` 讀取 CHS 磁區：

- setup：從 sector 2 開始讀取 4 個 sectors。
- kernel：從 sector 6 開始讀取 10 個 sectors。

讀取成功後，bootloader 使用 far jump：

```asm
ljmp $0x0000, $0x7e00
```

讀取失敗則顯示錯誤訊息並停在 `hlt` 迴圈。

### 4.3 Boot signature

最後兩 bytes 是：

```asm
.word 0xaa55
```

在磁碟檔案中會以 little-endian 順序形成 `55 aa`。BIOS 以此判斷 sector 是否具有可啟動格式。

## 5. Setup：進入 protected mode

檔案：[setup.s](my_os/boot/setup.s)

### 5.1 啟用 A20

早期 x86 為了相容 8086 的位址行為，可能會限制第 20 條位址線。setup 透過 port `0x92` 的 fast A20 gate 啟用 A20：

```asm
inb  $0x92, %al
orb  $0x02, %al
outb %al, $0x92
```

啟用後，CPU 才能正常存取 1 MiB 以上的位址範圍。這是切換至 protected mode 前常見的早期初始化步驟。

### 5.2 GDT

目前 GDT 包含三個 descriptor：

| Selector | 用途 | Access byte |
|---:|---|---:|
| `0x00` | Null descriptor | `0x00` |
| `0x08` | 32-bit code segment | `0x9A` |
| `0x10` | 32-bit data segment | `0x92` |

code 與 data segment 都採用 flat model：

- Base：`0x00000000`
- Limit：使用 4 KiB granularity 擴展至約 4 GiB
- Code：32-bit、可讀
- Data：32-bit、可寫

`lgdt` 只會載入 GDT descriptor。設定 `CR0.PE` 後，仍必須透過 far jump 重新載入 `CS`，讓處理器使用新的 code segment：

```asm
movl %cr0, %eax
orl  $0x01, %eax
movl %eax, %cr0
ljmp $0x08, $protected_mode_entry
```

### 5.3 Protected-mode 初始化

切換後，setup 會將 data selector `0x10` 載入 `DS`、`ES`、`FS`、`GS` 與 `SS`，再把 stack 設為 `0x90000`。

程式會在 VGA 記憶體 `0xB8000` 寫入 `PM`，作為進入 protected mode 的簡單視覺標記。接著呼叫位於 `0x10000` 的 kernel。

## 6. Linker script 與 kernel 入口

檔案：[kernel.ld](my_os/kernel.ld)

linker script 的核心設定如下：

```ld
ENTRY(kernel_main)

SECTIONS
{
    . = 0x10000;
    ...
}
```

這裡有兩個重要效果：

1. 將 `kernel_main` 設為 ELF entry point。
2. 將 kernel 的 section 安排在 `0x10000` 開始，使其符合 bootloader 的載入位置。

`.entry` section 被放在 `.text` 最前面，`kernel.c` 透過 GCC attribute 將 `kernel_main` 放入該 section：

```c
__attribute__((section(".entry")))
void kernel_main(void);
```

這能讓 kernel 被載入後，`0x10000` 的第一個程式碼位置就是核心入口。

## 7. Kernel 與 freestanding C

檔案：[kernel.c](my_os/kernel/kernel.c)

核心使用以下編譯選項：

- `-ffreestanding`：表示程式不依賴 hosted C environment。
- `-nostdlib`：不連結標準 C library 與預設 runtime。
- `-fno-pie`：避免產生 position-independent executable。
- `-fno-stack-protector`：避免加入需要 runtime 支援的 stack protector。
- `-I.`：讓核心模組能找到專案內的 header。

由於沒有標準輸出、作業系統服務或 libc，核心必須自行提供需要的函式。例如 [string.c](my_os/lib/string.c) 實作了 `strlen`、`memset`、`memcpy` 與 `itoa`。

## 8. VGA 文字驅動

檔案：[vga.c](my_os/drivers/vga.c)

傳統 VGA 文字模式的起始位址是 `0xB8000`。每個螢幕字元佔用 16 bits：

```text
bits 0–7   : ASCII character
bits 8–15  : color attribute
```

目前使用 80x25 的畫面：

```c
#define VGA_WIDTH  80
#define VGA_HEIGHT 25
```

驅動提供：

- `vga_init()`：設定預設顏色並清除畫面。
- `vga_clear()`：清除 80x25 個文字格。
- `vga_putc()`：輸出單一字元。
- `vga_puts()`：輸出 null-terminated 字串。
- `vga_putint()`：使用 `itoa` 輸出整數。
- `vga_set_color()`：設定前景色與背景色。

硬體游標透過 VGA ports `0x3D4` 與 `0x3D5` 更新。當游標超過最後一列時，驅動會將畫面向上移動一列，並清空新的最後一列。

目前 tab 字元會被忽略，這是刻意保留的簡化行為，未來可改為移動至下一個 tab stop。

## 9. 建置流程

完整建置由 [Makefile](my_os/Makefile) 負責：

```bash
make -C my_os
```

主要步驟如下：

1. 使用 `i686-elf-as` 組譯 `bootsect.S`。
2. 使用 `i686-elf-ld` 將 boot sector 連結至 `0x7C00`，並輸出 raw binary。
3. 組譯 `setup.s`，並將其連結至 `0x7E00`。
4. 使用 `i686-elf-gcc` 編譯 C 核心模組。
5. 使用 `kernel.ld` 連結 `kernel.elf`。
6. 使用 `objcopy` 將 ELF 轉成 `kernel.bin`。
7. 將 kernel 補齊至 5120 bytes。
8. 串接 boot sector、setup 與 kernel，產生 1.44 MiB 的 `os.img`。

建置產物可使用以下指令移除：

```bash
make -C my_os clean
```

## 10. 使用 QEMU 測試

```bash
make -C my_os run
```

預期可觀察到：

1. boot sector 的 BIOS 訊息。
2. setup 與 kernel 載入成功訊息。
3. `PM` protected-mode 標記。
4. kernel 顯示 `Hello World`。

QEMU 以 raw disk image 啟動，因此可以直接觀察 bootloader 與 kernel 的整合結果。若要進一步除錯，可使用 QEMU monitor、GDB stub，或先以 `objdump`、`readelf` 檢查產出的 ELF 與 binary。

## 11. 目前限制

目前版本尚未實作：

- IDT 與硬體中斷處理。
- PIT 或其他 timer interrupt。
- 鍵盤驅動與輸入緩衝。
- physical memory、heap 或 paging 管理。
- Process Control Block（PCB）。
- Context switching 與 scheduler。
- User mode、system call 與權限隔離。
- 檔案系統與磁碟抽象層。
- 錯誤處理、panic 與核心診斷介面。

因此，這個版本雖然可以開機並執行 C kernel，但還不能稱為完整的 time-sharing system。

## 12. 建議研究路線

### 階段一：穩定核心基礎

1. 補上 IDT 與 exception handler。
2. 建立 `panic()` 與基本核心診斷輸出。
3. 加入 keyboard driver。
4. 改善 bootloader 的磁碟讀取錯誤處理。

### 階段二：Timer 與中斷

1. 設定 PIT。
2. 建立固定頻率 timer interrupt。
3. 在 interrupt handler 中累計 tick。
4. 確認 interrupt return 與 register preservation 正確。

### 階段三：程序與多工

1. 設計 PCB，保存 stack pointer、register 與程序狀態。
2. 實作 kernel stack。
3. 實作最小 round-robin scheduler。
4. 在 timer interrupt 中觸發 context switch。
5. 測試多個 kernel thread 是否能交替執行。

### 階段四：記憶體與使用者空間

1. 建立 page directory 與 page table。
2. 將 kernel 與 user address space 分離。
3. 實作 ring 3 user mode。
4. 透過 system call 提供輸出與程序服務。

## 13. 建議實驗

### 實驗 A：修改開機訊息

修改 [bootsect.S](my_os/boot/bootsect.S) 的 `msg_boot`，重新建置並用 QEMU 啟動。觀察 BIOS real mode 的訊息輸出。

### 實驗 B：修改 kernel 載入位置

同時修改 bootloader 的 `ES:BX`、[kernel.ld](my_os/kernel.ld) 的起始位址，以及 setup 的呼叫位置。若三者不一致，核心通常會無法正常執行。

### 實驗 C：測試 VGA 滾動

在 [kernel.c](my_os/kernel/kernel.c) 輸出超過 25 行文字，觀察 `vga.c` 的 scroll 行為，並檢查硬體游標是否仍位於正確位置。

### 實驗 D：加入新的 VGA 控制字元

修改 `vga_putc()`，為 `\t` 實作 tab stop，或加入 backspace 的處理。這可以練習終端狀態與邊界條件。

## 14. 研究時應注意的問題

- Bootloader 讀取的 sector 數量必須與實際 binary 大小一致。
- `kernel.bin` 的最大大小受 bootloader 與預留磁區數限制。
- linker 位址、載入位址與跳轉位址必須相互一致。
- Protected mode 啟用後不能直接依賴 BIOS interrupt。
- C 程式使用的函式必須確認是否需要 libc 或 compiler runtime。
- VGA、GDT、stack 與 kernel 的記憶體範圍不應互相覆蓋。
- 每次修改 boot 或 linker 相關內容後，都應重新建置並以 QEMU 驗證。

## 15. 授權

本專案以 GNU General Public License version 3 或更新版本（GPLv3-or-later）授權。
詳細條款請參閱專案根目錄的 [LICENSE](LICENSE)。
