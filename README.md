# euler-vibe
An attempt at sandboxing coding agents on euler with singularity. No guarantees, use at your own risk!
- There's unrestricted access to network/GPU, please use accordingly and/or adjust as needed..

## Claude Code:

For an interactive setup, run `claude-launch`: an arrow-key menu that lets you pick the workspace, add read-only / read-write directories (with Tab completion) the agent may access, review the sandbox, and launch it. It just assembles the flags below and calls `claude-mobile`.

To run directly:
```
claude-mobile
```

`claude-mobile` runs [Claude Code](https://www.npmjs.com/package/@anthropic-ai/claude-code) in a singularity container with GPU access, `/home` mounted to `~/euler-vibe/home/claude-mobile` (auth tokens, session info), `/tmp` under local scratch (`$TMPDIR`), and the working directory as `/workspace`. By default it starts `claude` directly (with `--dangerously-skip-permissions`, since the in-container sandbox does not run inside apptainer); Claude's own remote/web control can be used to attach from elsewhere.

The same image also bundles Happy CLI `1.1.8`, built from the public `slopus/happy` source with a small local patch so it can use a proxy-aware websocket agent on proxy-restricted clusters, so a Happy-controlled session is available too:
```
claude-mobile --auth     # one-time: pair this machine with Happy
claude-mobile happy      # start a Happy-controlled Claude session
```

Other subcommands: `claude`/`raw` (Claude directly), `shell` (plain container shell), `logs`, `doctor`, `netcheck`, `nodecheck`. It accepts `--extra-bind SRC[:DEST]` and `--extra-read-bind SRC[:DEST]` wrapper flags before the subcommand. Auth, session state, and Happy pairing are stored under `$CLAUDE_MOBILE_HOME` (see [script](bin/claude-mobile)).

Build note: on proxy-restricted clusters the image installs `pnpm` via `npm` (corepack ignores the proxy) and sets `ELECTRON_SKIP_BINARY_DOWNLOAD=1` (Happy 1.1.8 added an electron package whose postinstall otherwise fetches a binary directly). If `mksquashfs` aborts at the final packing step under a tight job memory limit, cap it: `singularity build --mksquashfs-args "-processors 4 -mem 2048M" serve-sandboxes/claude-mobile.sif serve-sandboxes/claude-mobile.def`.

## See also
- https://github.com/rcarmo/agentbox
- https://github.com/uw-psych/ollama-container
