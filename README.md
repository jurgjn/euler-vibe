# euler-vibe
An attempt at sandboxing coding agents on euler with singularity/apptainer. No guarantees, use at your own risk! There's unrestricted access to network/GPU, please use accordingly and/or adjust as needed..

## Install

Check out the repo to your home directory and add its `bin/` to your `PATH`:
```
git clone https://github.com/jurgjn/euler-vibe.git ~/euler-vibe
echo 'export PATH=$HOME/euler-vibe/bin:$PATH' >> ~/.bashrc
```
The container images are not part of the repo: `euler-claude` builds `sandboxes/euler-claude.sif` from its `.def` on first launch.

## euler-claude

[`bin/euler-claude`](bin/euler-claude) runs [Claude Code](https://www.npmjs.com/package/@anthropic-ai/claude-code) in a container, in its own tmux session for the current directory:
```
cd /path/to/project
euler-claude                  # start Claude, or reattach to this directory's session
euler-claude --bind /some/dir # extra arguments go to `singularity exec`
```
Detach with `Ctrl-b d`; running `euler-claude` again in the same directory reattaches (arguments are then ignored). Each directory gets its own session `euler-claude-<dir>`, so `tmux ls` lists all running agents. Claude runs with `--dangerously-skip-permissions`: its own sandbox does not work inside apptainer, so the container is the sandbox.

Run it on a compute node with enough local scratch requested (`--tmp`), as that is where `/tmp` goes (see below). The best way to get one is [euler-tunnel](https://docs.hpc.ethz.ch/connections/euler-tunnel/): `euler-tunnel start` on a login node (takes `sbatch` options, e.g. `euler-tunnel start --time=8:00:00 --tmp=50G`) submits a job that you can then `ssh euler-tunnel` into directly from your laptop.

### What the container solves

Each choice below addresses a problem with running an agent on euler directly, or with apptainer's defaults:

- **The agent only sees the project.** The container runs with `--containall --cleanenv`: the only host directories inside are the current directory plus mounts listed in `.euler-vibe/mounts` (below). Your cluster home, other projects and the host environment (modules, conda, `PYTHONPATH`, ...) are not visible.
- **`/tmp` is big enough.** With `--containall`, apptainer's `/tmp` is a small in-memory tmpfs (`sessiondir max size`, 64 MiB by default), which builds and package installs quickly fill up. `euler-claude` instead binds a fresh directory under `$TMPDIR`, the job's local scratch, to `/tmp`, and removes it when the container exits.
- **You log in once.** Claude's login and settings, `~/.claude` and `~/.claude.json`, are mounted from `home/euler-claude` in this repo, shared by every project and session, so you don't have to log in again for each session or project. Your actual `~/.gitconfig`, if you have one, is mounted read-only so commits made in the container use your git identity. The rest of the home directory is part of the project's overlay image (below).
- **No piles of small files on the remote file system.** Changes to the container's own file system, including the home directory, e.g. `apt-get`, `npm -g` or `pip install --user` installs, packages added to the image's Python environment in `/opt/venv`, or caches, go to a persistent overlay image `.euler-vibe/overlays/euler-claude.img` in the project. That is a single (sparse) ext3 file, rather than the many thousands of small files such installs would otherwise create on `/cluster/project` or `/cluster/work`, which are slow there and count against the file quota. It is created automatically on first use with a size of `$EUVIBE_OVERLAY_SIZE` (in GiB, or with an `M`/`G`/`T` suffix; default 50). Delete it to start from a clean image. (The project directory, `~/.claude` and `~/.claude.json` are bind mounts, so writes there go straight to the host as usual.)
- **Images stay in sync with their definition.** If the `.def` next to an image has changed since the image was built (compared with the copy of the `.def` kept in the `.sif`), the image is rebuilt before starting.
- **Agents survive a dropped connection.** Claude runs inside tmux, one session per directory, so you can detach, log out and reattach later (on the same node; with euler-tunnel, `ssh euler-tunnel` gets you back to it).
- **GPUs are available** via `--nv`; Claude's auto-updater is disabled since the image is read-only.

### Per-project configuration in `.euler-vibe/`

All optional, in the directory you start `euler-claude` from:

| Path | Purpose |
| --- | --- |
| `.euler-vibe/mounts` | Extra bind mounts, one `src[:dst[:opts]]` per line (see below) |
| `.euler-vibe/sandboxes/euler-claude.sif` | Project image used instead of [`sandboxes/euler-claude.sif`](sandboxes/euler-claude.def); needs `claude` on `PATH` |
| `.euler-vibe/sandboxes/euler-claude.def` | Definition the project image is built (and rebuilt) from |
| `.euler-vibe/overlays/euler-claude.img` | Persistent overlay image, created automatically |

Example [`.euler-vibe/mounts`](example/.euler-vibe/mounts), making the group's shared data available read-only:
```
/cluster/work/beltrao/shared::ro             # empty dst: same path inside
/cluster/project/beltrao/shared::ro
/cluster/project/alphafold/alphafold3::ro
```
Other forms:
```
/cluster/work/beltrao/jjaenes/data           # read-write, same path inside
~/scratch:/scratch:ro                        # different path inside
${DATA}/*.parquet::ro                        # one mount per match
```
`$VAR` and `${VAR}` are taken from the environment, `~` is your home, relative paths are relative to the project directory. Every listed path must exist (globs may match nothing), and mistakes are reported before the tmux session starts.

A mount alone doesn't tell the agent what is in it. [`example/AGENTS.md`](example/AGENTS.md) describes the three directories above (layout, file formats, what not to do with them); copy the relevant sections into the project's own `AGENTS.md`/`CLAUDE.md`. Running `euler-claude` in [`example/`](example/) starts a session with both in place, using a project image built from [`example/.euler-vibe/sandboxes/euler-claude.def`](example/.euler-vibe/sandboxes/euler-claude.def) (a copy of the standard one, to edit as a starting point).

Add `.euler-vibe/overlays/` (and `.euler-vibe/sandboxes/*.sif`) to the project's `.gitignore`.

## Other scripts

- [`euler-qwen27b`](bin/euler-qwen27b): the same setup for [pi](https://github.com/earendil-works/pi) against a locally served Qwen model (`euler-qwen27b help`)
- [`euler-sandbox`](bin/euler-sandbox): the container wrapper on its own, e.g. `euler-sandbox exec image.sif bash`
- [`claude-mobile`](bin/claude-mobile), [`claude-launch`](bin/claude-launch): an earlier Claude Code setup, with an interactive launcher and [Happy](https://github.com/slopus/happy) for remote control

## See also
- https://github.com/DennisGankin/vibe-tunnel - VS Code and Claude Code in an apptainer container in a Slurm job on euler, opened from your laptop through a VS Code tunnel
- https://github.com/juliabuhmann/euler_agents - Claude Code in a singularity container on euler with only explicitly mounted directories, interactively in tmux or as unattended Slurm batch jobs that write a report
