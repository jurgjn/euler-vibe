#!/usr/bin/env bash
set -v -x -e -u -o pipefail

# Expected from the euler-vibe wrapper
: "${EUVIBE_DIR:?must be set}"
: "${EUVIBE_PORT:?must be set}"
: "${EUVIBE_MODEL:?must be set}"
: "${EUVIBE_SERVED_MODEL_NAME:?must be set}"
: "${EUVIBE_CONTEXT_LENGTH:?must be set}"

echo EUVIBE_DIR is $EUVIBE_DIR, EUVIBE_PORT is $EUVIBE_PORT

export EUVIBE_SIF=$EUVIBE_DIR/serve-local/sandboxes/sglang_v0.5.21.sif

export FROM="$(hostname) ${SLURM_NODEID}/${SLURM_NNODES}:"
export HEAD_NAME=$(scontrol show hostnames "$SLURM_JOB_NODELIST" | head -n 1)
export HEAD_ADDR=$(host $HEAD_NAME | awk '{ print $NF }' )
echo ${FROM} HEAD_NAME is $HEAD_NAME, HEAD_ADDR is $HEAD_ADDR, local TMPDIR is $TMPDIR

export OVERLAY_DIR="$TMPDIR/euler-vibe.$$"
echo ${FROM} OVERLAY_DIR is $OVERLAY_DIR
mkdir -p "$OVERLAY_DIR"/{home,models,overlay,tmp}

# Use exactly 2 GPUs, even if the job or node has more: the first two of
# those visible here (CUDA_VISIBLE_DEVICES under Slurm, else all on the node)
IFS=, read -r -a GPUS <<< "${CUDA_VISIBLE_DEVICES:-$(nvidia-smi --query-gpu=index --format=csv,noheader | paste -sd,)}"
if (( ${#GPUS[@]} < 2 )); then
    echo "${FROM} Need 2 GPUs, found ${#GPUS[@]}: ${GPUS[*]}" >&2
    exit 1
fi
export EUVIBE_GPUS="${GPUS[0]},${GPUS[1]}"
echo ${FROM} EUVIBE_GPUS is $EUVIBE_GPUS

ARGS=(
    --nv
    --cleanenv
    --containall

    # Specifically add an extra bind mount for /tmp as Apptainer default is too small
    --home $OVERLAY_DIR/home:/home
    --bind $OVERLAY_DIR/models:/models:ro --cwd /models
    --bind $OVERLAY_DIR/tmp:/tmp
    --overlay $OVERLAY_DIR/overlay

    # Memory is tight on 24 GiB cards; reclaim fragmented "reserved but
    # unallocated" memory (0.57 GiB in an OOM at --mem-fraction-static 0.88)
    --env PYTORCH_CUDA_ALLOC_CONF=expandable_segments:True
    --env CUDA_VISIBLE_DEVICES=$EUVIBE_GPUS
    # The image's runscript otherwise re-quotes and evals the arguments, which
    # strips the double quotes inside --json-model-override-args
    --env SINGULARITY_NO_EVAL=1

    # Like vLLM, SGLang uses high-performance Inter-Process Communication (IPC) for Multi-GPU configurations. Apptainer restricts access to /dev/shm on cluster nodes unless cleanly bound.
    #--bind /dev/shm:/dev/shm

    $EUVIBE_SIF
    
    # Do not rely on the container's default entrypoint. Apptainer often bypasses the entrypoint binary layer. Explicitly executing the module via Python works around this issue.
    python3 -m sglang.launch_server

    # https://recipes.vllm.ai/Qwen/Qwen3.8-27B-FP8
    --tp 2
    --model-path $EUVIBE_MODEL
    --served-model-name $EUVIBE_SERVED_MODEL_NAME

    # 2x rtx_4090 (TP=2): 13.8 GiB/GPU of weights (incl. the MTP head) leaves
    # room for one session at long context, so trade concurrency for context length
    --max-running-requests 1
    --context-length $EUVIBE_CONTEXT_LENGTH
    # Needed for 262144: only 16/64 layers are full attention, so the fp8 KV
    # cache is ~4 GiB/GPU at full context (bf16 would be ~8 GiB and not fit)
    --kv-cache-dtype fp8_e4m3

    # Linear-attention (mamba) state slots: 5 per running request with the
    # extra-buffer radix cache, plus one cached prefix. Left unset, sglang
    # gives mamba state ~half the memory left after weights (0.9:1 vs KV),
    # which with MTP held the KV cache to 102685 tokens
    --max-mamba-cache-size 6

    # Weights + KV + mamba state; the rest is headroom for CUDA context, NCCL,
    # activations and decode graphs. 0.84 was the limit with prefill graphs
    # (1.8 GiB outside this fraction; 0.88 ran out of memory in the forward pass)
    --mem-fraction-static 0.90
    # Smaller prefill chunks keep activation peaks within that headroom
    --chunked-prefill-size 4096
    # Prefill graphs cost 1.8 GiB/GPU; spend it on KV cache instead
    --disable-prefill-cuda-graph
    # Only capture graphs for batch sizes we can actually reach
    --cuda-graph-max-bs-decode 1

    # PCIe 4090s: custom allreduce is unsupported anyway; silences the warning
    --disable-custom-all-reduce

    # Text only: never load the vision encoder, leaving its memory to the KV
    # cache; image requests are rejected (models.json tells pi as much).
    # --language-model-only rejects Qwen3_5ForConditionalGeneration, but the
    # model honours the same setting declared in its config
    --json-model-override-args '{"language_model_only": true}'

    # Explicit rather than relying on chat-template auto-detection
    --reasoning-parser qwen3
    --tool-call-parser qwen3_coder

    # MTP: the checkpoint's own fp8 next-token head (mtp.safetensors, ~0.24
    # GiB/GPU) is the draft; Qwen3_5 does not default the draft path to the
    # target, so pass it explicitly. 3 steps, chain (topk 1), 4 draft tokens
    --speculative-algorithm NEXTN
    --speculative-draft-model-path $EUVIBE_MODEL
    --speculative-num-steps 3
    --speculative-eagle-topk 1
    --speculative-num-draft-tokens 4
    # The draft KV pool has a slot per target token, so keep it in fp8 too;
    # this only affects acceptance, not output
    --speculative-draft-kv-cache-dtype fp8_e4m3

    # Only reachable from this node (pi connects via localhost); key matches models.json
    --host 127.0.0.1
    --port $EUVIBE_PORT
    --api-key $OPENAI_API_KEY
)
echo ${FROM} ARGS is "${ARGS[@]}"

export MODEL_SRC=$EUVIBE_DIR/serve-local/models/$EUVIBE_MODEL
export MODEL_DST=$OVERLAY_DIR/models/$EUVIBE_MODEL
echo ${FROM} Copying model - MODEL_SRC is $MODEL_SRC, MODEL_DST is $MODEL_DST
rclone copy $MODEL_SRC $MODEL_DST \
    --exclude ".git/" \
    --progress --stats 1m \
    --transfers=4 \
    --multi-thread-streams=8 \
    --multi-thread-cutoff=64M

echo ${FROM} Starting container
exec singularity run "${ARGS[@]}"
