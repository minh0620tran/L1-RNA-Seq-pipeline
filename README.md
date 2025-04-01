# LINE-1-RNA-Seq-pipeline

## Overview

This pipeline is designed for analyzing LINE-1 RNA-Seq data using a stringent alignment strategy. Due to the repetitive nature of LINE-1 elements, we utilize **Bowtie1** with unique alignment settings to ensure high specificity in mapping reads to LINE-1 loci. The pipeline follows these major steps:

### Steps

Quality Control: Uses FastQC and Trimmomatic for read quality assessment and preprocessing.

Alignment: Bowtie1 with unique alignment settings to stringently map reads to LINE-1 sequences.

Post-Alignment Processing: Includes samtools for sorting, filtering, and indexing.

Quantification: Generates count tables for LINE-1 loci.

## Setup

### Requirements

Ensure the following dependencies are installed:
  - fastqc
  - fastp
  - bowtie=1.3.1
  - bedtools
  - samtools

## Installation

Clone this repository and set up the environment using the provided YAML file:

```bash
git clone https://github.com/minh0620tran/L1-RNA-Seq-pipeline.git
cd L1-RNA-Seq-pipeline
conda env create -f L1_rnaseq_pipeline.yml
conda activate L1_rnaseq_pipeline

## Computational requirements
Due to the computationally intensive nature of Bowtie1 alignment for repetitive elements and the substantial memory requirements for processing LINE-1 sequences, this pipeline is optimized for execution on High-Performance Computing (HPC) clusters.
For typical RNA-Seq datasets, we recommend the following SLURM parameters:
```bash
#SBATCH --qos=long
#SBATCH --job-name=LINE1-RNASeq
#SBATCH -o LINE1_RNASeq_OutputLog.txt
#SBATCH -e LINE1_RNASeq_ErrorLog.txt
#SBATCH --mail-user=user@abc.xyz
#SBATCH --mail-type=all
#SBATCH --time=7-00:00:00
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=12
#SBATCH --mem=128000

These specifications allocate:
- 128GB of RAM
- 12 CPU cores on a single node
- Up to 7 days of runtime
- Long queue priority

## Running the Pipeline

Before running L1-RNASeq-pipeline, you will need the hg38 reference genome in fasta format, with Bowtie1 index. To download hg38 reference genome: 

```bash
wget http://hgdownload.cse.ucsc.edu/goldenPath/hg38/bigZips/hg38.fa.gz
zcat hg38.fa.gz > hg38.fa
bowtie-build hg38.fa hg38

To execute the script: 
```for i in *_1.fastq *_1.fq; do sample=$(basename $i | sed 's/_1.*//'); sbatch --job-name=$sample L1_RNASeq.sh $i; done```

