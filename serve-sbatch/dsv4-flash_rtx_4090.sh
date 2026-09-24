#!/usr/bin/env bash
#SBATCH --job-name=euler-vibe-serve
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=64
#SBATCH --mem-per-cpu=4G
#SBATCH --gpus=rtx_4090:8
#SBATCH --time=0-12:00:00
#SBATCH --account=es_beltrao
#SBATCH --tmp=512G

set -x -e -u -o pipefail

export EU_VIBE_DIR=$(dirname $(dirname $(which euler-vibe)))
export EU_VIBE_PORT=27182

# EU_VIBE_DIR expected from euler-vibe wrapper
echo EU_VIBE_DIR is $EU_VIBE_DIR

# Non-Unsloth DeepSeek-V4-Flash GGUFs were converted without these paths thus deviating from the official weights.
export EU_VIBE_SIF=$EU_VIBE_DIR/images/llama.cpp_server-cuda13-b10298.sif

# https://unsloth.ai/docs/models/deepseek-v4#quantization-analysis
# Our UD-Q8_K_XL quant is fully lossless.
#export EU_VIBE_MODEL=unsloth/DeepSeek-V4-Flash-0731-GGUF/UD-Q8_K_XL
#export EU_VIBE_GGUF=$EU_VIBE_MODEL/DeepSeek-V4-Flash-0731-UD-Q8_K_XL-00001-of-00005.gguf

# UD-Q4_K_XL keeps the same bit-exact experts and only quantizes the non-expert tensors (4% of the model) to Q8_0, so it sits right next to Q8 in size and quality.
#export EU_VIBE_MODEL=unsloth/DeepSeek-V4-Flash-0731-GGUF/UD-Q4_K_XL
#export EU_VIBE_GGUF=$EU_VIBE_MODEL/DeepSeek-V4-Flash-0731-UD-Q4_K_XL-00001-of-00005.gguf

export EU_VIBE_MODEL=unsloth/DeepSeek-V4-Flash-0731-GGUF

#srun bash <<'EOF'
export FROM="$(hostname) ${SLURM_NODEID}/${SLURM_NNODES}:"
export HEAD_NAME=$(scontrol show hostnames "$SLURM_JOB_NODELIST" | head -n 1)
export HEAD_ADDR=$(host $HEAD_NAME | awk '{ print $NF }' )
echo ${FROM} HEAD_NAME is $HEAD_NAME, HEAD_ADDR is $HEAD_ADDR, local TMPDIR is $TMPDIR

API_KEY="1453b12a2bfb5f8ab4e8285ab2261bbe"

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
    --api-key $API_KEY
    --threads 8

    # drop your --host flag since the image default does the same thing
    --port $EU_VIBE_PORT

    # https://unsloth.ai/docs/models/deepseek-v4#dspark-speculative-decoding
    --alias DeepSeek-V4-Flash-0731
    --model $EU_VIBE_MODEL/UD-Q3_K_XL/DeepSeek-V4-Flash-0731-UD-Q3_K_XL-00001-of-00004.gguf
    --model-draft $EU_VIBE_MODEL/dspark-DeepSeek-V4-Flash-0731-Q8_0.gguf
    --n-gpu-layers 99
    --n-gpu-layers-draft 99
    --spec-type draft-dspark
    --spec-draft-n-max 3

    # https://unsloth.ai/docs/models/deepseek-v4#llama.cpp-guide
    --temp 1.0
    --top-p 0.95 # agentic
    --min-p 0.01

    # https://huggingface.co/deepseek-ai/DeepSeek-V4-Flash-0731
    # For the high and max reasoning effort levels, we recommend a maximum output length of 384K tokens.
    --ctx-size 262144

    --cache-type-k q8_0
    --cache-type-v q8_0
)
echo ${FROM} ARGS is "${ARGS[@]}"

echo ${FROM} TMPDIR is $TMPDIR
mkdir -p "$TMPDIR"/{home,models,overlay,tmp}
export MODEL_SRC=$EU_VIBE_DIR/models/$EU_VIBE_MODEL
export MODEL_DST=$TMPDIR/models/$EU_VIBE_MODEL
echo ${FROM} Copying model - MODEL_SRC is $MODEL_SRC, MODEL_DST is $MODEL_DST
rclone copy $MODEL_SRC $MODEL_DST \
    --include "UD-Q3_K_XL/**" \
    --include "dspark-*.gguf" \
    --progress --stats 1m \
    --transfers=4 \
    --multi-thread-streams=8 \
    --multi-thread-cutoff=64M

echo ${FROM} Starting container with ${API_KEY}
exec singularity run "${ARGS[@]}"
#EOF
