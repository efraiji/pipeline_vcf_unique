# Indexe le VCF d'entrée (nécessaire pour bcftools view -R dans bed2vcf).
# Placée en amont pour que l'indexation se fasse tôt et une seule fois
# par échantillon, avant que bed2vcf n'en ait besoin.

rule index_vcf:
    input:
        vcf = lambda wc: SAMPLE_TO_VCF[wc.sample],
    output:
        flag = "logs/index_vcf/{sample}.done",
    log:
        "logs/index_vcf/{sample}.log",
    resources:
        mem_mb  = 2000,
        runtime = 30,
    shell:
        """
        module load bcftools
        if [ ! -f "{input.vcf}.tbi" ] && [ ! -f "{input.vcf}.csi" ]; then
            bcftools index -t {input.vcf} 2> {log}
        else
            echo "Index deja present, on saute l'indexation." > {log}
        fi
        touch {output.flag}
        """



# ══════════════════════════════════════════════════════════════
# Spécifique GENPIPES : ne garder que les variants supportés par
# 2 callers ou plus (champ INFO/CALLERS séparé par des virgules,
# ex: CALLERS=vardict,mutect2 = 2 callers, CALLERS=varscan2 = 1).
# On détecte simplement la présence d'une virgule dans le champ.
# ══════════════════════════════════════════════════════════════

rule filter_multicaller_genpipes:
    input:
        vcf = lambda wc: SAMPLE_TO_VCF[wc.sample],
    output:
        vcf = f"{FILTERED_DIR}/{{sample}}.genpipes.multicaller.vcf.gz",
        tbi = f"{FILTERED_DIR}/{{sample}}.genpipes.multicaller.vcf.gz.tbi",
    log:
        "logs/filter_multicaller_genpipes/{sample}.log",
    envmodules:
        config["modules"]["bcftools"],
    resources:
        mem_mb  = 4000,
        runtime = 60,
    shell:
        r"""
        mkdir -p $(dirname {output.vcf})
        tmp="{output.vcf}.tmp.vcf"
 
        # Garde l'en-tête + les lignes dont le champ CALLERS contient une virgule
        # (donc au moins 2 callers listés)
        zcat {input.vcf} \
        | awk 'BEGIN{{OFS="\t"}} \
               /^#/ {{print; next}} \
               {{ \
                   n = split($8, info, ";"); \
                   keep = 0; \
                   for (i = 1; i <= n; i++) {{ \
                       if (info[i] ~ /^CALLERS=/ && info[i] ~ /,/) {{ \
                           keep = 1; \
                           break; \
                       }} \
                   }} \
                   if (keep) print; \
               }}' \
        > "$tmp" 2> {log}
 
        bgzip -f "$tmp"
        mv "$tmp.gz" {output.vcf}
        bcftools index -t {output.vcf} 2>> {log}
        """
 

# ══════════════════════════════════════════════════════════════
# vcf2bed pour les échantillons Genpipes : utilise le VCF déjà
# filtré (2+ callers) au lieu du VCF brut.
# ══════════════════════════════════════════════════════════════

# rule vcf2bed_genpipes:
#     input:
#         vcf = f"{FILTERED_DIR}/{{sample}}.genpipes.multicaller.vcf.gz",
#         flag = "logs/index_vcf/{sample}.done",
#     output:
#         bed = f"{BED_DIR}/{{sample}}.bed",
#     log:
#         "logs/vcf2bed/{sample}.log",
#     resources:
#         mem_mb   = 8000,
#         runtime  = 90,
#     shell:
#         r"""
#         mkdir -p $(dirname {output.bed})
#         if [[ "{input.vcf}" == *.gz ]]; then
#             zcat {input.vcf}
#         else
#             cat {input.vcf}
#         fi \
#         | awk 'BEGIN{{OFS="\t"}} !/^#/ && length($4)==1 && length($5)==1 {{print $1, $2-1, $2}}' \
#         > {output.bed} 2> {log}
#         """

rule vcf2bed_genpipes:
    input:
        vcf = f"{FILTERED_DIR}/{{sample}}.genpipes.multicaller.vcf.gz",
    output:
        bed = f"{BED_DIR}/{{sample}}.bed",
    log:
        "logs/vcf2bed/{sample}.log",
    envmodules:
        config["modules"]["bcftools"],
    resources:
        mem_mb   = 8000,
        runtime  = 90,
    shell:
        r"""
        mkdir -p $(dirname {output.bed})
        bcftools view -f PASS -v snps {input.vcf} \
        | bcftools query -f '%CHROM\t%POS0\t%END\n' \
        > {output.bed} 2> {log}
        """