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


# Convertit un VCF en BED en ne gardant que les SNV (REF=1bp, ALT=1bp).


rule vcf2bed:
    input:
        vcf  = lambda wc: SAMPLE_TO_VCF[wc.sample],
        flag = "logs/index_vcf/{sample}.done",
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



# rule vcf2bed:
#     input:
#         vcf  = lambda wc: SAMPLE_TO_VCF[wc.sample],
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