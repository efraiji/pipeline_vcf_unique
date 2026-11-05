# =====================================================================
# Pipeline vcf_unique — identification de variants uniques par échantillon
#
# Étapes :
#   1. vcf2bed         : VCF -> BED (SNV uniquement)
#   2. unique_bed      : variants présents dans un seul échantillon
#   3. filter_blacklist: soustraction des régions blacklistées
#   4. bed2vcf         : extraction des variants uniques depuis le VCF
#   5. annotate        : annotation vcfanno (gnomAD, etc.)
#   6. gnomad_filter   : filtrage sur INFO/gnomad_AF
# =====================================================================

import glob
from pathlib import Path

configfile: "config/config.yaml"

# --- Détection des échantillons ---
VCF_DIR     = config["vcf_dir"]
RESULTS_DIR = config["results_dir"]

_vcf_paths = sorted(glob.glob(f"{VCF_DIR}/*.vcf.gz") + glob.glob(f"{VCF_DIR}/*.vcf"))
if not _vcf_paths:
    raise ValueError(f"Aucun VCF trouvé dans {VCF_DIR}")

# nom d'échantillon = tout ce qui précède le premier point du basename
SAMPLE_TO_VCF = {Path(p).name.split(".")[0]: p for p in _vcf_paths}
SAMPLES = sorted(SAMPLE_TO_VCF.keys())

# --- Répertoires de sortie ---
BED_DIR        = f"{RESULTS_DIR}/bed"
UNIQUE_DIR     = f"{BED_DIR}/unique_bed"
FILTERED_DIR   = f"{UNIQUE_DIR}/filtered"
VCF_OUT_DIR    = f"{RESULTS_DIR}/vcf_unique"
ANNOT_DIR      = f"{VCF_OUT_DIR}/annot"
GNOMAD_DIR     = f"{ANNOT_DIR}/gnomad_filtered"

# --- Inclusions des règles ---
include: "workflow/rules/genpipes_filter.smk"
# include: "workflow/rules/vcf2bed.smk"
include: "workflow/rules/unique.smk"
include: "workflow/rules/blacklist.smk"
include: "workflow/rules/bed2vcf.smk"
include: "workflow/rules/annotate.smk"

# --- Cible finale ---
rule all:
    input:
        expand(f"{GNOMAD_DIR}/{{sample}}_gnomad_filtered.vcf.gz",     sample=SAMPLES),
        expand(f"{GNOMAD_DIR}/{{sample}}_gnomad_filtered.vcf.gz.tbi", sample=SAMPLES),
