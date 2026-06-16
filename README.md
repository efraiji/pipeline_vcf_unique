# pipeline_vcf_unique — version Snakemake

Identifie les variants SNV uniques à chaque échantillon, puis filtre via blacklists et gnomAD.

## Étapes (DAG)

```
vcf2bed -> unique_bed -> filter_blacklist -> bed2vcf -> annotate -> gnomad_filter
                            ^
                            +-- combined_blacklist
```

## Structure

```
.
├── Snakefile
├── config/config.yaml
├── workflow/rules/
│   ├── vcf2bed.smk
│   ├── unique.smk
│   ├── blacklist.smk
│   ├── bed2vcf.smk
│   └── annotate.smk
└── profiles/slurm/config.yaml
```

## Configuration

Éditer `config/config.yaml` :
- `vcf_dir` : dossier contenant les VCF d'entrée (`<sample>.*.vcf.gz`)
- `vcf_suffix` : suffixe complet (informatif — le code détecte `<sample>` comme tout ce qui précède le 1er point)
- `results_dir` : racine des sorties
- `blacklist_dir` / `blacklists` : BEDs blacklist
- `vcfanno_bin` / `vcfanno_toml` : annotation
- `gnomad_af_max` : seuil filtre gnomAD

## Lancer le pipeline

Dry-run (vérifier le DAG sans rien exécuter) :
```bash
snakemake -n
```
### Dry-run (vérifier sans exécuter)

```bash
snakemake --profile workflow/profiles/default --rerun-incomplete --keep-going -n
```

Exécution locale (1 thread) :
```bash
snakemake --cores 1
```

Sur le cluster SLURM (def-acheng) :
```bash
snakemake --profile profiles/slurm
```

Forcer la re-exécution d'une cible :
```bash
snakemake --profile profiles/slurm --forcerun gnomad_filter
```

## Prérequis cluster

- `snakemake >= 8` + `snakemake-executor-plugin-slurm`
- `module avail` doit exposer `bedtools/2.31.0` et `bcftools`
- Binaire `vcfanno` accessible au chemin défini dans `config.yaml`

## Sorties

```
<results_dir>/
├── bed/                            # BEDs SNV par échantillon
│   └── unique_bed/                 # BEDs uniques par échantillon
│       └── filtered/               # BEDs uniques moins blacklist
├── blacklist/combined_blacklist.bed
└── vcf_unique/                     # VCF des variants uniques
    └── annot/                      # VCF annotés vcfanno
        └── gnomad_filtered/        # VCF finaux filtrés gnomAD
```
