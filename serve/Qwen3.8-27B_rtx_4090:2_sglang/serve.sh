#!/usr/bin/env bash
set -v -x -e -u -o pipefail

# Expected from the euler-vibe wrapper
: "${EUVIBE_DIR:?must be set}"
: "${EUVIBE_PORT:?must be set}"
: "${EUVIBE_MODEL:?must be set}"
: "${EUVIBE_SERVED_MODEL_NAME:?must be set}"
: "${EUVIBE_DRAFT:?must be set}"
: "${EUVIBE_CONTEXT_LENGTH:?must be set}"

echo EUVIBE_DIR is $EUVIBE_DIR, EUVIBE_PORT is $EUVIBE_PORT

export EUVIBE_SIF=$EUVIBE_DIR/images/sglang_v0.5.21.sif

export FROM="$(hostname) ${SLURM_NODEID}/${SLURM_NNODES}:"
export HEAD_NAME=$(scontrol show hostnames "$SLURM_JOB_NODELIST" | head -n 1)
export HEAD_ADDR=$(host $HEAD_NAME | awk '{ print $NF }' )
echo ${FROM} HEAD_NAME is $HEAD_NAME, HEAD_ADDR is $HEAD_ADDR, local TMPDIR is $TMPDIR

export OVERLAY_DIR="$TMPDIR/euler-vibe.$$"
echo ${FROM} OVERLAY_DIR is $OVERLAY_DIR
mkdir -p "$OVERLAY_DIR"/{home,models,overlay,tmp}

ARGS=(
    --nv
    --cleanenv
    --containall

    # Specifically add an extra bind mount for /tmp as Apptainer default is too small
    --home $OVERLAY_DIR/home:/home
    --bind $OVERLAY_DIR/models:/models:ro --cwd /models
    --bind $OVERLAY_DIR/tmp:/tmp
    --overlay $OVERLAY_DIR/overlay

    # Like vLLM, SGLang uses high-performance Inter-Process Communication (IPC) for Multi-GPU configurations. Apptainer restricts access to /dev/shm on cluster nodes unless cleanly bound.
    #--bind /dev/shm:/dev/shm

    $EUVIBE_SIF
    
    # Do not rely on the container's default entrypoint. Apptainer often bypasses the entrypoint binary layer. Explicitly executing the module via Python works around this issue.
    python3 -m sglang.launch_server

    # https://recipes.vllm.ai/Qwen/Qwen3.8-27B-FP8
    --tp ${SLURM_GPUS_ON_NODE:-$(nvidia-smi -L | wc -l)}
    --model-path $EUVIBE_MODEL
    --served-model-name $EUVIBE_SERVED_MODEL_NAME

    --max-running-requests 2
    --context-length $EUVIBE_CONTEXT_LENGTH
    #--kv-cache-dtype fp8_e4m3

    # Lower = more headroom for activations/CUDA graphs (0.95 left <1 GB free)
    --mem-fraction-static 0.75
    # Only capture graphs for batch sizes we can actually reach
    --cuda-graph-max-bs-decode 2
    --cuda-graph-max-bs-prefill 2048

    # 4 PCIe 4090s: custom allreduce is unsupported anyway; silences the warning
    --disable-custom-all-reduce

    # Explicit rather than relying on chat-template auto-detection
    --reasoning-parser qwen3
    --tool-call-parser qwen3_coder

    --speculative-algorithm DFLASH
    --speculative-draft-model-path $EUVIBE_DRAFT
    --speculative-dflash-block-size 6

    # Draft KV in fp8: only affects acceptance, not output; frees device memory
    --speculative-draft-kv-cache-dtype fp8_e4m3

    # Only reachable from this node (pi connects via localhost); key matches models.json
    --host 127.0.0.1
    --port $EUVIBE_PORT
    --api-key $OPENAI_API_KEY
)
echo ${FROM} ARGS is "${ARGS[@]}"

export MODEL_SRC=$EUVIBE_DIR/models/$EUVIBE_MODEL
export MODEL_DST=$OVERLAY_DIR/models/$EUVIBE_MODEL
echo ${FROM} Copying model - MODEL_SRC is $MODEL_SRC, MODEL_DST is $MODEL_DST
rclone copy $MODEL_SRC $MODEL_DST \
    --exclude ".git/" \
    --progress --stats 1m \
    --transfers=4 \
    --multi-thread-streams=8 \
    --multi-thread-cutoff=64M

export DRAFT_SRC=$EUVIBE_DIR/models/$EUVIBE_DRAFT
export DRAFT_DST=$OVERLAY_DIR/models/$EUVIBE_DRAFT
echo ${FROM} Copying draft - MODEL_SRC is $DRAFT_SRC, MODEL_DST is $DRAFT_DST
rclone copy $DRAFT_SRC $DRAFT_DST \
    --exclude ".git/" \
    --progress --stats 1m \
    --transfers=4 \
    --multi-thread-streams=8 \
    --multi-thread-cutoff=64M

echo ${FROM} Starting container
exec singularity run "${ARGS[@]}"
