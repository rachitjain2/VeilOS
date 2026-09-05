# VEILOS Developer Workspace

The **DEVELOPER WORKSPACE** profile provides a preconfigured, disposable programming environment.

## Architecture

Developers can compile code, clone repositories, and install dependencies (`npm install`, `pip install`) with zero side effects on the host operating system. When the workspace closes, all installed packages and ephemeral scratch files are scrubbed from RAM.

```
veil-run --profile development
          │
          ▼
   Bubblewrap Sandbox
   ├── Root Filesystem: Read-Only (/usr, /lib, /bin)
   ├── Ephemeral Workspace: tmpfs ($HOME/project)
   ├── Resource Quota: 4096 MB RAM, max 1024 PIDs
   └── Host Files: Blocked / Masked
          │
          ▼
   veilos-dev-starter
   ├── Geany / Mousepad (Code Editor)
   └── XFCE Terminal (Pre-navigated to $HOME/project)
```

---

## Installed Packages & Toolchain

The following packages are baked directly into the VEILOS live rootfs:

| Component | Exact Debian Package(s) | Description |
| :--- | :--- | :--- |
| **Git** | `git` | Distributed version control |
| **Node.js** | `nodejs` | JavaScript runtime |
| **npm** | `npm` | Node package manager |
| **Python 3** | `python3`, `python3-dev` | Python 3 interpreter and headers |
| **pip & venv** | `python3-pip`, `python3-venv` | Python package manager and virtual environments |
| **C/C++ Toolchain** | `build-essential`, `gcc`, `g++`, `make`, `pkg-config` | Core compilers and build utilities |
| **Network Tools** | `curl`, `wget`, `ca-certificates` | HTTP/HTTPS transfer utilities |
| **Code Editor** | `geany`, `geany-plugins`, `mousepad` | Fast, lightweight local IDE / editor |
| **Terminal & Shell** | `xfce4-terminal`, `tmux` | Multi-pane terminal environment |
| **Utilities** | `htop`, `tree`, `jq`, `unzip`, `zip` | CLI inspect and extraction tools |

---

## Package Isolation (`npm`, `pip`)

When a developer runs:
```bash
npm install express
```
or
```bash
pip install flask
```

1. Files are downloaded into the isolated workspace directory:
   - `~/project/node_modules/`
   - `~/.npm-global/`
   - `~/.cache/pip/`
2. The host filesystem `/` remains completely **Read-Only** (`--ro-bind`).
3. The host user's actual home directory is completely invisible.
4. On workspace exit, the entire ephemeral tree is zeroed and wiped.