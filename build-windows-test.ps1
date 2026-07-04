# continuwuity Windows native build test (SunfyInput 2026-06-30)
#   Linux-only features OFF: io_uring / jemalloc / systemd / journald
#   Windows-safe subset: compression + media + url_preview + ring TLS
#   Toolchain: E:\ VS2022 Community MSVC + G:\LLVM (libclang) + C:\Program Files\NASM
$ErrorActionPreference = "Stop"

# --- 1. Import MSVC x64 dev environment from vcvars64.bat ---
$vcvars = "E:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvars64.bat"
Write-Host "Importing MSVC env from vcvars64..."
$envDump = cmd /c "`"$vcvars`" >nul 2>&1 && set"
foreach ($line in $envDump) {
    if ($line -match '^([^=]+)=(.*)$') {
        Set-Item -Path ("Env:" + $matches[1]) -Value $matches[2]
    }
}

# --- 2. libclang (bindgen -> RocksDB FFI bindings) ---
$env:LIBCLANG_PATH = "G:\LLVM\bin"

# --- 3. Prepend LLVM + NASM to PATH ---
$env:PATH = "G:\LLVM\bin;C:\Program Files\NASM;" + $env:PATH

# --- 4. Toolchain diagnostics ---
Write-Host "==================== TOOLCHAIN CHECK ===================="
Write-Host ("cl      : " + ((Get-Command cl.exe    -ErrorAction SilentlyContinue).Source))
Write-Host ("clang   : " + ((Get-Command clang.exe -ErrorAction SilentlyContinue).Source))
Write-Host ("nasm    : " + ((Get-Command nasm.exe  -ErrorAction SilentlyContinue).Source))
Write-Host ("cmake   : " + ((Get-Command cmake.exe -ErrorAction SilentlyContinue).Source))
Write-Host ("cargo   : " + ((Get-Command cargo.exe -ErrorAction SilentlyContinue).Source))
Write-Host ("LIBCLANG_PATH = " + $env:LIBCLANG_PATH)
Write-Host "========================================================"

# --- 5. Build (Windows-safe feature subset, size-optimized profile) ---
# Uses the locally-added [profile.release-small] in Cargo.toml (inherits release,
# adds lto="fat" + codegen-units=1 + opt-level="z") to shrink the exe.
# Output lands in target/release-small/conduwuit.exe.
$features = "zstd_compression,brotli_compression,gzip_compression,media_thumbnail,url_preview,ring,element_hacks,bindgen-runtime,release_max_log_level"
Write-Host "cargo build --profile release-small --no-default-features --features $features"
cargo build --profile release-small --no-default-features --features $features
Write-Host "==================== BUILD EXIT CODE: $LASTEXITCODE ===================="
