params.genome_file="/Users/torisauve/Desktop/summer25/progress_report_test/UP000006548_3702.fasta"
params.outdir="/Users/torisauve/Desktop/summer25/progress_report_test/output"

process run_nlrtracker {

    input:
    path ref_ch
    
   
    output:
    path "nlrtracker_output/*", emit: results
    path "nlrtracker_output/nlrtracker.tsv", emit: nlrtracker_file
    publishDir "${params.outdir}", mode: 'copy'
   

    script:
    """
    source /opt/conda/etc/profile.d/conda.sh
    conda activate nlrtracker
    /opt/NLRtracker/NLRtracker.sh -s ${ref_ch} -o nlrtracker_output -c 4 
    """
}

process python_task_nlrtracker {
    
     input: 
     path nlrtracker_tsv_path

     output:
     path "nlrtracker_df.pkl", emit: nlr_dataframe
     

     publishDir "${params.outdir}/nlrtracker_analysis", mode: 'copy' 

     script: 
     """
     #!/usr/bin/env python
     import pandas as pd
     nlrtracker_df = pd.read_csv("$nlrtracker_tsv_path", sep='\\t')
            
      
     nlrtracker_df.to_pickle("nlrtracker_df.pkl")
            
     """
              
}

process run_resistify {

    input:
    path ref_ch


    output:
    path "resistify_output/motifs.tsv", emit: motifs_file

    publishDir "${params.outdir}", mode: 'copy'


    script:
    """
    source /opt/conda/etc/profile.d/conda.sh
    conda activate resistify
    resistify nlr ${ref_ch} -o resistify_output 
    """
}


process python_task_resistify {
     input:
     path motifs_tsv
        
     output:
     path "resistify_df.pkl", emit: resistify_dataframe

     publishDir "${params.outdir}/resistify_analysis", mode: 'copy'
    
     script:
     """
     #!/usr/bin/env python
    
     import pandas as pd
     resistify_df = pd.read_csv("$motifs_tsv", sep='\\t')
     resistify_df.to_pickle("resistify_df.pkl")
    
    
     """
    
     
}   


workflow {

    ref_ch=Channel.fromPath(params.genome_file) 
    
    run_nlrtracker(
        ref_ch )

    run_resistify(
        ref_ch )

    python_task_nlrtracker(
        run_nlrtracker.out.nlrtracker_file  )
    
    python_task_resistify(run_resistify.out.motifs_file
         )
}
