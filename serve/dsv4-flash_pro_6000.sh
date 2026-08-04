#!/usr/bin/env bash
#SBATCH --job-name=euler-vibe-serve
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=48
#SBATCH --mem-per-cpu=8G
#SBATCH --gpus=pro_6000:2
#SBATCH --time=0-04:00:00
#SBATCH --tmp=512G

# https://github.com/local-inference-lab/rtx6kpro/blob/master/models/ds4dspark-v20.md
# https://www.linkedin.com/pulse/running-deepseek-v4-flash-700-tokenss-2x-rtx-pro-6000-ovidiu-dan-qo8nc
# https://hub.docker.com/r/voipmonitor/vllm/
# https://news.ycombinator.com/item?id=48547347

set -x -e -u -o pipefail

# EU_VIBE_DIR expected from euler-vibe wrapper
export EU_VIBE_SIF=$EU_VIBE_DIR/images/vllm_gilded-gnosis-v20-vllmf5981f1-si2b9bf2a-fi801d57a-cu132-20260803-r24.sif
export EU_VIBE_MODEL=deepseek-ai/DeepSeek-V4-Flash-0731
echo EU_VIBE_DIR is $EU_VIBE_DIR
echo EU_VIBE_SIF is $EU_VIBE_SIF
echo EU_VIBE_PORT is $EU_VIBE_PORT
echo EU_VIBE_MODEL is $EU_VIBE_MODEL

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

    # https://github.com/local-inference-lab/rtx6kpro/blob/master/models/ds4dspark-v20.md
    --env CUDA_VISIBLE_DEVICES=0,1
    --env PORT=$EU_VIBE_PORT
    --env MODE=dspark
    --env BACKEND=b12x-a8
    --env TP_SIZE=2
    --env DCP_SIZE=1
    --env DSPARK_DEPTH_MODE=fixed
    --env DSPARK_TOKENS=5
    --env MAX_NUM_SEQS=2
    #--env MAX_MODEL_LEN=524288
    --env MAX_MODEL_LEN=1048576
    --env MAX_NUM_BATCHED_TOKENS=2048
    --env GPU_MEMORY_UTILIZATION=0.975
    --env LOAD_FORMAT=instanttensor
    --env INSTANTTENSOR_BACKEND=BUFFERED
    --env KV_OFFLOADING_SIZE=0

    # 
    #--env KV_OFFLOADING_SIZE=192

    # Specifically add an extra bind mount for /tmp as Apptainer default is too small
    --home $TMPDIR/home:/home
    --bind $TMPDIR/models:/models:ro --cwd /models
    --bind $TMPDIR/tmp:/tmp
    --overlay $TMPDIR/overlay
    --bind $EU_VIBE_DIR/cache:/cache

    $EU_VIBE_SIF

    # https://github.com/local-inference-lab/vllm/blob/feat/gg-ds4-0731-launcher-20260731/serve-ds4-flash.sh
    /usr/local/bin/serve-ds4-flash.sh

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
exec singularity exec "${ARGS[@]}"
