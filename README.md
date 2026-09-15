# time-sharing-system

一個以 x86 為目標、從 bootloader 開始實作的簡易作業系統專案。目前版本已完成基本開機流程、32-bit protected mode 切換、核心載入，以及 VGA 文字模式輸出。

> 目前仍處於最小可啟動核心階段，尚未實作真正的多工、程序管理或使用者空間。

## 開發環境

本專案以 macOS 為主要開發環境，依賴以下工具：

- `i686-elf-binutils`
- `i686-elf-gcc`
- `qemu`

安裝方式：

```bash
brew install i686-elf-binutils
brew install i686-elf-gcc
brew install qemu
```

## 專案結構

```text
my_os/
├── boot/
│   ├── bootsect.S       # 16-bit boot sector，使用 BIOS 載入後續程式
│   └── setup.s          # 啟用 A20、建立 GDT，切換至 32-bit protected mode
├── drivers/
│   ├── vga.h            # VGA 文字模式介面
│   └── vga.c            # VGA 文字驅動、游標、換頁與顏色
├── kernel/
│   ├── io.h             # x86 Port I/O 封裝
│   └── kernel.c         # 核心進入點
├── lib/
│   ├── string.h         # 核心使用的字串與記憶體函式宣告
│   └── string.c         # strlen、memset、memcpy、itoa
├── kernel.ld             # Kernel linker script
└── Makefile              # 建置、執行與清理指令
```

## 開機與記憶體配置

目前的磁碟映像檔由以下部分組成：

| 磁碟區段 | 內容 | 載入位置 |
|---|---|---|
| Sector 1 | `bootsect.bin` | BIOS 載入至 `0x0000:0x7C00` |
| Sector 2–5 | `setup.bin` | `0x0000:0x7E00` |
| Sector 6–15 | `kernel.bin` | `0x1000:0x0000`，線性位址 `0x10000` |

開機流程如下：

1. BIOS 載入 boot sector。
2. `bootsect.S` 使用 BIOS `INT 0x13` 載入 setup 與 kernel。
3. 跳轉至 `setup.s`。
4. setup 啟用 A20、載入 GDT，並將 CPU 切換至 32-bit protected mode。
5. 建立 32-bit stack 後，呼叫位於 `0x10000` 的 `kernel_main`。
6. Kernel 初始化 VGA 並顯示測試訊息。

## 建置與執行

在專案根目錄執行：

```bash
make -C my_os
```

成功後會產生：

- `my_os/bootsect.bin`
- `my_os/setup.bin`
- `my_os/kernel.bin`
- `my_os/kernel.elf`
- `my_os/os.img`

使用 QEMU 啟動：

```bash
make -C my_os run
```

清理建置產物：

```bash
make -C my_os clean
```

## 目前功能

- 16-bit boot sector 初始化與 BIOS 磁碟讀取
- Boot drive 編號保存
- setup 與 kernel 載入錯誤訊息
- A20 位址線啟用
- GDT 建立與 protected mode 切換
- 32-bit kernel stack 初始化
- VGA 80x25 文字模式輸出
- 游標位置更新
- 換行、回車與畫面滾動
- 前景色與背景色設定
- 十進位與十六進位整數輸出
- 基本字串與記憶體操作函式

目前核心啟動後會顯示：

```text
Hello World
```

## 目前限制與後續方向

目前尚未包含：

- Interrupt Descriptor Table（IDT）與硬體中斷
- Programmable Interval Timer（PIT）
- 鍵盤輸入
- 程序與執行緒管理
- Context switching
- Scheduler
- 記憶體管理與 paging
- 使用者模式與系統呼叫
- 檔案系統

後續預計以 Timer interrupt、程序控制區塊（PCB）與 context switching 為基礎，逐步加入 time-sharing system 所需的多工核心功能。

## 目前版本更新摘要

### Boot 與核心啟動

- 新增 16-bit boot sector。
- 使用 BIOS 磁碟服務載入 setup 與 kernel。
- 新增磁碟讀取失敗訊息與停止流程。
- 新增從 real mode 切換至 32-bit protected mode 的 setup 程式。
- 啟用 A20 位址線並建立 flat-model GDT。
- 將 kernel 載入並連結至線性位址 `0x10000`。

### Kernel 與 VGA

- 新增 `kernel_main` 核心進入點。
- 新增 VGA 文字模式驅動。
- 支援游標更新、換行、回車與畫面滾動。
- 支援 VGA 前景色與背景色。
- 新增整數輸出與基本字串函式。

### 建置工具

- 新增 Makefile，自動完成 boot sector、setup、kernel 與磁碟映像檔建置。
- 新增 QEMU 執行指令。
- 新增清理編譯產物的指令。
