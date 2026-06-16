# Pour chaque échantillon : soustrait l'union des BEDs des AUTRES échantillons.
# Produit un BED des positions présentes uniquement dans cet échantillon.

def _others_beds(wildcards):
    return [f"{BED_DIR}/{s}.bed" for s in SAMPLES if s != wildcards.sample]

rule unique_bed:
    input:
        current = f"{BED_DIR}/{{sample}}.bed",
        others  = _others_beds,
    output:
        unique  = f"{UNIQUE_DIR}/{{sample}}_unique.bed",
    log:
        "logs/unique_bed/{sample}.log",
    envmodules:
        config["modules"]["bedtools"],
    resources:
        mem_mb  = 2000,
        runtime = 60,
    shell:
        r"""
        mkdir -p $(dirname {output.unique})
        merged=$(mktemp --suffix=.bed)
        trap "rm -f $merged" EXIT

        cat {input.others} | sort -k1,1 -k2,2n | bedtools merge > "$merged" 2> {log}
        bedtools subtract -a {input.current} -b "$merged" > {output.unique} 2>> {log}
        """
