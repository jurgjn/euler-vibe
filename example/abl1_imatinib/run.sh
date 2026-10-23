#!/bin/bash
# Boltz-2: ABL1 kinase domain + imatinib, then compare to the 2HYY crystal structure
set -euo pipefail
cd "$(dirname "$0")"
python ../scripts/crop_af3_msa.py /cluster/project/beltrao/shared/25.05_alphafold3_msas_human/p00519_data.json.gz 229 500 abl1_229-500.a3m
boltz predict abl1_imatinib.yaml --out_dir . --diffusion_samples 5 --use_potentials
python ../scripts/compare_to_xtal.py /cluster/project/alphafold/alphafold3/mmcif_files/2hyy.cif A STI \
    "$(grep smiles: abl1_imatinib.yaml | cut -d"'" -f2)" boltz_results_abl1_imatinib/predictions/abl1_imatinib/abl1_imatinib_model_*.cif
