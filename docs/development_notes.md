&nbsp;&nbsp;&nbsp;&nbsp;This project containerizes several major NLR detection tools, develops a Nextflow-based pipeline, and Python-based tools to evaluate consolidate results and understand the performance of the methods used in the pipeline (Figure 2). 

**Setup for Local Machines:** 

&nbsp;&nbsp;&nbsp;&nbsp;Docker was used to construct containers for Resistify and NLRtracker. Constructing a container for Resistify involved a python installation, a conda installation and the creation of a conda environment by calling an environment.yml file that contained the Resistify Python package.

&nbsp;&nbsp;&nbsp;&nbsp;The NLRtracker image creation involved building several dependencies for the program. Because of dependencies such as Interproscan, the program required an Ubuntu operating system, so the Ubuntu:20.04 base image was used. Core dependencies including Interproscan-5.53-87.0 and Fimo (via Meme Suite 5.2.0) were loaded by pulling their tarballs. Dependencies Meme Suite relies on were added to the image using Ubuntu’s apt-get function including Perl, libxml-parser-perl, libxml-simple-perl, libjson-perl, libhtml-template-perl, python3, zlib, Ghostscript, libtools, autoconf, automake, and wget. The command for installing Meme Suite involved pulling the tarball using wget, and building the executable using make. 

&nbsp;&nbsp;&nbsp;&nbsp;Interproscan dependencies included perl, python3, and open-jdk-11 (java). Java was similarly installed using Ubuntu’s installation command. Conda installation instructions were then added to the Dockerfile. Additional dependencies for NLRtracker including HMMER 3.3.2, r-base, r-essentials, r-tidyverse, r-biocmanager, and the r Bioconductor-biostrings package were built into the image by building a conda environment using the environment.yml file. Work directories for Fimo and Interproscan were set using Docker’s WORKDIR command. Fimo was set in /usr/local/src, while interproscan was set in /opt/interproscan-5.53-87.0. Finally, the NLRtracker directory containing its executable was cloned from github, and its working directory was set as /opt/NLRtracker. The container was then built using the “docker build” command, which required an additional flag to force Docker to run using Ubuntu’s architecture (--platform linux/amd64).

&nbsp;&nbsp;&nbsp;&nbsp;A pipeline that could run both Resistify and NLRtracker by pulling Docker images from Docker’s cloud repo was constructed using Nextflow. The Nextflow run file (pipeline.nf) was constructed by creating execute processes for NLRtracker and Resistify. A Nextflow configuration file (nextflow.config), was also constructed to allow Nextflow to pull the necessary Docker images. Each process in the configuration was set with its process name along with its container name. NLRtracker’s image was called from Docker’s repository as torisauve/nlrtracker:latest and Resistify’s was called as torisauve/resistify. NLRtracker required more CPU than Docker’s default, so the process’s CPU was set to 10 and its memory was set to 12GB. End users should also note that it was necessary to change the Docker CPU setting to 4 in their Docker application. Finally, a Docker profile was set to enable Docker in Nextflow. Because the images require an alternate platform from Mac architecture (linux/arm64/v8), it was necessary to define the platform as linux/amd64. 

*Development Challenges and Solutions:*

**Challenge 1: Fimo Installation Unit Test**
The “make test” command was removed from the Meme Suite build, as the unit test for a different, unnecessary package for running Fimo continuously failed, creating a fatal error in the installation. Removal of the unit testing allowed Fimo to run without fail, but before publication of this work, it would be necessary to identify and remove only the unit test that caused the complete test to fail.


**Challenge 2: Interproscan Directory Conflicts**
Interproscan insisted on computing from its own opt/interproscan-5.53-87.0 directory, which led to a fatal error in which interproscan could not locate Nextflow’s work directory to access the pipeline’s output directory. This was problematic as interproscan needed to access the tmp.fasta (its input file) and the directory to place its output files. As a result, interproscan’s execution command in the NLRtracker.sh file “-i \\${fasta}, where \\${fasta}=\\${outdir}/tmp.fasta would result in interproscan looking for opt/interproscan-5.53-87.0/out_dir/tmp.fasta.

To fix this, fasta=\\$(readlink -f \\$fasta) was added under the line that defines \\${fasta}. This made interproscan look at the absolute path instead of relative paths. Additionally, \\$(pwd) was added to the front of “-o \\${outdir}/interproscan_result.gff” to avoid a similar pathing problem. Following these changes, the Nextflow pipeline ran successfully on a local device. 

**Challenge 3: Interproscan CPU Flag**

Interproscan required 4 CPUs to run on a local device. However, Interproscan's default CPU's is 2 by default. Interproscan has a CPU flag in its command to adjust from the default. However, this flag is broken in this version of Interproscan and when added, raised an error claiming that “-c was not recognized”.

To solve this, it was necessary to run the container, navigate to interproscan’s directory and open interproscan’s configuration file (interproscan.properties). Once there, the default CPU for interproscan was changed from 2 to 4 by changing worker.number.of.embedded.workers and worker.maxnumber.of.embedded.workers to equal 4. 

**Setup for the HPC:**

&nbsp;&nbsp;&nbsp;&nbsp;To run on NYU’s HPC a number of changes were made to the Nextflow pipeline setup, the Docker build for NLRtracker, and the NLRtracker executable within the Docker container. This was necessary because Singularity had to be used to pull and run the Docker images instead of Docker. Singularity has slightly different security privileges when it comes to directories. Singularity does not allow the creation of directories in running containers. 

&nbsp;&nbsp;&nbsp;&nbsp;One change was made to the pipeline.nf file: a few lines were added to the Resistify process script for the creation of a temporary directory required for Matplotlib, one of Restify’s dependencies. A parameters section was added to the nextflow.config file to set the HPC’s computing environment for Nextflow to use. Additionally, resource limits were set in place. The executor was set to slurm and the HPC account was added using the “clusterOptions” command. Finally, Singularity was enabled using Singularity.enabled. 

&nbsp;&nbsp;&nbsp;&nbsp;The Docker build for NLRtracker required quite a few changes. To make development easier in the container, nano was added to avoid reliance on sed commands when making changes to files within the container. Additionally, unlike the local machine, the HPC does not have access to lib packages, so zliblg-dev and libgd-dev were added. Further problems will be discussed in the below section. 

*HPC-Specific Development Challenges and Solutions:*

Adapting the pipeline for the HPC environment introduced several additional technical challenges:

**Challenge 1: Large Image Size Restrictions**

&nbsp;&nbsp;&nbsp;&nbsp; The NYU HPC does not allow users to pull large images. This was problematic because one of NLRtracker’s dependencies, Interproscan, relies on multiple, large datasets, which results in a 118 GB image once built. 

&nbsp;&nbsp;&nbsp;&nbsp;To solve this, it was necessary to build interproscan into the container without these datasets and then mount them to the container in Singularity. Older version of interproscan downloads these datasets separately, but the required version has them inside the main tarball. The interproscan directory was downloaded to the local machine, uploaded to the HPC, the dataset was deleted from the local copy of interproscan and the file was re-tarred. In the Dockerfile, a command to untar the copy of Interproscan without the dataset replaced the wget command that pulled the directory from Interproscan’s website. Finally, the interproscan datasets were mounted to the Singularity profile using the “runOptions” command so that interproscan could still access them. It is worth noting to users that this command had to be set as “singularity.runOptions=path/to/file” instead of “runOptions=path/to/file”; without “singularity.”, the mounted directory was not located. 

**Challenge 2: Interproscan Path Resolution in Singularity**

&nbsp;&nbsp;&nbsp;&nbsp;The fix for the local interproscan input and output directory problem led to Interproscan looking for the tmp.fasta in opt/interproscan-5.53-87.0/nlrtracker_output/tmp.fasta instead of the nlrtracker_output directory in Nextflow’s work directory. 

&nbsp;&nbsp;&nbsp;&nbsp;To address this, it was necessary to set a Nextflow current working directory before the interproscan command as NEXTFLOW_CWD=\\$(PWD). Simply placing \\$(PWD) in the interproscan input flag led to the program navigating to its directory. To fix this, the input and output files were set to “\\${NEXTFLOW_CWD}/\\${OUT_DIR}/tmp.fasta” and “\\${NEXTFLOW_CWD}/\\${OUT_DIR}/interproscan_output.gff”, respectively. 

**Challenge 3: Singularity Directory Creation Restrictions** 

&nbsp;&nbsp;&nbsp;&nbsp;Singularity does not allow the directory creation inside its images once they are running. However, interproscan requires the ability to create a temporary directory to function. 

&nbsp;&nbsp;&nbsp;&nbsp;To fix this problem, a temporary directory was set in the NLRtracker.sh file as IPR_TEMP_DIR=”\\${NEXTFLOW_CWD}/tmp_ipr_scratch”. This directory was then made using “mkdir -p “IPR_TEMP_DIR”. The –tempdir flag was added to the interproscan command to direct interproscan to the temporary directory. 

**Challenge 4: Interproscan CPU Limit**

&nbsp;&nbsp;&nbsp;&nbsp;A final problem with interproscan resulted from a CPU limit on the dependency. This problem resulted in interproscan’s calculation reaching 83% completion and then failing without throwing an error flag. 

&nbsp;&nbsp;&nbsp;&nbsp;To solve this, it was necessary to run the container, navigate to interproscan’s directory and open interproscan’s configuration file (interproscan.properties). Once there, the default CPU for interproscan was changed from 2 to 16 by changing worker.number.of.embedded.workers and worker.maxnumber.of.embedded.workers to equal 16. This was later similarly addressed in the local configuration. 

&nbsp;&nbsp;&nbsp;&nbsp;Once these changes were made, the pipeline successfully ran on the HPC.
