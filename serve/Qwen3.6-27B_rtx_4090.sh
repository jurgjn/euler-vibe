#!/usr/bin/env bash
#SBATCH --job-name=euler-vibe-serve
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=64
#SBATCH --mem-per-cpu=4G
#SBATCH --gpus=rtx_4090:4
#SBATCH --time=0-12:00:00
#SBATCH --account=es_beltrao
#SBATCH --tmp=128G

set -x -e -u -o pipefail

export EU_VIBE_DIR=$(dirname $(dirname $(which euler-vibe)))
export EU_VIBE_PORT=27182

# EU_VIBE_DIR expected from euler-vibe wrapper
echo EU_VIBE_DIR is $EU_VIBE_DIR

# https://hub.docker.com/r/vllm/vllm-openai/tags
export EU_VIBE_SIF=$EU_VIBE_DIR/images/vllm-openai_v0.26.0-x86_64.sif

# There are two secondary wins from FP8 on your hardware that matter almost as much as raw speed.
# First, KV-cache headroom: 27 GB of freed VRAM across the node means you can actually sustain long contexts at 256K without starving the cache.
export EU_VIBE_MODEL=Qwen/Qwen3.6-27B-FP8

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
    --env PYTORCH_CUDA_ALLOC_CONF=expandable_segments:True

    # Specifically add an extra bind mount for /tmp as Apptainer default is too small
    --home $TMPDIR/home:/home
    --bind $TMPDIR/models:/models:ro --cwd /models
    --bind $TMPDIR/tmp:/tmp
    --overlay $TMPDIR/overlay

    $EU_VIBE_SIF
    $EU_VIBE_MODEL

    # https://recipes.vllm.ai/Qwen/Qwen3.6-27B
    --trust-remote-code
    --tensor-parallel-size $SLURM_GPUS_ON_NODE
    --enable-auto-tool-choice
    --tool-call-parser qwen3_coder
    --reasoning-parser qwen3
    --language-model-only

    # https://huggingface.co/Qwen/Qwen3.6-27B
    # Thinking mode for precise coding tasks (e.g. WebDev)
    --override-generation-config.temperature 0.6
    --override-generation-config.top_p 0.95
    --override-generation-config.top_k 20
    --override-generation-config.min_p 0.0
    --override-generation-config.presence_penalty 0.0
    --override-generation-config.repetition_penalty 1.0

    --max-model-len 262144

    #--gpu-memory-utilization 0.92
    # Give the KV cache an explicit, smaller budget
    --kv-cache-memory 12884901888

    --max-num-seqs 32
    --max-num-batched-tokens 8192

    # Prefix caching is clearly paying off (hit rates climbing to 85%+)
    --enable-prefix-caching

    # Start with 2 as a sane default on 4090s; going to 3 buys a bit more single-stream speed but costs more wasted compute at higher concurrency.
    --speculative-config.method mtp
    --speculative-config.num_speculative_tokens 3

    # If you ever want calibrated scales, they can be generated with llm-compressor and baked into a checkpoint, but I wouldn't bother unless you observe quality degradation at long context.
    --kv-cache-dtype fp8

    # expected on this hardware and there's not much to do beyond adding --disable-custom-all-reduce to silence the warning
    --disable-custom-all-reduce

    # Allow connections to vllm from other machines
    --host 0.0.0.0
    --port $EU_VIBE_PORT
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
