# Extrait du VCF original les positions retenues dans le BED filtré.

rule bed2vcf:
    input:
        vcf = lambda wc: SAMPLE_TO_VCF[wc.sample],
        bed = f"{FILTERED_DIR}/{{sample}}_unique_filtered.bed",
    output:
        vcf = f"{VCF_OUT_DIR}/{{sample}}_unique_filtered.vcf.gz",
        tbi = f"{VCF_OUT_DIR}/{{sample}}_unique_filtered.vcf.gz.tbi",
    log:
        "logs/bed2vcf/{sample}.log",
    envmodules:
        config["modules"]["bcftools"],
    resources:
        mem_mb  = 1000,
        runtime = 60,
    shell:
        r"""
        mkdir -p $(dirname {output.vcf})
        bcftools view -R {input.bed} -O z -o {output.vcf} {input.vcf} 2> {log}
        bcftools index -t {output.vcf} 2>> {log}
        """
