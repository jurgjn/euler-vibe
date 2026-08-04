# https://pi.dev/docs/latest/containerization#plain-docker
FROM node:24-bookworm-slim

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        bash \
        ca-certificates \
        chromium \
        curl \
        fd-find \
        file \
        git \
        jq \
        less \
        libxml2-utils \
        lynx \
        poppler-utils \
        pandoc \
        python3 \
        python3-pip \
        ripgrep \
        sqlite3 \
        unzip \
        xz-utils \
    && rm -rf /var/lib/apt/lists/*

# fd-find installs the binary as fdfind on Debian, not fd — same Debian naming collision that bites everyone. The agent will almost certainly try fd and get command-not-found, exactly like it just did with python3. Worth symlinking.
RUN ln -s /usr/bin/fdfind /usr/local/bin/fd

# Bookworm is PEP 668-managed, so pip refuses to touch the system env without this flag.
# In a throwaway sandbox there is no system to protect, so this is the simple correct answer.
# Setting it as env too, so the *agent's own* ad-hoc `pip install` succeeds first try
# instead of failing, reading the PEP 668 hint, and retrying.
ENV PIP_BREAK_SYSTEM_PACKAGES=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PIP_ROOT_USER_ACTION=ignore

# Bookworm is PEP 668-managed, so pip refuses to touch the system env without this flag.
# In a throwaway sandbox there is no system to protect, so this is the simple correct answer.
RUN pip install --no-cache-dir \
        # PDF
        pymupdf \
        pdfplumber \
        pypdf \
        # spreadsheets. python-calamine is a Rust reader ~10x faster than openpyxl,
        # which matters for the 15 MB supplementary files; usable via
        # pd.read_excel(..., engine="calamine"). xlsx2csv streams without loading the sheet.
        openpyxl \
        python-calamine \
        xlrd \
        xlsx2csv \
        pandas \
        # tabulate is what DataFrame.to_markdown() needs. Without it the agent
        # writes the whole summary table, then hits ImportError at the last step.
        tabulate \
        # HTML/XML: proper parsers instead of re.sub(r'<[^>]+>', ' ', html)
        lxml \
        beautifulsoup4 \
        html5lib \
        html2text \
        trafilatura \
        # HTTP
        requests \
        httpx

# curl defaults. Three fixes at once:
#   --fail-with-body : the original `curl -o SuppData25.xlsx` would happily write a
#                      404 page into a .xlsx and report success. This exits non-zero.
#   --silent/--show-error : kills the progress meters that flooded the transcript.
#   browser UA       : the actual thing that got past nature.com's challenge page.
RUN printf '%s\n' \
    'location' \
    'fail-with-body' \
    'silent' \
    'show-error' \
    'retry = 3' \
    'retry-delay = 1' \
    'retry-connrefused' \
    'user-agent = "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0.0.0 Safari/537.36"' \
    > /root/.curlrc

# Point any puppeteer/playwright-flavoured code at the chromium already installed
# rather than letting it download a second copy at runtime.
ENV PUPPETEER_SKIP_DOWNLOAD=1 \
    PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium \
    CHROME_PATH=/usr/bin/chromium \
    CHROMIUM_FLAGS="--no-sandbox --disable-dev-shm-usage"

# UTF-8 everywhere. Extracted PDF text is full of ’ – ° μ; the default C locale
# turns that into UnicodeEncodeError on write.
ENV LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    PYTHONUNBUFFERED=1 \
    PYTHONIOENCODING=utf-8

# Per-sheet row counts for spreadsheets — the one operation this workload repeats
# for every supplementary file. Opinionated inclusion; drop it if you'd rather the
# agent write its own each time.
RUN cat > /usr/local/bin/xlsx-rows <<'EOF' \
    && chmod +x /usr/local/bin/xlsx-rows
#!/usr/bin/env python3
"""Print sheet name, total rows, non-empty rows, and column count for each sheet."""
import sys
from python_calamine import CalamineWorkbook

for path in sys.argv[1:]:
    try:
        wb = CalamineWorkbook.from_path(path)
    except Exception as e:
        print(f"{path}\tERROR\t{type(e).__name__}: {e}")
        continue
    for name in wb.sheet_names:
        rows = wb.get_sheet_by_name(name).to_python()
        nonempty = sum(1 for r in rows if any(str(c).strip() for c in r))
        ncol = max((len(r) for r in rows), default=0)
        print(f"{path}\t{name}\trows={len(rows)}\tnonempty={nonempty}\tcols={ncol}")
EOF

RUN npm install -g --ignore-scripts @earendil-works/pi-coding-agent

# NOTE: the previous `npm:pi-model-discovery` (no "s") is a different, older
# package (0.3.x). This is the current one, pinned so the patch step below
# always targets a known layout.
RUN pi install npm:pi-models-discovery@1.0.1

#RUN pi install npm:pi-web-extension

#RUN npm install -g agent-browser
#RUN pi install npm:pi-agent-browser-native

RUN pi install npm:pi-web-access

# Strip pi-extensions-i18n out of pi-models-discovery, keeping English only:
#   1. package.json: drop "../pi-extensions-i18n/index.ts" from the pi.extensions
#      manifest (pi reads this at load time) and the npm dependency.
#   2. locales/index.json: flatten {key: {zh-CN, en-US}} to {key: en-US string}.
#   3. src/index.ts: replace the pi-extensions-i18n import with a tiny inline
#      English-only t() that does the same {placeholder} interpolation.
#   4. package-lock.json: remove the i18n entries so a later `pi install` /
#      `pi update` inside the container can't resurrect the orphaned package.
#   5. Delete node_modules/pi-extensions-i18n and the zh-CN README.
# Every expectation is asserted; if a future version bump changes the layout,
# the build fails here instead of silently shipping an unpatched extension.
# Must run AFTER all `pi install` lines (each one re-runs npm in ~/.pi/agent/npm).
RUN python3 - <<'EOF'
import json, sys, os, shutil

PKG = "/root/.pi/agent/npm/node_modules/pi-models-discovery"

def die(msg):
    sys.exit(f"patch-models-discovery: FATAL: {msg}")

# --- 1. package.json: drop the i18n manifest entry and the npm dependency ---
pj_path = os.path.join(PKG, "package.json")
with open(pj_path, encoding="utf-8") as f:
    pj = json.load(f)

exts = pj.get("pi", {}).get("extensions")
if exts != ["./index.ts", "../pi-extensions-i18n/index.ts"]:
    die(f"unexpected pi.extensions manifest: {exts!r}")
pj["pi"]["extensions"] = ["./index.ts"]

deps = pj.get("dependencies", {})
if "pi-extensions-i18n" not in deps:
    die(f"pi-extensions-i18n not in dependencies: {deps!r}")
del deps["pi-extensions-i18n"]
if not deps:
    del pj["dependencies"]

with open(pj_path, "w", encoding="utf-8") as f:
    json.dump(pj, f, indent=2, ensure_ascii=False)
    f.write("\n")

# --- 2. locales/index.json: flatten {key: {zh-CN, en-US}} -> {key: en-US} ---
loc_path = os.path.join(PKG, "locales", "index.json")
with open(loc_path, encoding="utf-8") as f:
    catalog = json.load(f)

flat = {}
for key, entry in catalog.items():
    if not isinstance(entry, dict) or "en-US" not in entry:
        die(f"locale entry {key!r} has no en-US translation")
    flat[key] = entry["en-US"]

with open(loc_path, "w", encoding="utf-8") as f:
    json.dump(flat, f, indent=2, ensure_ascii=False)
    f.write("\n")

# --- 3. src/index.ts: swap the i18n library for an inline English-only t() ---
src_path = os.path.join(PKG, "src", "index.ts")
with open(src_path, encoding="utf-8") as f:
    src = f.read()

OLD = (
    'import { createTranslator, loadCatalog } from "pi-extensions-i18n";\n'
    '\n'
    'const i18n = createTranslator(loadCatalog(new URL("../locales/index.json", import.meta.url)));\n'
)
NEW = (
    'import { readFileSync } from "node:fs";\n'
    'import { fileURLToPath } from "node:url";\n'
    '\n'
    '// English-only messages; pi-extensions-i18n removed at image build time.\n'
    'const MESSAGES: Record<string, string> = JSON.parse(\n'
    '\treadFileSync(fileURLToPath(new URL("../locales/index.json", import.meta.url)), "utf8"),\n'
    ');\n'
    'const i18n = {\n'
    '\tt(key: string, params?: Record<string, string | number>): string {\n'
    '\t\tconst template = MESSAGES[key];\n'
    '\t\tif (template === undefined) throw new Error(`Unknown message key: ${key}`);\n'
    '\t\treturn template.replace(/\\{([A-Za-z0-9_]+)\\}/g, (ph, name: string) => {\n'
    '\t\t\tconst value = params?.[name];\n'
    '\t\t\tif (value === undefined) throw new Error(`Missing interpolation value for ${ph}`);\n'
    '\t\t\treturn String(value);\n'
    '\t\t});\n'
    '\t},\n'
    '};\n'
)
if src.count(OLD) != 1:
    die("expected i18n import block not found exactly once in src/index.ts")
src = src.replace(OLD, NEW)
if 'from "pi-extensions-i18n"' in src:
    die("src/index.ts still imports pi-extensions-i18n after patch")

with open(src_path, "w", encoding="utf-8") as f:
    f.write(src)

# --- 4. clean the pi npm lockfile so later `pi install`/`pi update` runs
#        don't resurrect the orphaned i18n package ---
lock_path = os.path.normpath(os.path.join(PKG, "..", "..", "package-lock.json"))
if os.path.exists(lock_path):
    with open(lock_path, encoding="utf-8") as f:
        lock = json.load(f)
    pkgs = lock.get("packages", {})
    pkgs.pop("node_modules/pi-extensions-i18n", None)
    entry = pkgs.get("node_modules/pi-models-discovery", {})
    entry_deps = entry.get("dependencies", {})
    entry_deps.pop("pi-extensions-i18n", None)
    if not entry_deps:
        entry.pop("dependencies", None)
    with open(lock_path, "w", encoding="utf-8") as f:
        json.dump(lock, f, indent=2, ensure_ascii=False)
        f.write("\n")

# --- 5. remove the now-orphaned i18n package and the Chinese README ---
i18n_dir = os.path.normpath(os.path.join(PKG, "..", "pi-extensions-i18n"))
if os.path.isdir(i18n_dir):
    shutil.rmtree(i18n_dir)

zh_readme = os.path.join(PKG, "README.zh-CN.md")
if os.path.exists(zh_readme):
    os.remove(zh_readme)

print("patch-models-discovery: OK (i18n removed, English-only)")
EOF

COPY models.json /root/.pi/agent/models.json

WORKDIR /workspace
ENTRYPOINT ["pi"]