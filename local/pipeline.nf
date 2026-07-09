params.genome_file = null
params.proteome_file = null
params.outdir = './output'

process run_nlrtracker {
    

    input:
    path prot_ch
    
   
    output:
    path "nlrtracker_output/*", emit: results
    path "nlrtracker_output/Domains.tsv", emit: nlrtracker_output
    publishDir "${params.outdir}/nlrtracker_results", mode: 'copy'
   

    script:
    """ 

    source /opt/conda/etc/profile.d/conda.sh
    conda activate nlrtracker
    /opt/NLRtracker/NLRtracker.sh -s ${ref_ch} -o nlrtracker_output -c -c ${task.cpus} 
    """
}

process run_resistify {

    input:
    path prot_ch


    output:
    path "resistify_output/*", emit: results
    path "resistify_output/domains.tsv", emit: resistify_output
    publishDir "${params.outdir}/resistify_results", mode: 'copy'


    script:
    """
    
    source /opt/conda/etc/profile.d/conda.sh
    conda activate resistify
    resistify nlr ${ref_ch} -o resistify_output 
    """
}

process run_annotator {
    
    publishDir "${params.outdir}/nlrannotator_results", mode: 'copy'

    input:
    path ref_ch
    
   
    output:
    path "nlrannotator_output/*", emit: results
    

    script:
    """
    mkdir -p nlrannotator_output
    java -jar /opt/NLR-Annotator/NLR-Annotator-v2.1b.jar \
    -i ${ref_ch} \
    -x /opt/NLR-Annotator/src/mot.txt \
    -y /opt/NLR-Annotator/src/store.txt -o nlrannotator_output/output.txt \
    -g nlrannotator_output/output.gff \
    -b nlrannotator_output/output.bed \
    """
}

workflow {

    gff_ch = Channel.fromPath(params.gff_file)

    ref_ch=Channel.fromPath(params.genome_file) 
       
    run_nlrtracker(prot_ch)
    run_resistify(prot_ch)
    run_annotator(ref_ch)
    
}
