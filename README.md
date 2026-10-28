# euler-vibe
An attempt at sandboxing coding agents on euler with singularity/apptainer, for now mostly focused on Claude Code. No guarantees, use at your own risk! The agent has unrestricted network and GPU access (use accordingly and/or adjust as needed), plus your git name and email from `~/.gitconfig` (as `GIT_AUTHOR_NAME` etc.) so that its commits use your identity. On purpose, it has no access to euler's Slurm (so it can't submit or manage jobs) or to anything else in your home directory, such as SSH keys or other secrets.

## Install

Check out the repo to your home directory and add its `bin/` to your `PATH`:
```
git clone https://github.com/jurgjn/euler-vibe.git ~/euler-vibe
echo 'export PATH=$HOME/euler-vibe/bin:$PATH' >> ~/.bashrc
```
The container images are not part of the repo: `euler-claude` builds `sandboxes/euler-claude.sif` from `sandboxes/euler-claude.def` on first launch.

## euler-claude

[`bin/euler-claude`](bin/euler-claude) runs [Claude Code](https://www.npmjs.com/package/@anthropic-ai/claude-code) in a container, in its own tmux session for the current directory:
```
cd /path/to/project
euler-claude                  # start Claude, or reattach to this directory's session
euler-claude --bind /some/dir # extra arguments go to `singularity exec`
```
Detach with `Ctrl-b d`; running `euler-claude` again in the same directory reattaches (arguments are then ignored). Each directory gets its own session `euler-claude-<dir>`, so `tmux ls` lists all running agents.

Run `euler-claude` on a compute node with enough local scratch requested (`--tmp`), as that is where `/tmp` goes (see below). The best way to get such a node is [euler-tunnel](https://docs.hpc.ethz.ch/connections/euler-tunnel/). Run `euler-tunnel start` on a login node to submit a job, then `ssh euler-tunnel` into it directly from your laptop. `euler-tunnel start` takes `sbatch` options, e.g. `euler-tunnel start --time=8:00:00 --tmp=50G`.

### What the container solves

Each choice below addresses a problem with running an agent on euler directly, or with apptainer's defaults:

- **The agent only sees the project.** The container runs with `--containall --cleanenv`, so the only host directories inside are the project (the directory you start `euler-claude` from) and the mounts listed in `.euler-vibe/mounts` (below). Your cluster home, other projects and the host environment (modules, conda, `PYTHONPATH`, ...) are not visible. Started in [`example/`](example/), Claude sees `example/` and the group's three shared data directories, which are mounted read-only. This repo is also mounted read-only at the same path (as `$EUVIBE_DIR`), so Claude can read the sandbox's own scripts and `.def` when debugging it; its `home/`, which holds the agents' logins, is hidden behind an empty directory. The repo isn't mounted when the project is inside it, as the read-only mount would hide the writable project.
- **Claude doesn't stop to ask for permission.** It runs with `--dangerously-skip-permissions`, because Claude Code's own sandbox does not work inside apptainer; the container is the sandbox instead.
- **`/tmp` is big enough.** With `--containall`, apptainer's `/tmp` is a small in-memory tmpfs (`sessiondir max size`, 64 MiB by default), which fills up quickly during builds and package installs. `euler-claude` instead binds a fresh directory to `/tmp`. That directory is under `$TMPDIR`, the job's local scratch, and is removed when the container exits.
- **You log in once.** Claude's login and settings (`~/.claude` and `~/.claude.json`) are mounted from `home/euler-claude` in this repo. Every project and session shares them, so you don't have to log in again for each session or project. The shared `~/.claude` also makes the skills in `~/.claude/skills` available in every project, such as the [writing skills](#writing-skills) below. Your `~/.gitconfig` itself is not mounted; instead, its `user.name` and `user.email` are passed in as `GIT_AUTHOR_NAME`, `GIT_AUTHOR_EMAIL`, `GIT_COMMITTER_NAME` and `GIT_COMMITTER_EMAIL`, so commits made in the container use your git identity. The rest of the home directory is part of the project's overlay image (below).
- **Claude knows where it runs.** A global [`CLAUDE.md`](home/euler-claude/.claude/CLAUDE.md) in the shared `~/.claude` is loaded in every project. It describes euler and the sandbox: which paths are visible (including this repo, for debugging), where writes go (project, overlay or `/tmp`), the software in the image, and the [euler docs](https://docs.hpc.ethz.ch/) to consult. It forbids Slurm use and tells Claude to stop and report if Slurm turns out to be reachable. Changes that only you can make, such as a new mount, a package in the `.def` or a job to submit, are written to `AGENT_REQUESTS.md` in the project.
- **No piles of small files on the remote file system.** Changes to the container's own file system, including the home directory, go to a persistent overlay image, `.euler-vibe/overlays/euler-claude.img`, in the project. Examples are `apt-get`, `npm -g` or `pip install --user` installs, packages added to the image's Python environment in `/opt/venv`, and caches. The overlay is a single (sparse) ext3 file, rather than the many thousands of small files that such installs would otherwise create on `/cluster/project` or `/cluster/work`, which are slow there and count against the file quota. For example, Boltz-2 downloads ~8 GB of weights and chemical component data in ~45k files on first use; in [`example/`](example/) those files go to `~/.boltz` inside the overlay instead of the project directory. The overlay is created automatically on first use with a size of `$EUVIBE_OVERLAY_SIZE` (in GiB, or with an `M`/`G`/`T` suffix; default 50). Delete it to start from a clean image. (The project directory, `~/.claude` and `~/.claude.json` are bind mounts, so writes there go straight to the host as usual.)
- **Images stay in sync with their definition.** If the `.def` next to an image has changed since the image was built, the image is rebuilt before starting. The `.def` is compared with the copy of it that is kept in the `.sif`. Edit [`example/.euler-vibe/sandboxes/euler-claude.def`](example/.euler-vibe/sandboxes/euler-claude.def) and the next `euler-claude` in `example/` rebuilds `euler-claude.sif` next to it.
- **Agents survive a dropped connection.** Claude runs inside tmux, one session per directory, so you can detach, log out and reattach later (on the same node; with euler-tunnel, `ssh euler-tunnel` gets you back to it).
- **GPUs are available** via `--nv`, e.g. for the Boltz-2 run in [`example/`](example/).
- **Claude doesn't try to update itself.** The image is read-only, so Claude's auto-updater is disabled.

### Per-project configuration in `.euler-vibe/`

All optional, in the directory that you start `euler-claude` from. [`example/`](example/) uses all of them:

| Path | Purpose |
| --- | --- |
| `.euler-vibe/mounts` | Extra bind mounts, one `src[:dst[:opts]]` per line (see below) |
| `.euler-vibe/sandboxes/euler-claude.sif` | Project image used instead of [`sandboxes/euler-claude.sif`](sandboxes/euler-claude.def); needs `claude` on `PATH` |
| `.euler-vibe/sandboxes/euler-claude.def` | Definition that the project image is built (and rebuilt) from |
| `.euler-vibe/overlays/euler-claude.img` | Persistent overlay image, created automatically |

[`example/.euler-vibe/mounts`](example/.euler-vibe/mounts) makes the group's shared data available read-only:
```
/cluster/project/alphafold/alphafold3::ro    # empty dst: same path inside
/cluster/project/beltrao/shared::ro
/cluster/work/beltrao/shared::ro
```
Other forms:
```
/cluster/work/beltrao/jjaenes/data           # read-write, same path inside
~/scratch:/scratch:ro                        # different path inside
${DATA}/*.parquet::ro                        # one mount per match
```
`$VAR` and `${VAR}` are taken from the environment, `~` is your home, relative paths are relative to the project directory. Every listed path must exist (globs may match nothing), and mistakes are reported before the tmux session starts.

A mount alone doesn't tell the agent what is in it. [`example/AGENTS.md`](example/AGENTS.md) describes the three directories above: their layout, file formats, and what not to do with them. It also describes the software installed in the container and how to use it. Copy the relevant sections into the project's own `AGENTS.md`/`CLAUDE.md`.

[`example/.euler-vibe/sandboxes/euler-claude.def`](example/.euler-vibe/sandboxes/euler-claude.def) is the standard [`sandboxes/euler-claude.def`](sandboxes/euler-claude.def) with a block of project-specific additions: Boltz-2 in its own venv with `boltz` on `PATH`, and `gemmi` and `rdkit` in the default Python. To start a project image of your own, copy the standard `.def` into `.euler-vibe/sandboxes/` and add to it.

Add `.euler-vibe/overlays/` and `.euler-vibe/sandboxes/*.sif` to the project's `.gitignore`, as in [`example/.gitignore`](example/.gitignore).

## Example: Boltz-2 on ABL1 + imatinib

[`example/`](example/) started out with only the mounts, `AGENTS.md` and the standard `.def`. Claude was asked to

> Set up boltz2 in this container an run a small example, e.g. imatinib into ABL1

Following `AGENTS.md`, Claude used the group's precomputed AlphaFold 3 MSA for ABL1 instead of an MSA server. It cropped the MSA to the kinase domain ([`scripts/crop_af3_msa.py`](example/scripts/crop_af3_msa.py)), predicted the complex with 5 samples plus its binding affinity, and compared the models with crystal structure 2HYY from the copy of the PDB in the AF3 databases ([`scripts/compare_to_xtal.py`](example/scripts/compare_to_xtal.py)). [`abl1_imatinib/run.sh`](example/abl1_imatinib/run.sh) reruns all three steps. On one RTX 4090 it takes ~4 minutes:

| | |
| --- | --- |
| Confidence (best model) | confidence 0.956, ipTM 0.982, ligand ipTM 0.982, pLDDT 0.949 |
| Affinity | binder probability 0.73, predicted IC50 ~80 nM (measured: ~10-600 nM) |
| vs. crystal 2HYY (263 CA pairs) | protein CA RMSD 0.58-0.64 Å, ligand RMSD 0.31-0.56 Å |

ABL1-imatinib structures are in Boltz-2's training data, so this checks the setup rather than benchmarking the model.

The first attempt installed Boltz into a venv in the project directory and ran into the following problems:
- Triton failed to compile its GPU kernels because the system Python has no `Python.h`.
- The venv and Boltz cache added ~15 GB in ~85k files to `/cluster/project`.
- The shared Boltz-2 weights turned out to be in AF3 format, so native Boltz couldn't load them.
- The local PDB mirror was incomplete.

These lessons are now in the project's `.def` (Boltz on a uv-managed Python, in the image) and in `AGENTS.md` (where the cache goes, which shared data does and doesn't work), so the next session starts from there.

## Writing skills

Four skills in [`home/euler-claude/.claude/skills/`](home/euler-claude/.claude/skills/) edit English prose for human readers. Because `~/.claude` is shared, they work in every project: type a skill's name as a slash command, e.g. `/edit-for-readers README.md`, or ask Claude to use it. Each skill returns the edited text with a short list of its changes, and each names its sources.

| Skill | What it fixes | Sources |
| --- | --- | --- |
| [`edit-for-clarity`](home/euler-claude/.claude/skills/edit-for-clarity/SKILL.md) | Six sentence patterns that slow readers down and that AI models overuse: rare word combinations, human verbs for things, nouns used as verbs, a missing "that", stacks of nouns, and long gaps between related words | Clark, Martin & Mahowald (2026) |
| [`edit-for-lucidity`](home/euler-claude/.claude/skills/edit-for-lucidity/SKILL.md) | Terms and explicitness: the same word for the same thing, no ambiguous "this", and every term explained before it is needed | McIntyre's lucidity principles (1997–1998) |
| [`edit-for-coherence`](home/euler-claude/.claude/skills/edit-for-coherence/SKILL.md) | Paragraphs in the standard format for scientific writing: one point per paragraph, stated in the first sentence and closed by a conclusion, with old information before new | Strunk (1920), Gopen & Swan (1990), Mensh & Kording (2017), Plaxco (2010), Carandini (2022) |
| [`edit-for-readers`](home/euler-claude/.claude/skills/edit-for-readers/SKILL.md) | All three in one top-down pass: paragraphs, then terms, then sentences | The three skills above |

## Other scripts

- [`euler-qwen27b`](bin/euler-qwen27b): the same setup for [pi](https://github.com/earendil-works/pi) against a locally served Qwen model (`euler-qwen27b help`)
- [`euler-sandbox`](bin/euler-sandbox): the container wrapper on its own, e.g. `euler-sandbox exec image.sif bash`
- [`claude-mobile`](bin/claude-mobile), [`claude-launch`](bin/claude-launch): an earlier Claude Code setup, with an interactive launcher and [Happy](https://github.com/slopus/happy) for remote control

## See also
- https://github.com/evocellnet/ai-hackathon - notes from the group's AI hackathon: setting up euler, the group's shared data, requesting a GPU node, and options for running Claude Code sandboxed on euler
- https://github.com/DennisGankin/vibe-tunnel - VS Code and Claude Code in an apptainer container in a Slurm job on euler, opened from your laptop through a VS Code tunnel
- https://github.com/juliabuhmann/euler_agents - Claude Code in a singularity container on euler with only explicitly mounted directories, interactively in tmux or as unattended Slurm batch jobs that write a report
