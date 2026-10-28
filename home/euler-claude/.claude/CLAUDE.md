# Environment: euler cluster, inside a sandbox

You are running on a compute node of euler, ETH Zurich's HPC cluster (Slurm, shared
parallel file systems), inside an apptainer container started by `euler-claude`
(https://github.com/jurgjn/euler-vibe). The container is the sandbox, so Claude Code
runs without permission prompts.

For anything about euler itself (file systems and quotas, GPU types, Slurm options for
job scripts, modules, storage), consult the official docs at https://docs.hpc.ethz.ch/
rather than guessing.

## What you can and can't reach

- **Visible host paths:** only the project directory (the working directory you were
  started in) and the extra mounts listed in its `.euler-vibe/mounts`, often read-only.
  The user's cluster home, other projects and the host's modules/conda are not visible.
- **The sandbox's own code:** the euler-vibe repo that started this container is
  mounted read-only at `$EUVIBE_DIR` (its `home/`, with all agents' logins, is hidden).
  Read `bin/euler-claude`, `bin/euler-sandbox` and the image's `.def` in
  `sandboxes/` there when debugging the sandbox itself, e.g. a missing mount or tool.
  Not mounted if the project is inside the repo.
- **No Slurm:** `sbatch`, `squeue` etc. are unavailable. You can't submit or manage
  jobs; work on the current node, or write job scripts for the user to submit.
  **Never submit, cancel or modify Slurm jobs**, even if it seems possible. If you
  find that Slurm is reachable from inside the container (Slurm commands work, or a
  Slurm socket, config or munge key is visible), stop what you are doing and tell the
  user right away: it means the sandbox is leaking.
- **Network and GPUs:** unrestricted network access, and the job's GPUs (if any) via
  `--nv`. Check with `nvidia-smi`.
- **Git:** commits use the user's name and email via `GIT_AUTHOR_*`/`GIT_COMMITTER_*`.
  There are no SSH keys or other credentials, so pushing usually won't work.

## Where files go

- **Project directory** (`/cluster/project/...` or `/cluster/work/...`): bind-mounted,
  writes go straight to the host. These file systems are slow with many small files
  and have file-count quotas, so don't put venvs, caches or large unpacked downloads
  here.
- **Everything else** (`$HOME` apart from `~/.claude`, `/usr`, `/opt`, ...): writes go
  to the project's persistent overlay image `.euler-vibe/overlays/euler-claude.img`.
  This is the place for `apt-get`, `npm -g`, `pip install` (into `/opt/venv`), model
  weights and caches. It persists across sessions but is limited in size (default 50 GiB).
- **`/tmp`**: the job's fast local scratch, deleted when the container exits.
  `uv`, `pixi` and `cargo` caches go there.
- **`~/.claude`**: shared by all projects; changes here affect every session.

## Software in the image

Ubuntu 24.04 with CUDA 12.6 and build tools; Python 3.13 in `/opt/venv` (default, with
PyTorch, pandas, polars, scipy, scikit-learn, biopython, matplotlib, seaborn); `uv`,
`pixi`, Node.js, Rust, `git`/`git-lfs`, `ripgrep`. A project may use its own image
(`.euler-vibe/sandboxes/euler-claude.def`); see the project's `AGENTS.md`/`CLAUDE.md`
for what it adds and for what the mounted data directories contain.

## Requesting sandbox changes

Some changes can only be made from outside the container: a new or read-write mount,
a package added to the image's `.def`, a larger overlay, a credential, or a Slurm
job. If you need one, add an entry to `AGENT_REQUESTS.md` in the project directory
(create it if missing) saying what you need, why, and the exact change if you know it
(e.g. the line for `.euler-vibe/mounts`). Then tell the user, and continue with a
workaround if there is one.
