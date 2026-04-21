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

Happy's Quick Start guide was last updated on March 23, 2026 and still shows `npm install -g happy-coder`, but the current upstream Happy README now says the package moved to `happy`. This image builds Happy CLI `1.1.7` from the public `slopus/happy` source and applies a small local patch so `codex-mobile` can use a proxy-aware websocket agent on proxy-restricted clusters instead of assuming direct websocket connectivity.

## See also
- https://github.com/rcarmo/agentbox
- https://github.com/uw-psych/ollama-container
