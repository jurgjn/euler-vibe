# AGENTS.md

## Shared data: `/cluster/work/beltrao/shared`

Local mirrors of public structure databases, shared across the group. Use them instead of downloading the same files again. Inside an `euler-claude` container the directory is only visible if it is listed in the project's `.euler-vibe/mounts` (e.g. `/cluster/work/beltrao/shared::ro`). Treat it as read-only: the files are large and other people's jobs use them.

| Path | Contents |
| --- | --- |
| `alphafold/v6/` | [AlphaFold DB](https://alphafold.ebi.ac.uk/download) v6, mirrored from `ftp.ebi.ac.uk/pub/databases/alphafold/v6/` |
| `alphafold/v6/UP*_<taxid>_<CODE>_v6.tar` | Predicted structures for each model-organism / pathogen proteome, e.g. `UP000005640_9606_HUMAN_v6.tar`, `UP000002311_559292_YEAST_v6.tar` |
| `alphafold/v6/swissprot_{cif,pdb}_v6.tar` | All Swiss-Prot predictions, mmCIF and PDB format (~40 GB and ~29 GB) |
| `alphafold/v6/msa_depths.csv` | MSA depth per prediction (~3.8 GB) |
| `afdb_v6.sh` | `lftp` mirror script that produced `alphafold/` |
| `local.txt`, `remote.txt` | Size and name of each file, local and on the EBI server; identical means the mirror is complete |
| `rsyncPDB/` | Full PDB archive (`/pub/pdb`, ~250 GB) mirrored via rsync from PDBe (`rsync.ebi.ac.uk::pub/databases/rcsb/pdb-remediated`) |
| `rsyncPDB/data/structures/divided/{mmCIF,pdb,...}/` | Entries by format, in subdirectories named after the middle two characters of the PDB ID (`1abc` → `ab/`) |
| `rsyncPDB/data/{assemblies,biounit,component-models,...}/`, `rsyncPDB/derived_data/` | Biological assemblies, chemical components, derived data |
| `rsyncPDB.sh` | Mirror script for `rsyncPDB/` (from RCSB's [`rsyncPDB.sh`](https://files.rcsb.org/pub/pdb/software/rsyncPDB.sh), `--delete` enabled) |
| `rsyncPDB.txt` | Log of the last `rsyncPDB.sh` run. A finished sync ends with rsync's transfer summary; if the log ends in file names, the sync is still running (or was cut off) and `rsyncPDB/` may be incomplete |

The AlphaFold tars contain gzipped models named `AF-<UniProt>-F<n>-model_v6.{cif,pdb}.gz`. Read single entries with `tar -xOf <tar> <member>` or Python's `tarfile`. Don't unpack whole archives into `/cluster/project` or `/cluster/work`: millions of small files are slow there and count against the file quota. Unpack into the job's local scratch (`$TMPDIR`) instead.

## Shared data: `/cluster/project/beltrao/shared`

Group-made AlphaFold 3 inputs, outputs, containers and weights (see its `README.md`). Mounted read-only via `/cluster/project/beltrao/shared::ro`.

| Path | Contents |
| --- | --- |
| `25.05_alphafold3_msas_human/`, `25.06_alphafold3_msas_yeast/` | Pre-computed AlphaFold 3 data pipeline output (MSAs + templates) for the human (~20k) and yeast (~6k) proteomes, sequences from AFDB v4. One `<uniprot>_data.json.gz` per protein (lower-case accession, e.g. `a0a024r1r8_data.json.gz`); both directories include a [pre-generated data-fill index](https://github.com/jurgjn/af3io). Reuse these instead of re-running the (slow) data pipeline |
| `25.05.22_alphafold3_tubb/` | AlphaFold 3 predictions of TUBB (P07437) + TUBA1B (Q71U36) with ~1,100 partner proteins, one standard AF3 output directory per complex (`p07437_q71u36_<partner>/`) |
| `human-resid.tsv.gz` | Per-residue table for the human proteome: `resid_id`, `uniprot_id`, `resid`, `pos`, `pLDDT`, `am_mean_pathogenicity` (AlphaMissense) |
| `alphafold3/images/` | Apptainer images (`*.sif`) of [AlphaFold 3 builds](https://hub.docker.com/r/jurgjn/alphafold3) (releases and specific commits) and related tools (Boltz, ColabFold, OpenFold3, ...); `README.md` logs additions |
| `alphafold3/models/af3.bin.zst` | AlphaFold 3 model parameters, subject to the [AF3 weights terms of use](https://github.com/google-deepmind/alphafold3/blob/main/WEIGHTS_TERMS_OF_USE.md): don't copy them elsewhere |
| `alphafold3/models-af3-any-model{,-hf}/` | Weights of other AF3-architecture models (Boltz-2, Chai-1, OpenFold3, Protenix, RoseTTAFold3, ...) converted to AF3's JAX format for [`sokrypton/alphafold3@af3-any-model`](https://github.com/sokrypton/alphafold3/tree/af3-any-model); `-hf/README.md` lists models and licences |
| `26.06_of3_weights_converted/` | OpenFold3 weights ported to AF3 format |
| `JvG/` | Personal project directory, not general-purpose data |

## Shared data: `/cluster/project/alphafold/alphafold3`

The AlphaFold 3 genetic and structure databases, as fetched by `fetch_databases.sh` (from AF3's script of the same name). Pass this directory as AF3's `--db_dir`. Mounted read-only via `/cluster/project/alphafold/alphafold3::ro`; it is maintained centrally, not by the group.

| Path | Contents |
| --- | --- |
| `uniref90_2022_05.fa`, `uniprot_all_2021_04.fa`, `mgy_clusters_2022_05.fa`, `bfd-first_non_consensus_sequences.fasta` | Protein sequence databases for MSA search (~70–130 GB each) |
| `nt_rna_2023_02_23_*.fasta`, `rfam_14_9_*.fasta`, `rnacentral_active_*.fasta` | RNA sequence databases |
| `pdb_seqres_2022_09_28.fasta` | PDB sequences for template search |
| `mmcif_files/` | PDB mmCIF files (~196k, flat, `<pdbid>.cif`) used for templates, PDB snapshot of 2022-09-28; `pdb_2022_09_28_mmcif_files.tar` is the same as an archive (~250 GB) |

For up-to-date PDB entries use `rsyncPDB/` in `/cluster/work/beltrao/shared` instead.
