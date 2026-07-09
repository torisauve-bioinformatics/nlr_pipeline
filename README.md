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
## HPC Support

The pipeline also runs on SLURM-managed HPC clusters via Singularity. This required several adaptations beyond the local Docker setup. See [Development Challenges](#development-challenges) below for details.

## Development Challenges 

Containerizing this pipeline meant packaging tools with non-trivial dependency chains, most notably **InterProScan**, which requires large reference databases and a specific runtime environment. A few of the harder problems along the way:

**Reference database size vs. HPC image limits.** InterProScan's bundled reference datasets result in a built image of ~118GB, exceeding what many HPC's allows for a single pulled image. Fix: the datasets were stripped out of the image at build time and instead mounted separately at runtime via Singularity's `runOptions` (note: must be set as `singularity.runOptions`, not `runOptions`, or the mount silently fails to resolve).

**Path resolution across Docker → Singularity.** InterProScan insists on resolving paths relative to its own install directory rather than Nextflow's work directory, which breaks silently when moving from Docker (local) to Singularity (HPC), since Singularity also disallows directory creation inside a running container. Fix: absolute paths were enforced explicitly (`readlink -f`, `$(pwd)`), and a dedicated scratch directory was created ahead of time and passed to InterProScan via its `--tempdir` flag.

**Broken CLI flags in this InterProScan version.** The documented `-c` CPU flag errors out rather than setting thread count, and CPU limits that work locally cause silent failures at higher core counts on HPC (jobs would reach ~83% completion and die without an error). Fix: worker counts were set directly in `interproscan.properties` (`worker.number.of.embedded.workers`) rather than via the CLI flag.

Full build notes and additional fixes (Meme Suite/Fimo unit test failures, ARM vs. amd64 platform handling, HPC-specific library dependencies) are documented in [`docs/development-notes.md`](docs/development-notes.md).

