"""Compare predicted protein-ligand models to a crystal structure.

Superposes each model onto the crystal on sequence-aligned protein CA atoms, then reports
protein CA RMSD and symmetry-aware ligand heavy-atom RMSD (no ligand refit).

Usage: compare_to_xtal.py <xtal.cif> <xtal_chain> <xtal_ligand_resname> <smiles> <model.cif>...
"""
import re
import sys
import gemmi
from rdkit import Chem
from rdkit.Chem import AllChem, rdMolAlign

xtal_path, xtal_chain, xtal_lig, smiles, *models = sys.argv[1:]
template = Chem.MolFromSmiles(smiles)


def load(path):
    st = gemmi.read_structure(path)
    st.setup_entities()
    st.remove_hydrogens()
    return st[0]


def ligand_mol(residue):
    pdb = ''.join(
        f'HETATM{i + 1:5d} {a.name:<4s} LIG A   1    {a.pos.x:8.3f}{a.pos.y:8.3f}{a.pos.z:8.3f}  1.00  0.00          {a.element.name:>2s}\n'
        for i, a in enumerate(residue))
    mol = Chem.MolFromPDBBlock(pdb, removeHs=True, proximityBonding=True)
    return AllChem.AssignBondOrdersFromTemplate(template, mol)


ref = load(xtal_path)
ref_chain = ref[xtal_chain]
ref_poly = ref_chain.get_polymer()
ref_lig = next(r for r in ref_chain if r.name == xtal_lig)
ref_mol = ligand_mol(ref_lig)

for path in models:
    model = load(path)
    poly = model['A'].get_polymer()
    aln = gemmi.align_sequence_to_polymer([r.name for r in poly], ref_poly, gemmi.PolymerType.PeptideL)
    # pair residues over aligned (M) positions of the CIGAR string
    pairs, qi, ti = [], 0, 0
    for length, op in ((int(c[:-1]), c[-1]) for c in re.findall(r'\d+[MID]', aln.cigar_str())):
        for _ in range(length):
            if op == 'M':
                pairs.append((poly[qi], ref_poly[ti]))
                qi += 1; ti += 1
            elif op == 'I':
                qi += 1
            else:
                ti += 1
    pairs = [(a['CA'][0].pos, b['CA'][0].pos) for a, b in pairs if a.find_atom('CA', '*') and b.find_atom('CA', '*')]
    sup = gemmi.superpose_positions([b for a, b in pairs], [a for a, b in pairs])
    model.transform_pos_and_adp(sup.transform)
    lig = next(r for r in model['B'])
    rmsd = rdMolAlign.CalcRMS(ligand_mol(lig), ref_mol)
    print(f'{path.rsplit("/", 1)[-1]}\tCA pairs {sup.count}\tCA RMSD {sup.rmsd:.2f} A\tligand RMSD {rmsd:.2f} A\tidentity {aln.calculate_identity():.1f}%')
