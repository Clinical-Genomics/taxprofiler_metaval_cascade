process CAT_FASTQ {
    publishDir "${results_dir}/merged_filtered_fastq", mode: 'copy', pattern: "*_merged*.fastq.gz"

    input:
    val results_dir  // pass the actual path string

    output:
    path "*_merged*.fastq.gz", emit: merged_fastq
    path "samplesheet.csv", emit: samplesheet

    script:
    def output_dir = "${results_dir}/merged_filtered_fastq"
    """
    echo "sample,instrument_platform,fastq_1,fastq_2" > samplesheet.csv

    # Process each subdirectory
    for subdir in bbduk nanoq filtlong; do
        fastq_dir="${results_dir}/\${subdir}"

        # Skip if directory doesn't exist
        if [[ ! -d "\${fastq_dir}" ]]; then
            continue
        fi

        # Determine instrument_platform type
        case "\${subdir}" in
            bbduk)
                instrument_platform="ILLUMINA"
                ;;
            nanoq|filtlong)
                instrument_platform="OXFORD_NANOPORE"
                ;;
        esac

        # Get unique sample names
        if [[ "\${instrument_platform}" == "ILLUMINA" ]]; then
            samples=\$(ls \${fastq_dir}/*.fastq.gz 2>/dev/null | xargs -n 1 basename | cut -d'_' -f1 | sort -u || true)
        else
            samples=\$(ls \${fastq_dir}/*_filtered.fastq.gz 2>/dev/null | xargs -n 1 basename | sed 's/_filtered.fastq.gz//' | cut -d'_' -f1 | sort -u || true)
        fi

        # Concatenate fastq files for each sample
        for sample in \${samples}; do
            if [[ "\${instrument_platform}" == "ILLUMINA" ]]; then
                read1=\$(find \${fastq_dir} -name "\${sample}_*_1.fastq.gz" 2>/dev/null | sort || true)
                if [[ -n "\${read1}" ]]; then
                    cat \${read1} > \${sample}_merged_1.fastq.gz
                fi

                read2=\$(find \${fastq_dir} -name "\${sample}_*_2.fastq.gz" 2>/dev/null | sort || true)
                if [[ -n "\${read2}" ]]; then
                    cat \${read2} > \${sample}_merged_2.fastq.gz
                    echo "\${sample},\${instrument_platform},${output_dir}/\${sample}_merged_1.fastq.gz,${output_dir}/\${sample}_merged_2.fastq.gz" >> samplesheet.csv
                else
                    echo "\${sample},\${instrument_platform},${output_dir}/\${sample}_merged_1.fastq.gz," >> samplesheet.csv
                fi
            else
                nanopore_fastq=\$(find \${fastq_dir} -name "\${sample}_*_filtered.fastq.gz" 2>/dev/null | sort || true)
                if [[ -n "\${nanopore_fastq}" ]]; then
                    cat \${nanopore_fastq} > \${sample}_merged.fastq.gz
                    echo "\${sample},\${instrument_platform},${output_dir}/\${sample}_merged.fastq.gz," >> samplesheet.csv
                fi
            fi
        done
    done
    """
}
