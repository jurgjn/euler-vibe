# euler-vibe
An attempt at sandboxing codex on euler with singularity, see [speedrun.ipynb](speedrun.ipynb) for setup and example usage.
- All codex sandboxing is disabled, should be able to run for longer periods as an agent
- `codex-eu` script runs Codex in a singularity container with the following mount points:
    - Current working directory
    - `/home` mounted to `~/euler-vibe/home/codex-eu` to store authentication tokens, session info, etc
    - `/tmp` mounted to a unique sub-directory under local scratch (`$TMPDIR`)
- On the first run, log in with "Sign in with Device Code". The authentication token is then kept between sessions
- There's unrestricted access to network/GPU, please use accordingly and/or adjust as needed..

See also:
- https://github.com/rcarmo/agentbox
- https://github.com/uw-psych/ollama-container
