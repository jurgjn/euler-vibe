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
