# euler-vibe

An attempt at sandboxing codex on euler with singularity.

Setup - clone repo, build image, add run script to $PATH:
```
git clone git@github.com:jurgjn/euler-vibe.git
cd euler-vibe
singularity build images/codex-eu.sif images/codex-eu.def
singularity build images/codex-mobile.sif images/codex-mobile.def
export PATH="$HOME/euler-vibe/bin:$PATH"
```

Example agentic task:
```
cd $SCRATCH
git clone https://github.com/DunbrackLab/IPSAE.git
cd IPSAE
codex-eu
# Example prompt:
#   Please familiarise yourself with the repository and optimise ipsae.py for speed
```

This starts codex [in full YOLO mode](https://mariozechner.at/posts/2025-11-30-pi-coding-agent/) in a singularity container with the current working directory ($SCRATCH/IPSAE in the example) mounted at `/workspace`.

Any arguments to the codex-eu script will be passed on to the codex binary in the container, e.g. can resume a session with:
```
codex-eu resume 019d915a-15fc-7f50-9382-5812de8bdc74
```

On the first run, log in via "Sign in with Device Code". The authentication tokens are stored under $CODEX_EU_HOME (see [script](bin/codex-eu)), so only needs to be done once.

Mobile-enabled Codex setup via Happy:
```
codex-mobile --auth
codex-mobile
```

`codex-mobile` uses the same `singularity` flags, GPU access, `/home`, `/tmp`, and `/workspace` mounts as `codex-eu`, but starts `happy codex` inside the container so the session can be picked up from the Happy mobile or web app.

`codex-mobile --auth` shows the Happy pairing QR code from inside the container. After pairing, launch `codex-mobile` to start a Codex session that Happy can hand off to mobile. Session state, Happy pairing data, and Codex auth for this image are stored under `$CODEX_MOBILE_HOME` (see [script](bin/codex-mobile)).

Happy's Quick Start guide was last updated on March 23, 2026 and still shows `npm install -g happy-coder`, but the current upstream Happy README now says the package moved to `happy`. This image builds Happy CLI `1.1.7` from the public `slopus/happy` source and applies a small local patch so `codex-mobile` can use a proxy-aware websocket agent on proxy-restricted clusters instead of assuming direct websocket connectivity.

See also:
- https://github.com/rcarmo/agentbox
- https://github.com/uw-psych/ollama-container
