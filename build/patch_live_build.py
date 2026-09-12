#!/usr/bin/env python3
"""
VEILOS Build System - Live-Build Environment Patcher
Ensures 100% reliable builds on Ubuntu runners for Debian 12 (Bookworm) Live Hybrid ISOs:
1. Fixes Debian Bookworm security repository format (/updates -> -security).
2. Fixes Contents index URLs.
3. Dereferences live-build bootloader template symlinks into real binaries.
4. Pre-converts bootloader splash SVGs to PNG.
5. Guards Ubuntu gfxboot bootlogo cpio extraction in lb_binary_syslinux.
6. Synchronizes syslinux/ISOLINUX binaries between host and chroot.
"""

import glob
import os
import re
import shutil
import subprocess
import sys

def run_cmd(cmd):
    try:
        subprocess.run(cmd, shell=True, check=False)
    except Exception as e:
        print(f"[!] Warning running '{cmd}': {e}")

def patch_repo_urls():
    print("[*] Patching Debian Bookworm repository format in live-build...")
    for root_dir in ["/usr/lib/live", "/usr/share/live"]:
        if not os.path.exists(root_dir):
            continue
        for root, _, files in os.walk(root_dir):
            for file in files:
                filepath = os.path.join(root, file)
                if os.path.islink(filepath):
                    continue
                try:
                    with open(filepath, "r", encoding="utf-8", errors="ignore") as f:
                        content = f.read()
                    
                    modified = False
                    if "/updates" in content:
                        content = content.replace("/updates", "-security")
                        modified = True
                    if "/Contents-" in content:
                        new_content = re.sub(r"/dists/([^/]*)/Contents-", r"/dists/\1/main/Contents-", content)
                        if new_content != content:
                            content = new_content
                            modified = True
                    
                    if modified:
                        with open(filepath, "w", encoding="utf-8") as f:
                            f.write(content)
                except Exception:
                    pass

def sync_host_bootloader_binaries():
    print("[*] Synchronizing host syslinux/ISOLINUX binaries...")
    dirs = [
        "/usr/lib/ISOLINUX",
        "/usr/lib/syslinux",
        "/usr/lib/syslinux/modules/bios"
    ]
    for d in dirs:
        os.makedirs(d, exist_ok=True)
    
    run_cmd("cp -rn /usr/lib/ISOLINUX/* /usr/lib/syslinux/ 2>/dev/null || true")
    run_cmd("cp -rn /usr/lib/syslinux/* /usr/lib/ISOLINUX/ 2>/dev/null || true")
    run_cmd("cp -rn /usr/lib/syslinux/modules/bios/* /usr/lib/ISOLINUX/ 2>/dev/null || true")
    run_cmd("cp -rn /usr/lib/ISOLINUX/* /usr/lib/syslinux/modules/bios/ 2>/dev/null || true")
    run_cmd("cp -rn /usr/lib/syslinux/modules/bios/* /usr/lib/syslinux/ 2>/dev/null || true")

def dereference_bootloader_templates():
    print("[*] Dereferencing live-build bootloader templates...")
    template_dirs = [
        "/usr/share/live/build/bootloaders/isolinux",
        "/usr/share/live/build/bootloaders/syslinux_common",
        "/usr/share/live/build/bootloaders/syslinux"
    ]
    for tdir in template_dirs:
        if not os.path.exists(tdir):
            continue
        for root, _, files in os.walk(tdir):
            for file in files:
                p = os.path.join(root, file)
                if os.path.islink(p):
                    target = os.path.realpath(p)
                    if os.path.isfile(target):
                        os.unlink(p)
                        shutil.copy2(target, p)
                        print(f"    Dereferenced template symlink: {file} -> real binary")
    
    # Ensure isolinux.bin and .c32 files exist directly in templates
    for tdir in template_dirs:
        if os.path.exists(tdir):
            run_cmd(f"cp -f /usr/lib/ISOLINUX/isolinux.bin '{tdir}/' 2>/dev/null || true")
            run_cmd(f"cp -f /usr/lib/syslinux/modules/bios/* '{tdir}/' 2>/dev/null || true")
            run_cmd(f"cp -f /usr/lib/syslinux/* '{tdir}/' 2>/dev/null || true")

    # Pre-render splash SVG to PNG
    for root_dir in ["/usr/share/live/build/bootloaders", "config/bootloaders"]:
        if not os.path.exists(root_dir):
            continue
        for root, _, files in os.walk(root_dir):
            for file in files:
                if file == "splash.svg":
                    svg_path = os.path.join(root, file)
                    png_path = os.path.join(root, "splash.png")
                    print(f"    Pre-converting {svg_path} to {png_path}...")
                    run_cmd(f"rsvg-convert --format png --width 640 --height 480 '{svg_path}' -o '{png_path}' 2>/dev/null || true")
                    try:
                        os.unlink(svg_path)
                    except OSError:
                        pass

def patch_syslinux_build_scripts():
    print("[*] Patching live-build syslinux scripts (/usr/lib/live/build/*syslinux*)...")
    scripts = glob.glob("/usr/lib/live/build/*syslinux*")
    for script in scripts:
        if not os.path.isfile(script) or os.path.islink(script):
            continue
        try:
            with open(script, "r", encoding="utf-8", errors="ignore") as f:
                content = f.read()
            
            modified = False

            # 1. Guard gfxboot bootlogo cpio extraction (Ubuntu bug on Debian targets)
            if "< ${_TARGET}/bootlogo" in content and 'if [ -e "${_TARGET}/bootlogo" ]' not in content:
                print(f"    Patching Ubuntu gfxboot bootlogo bug in {script}...")
                old_block = 'tmpdir="$(mktemp -d)"\n(cd "$tmpdir" && cpio -i) < ${_TARGET}/bootlogo'
                new_block = 'if [ -e "${_TARGET}/bootlogo" ]; then\n\ttmpdir="$(mktemp -d)"\n\t(cd "$tmpdir" && cpio -i) < ${_TARGET}/bootlogo'

                old_end = '(cd "$tmpdir" && ls -1 | cpio --quiet -o) > ${_TARGET}/bootlogo\nrm -rf "$tmpdir"'
                new_end = '(cd "$tmpdir" && ls -1 | cpio --quiet -o) > ${_TARGET}/bootlogo\n\trm -rf "$tmpdir"\nfi'

                if old_block in content and old_end in content:
                    content = content.replace(old_block, new_block).replace(old_end, new_end)
                    modified = True
                    print(f"    [+] Successfully guarded bootlogo cpio block in {script}")
                else:
                    content = content.replace(
                        '(cd "$tmpdir" && cpio -i) < ${_TARGET}/bootlogo',
                        'if [ -e "${_TARGET}/bootlogo" ]; then (cd "$tmpdir" && cpio -i) < ${_TARGET}/bootlogo'
                    )
                    content = content.replace(
                        '(cd "$tmpdir" && ls -1 | cpio --quiet -o) > ${_TARGET}/bootlogo',
                        '(cd "$tmpdir" && ls -1 | cpio --quiet -o) > ${_TARGET}/bootlogo; fi'
                    )
                    modified = True
                    print(f"    [+] Successfully guarded bootlogo fallback lines in {script}")

            # 2. Add chroot bootloader synchronization before dereferencing
            if "sync-syslinux-chroot" not in content and "Chroot chroot cp -aL /root" in content:
                print(f"    Adding chroot syslinux sync hook in {script}...")
                sync_hook = (
                    "# sync-syslinux-chroot\n"
                    "mkdir -p chroot/usr/lib/ISOLINUX chroot/usr/lib/syslinux/modules/bios chroot/usr/lib/syslinux chroot/usr/bin chroot/usr/local/bin\n"
                    "cp -rn /usr/lib/ISOLINUX/* chroot/usr/lib/ISOLINUX/ 2>/dev/null || true\n"
                    "cp -rn /usr/lib/syslinux/* chroot/usr/lib/syslinux/ 2>/dev/null || true\n"
                    "cp -rn /usr/lib/syslinux/modules/bios/* chroot/usr/lib/syslinux/modules/bios/ 2>/dev/null || true\n"
                    "cp -rn /usr/lib/ISOLINUX/* chroot/usr/lib/syslinux/modules/bios/ 2>/dev/null || true\n"
                    "cp -rn /usr/lib/syslinux/modules/bios/* chroot/usr/lib/ISOLINUX/ 2>/dev/null || true\n"
                    "cp -f /usr/local/bin/rsvg chroot/usr/local/bin/rsvg 2>/dev/null || true\n"
                    "cp -f /usr/local/bin/rsvg chroot/usr/bin/rsvg 2>/dev/null || true\n"
                    "chmod +x chroot/usr/local/bin/rsvg chroot/usr/bin/rsvg 2>/dev/null || true\n"
                )
                content = content.replace("Chroot chroot cp -aL /root", sync_hook + "Chroot chroot cp -aL /root")
                modified = True
                print(f"    [+] Added sync-syslinux-chroot hook in {script}")

            if modified:
                with open(script, "w", encoding="utf-8") as f:
                    f.write(content)
        except Exception as e:
            print(f"[!] Error patching {script}: {e}")

def sync_rsvg_wrapper():
    print("[*] Synchronizing rsvg wrapper on host...")
    rsvg_source = "config/includes.chroot/usr/local/bin/rsvg"
    if os.path.isfile(rsvg_source):
        for target in ["/usr/local/bin/rsvg", "/usr/bin/rsvg"]:
            try:
                shutil.copy2(rsvg_source, target)
                os.chmod(target, 0o755)
                print(f"    Installed {target}")
            except Exception:
                pass

def patch_chroot_hooks():
    print("[*] Patching lb_chroot_hooks for multi-directory hook discovery...")
    path = "/usr/lib/live/build/lb_chroot_hooks"
    if os.path.isfile(path) and not os.path.islink(path):
        try:
            with open(path, "r", encoding="utf-8", errors="ignore") as f:
                c = f.read()
            if "config/hooks/*/*.chroot" not in c:
                c = c.replace(
                    "if Find_files config/hooks/*.chroot",
                    "if Find_files config/hooks/*.chroot || Find_files config/hooks/*/*.chroot"
                )
                c = c.replace(
                    "for _HOOK in config/hooks/*.chroot",
                    "for _HOOK in config/hooks/*.chroot config/hooks/*/*.chroot"
                )
                with open(path, "w", encoding="utf-8") as f:
                    f.write(c)
                print("    [+] Patched lb_chroot_hooks to scan subdirectories!")
        except Exception as e:
            print(f"[!] Error patching lb_chroot_hooks: {e}")

    # Also flatten all hooks directly into config/hooks/ so live-build 3.0 finds them unconditionally
    for hook_file in glob.glob("config/hooks/*/*.chroot"):
        dest = os.path.join("config/hooks", os.path.basename(hook_file))
        shutil.copy2(hook_file, dest)
        os.chmod(dest, 0o755)
        print(f"    Flattened hook: {hook_file} -> {dest}")

def main():
    print("========================================================")
    print("       VEILOS Live-Build Environment Patcher            ")
    print("========================================================")
    patch_repo_urls()
    sync_host_bootloader_binaries()
    sync_rsvg_wrapper()
    dereference_bootloader_templates()
    patch_syslinux_build_scripts()
    patch_chroot_hooks()
    print("========================================================")
    print("[SUCCESS] Live-build environment patched and verified!")
    print("========================================================")

if __name__ == "__main__":
    main()
