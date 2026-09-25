#!/usr/bin/env bash
set -x -e -u -o pipefail

# Expected from the euler-vibe wrapper
: "${EU_VIBE_DIR:?must be set (run via euler-vibe serve_local)}"
: "${EU_VIBE_PORT:?must be set (run via euler-vibe serve_local)}"
echo EU_VIBE_DIR is $EU_VIBE_DIR, EU_VIBE_PORT is $EU_VIBE_PORT

# https://hub.docker.com/r/vllm/vllm-openai/tags
#export EU_VIBE_SIF=$EU_VIBE_DIR/images/vllm-openai_qwen38.sif
export EU_VIBE_SIF=$EU_VIBE_DIR/images/vllm-openai_v0.29.0-x86_64.sif

# There are two secondary wins from FP8 on your hardware that matter almost as much as raw speed.
# First, KV-cache headroom: 27 GB of freed VRAM across the node means you can actually sustain long contexts at 256K without starving the cache.
export EU_VIBE_MODEL=Qwen/Qwen3.8-27B-FP8

#srun bash <<'EOF'
export FROM="$(hostname) ${SLURM_NODEID}/${SLURM_NNODES}:"
export HEAD_NAME=$(scontrol show hostnames "$SLURM_JOB_NODELIST" | head -n 1)
export HEAD_ADDR=$(host $HEAD_NAME | awk '{ print $NF }' )
echo ${FROM} HEAD_NAME is $HEAD_NAME, HEAD_ADDR is $HEAD_ADDR, local TMPDIR is $TMPDIR

ARGS=(
    --nv
    --cleanenv
    --containall

    # HF-offline setup from: https://dl.acm.org/doi/10.1145/3731599.3767356
    --env OMP_NUM_THREADS=1
    --env HF_HUB_ENABLE_HF_TRANSFER=0
    --env HF_HUB_DISABLE_TELEMETRY=1
    --env VLLM_NO_USAGE_STATS=1
    --env DO_NOT_TRACK=1
    --env HF_DATASETS_OFFLINE=1
    --env TRANSFORMERS_OFFLINE=1
    --env HF_HUB_OFFLINE=1
    #--env VLLM_DISABLE_COMPILE_CACHE=1

    # Enable expandable segments to kill the fragmentation loss.
    #--env PYTORCH_CUDA_ALLOC_CONF=expandable_segments:True

    # Specifically add an extra bind mount for /tmp as Apptainer default is too small
    --home $TMPDIR/home:/home
    --bind $TMPDIR/models:/models:ro --cwd /models
    --bind $TMPDIR/tmp:/tmp
    --overlay $TMPDIR/overlay

    $EU_VIBE_SIF
    $EU_VIBE_MODEL

    # https://recipes.vllm.ai/Qwen/Qwen3.8-27B-FP8
    --tensor-parallel-size ${SLURM_GPUS_ON_NODE:-$(nvidia-smi -L | wc -l)}
    --enable-auto-tool-choice
    --tool-call-parser qwen3_coder
    --reasoning-parser qwen3
    # Recipe uses 3; 2 wastes less compute on rejected drafts, benchmark both
    --speculative-config.method mtp
    --speculative-config.num_speculative_tokens 3
    --language-model-only

    # https://huggingface.co/Qwen/Qwen3.8-27B
    # We recommend using the following sets of sampling parameters for generation
    --override-generation-config.temperature 1.0
    --override-generation-config.top_p 0.95
    --override-generation-config.top_k 20
    --override-generation-config.min_p 0.0
    --override-generation-config.presence_penalty 0.0
    --override-generation-config.repetition_penalty 1.0

    # Native max context (max_position_embeddings in config.json)
    --max-model-len 262144
    #--max-model-len 131072
    #--max-model-len 65536
    #--override-generation-config.max_tokens 131072

    # Default is 0.9; the GPUs are dedicated to vllm, so give the rest to the KV cache
    --gpu-memory-utilization 0.95
    # Give the KV cache an explicit, smaller budget
    #--kv-cache-memory 12884901888

    --max-num-seqs 4
    # Larger prefill chunks speed up long agent prompts
    --max-num-batched-tokens 16384

    # Prefix caching is on by default (also for this hybrid model, with mamba_cache_mode=align);
    # hit rates climbed to 85%+ with agent sessions
    #--enable-prefix-caching

    # If you ever want calibrated scales, they can be generated with llm-compressor and baked into a checkpoint, but I wouldn't bother unless you observe quality degradation at long context.
    # Needed for 262144: on 2x rtx_4090, the bf16 KV cache fits ~182K tokens; fp8 roughly doubles this
    --kv-cache-dtype fp8

    # expected on this hardware and there's not much to do beyond adding --disable-custom-all-reduce to silence the warning
    #--disable-custom-all-reduce

    # Only reachable from this node (pi connects via localhost); key matches models.json
    --host 127.0.0.1
    --port $EU_VIBE_PORT
    --api-key no-key
)
echo ${FROM} ARGS is "${ARGS[@]}"

echo ${FROM} TMPDIR is $TMPDIR
mkdir -p "$TMPDIR"/{home,models,overlay,tmp}
export MODEL_SRC=$EU_VIBE_DIR/models/$EU_VIBE_MODEL
export MODEL_DST=$TMPDIR/models/$EU_VIBE_MODEL
echo ${FROM} Copying model - MODEL_SRC is $MODEL_SRC, MODEL_DST is $MODEL_DST
rclone copy $MODEL_SRC $MODEL_DST \
    --exclude ".git/" \
    --progress --stats 1m \
    --transfers=4 \
    --multi-thread-streams=8 \
    --multi-thread-cutoff=64M

echo ${FROM} Starting vllm container
exec singularity run "${ARGS[@]}"
#EOF
