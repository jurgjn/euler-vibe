# euler-vibe

An attempt at sandboxing codex on euler with singularity.

Setup - clone repo, build image, add run script to $PATH:
```
git clone git@github.com:jurgjn/euler-vibe.git
singularity build images/codex-eu.sif images/codex-eu.def
export PATH="$HOME/euler-vibe/bin:$PATH"
```

Example agentic task:
```
cd $SCRATCH
git clone https://github.com/DunbrackLab/IPSAE.git
cd IPSAE

# Example prompt:
#   Please familiarise yourself with the repository and optimise ipsae.py for speed
```

This starts codex [in full YOLO mode](https://mariozechner.at/posts/2025-11-30-pi-coding-agent/) in a singularity container with the current working directory ($SCRATCH/IPSAE in the example) mounted at `/workspace`.

Any arguments to the codex-eu script will be passed on to the codex binary in the container, e.g. can resume a session with:
```
codex-eu resume 019d915a-15fc-7f50-9382-5812de8bdc74
```

On the first run, log in via "Sign in with Device Code". The authentication tokens are stored under $CODEX_EU_HOME (see [script](bin/codex-eu)), so only needs to be done once.

See also:
- https://github.com/rcarmo/agentbox
- https://github.com/uw-psych/ollama-container
