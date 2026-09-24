#!/usr/bin/env bash
set -x -e -u -o pipefail

# Expected from the euler-vibe wrapper
: "${EU_VIBE_DIR:?must be set (run via euler-vibe serve_local)}"
: "${EU_VIBE_PORT:?must be set (run via euler-vibe serve_local)}"
echo EU_VIBE_DIR is $EU_VIBE_DIR, EU_VIBE_PORT is $EU_VIBE_PORT

# https://hub.docker.com/r/vllm/vllm-openai/tags
#export EU_VIBE_SIF=$EU_VIBE_DIR/images/vllm-openai_qwen38.sif
export EU_VIBE_SIF=$EU_VIBE_DIR/images/llama.cpp_server-cuda13-b10298.sif

# There are two secondary wins from FP8 on your hardware that matter almost as much as raw speed.
# First, KV-cache headroom: 27 GB of freed VRAM across the node means you can actually sustain long contexts at 256K without starving the cache.
export EU_VIBE_MODEL=unsloth/Qwen3.8-27B-GGUF

#srun bash <<'EOF'
export FROM="$(hostname) ${SLURM_NODEID}/${SLURM_NNODES}:"
export HEAD_NAME=$(scontrol show hostnames "$SLURM_JOB_NODELIST" | head -n 1)
export HEAD_ADDR=$(host $HEAD_NAME | awk '{ print $NF }' )
echo ${FROM} HEAD_NAME is $HEAD_NAME, HEAD_ADDR is $HEAD_ADDR, local TMPDIR is $TMPDIR

ARGS=(
    --nv
    --cleanenv
    --containall

    --env DO_NOT_TRACK=1

    # FIX: --nv/--cleanenv clobber the image's LD_LIBRARY_PATH, so llama-server
    # can't find libllama-server-impl.so next to it in /app. Restore it, and
    # keep /.singularity.d/libs so the injected NVIDIA driver libs still resolve.
    --env LD_LIBRARY_PATH=/app:/usr/local/lib:/.singularity.d/libs

    # For serving it rarely matters, but setting it to 8 (cores ÷ workers) is the more correct value on this box and occasionally avoids weird load-time thrashing
    --env OMP_NUM_THREADS=8

    # Specifically add an extra bind mount for /tmp as Apptainer default is too small
    --home $TMPDIR/home:/home
    --bind $TMPDIR/models:/models:ro --cwd /models
    --bind $TMPDIR/tmp:/tmp
    --overlay $TMPDIR/overlay

    $EU_VIBE_SIF
    --threads 8

    # drop your --host flag since the image default does the same thing
    --port $EU_VIBE_PORT

    #--alias Qwen3.8-27B-UD-Q6_K_XL
    #--model $EU_VIBE_MODEL/Qwen3.8-27B-UD-Q6_K_XL.gguf
    --models-dir $EU_VIBE_MODEL
    --models-preset router-presets.ini

    # https://unsloth.ai/docs/models/qwen3.8#recommended-settings
    --temp 1.0
    --top-p 0.95
    --top-k 20
    --min-p 0.01
    --presence-penalty 0
    --repeat-penalty 1.0

    --api-key no-key

    --reasoning on

    #--cache-type-k q8_0
    #--cache-type-v q8_0
)
echo ${FROM} ARGS is "${ARGS[@]}"

echo ${FROM} TMPDIR is $TMPDIR
mkdir -p "$TMPDIR"/{home,models,overlay,tmp}
export MODEL_SRC=$EU_VIBE_DIR/models/$EU_VIBE_MODEL
export MODEL_DST=$TMPDIR/models/$EU_VIBE_MODEL
echo ${FROM} Copying model - MODEL_SRC is $MODEL_SRC, MODEL_DST is $MODEL_DST
rclone copy $MODEL_SRC $MODEL_DST \
    --include "Qwen3.8-27B-UD-Q6_K_XL.gguf" \
    --progress --stats 5s \
    --transfers=4 \
    --multi-thread-streams=8 \
    --multi-thread-cutoff=64M

cat > "$TMPDIR/models/router-presets.ini" <<'INI'
version = 1

[Qwen3.8-27B-UD-Q6_K_XL]
load-on-startup = true
INI
echo ${FROM} Starting container
exec singularity run "${ARGS[@]}"
#EOF
