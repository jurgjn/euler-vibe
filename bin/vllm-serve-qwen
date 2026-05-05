#!/usr/bin/env bash

# Use location of the script to find locations for config & container image
EU_VIBE_BIN=$(realpath $0)
EU_VIBE_DIR=$(dirname $(dirname $EU_VIBE_BIN))
EU_VIBE_SIF=$EU_VIBE_DIR/images/vllm-openai-rocm_nightly.sif

EU_VIBE_HOME=$TMPDIR/vllm-serve-qwen.$$/home
EU_VIBE_TMP=$TMPDIR/vllm-serve-qwen.$$/tmp

# Ensure mount point directories are present
mkdir -p $EU_VIBE_HOME $EU_VIBE_TMP

# Run singularity/vllm
singularity run \
    --rocm \
    --cleanenv \
    --containall \
    --env OMP_NUM_THREADS=1 \
    --env HF_HUB_ENABLE_HF_TRANSFER=0 \
    --env HF_HUB_DISABLE_TELEMETRY=1 \
    --env VLLM_NO_USAGE_STATS=1 \
    --env DO_NOT_TRACK=1 \
    --env HF_DATASETS_OFFLINE=1 \
    --env TRANSFORMERS_OFFLINE=1 \
    --env HF_HUB_OFFLINE=1 \
    --env VLLM_DISABLE_COMPILE_CACHE=1 \
    --bind $EU_VIBE_DIR/models:/models:ro --cwd /models \
    --home $EU_VIBE_HOME:/home \
    --bind $EU_VIBE_TMP:/tmp \
    $EU_VIBE_SIF \
        Qwen3.6-27B \
            --trust-remote-code \
            --tensor-parallel-size 1 \
            --enable-auto-tool-choice \
            --tool-call-parser qwen3_coder \
            --reasoning-parser qwen3 \
            --language-model-only \
            --max-model-len 262144 \
            --max-num-seqs 16 \
            --override-generation-config.temperature 0.6 \
            --override-generation-config.top_p 0.95 \
            --override-generation-config.top_k 20 \
            --override-generation-config.min_p 0.0 \
            --override-generation-config.presence_penalty 0.0 \
            --override-generation-config.repetition_penalty 1.0 \
            --host 0.0.0.0 \
            --port 11434
