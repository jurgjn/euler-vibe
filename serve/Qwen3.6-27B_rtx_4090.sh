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

    # Specifically add an extra bind mount for /tmp as Apptainer default is too small
    --home $TMPDIR/home:/home
    --bind $TMPDIR/models:/models:ro --cwd /models
    --bind $TMPDIR/tmp:/tmp
    --overlay $TMPDIR/overlay

    $EU_VIBE_DIR/images/vllm-openai_v0.25.1-x86_64.sif
    $EU_VIBE_MODEL

    # https://recipes.vllm.ai/Qwen/Qwen3.6-27B
    --trust-remote-code
    --tensor-parallel-size $SLURM_GPUS_ON_NODE
    --enable-auto-tool-choice
    --tool-call-parser qwen3_coder
    --reasoning-parser qwen3
    --language-model-only

    # Prefix caching is clearly paying off (hit rates climbing to 85%+)
    --enable-prefix-caching

    --gpu-memory-utilization 0.95
    --max-model-len 262144

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
    --progress --stats 2m \
    --multi-thread-streams=$SLURM_CPUS_PER_TASK

echo ${FROM} Starting vllm container
exec singularity run "${ARGS[@]}"
#EOF
