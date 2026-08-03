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

#RUN pi install npm:pi-web-extension

#RUN npm install -g agent-browser
#RUN pi install npm:pi-agent-browser-native

RUN pi install npm:pi-web-access

COPY models.json /root/.pi/agent/models.json

WORKDIR /workspace
ENTRYPOINT ["pi"]
