#!/usr/bin/env bash
#SBATCH --job-name=euler-vibe-serve
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=24
#SBATCH --mem-per-cpu=8G
#SBATCH --gpus=nvidia_rtx_pro_6000:1
#SBATCH --time=0-01:00:00
#SBATCH --tmp=64G

set -x -e -u -o pipefail

# EU_VIBE_DIR expected from euler-vibe wrapper
echo EU_VIBE_DIR is $EU_VIBE_DIR
export EU_VIBE_MODEL=Qwen/Qwen3.6-27B-FP8

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

    # Set cache location
    --env VLLM_CACHE_ROOT=/cache

    # Specifically add an extra bind mount for /tmp as Apptainer default is too small
    --home $TMPDIR/home:/home
    --bind $TMPDIR/models:/models:ro --cwd /models
    --bind $TMPDIR/tmp:/tmp
    --overlay $TMPDIR/overlay
    --bind $EU_VIBE_DIR/cache:/cache

    $EU_VIBE_DIR/images/vllm-openai_v0.23.0.sif
    $EU_VIBE_MODEL

    # https://recipes.vllm.ai/Qwen/Qwen3.6-27B
    --trust-remote-code
    --tensor-parallel-size $SLURM_GPUS_ON_NODE
    --enable-auto-tool-choice
    --tool-call-parser qwen3_coder
    --reasoning-parser qwen3
    --language-model-only

    --speculative-config.method mtp
    --speculative-config.num_speculative_tokens 2

    --gpu-memory-utilization 0.92
    --max-model-len 262144
    --enable-chunked-prefill
    --max-num-seqs 16

    # https://huggingface.co/Qwen/Qwen3.6-27B
    --override-generation-config.temperature 0.6
    --override-generation-config.top_p 0.95
    --override-generation-config.top_k 20
    --override-generation-config.min_p 0.0
    --override-generation-config.presence_penalty 0.0
    --override-generation-config.repetition_penalty 1.0

    # Allow connections to vllm from other machines
    --host 0.0.0.0
    --port 8001

    # https://github.com/local-inference-lab/rtx6kpro/blob/master/models/qwen35-27b.md
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
    --multi-thread-streams=$SLURM_CPUS_PER_TASK \
    --transfers=$SLURM_CPUS_PER_TASK \
    --checkers=$SLURM_CPUS_PER_TASK \
    --multi-thread-streams=4 \
    --multi-thread-cutoff=64M

echo ${FROM} Starting vllm container
exec singularity run "${ARGS[@]}"
