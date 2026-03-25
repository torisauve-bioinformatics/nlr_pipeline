# nlr_pipeline 
Nextflow pipeline with fully containerized NLR programs including NLRtracker, Resistify, and NLRAnnotator. 
System Requirements: 
Nextflow 
Docker: Make sure that Use Rosetta for x86_64/amd64 emulation on Apple Silicon box in your docker Settings->General is selected -Make sure that CPU limit is set to 10 and Memory limit is set to 12GB in Settings->Resources
Run Instructions: 
Command: nextflow run pipeline.nf -profile docker -c nextflow.config --genome_file {fasta file} 

