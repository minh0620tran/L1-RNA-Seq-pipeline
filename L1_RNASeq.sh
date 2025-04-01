#!/bin/bash
#SBATCH --qos=long
#SBATCH --job-name=RNASeq
#SBATCH -o RNASeq_OutputLog.txt
#SBATCH -e RNASeq_ErrorLog.txt
#SBATCH --mail-user=user@tulane.edu
#SBATCH --mail-type=all
#SBATCH --time=7-00:00:00
#SBATCH --nodes=1 
#SBATCH --ntasks-per-node=12
#SBATCH --mem=128000

#Usage: for i in *_1.fastq *_1.fq; do sample=$(basename $i | sed 's/_1.*//'); sbatch --job-name=$sample L1_RNASeq.sh $i; done
# Load Conda
source ~/.bashrc  # Ensure conda is available (if using bash)
conda activate L1_rnaseq_pipeline  # Activate environment

# Check if argument is provided
if [ $# -eq 0 ]; then
    echo "Error: No input file specified"
    echo "Usage: $0 input_fastq_file"
    exit 1
fi

# Check file extension and get prefix flexibly
if [[ $1 =~ \.(fastq|fq)(_[1-2])?\.(gz)?$ ]]; then
    # Remove file extension and potential paired-end identifier
    prefix=$(basename "$1" | sed -E 's/_?[12]?\.(fastq|fq)(\.gz)?$//')
else
    echo "Error: Input file must have .fastq or .fq extension (with optional .gz). Do not use gzip files."
    exit 1
fi

# Get directory of the input file
fastq_file_path=$(dirname "$1")

# Create new directory for each sample 
sample_dir=${fastq_file_path}/"${prefix}"
mkdir -p ${sample_dir}  # Create directory if it doesn't exist
mkdir -p ${sample_dir}/fastqc_reports/  # Create fastqc reports directory

# Move fastq files to sample directory (handling both .fastq and .fq extensions)
mv ${prefix}_1.{fastq,fq} ${prefix}_2.{fastq,fq} ${sample_dir}/ 2>/dev/null || true

# Change to sample directory for processing
cd ${sample_dir}

echo ">>> Running FastQC on raw reads"
fastqc ${prefix}_1.{fastq,fq} ${prefix}_2.{fastq,fq} -o fastqc_reports/

echo ">>> Running Fastp for quality analysis (without trimming)"
fastp -w 10 \
      -i ${prefix}_1.{fastq,fq} -I ${prefix}_2.{fastq,fq} \
      --detect_adapter_for_pe \
      --disable_trim_poly_g \
      --disable_length_filtering \
      --html ${prefix}_fastp_report.html \
      --json ${prefix}_fastp_report.json \
      -o ${prefix}_filtered_1.fastq \
      -O ${prefix}_filtered_2.fastq

echo ">>> Alignment of fastq files to the genome using Bowtie"
bowtie -p 10 -m 1 -S -y -v 3 -X 600 --chunkmbs 8184 \
       /lustre/project/vperepe/apps/bowtieIndexes/hg38_chr_labels \
       -1 ${prefix}_filtered_1.fastq -2 ${prefix}_filtered_2.fastq | \
       samtools view -hbuS - | \
       samtools sort -o ${prefix}_bowtie_hg38_sorted.bam

echo ">>> Remove duplicates"
samtools rmdup ${prefix}_bowtie_hg38_sorted.bam ${prefix}_rmdup_bowtie_hg38_sorted.bam

echo ">>> Generate read counts against L1 loci"
bedtools coverage -a /lustre/project/vperepe/Minh/general_toolkits/FL-L1-BLAST_RM_plus_hg38_1_2021.bed \
                 -b ${prefix}_rmdup_bowtie_hg38_sorted.bam > \
                 ${prefix}_L1_read_counts.txt

echo ">>> Index bam file"
samtools index ${prefix}_rmdup_bowtie_hg38_sorted.bam

echo "Pipeline completed successfully for ${prefix}"