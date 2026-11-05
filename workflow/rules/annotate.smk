# Annotation vcfanno puis filtrage gnomAD.

rule annotate:
    input:
        vcf  = f"{VCF_OUT_DIR}/{{sample}}_unique_filtered.vcf.gz",
        toml = config["vcfanno_toml"],
    output:
        vcf  = f"{ANNOT_DIR}/{{sample}}.annot.vcf.gz",
        tbi  = f"{ANNOT_DIR}/{{sample}}.annot.vcf.gz.tbi",
    params:
        vcfanno = config["vcfanno_bin"],
    log:
        "logs/annotate/{sample}.log",
    envmodules:
        config["modules"]["bedtools"],
        config["modules"]["bcftools"],
    resources:
        mem_mb  = 32000,
        runtime = 299,
        cpus_per_task = 2,
    shell:
        r"""
        mkdir -p $(dirname {output.vcf})
        tmp="{output.vcf}.tmp.vcf"
        {params.vcfanno} {input.toml} {input.vcf} > "$tmp" 2> {log}
        bgzip -f "$tmp"
        mv "$tmp.gz" {output.vcf}
        bcftools index -t {output.vcf} 2>> {log}
        """

rule gnomad_filter:
    input:
        vcf = f"{ANNOT_DIR}/{{sample}}.annot.vcf.gz",
    output:
        vcf = f"{GNOMAD_DIR}/{{sample}}_gnomad_filtered.vcf.gz",
        tbi = f"{GNOMAD_DIR}/{{sample}}_gnomad_filtered.vcf.gz.tbi",
    params:
        af_max = config["gnomad_af_max"],
    log:
        "logs/gnomad_filter/{sample}.log",
    envmodules:
        config["modules"]["bcftools"],
    resources:
        mem_mb  = 1000,
        runtime = 60,
    shell:
        r"""
        mkdir -p $(dirname {output.vcf})
        bcftools view \
            -i 'INFO/gnomad_AF <= {params.af_max} || INFO/gnomad_AF="."' \
            -O z -o {output.vcf} \
            {input.vcf} 2> {log}
        bcftools index -t {output.vcf} 2>> {log}
        """
