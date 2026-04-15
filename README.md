# euler-vibe

An attempt at sandboxing codex on euler with singularity.

Setup:
```
git clone git@github.com:jurgjn/euler-vibe.git
singularity build images/codex-eu.sif images/codex-eu.def
export PATH="$HOME/euler-vibe/bin:$PATH"
```

Example agentic task:
```
cd $SCRATCH
git clone https://github.com/DunbrackLab/IPSAE.git
codex-eu
```

This starts codex [in full YOLO mode](https://mariozechner.at/posts/2025-11-30-pi-coding-agent/) in a singularity container with $SCRATCH/IPSAE mounted at `/workspace`.

As an example prompt, try: "Please familiarise yourself with the repository and optimise ipsae.py for speed."

On the first run, log in via "Sign in with Device Code". The authentication tokens are stored under $CODEX_EU_HOME (see script), so only needs to be done once.

See also:
- https://github.com/rcarmo/agentbox
- https://github.com/uw-psych/ollama-container
