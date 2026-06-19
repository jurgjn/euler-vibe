# euler-vibe

An attempt at sandboxing codex on euler with singularity, see [speedrun.ipynb](speedrun.ipynb) for setup and example usage.
- All codex sandboxing is disabled, should be able to run for longer periods as an agent
- `codex-eu` script runs Codex in a singularity container with the following mount points:
    - Current working directory
    - `/home` mounted to `~/euler-vibe/home/codex-eu` to store authentication tokens, session info, etc
    - `/tmp` mounted to a unique sub-directory under local scratch (`$TMPDIR`)
- On the first run, log in with "Sign in with Device Code". The authentication token is then kept between sessions
- There's unrestricted access to network/GPU, please use accordingly and/or adjust as needed..

## Mobile-enabled Codex setup via Happy:
```
codex-mobile --auth
codex-mobile
```

`codex-mobile` uses the same `singularity` flags, GPU access, `/home`, `/tmp`, and `/workspace` mounts as `codex-eu`, but starts `happy codex` inside the container so the session can be picked up from the Happy mobile or web app.

`codex-mobile --auth` shows the Happy pairing QR code from inside the container. After pairing, launch `codex-mobile` to start a Codex session that Happy can hand off to mobile. Session state, Happy pairing data, and Codex auth for this image are stored under `$CODEX_MOBILE_HOME` (see [script](bin/codex-mobile)).

`codex-mobile` also accepts repeated `--extra-bind SRC[:DEST]` and `--extra-read-bind SRC[:DEST]` wrapper flags before the subcommand so additional paths can be mounted read-write or read-only inside the container.

Happy's Quick Start guide was last updated on March 23, 2026 and still shows `npm install -g happy-coder`, but the current upstream Happy README now says the package moved to `happy`. This image builds Happy CLI `1.1.7` from the public `slopus/happy` source and applies a small local patch so `codex-mobile` can use a proxy-aware websocket agent on proxy-restricted clusters instead of assuming direct websocket connectivity.

## Claude Code:

For an interactive setup, run `claude-launch`: an arrow-key menu that lets you pick the workspace, add read-only / read-write directories (with Tab completion) the agent may access, review the sandbox, and launch it. It just assembles the flags below and calls `claude-mobile`.

To run directly:
```
claude-mobile
```

`claude-mobile` runs [Claude Code](https://www.npmjs.com/package/@anthropic-ai/claude-code) with the same `singularity` flags, GPU access, and `/home`, `/tmp`, `/workspace` mounts as `codex-mobile`. By default it starts `claude` directly (with `--dangerously-skip-permissions`, since the in-container sandbox does not run inside apptainer); Claude's own remote/web control can be used to attach from elsewhere.

The same image also bundles Happy CLI `1.1.8` (proxy-patched as above), so a Happy-controlled session is available too:
```
claude-mobile --auth     # one-time: pair this machine with Happy
claude-mobile happy      # start a Happy-controlled Claude session
```

Other subcommands: `claude`/`raw` (Claude directly), `shell` (plain container shell), `logs`, `doctor`, `netcheck`, `nodecheck`. Like `codex-mobile`, it accepts `--extra-bind SRC[:DEST]` and `--extra-read-bind SRC[:DEST]` wrapper flags before the subcommand. Auth, session state, and Happy pairing are stored under `$CLAUDE_MOBILE_HOME` (see [script](bin/claude-mobile)).

Build note: on proxy-restricted clusters the image installs `pnpm` via `npm` (corepack ignores the proxy) and sets `ELECTRON_SKIP_BINARY_DOWNLOAD=1` (Happy 1.1.8 added an electron package whose postinstall otherwise fetches a binary directly). If `mksquashfs` aborts at the final packing step under a tight job memory limit, cap it: `singularity build --mksquashfs-args "-processors 4 -mem 2048M" images/claude-mobile.sif images/claude-mobile.def`.

## See also
- https://github.com/rcarmo/agentbox
- https://github.com/uw-psych/ollama-container
