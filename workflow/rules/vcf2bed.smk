# Convertit un VCF en BED en ne gardant que les SNV (REF=1bp, ALT=1bp).

rule vcf2bed:
    input:
        vcf = lambda wc: SAMPLE_TO_VCF[wc.sample],
    output:
        bed = f"{BED_DIR}/{{sample}}.bed",
    log:
        "logs/vcf2bed/{sample}.log",
    resources:
        mem_mb   = 8000,
        runtime  = 90,
    shell:
        r"""
        mkdir -p $(dirname {output.bed})
        if [[ "{input.vcf}" == *.gz ]]; then
            zcat {input.vcf}
        else
            cat {input.vcf}
        fi \
        | awk 'BEGIN{{OFS="\t"}} !/^#/ && length($4)==1 && length($5)==1 {{print $1, $2-1, $2}}' \
        > {output.bed} 2> {log}
        """
