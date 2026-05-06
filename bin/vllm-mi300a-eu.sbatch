#!/usr/bin/env bash
#SBATCH --job-name=vllm-mi300a-eu
#SBATCH --nodes=2
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=24
#SBATCH --mem-per-cpu=4G
#SBATCH --gpus-per-node=mi300a:4
#SBATCH --time=0-00:30:00

# Head node address for vllm
export HEAD_NAME=$(scontrol show hostnames "$SLURM_JOB_NODELIST" | head -n 1)
export HEAD_ADDR=$(host $HEAD_NAME | awk '{ print $NF }' )

echo HEAD_NAME / HEAD_ADDR is $HEAD_NAME / $HEAD_ADDR

# Use location of the script to find locations for config & container image
export EU_VIBE_BIN=/cluster/project/beltrao/jjaenes/euler-vibe/bin/vllm-mi300a-eu.sbatch
export EU_VIBE_DIR=$(dirname $(dirname $EU_VIBE_BIN))
export EU_VIBE_SIF=$EU_VIBE_DIR/images/vllm-openai-rocm_nightly.sif
export EU_VIBE_TMP=$SCRATCH/vllm-serve.$SLURM_JOB_ID

echo EU_VIBE_BIN is $EU_VIBE_BIN
echo EU_VIBE_DIR is $EU_VIBE_DIR
echo EU_VIBE_SIF is $EU_VIBE_SIF
echo EU_VIBE_TMP is $EU_VIBE_TMP

mkdir -p $EU_VIBE_TMP

# Apptainer environment variables
cat > $EU_VIBE_TMP/env-file.txt <<'EOF'
OMP_NUM_THREADS=1
HF_HUB_ENABLE_HF_TRANSFER=0
HF_HUB_DISABLE_TELEMETRY=1
VLLM_NO_USAGE_STATS=1
DO_NOT_TRACK=1
HF_DATASETS_OFFLINE=1
TRANSFORMERS_OFFLINE=1
HF_HUB_OFFLINE=1
VLLM_DISABLE_COMPILE_CACHE=1
EOF

# vllm config
cat > $EU_VIBE_TMP/config.yaml <<'EOF'
trust-remote-code: True
enable-auto-tool-choice: True
tool-call-parser: "qwen3_coder"
reasoning-parser: "qwen3"
language-model-only: True
max-model-len: 262144
max-num-seqs: 16
override-generation-config:
    temperature: 0.6
    top_p: 0.95
    top_k: 20
    min_p: 0.0
    presence_penalty: 0.0
    repetition_penalty: 1.0
host: 0.0.0.0
EOF

# Run vllm serve with rank 0 as head node and the rest as headless
srun bash <<'EOF'
echo $(hostname): SLURM_NODEID / SLURM_NNODES is $SLURM_NODEID / $SLURM_NNODES

export EU_VIBE_TMP_NODE=${EU_VIBE_TMP}/$(hostname)
echo $(hostname): EU_VIBE_TMP_NODE is $EU_VIBE_TMP_NODE

mkdir -p $EU_VIBE_TMP_NODE/home $EU_VIBE_TMP_NODE/tmp
cp $EU_VIBE_TMP/config.yaml $EU_VIBE_TMP_NODE/home/config.yaml

# Serve vllm; add --headless if rank > 0
if [ "$SLURM_NODEID" -eq 0 ]; then
    export ARG_HEADLESS=''
else
    export ARG_HEADLESS='--headless'
fi
echo $(hostname): ARG_HEADLESS is $ARG_HEADLESS
export TENSOR_PARALLEL_SIZE=$(expr $SLURM_GPUS_ON_NODE \* $SLURM_NNODES)
singularity run --rocm --cleanenv --containall \
    --env-file $EU_VIBE_TMP/env-file.txt \
    --bind $EU_VIBE_DIR/models:/models:ro --cwd /models \
    --home $EU_VIBE_TMP_NODE/home:/home \
    --bind $EU_VIBE_TMP_NODE/tmp:/tmp \
    $EU_VIBE_SIF Qwen3.6-27B --config /home/config.yaml \
        --nnodes $SLURM_NNODES --node-rank $SLURM_NODEID --tensor-parallel-size $TENSOR_PARALLEL_SIZE --master-addr $HEAD_ADDR $ARG_HEADLESS
EOF
