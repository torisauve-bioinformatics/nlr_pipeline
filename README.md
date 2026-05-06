# NLR Discovery Pipeline
A **Nextflow** pipeline for the identification and annotation of NLR (Nucleotide-binding Leucine-rich Repeat) genes. This workflow integrates three major tools in a fully containerized environment:
+ **NLRtracker**
+ **Resistify**
+ **NLRAnnotator**

# System Requirements
**Nextflow & Docker**
This pipeline requires Nextflow and Docker to be installed on your system.

Docker Configuration (Crucial)
To ensure the containers run correctly, especially on Apple Silicon (M1/M2/M3), please adjust your Docker Desktop settings:

1. Emulation: Go to Settings -> General and ensure "Use Rosetta for x86_64/amd64 emulation" is selected.

2. Resources: Go to Settings -> Resources and set the following limits:

+ **CPU**: 10
+ **Memory**: 12GB

# Run Instructions
To run the pipeline, use the following command. 
```
nextflow run pipeline.nf \
  -profile docker \
  -c nextflow.config \
  --genome_file path/to/your/genome.fasta
  --proteome_file path/to/your/protein.fasta
```
