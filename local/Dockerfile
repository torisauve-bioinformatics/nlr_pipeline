FROM ubuntu:20.04

LABEL description="Docker image for the NLRtracker pipeline and its dependencies."

# Set environment variables for non-interactive installations and define key paths
ENV DEBIAN_FRONTEND=noninteractive
ENV JAVA_HOME="/usr/lib/jvm/java-11-openjdk-amd64"
ENV PATH="${JAVA_HOME}/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

# --- Install System Dependencies and Core Tools ---
RUN apt-get update --fix-missing && \
    apt-get install -y --no-install-recommends \
    git \
    libexpat1-dev \
    autoconf \
    automake \
    make \
    perl \
    python3 \
    libtool \
    gcc \
    g++ \
    wget \
    ghostscript \
    curl \
    openjdk-11-jdk \    
    bzip2 \
    build-essential \
    zlib1g-dev \
    libgd-dev \
    libxml-parser-perl \
    libxml-simple-perl \
    libjson-perl \
    libhtml-template-perl \
    ca-certificates && \
    update-ca-certificates && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*



# --- Install MEME Suite v5.2.0 (for FIMO) ---
WORKDIR /usr/local/src

RUN wget http://meme-suite.org/meme-software/5.2.0/meme-5.2.0.tar.gz && \
    tar -zxf meme-5.2.0.tar.gz && \
    cd meme-5.2.0 && \
    ./configure --prefix=/usr/local/meme-5.2.0 --enable-build-libxml2 --enable-build-libxslt && \
    make && \
    make install && \
    rm -rf /usr/local/src/meme-5.2.0 meme-5.2.0.tar.gz

# Add FIMO's binary directory to PATH
ENV PATH="${PATH}:/usr/local/meme-5.2.0/bin:/usr/local/meme-5.2.0/libexec/meme-5.2.0"



# Install miniconda and create env for R packages 

WORKDIR /opt

RUN curl -LO "https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh" && \
    bash Miniconda3-latest-Linux-x86_64.sh -b -p /opt/conda && \
    rm Miniconda3-latest-Linux-x86_64.sh && \
    /opt/conda/bin/conda init && \
    /opt/conda/bin/conda clean -afy    

ENV PATH="/opt/conda/bin:${PATH}"

# Initialize Conda for bash shell, ensuring `conda activate` works.

COPY environment.yml .
RUN conda tos accept --override-channels --channel https://repo.anaconda.com/pkgs/main && \
    conda tos accept --override-channels --channel https://repo.anaconda.com/pkgs/r && \
    conda env create -f environment.yml -n nlrtracker


# --- Install InterProScan 5-44.0 ---

WORKDIR /usr/local/src
ENV INTERPROSCAN_VERSION="5.53-87.0"
ENV INTERPROSCAN_DIR="/opt/interproscan-${INTERPROSCAN_VERSION}"

RUN mkdir -p ${INTERPROSCAN_DIR} && \
    wget ftp://ftp.ebi.ac.uk/pub/software/unix/iprscan/5/5.53-87.0/interproscan-5.53-87.0-64-bit.tar.gz && \
    tar -xzf interproscan-5.53-87.0-64-bit.tar.gz -C ${INTERPROSCAN_DIR} --strip-components=1 && \
    rm interproscan-${INTERPROSCAN_VERSION}-64-bit.tar.gz


RUN sed -i '2a\cd "$(dirname "$0")" || { echo "Error: Could not change directory to $(dirname "$0")"; exit 1; }' \
    ${INTERPROSCAN_DIR}/interproscan.sh

# Make interproscan.sh executable and add its directory to PATH

RUN chmod +x ${INTERPROSCAN_DIR}/interproscan.sh && \
    interproscan.sh --version

# --- Clone the NLRtracker pipeline ---
WORKDIR /opt
ENV NLRTRACKER_REPO_NAME="NLRtracker" 
RUN git clone https://github.com/slt666666/NLRtracker "/opt/${NLRTRACKER_REPO_NAME}" 

# Set the working directory to where NLRtracker.sh resides
WORKDIR "/opt/${NLRTRACKER_REPO_NAME}"

ENV PATH="/opt/interproscan-5.53-87.0:/usr/local/meme-5.2.0/bin:/usr/local/meme-5.2.0/libexec/meme-5.2.0:${PATH}"
# --- Final Configuration ---
CMD ["/bin/bash"]


