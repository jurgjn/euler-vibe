"""Crop the unpaired MSA from an AF3 *_data.json.gz to a residue range and write it as .a3m for Boltz.

Usage: crop_af3_msa.py <data.json.gz> <start> <end> <out.a3m>   (1-based, inclusive)
"""
import gzip, json, sys

path, start, end, out = sys.argv[1], int(sys.argv[2]), int(sys.argv[3]), sys.argv[4]
with gzip.open(path, 'rt') as fh:
    protein = json.load(fh)['sequences'][0]['protein']

seen, records = set(), []
lines = protein['unpairedMsa'].splitlines()
for header, seq in zip(lines[0::2], lines[1::2]):
    match_cols = ''.join(c for c in seq if not c.islower())  # drop insertions -> query-aligned columns
    assert len(match_cols) == len(protein['sequence']), header
    crop = match_cols[start - 1:end]
    if crop.strip('-') and crop not in seen:
        seen.add(crop)
        records.append((header, crop))

assert records[0][1] == protein['sequence'][start - 1:end]
with open(out, 'w') as fh:
    fh.writelines(f'{h}\n{s}\n' for h, s in records)
print(f'{len(records)} sequences, length {end - start + 1}: {records[0][1]}')
