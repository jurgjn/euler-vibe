#!/usr/bin/env bash
set -euo pipefail

# setup.sh ------------------------------------------------------------------
# One-time setup for a fresh clone:
#   1. build the Singularity image that claude-mobile runs inside, and
#   2. put this repo's bin/ on your PATH so `claude-launch` works anywhere.
#
# A clone ships images/*.def but not the built .sif (it is gitignored and
# ~680 MB), so the image has to be built once before anything can launch.
#
# Safe to re-run: an existing image is kept unless --force, and the PATH block
# is written to your shell rc file only once.

REPO=$(cd "$(dirname "$(realpath "$0")")" && pwd)
IMAGE=${CLAUDE_MOBILE_IMAGE:-$REPO/images/claude-mobile.sif}
DEF_REL=images/claude-mobile.def
BEGIN_MARK='# >>> euler-vibe >>>'
END_MARK='# <<< euler-vibe <<<'

DO_BUILD=1
DO_PATH=1
FORCE=0
ASSUME_YES=0
LOW_MEM=0
RC_FILE=${RC_FILE:-$HOME/.bashrc}

if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
    BOLD=$'\033[1m'; DIM=$'\033[2m'; RST=$'\033[0m'
    GREEN=$'\033[32m'; YELLOW=$'\033[33m'; RED=$'\033[31m'; CYAN=$'\033[36m'
else
    BOLD= DIM= RST= GREEN= YELLOW= RED= CYAN=
fi

say()  { printf '%s\n' "$*"; }
step() { printf '\n%s==>%s %s%s%s\n' "$CYAN" "$RST" "$BOLD" "$*" "$RST"; }
ok()   { printf '  %s✓%s %s\n' "$GREEN" "$RST" "$*"; }
warn() { printf '  %s!%s %s\n' "$YELLOW" "$RST" "$*"; }
die()  { printf '  %s✗ %s%s\n' "$RED" "$*" "$RST" >&2; exit 1; }

usage() {
    cat <<EOF
Usage: ./setup.sh [options]

  --no-build      skip building the container image
  --no-path       skip adding bin/ to your shell rc file
  --force         rebuild the image even if it exists, and rewrite the PATH block
  --low-mem       cap mksquashfs resources (use if the build gets OOM-killed)
  --rc FILE       shell rc file to edit (default: \$HOME/.bashrc)
  -y, --yes       do not prompt before editing the rc file
  -h, --help      show this help

Environment:
  CLAUDE_MOBILE_IMAGE   build/check this image path instead of the default
EOF
}

while [ $# -gt 0 ]; do
    case "$1" in
        --no-build) DO_BUILD=0 ;;
        --no-path)  DO_PATH=0 ;;
        --force)    FORCE=1 ;;
        --low-mem)  LOW_MEM=1 ;;
        --rc)       shift; [ $# -gt 0 ] || die "--rc needs a file"; RC_FILE=$1 ;;
        -y|--yes)   ASSUME_YES=1 ;;
        -h|--help)  usage; exit 0 ;;
        *)          usage >&2; die "unknown option: $1" ;;
    esac
    shift
done

confirm() {
    [ "$ASSUME_YES" -eq 1 ] && return 0
    [ -t 0 ] || { warn "not a terminal; skipping (use --yes to allow)"; return 1; }
    local reply
    read -r -p "  $1 [y/N] " reply || return 1
    case "$reply" in y|Y|yes|YES) return 0 ;; *) return 1 ;; esac
}

printf '%s%s euler-vibe setup %s\n' "$BOLD" "$CYAN" "$RST"
say "  repo:  $REPO"
say "  image: $IMAGE"

# --- 1. container image ----------------------------------------------------
if [ "$DO_BUILD" -eq 1 ]; then
    step "Container image"
    if [ -e "$IMAGE" ] && [ "$FORCE" -eq 0 ]; then
        ok "already present ($(du -h "$IMAGE" | cut -f1)) — use --force to rebuild"
    else
        SINGULARITY=$(command -v singularity || command -v apptainer || true)
        [ -n "$SINGULARITY" ] || die "neither singularity nor apptainer found on PATH.
    On Euler this usually means you are on a node without it, or need: module load eth_proxy"
        [ -e "$REPO/$DEF_REL" ] || die "build recipe missing: $REPO/$DEF_REL"

        # The image pulls base layers from ghcr.io/docker.io, which needs the
        # cluster proxy. Without it the build fails partway through %post.
        if [ -z "${http_proxy:-}${HTTP_PROXY:-}" ]; then
            warn "no http_proxy set — on Euler run 'module load eth_proxy' first,"
            warn "otherwise the build cannot reach ghcr.io / docker.io"
            confirm "Continue anyway?" || die "aborted"
        fi

        mkdir -p "$(dirname "$IMAGE")"
        args=()
        if [ "$LOW_MEM" -eq 1 ]; then
            args+=(--mksquashfs-args "-processors 4 -mem 2048M")
            say "  ${DIM}using capped mksquashfs resources${RST}"
        fi
        say "  ${DIM}building — this takes a while and needs several GB of scratch${RST}"
        # The recipe copies images/patch-happy-force-polling.mjs by relative
        # path, so the build has to run from the repository root.
        ( cd "$REPO" && "$SINGULARITY" build "${args[@]}" "$IMAGE" "$DEF_REL" ) \
            || die "build failed. If mksquashfs was killed, retry with: ./setup.sh --low-mem --force"
        # A build can exit 0 without producing the image; do not claim success
        # until the file is actually there.
        [ -e "$IMAGE" ] || die "build reported success but $IMAGE does not exist"
        ok "built $IMAGE ($(du -h "$IMAGE" | cut -f1))"
    fi
else
    step "Container image"
    say "  ${DIM}skipped (--no-build)${RST}"
fi

# --- 2. PATH ---------------------------------------------------------------
if [ "$DO_PATH" -eq 1 ]; then
    step "PATH"
    block=$(printf '%s\n# Added by euler-vibe setup.sh — delete this block to undo.\nexport PATH="%s/bin:$PATH"\n%s' \
            "$BEGIN_MARK" "$REPO" "$END_MARK")

    if [ -e "$RC_FILE" ] && grep -Fq "$BEGIN_MARK" "$RC_FILE"; then
        if grep -Fq "$REPO/bin" "$RC_FILE" && [ "$FORCE" -eq 0 ]; then
            ok "$RC_FILE already points at $REPO/bin"
        elif confirm "Update the existing euler-vibe block in $RC_FILE?"; then
            tmp=$(mktemp)
            awk -v b="$BEGIN_MARK" -v e="$END_MARK" \
                'index($0,b){skip=1} !skip{print} index($0,e){skip=0}' \
                "$RC_FILE" > "$tmp"
            printf '%s\n' "$block" >> "$tmp"
            cp "$RC_FILE" "$RC_FILE.euler-vibe.bak"
            mv "$tmp" "$RC_FILE"
            ok "updated (previous version saved as $RC_FILE.euler-vibe.bak)"
        else
            warn "left $RC_FILE unchanged"
        fi
    elif confirm "Add $REPO/bin to your PATH via $RC_FILE?"; then
        [ -e "$RC_FILE" ] && printf '\n' >> "$RC_FILE"
        printf '%s\n' "$block" >> "$RC_FILE"
        ok "added to $RC_FILE"
    else
        warn "skipped — run claude-launch as $REPO/bin/claude-launch,"
        warn "or add $REPO/bin to PATH yourself"
    fi
else
    step "PATH"
    say "  ${DIM}skipped (--no-path)${RST}"
fi

# --- done ------------------------------------------------------------------
step "Done"
if [ -e "$IMAGE" ]; then
    say "  Start a new shell (or: source $RC_FILE), then run:"
    say "    ${CYAN}claude-launch${RST}"
else
    say "  Image not built yet — run ./setup.sh once the image can be built,"
    say "  then start claude-launch."
fi
