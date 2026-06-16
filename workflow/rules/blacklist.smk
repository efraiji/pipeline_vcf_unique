# Construit la blacklist combinée (une seule fois) puis filtre chaque BED unique.

BLACKLIST_FILES = [f"{config['blacklist_dir']}/{b}" for b in config["blacklists"]]

rule combined_blacklist:
    input:
        BLACKLIST_FILES,
    output:
        combined = f"{RESULTS_DIR}/blacklist/combined_blacklist.bed",
    log:
        "logs/combined_blacklist.log",
    envmodules:
        config["modules"]["bedtools"],
    resources:
        mem_mb  = 1000,
        runtime = 30,
    shell:
        r"""
        mkdir -p $(dirname {output.combined})
        cat {input} \
          | awk -F'\t' 'BEGIN{{OFS="\t"}} {{print $1, $2, $3}}' \
          | sort -k1,1 -k2,2n \
          | bedtools merge \
          > {output.combined} 2> {log}
        """

rule filter_blacklist:
    input:
        bed       = f"{UNIQUE_DIR}/{{sample}}_unique.bed",
        blacklist = f"{RESULTS_DIR}/blacklist/combined_blacklist.bed",
    output:
        filtered  = f"{FILTERED_DIR}/{{sample}}_unique_filtered.bed",
    log:
        "logs/filter_blacklist/{sample}.log",
    envmodules:
        config["modules"]["bedtools"],
    resources:
        mem_mb  = 1000,
        runtime = 60,
        cpus_per_task = 4,
    shell:
        r"""
        mkdir -p $(dirname {output.filtered})
        if [ ! -s {input.bed} ]; then
            echo "BED vide, sortie vide" > {log}
            : > {output.filtered}
            exit 0
        fi
        awk -F'\t' 'BEGIN{{OFS="\t"}} {{print $1, $2, $3}}' {input.bed} \
          | bedtools subtract -a - -b {input.blacklist} \
          > {output.filtered} 2> {log}
        """
