import os
import pandas as pd

##################################################
# SHELL
##################################################
# default executable for snakmake
shell.executable("bash")

##################################################
# PATHS
##################################################
# default configuration file
configfile:
    srcdir("config/config.proteomics.yaml")

# relevant paths
BINDIR      = srcdir("workflow/bin")
ENVDIR      = srcdir("workflow/envs")
CONFIGDIR   = srcdir("config")
RESOURCEDIR = srcdir("resources")
WORKDIR     = os.environ.get("WORKDIR", config['workdir'])
OUTPUTDIR   = os.environ.get("OUTPUTDIR", config['outputdir'])
TMPDIR      = os.environ.get("TMPDIR", config['tmp_dir'])

# parameters
FIRST_NAME  = os.environ.get("FIRST_NAME", config["raws"]["first_name"])
LAST_NAME   = os.environ.get("LAST_NAME", config["raws"]["last_name"])
EMAIL       = os.environ.get("EMAIL", config["raws"]["email"])
ADDRESS     = os.environ.get("ADDRESS", config["raws"]["address"])
ORG_NAME    = os.environ.get("ORG_NAME", config["raws"]["org_name"])
ORG_EMAIL   = os.environ.get("ORG_EMAIL", config["raws"]["org_email"])
ORG_ADDRESS = os.environ.get("ORG_ADDRESS", config["raws"]["org_address"])
THERMOFOLD  = os.environ.get("THERMOFOLD", config["raws"]["ThermoFold"])
CONTIG_INFO_FILE_DIR = os.path.join(OUTPUTDIR,"assemblies")
PROCESSED_REPORTS_DIR = os.path.join(OUTPUTDIR,"Processed_Peptide_Reports")

##################################################
# WORKDIR
##################################################
workdir:
    WORKDIR

CONFIGDIR = 'config'
SAMPLEINFO_FILE = os.path.join(CONFIGDIR, "sample_info.csv")
SAMPLEINFO_FILE_FINAL = os.path.join(CONTIG_INFO_FILE_DIR, "sample_info_final.csv")
sample_info_final=pd.read_csv(SAMPLEINFO_FILE_FINAL, sep=',')
sample_info     = pd.read_csv(SAMPLEINFO_FILE, sep=',')
Samples         = sample_info['Sample'].drop_duplicates().to_list()

# split the sample info file into two parts: proteomic raw files and genomic databases
sample_raw = sample_info[['Sample','Raw file']].drop_duplicates()
sample_raw[['filename','extension']] = sample_raw['Raw file'].str.split('.',expand=True)
RawFiles        = (sample_raw['Sample']+'/'+sample_raw['filename']).to_list()

# sample_info['Raw file URLs'].to_csv("config/rawurls.txt", index=False, header=False)
# RawURLs         = os.path.join("","config/rawurls.txt")
Proteins        = sample_info['Db_name'].drop_duplicates().to_list()
HUMAN_FASTA = os.path.join(RESOURCEDIR, "human_db.fa")
CRAP_FASTA = os.path.join(RESOURCEDIR, "crap_db.fa")
I_PROTEINS = [os.path.splitext(os.path.basename(f))[0] for f in Proteins]
Assemblies      =sample_info_final['Assembly'].to_list()

#input files
STUDY = os.environ.get("STUDY", config["raws"]["Study"])
PRIDE_ID = os.environ.get("PRIDE_ID", config["raws"]["Pride_id"])
VERSION = os.environ.get("VERSION", config["raws"]["Version"])
DB_SIZE = os.environ.get("DB_SIZE", config["raws"]["Db_size"])
# I_PROTEINS = os.environ.get("PROTEINS", config["raws"]["Proteins"])
# I_PROTEINS = sample_info['Db_name'].drop_duplicates().to_list()
# I_THERMORAW = os.environ.get("THERMORAW", config["raws"]["ThermoRaw"])
# I_THERMORAW = sample_info['Raw file'].to_list()


# data
OUTPUT_FILE = expand("assemblies/{aname}_contig_info.txt", aname=Assemblies)
PROTEIN_FILE = expand("assemblies/{aname}.faa.gz", aname=Assemblies)
# THERMORAW_NAMES = [os.path.splitext(os.path.basename(f))[0] for f in I_THERMORAW]
# THERMORAW_NAMES = [os.path.splitext(os.path.basename(f))[0] for f in I_THERMORAW]
THERMORAW = expand("{iname}/{bname}.raw", iname=THERMOFOLD, bname=RawFiles)
# THERMOMGF = expand("{fname}/{bname}.mzML", fname=THERMOFOLD, bname=THERMORAW_NAMES)
THERMOMGF = expand("{iname}/{bname}.mzML", iname=THERMOFOLD, bname=RawFiles)

METADATA_FILE=expand("{iname}_info.tsv",iname=STUDY)
DATABASE_FILE=expand("assemblies/databases/unique_{iname}_cluster_set_1.fasta",iname=STUDY)
# DATABASE_FILE = dynamic(expand("assemblies/databases/unique_{iname}_cluster_set_{{PART}}.faa", iname=STUDY))
# PROTEINS_PROC  = expand("assemblies/databases/{pname}.fasta", pname=Proteins)
PROTEINS_DECOY = expand("assemblies/databases/{pname}_concatenated_target_decoy.fasta", pname=I_PROTEINS)
# PROTEINS_DECOY = expand("assemblies/databases/unique_{iname}_cluster_set_{{PART}}_concatenated_target_decoy.fasta", iname=STUDY)

SEARCHGUI_PAR  = expand("searchgui/{fname}_searchgui.par", fname=PRIDE_ID)
SEARCHGUI_ZIP  = expand("searchgui/{fname}_searchgui.zip", fname=Samples)
PEPTIDESHAKER_MZID = expand("peptideshaker/{fname}_peptideshaker.mzid", fname=Samples)
FINAL_MZID = expand("{fname}/{fname}_final.mzid", fname=THERMOFOLD)
# PSM_TMP_RPT = expand("{fname}/peptideshaker_peptideshaker_1_Default_PSM_Report.txt", fname=THERMOFOLD)
PROTEIN_TMP_RPT = expand("{fname}/peptideshaker_peptideshaker_1_Default_Protein_Report.txt", fname=THERMOFOLD)
PEPTIDE_TMP_RPT = expand("{fname}/peptideshaker_peptideshaker_1_Default_Peptide_Report.txt", fname=THERMOFOLD)
# PSM_RPT = expand("{fname}/{fname}_psm_report.txt", fname=THERMOFOLD)
RPT_NAMES = [os.path.splitext(os.path.basename(f))[0] for f in Samples]
PROTEIN_RPT = expand("results/reports/proteins/{fname}_protein_report.txt", fname=RPT_NAMES)
PEPTIDE_RPT = expand("results/reports/peptides/{fname}_peptide_report.txt", fname=RPT_NAMES)
PROCESSED_RPT = expand("results/reports/processed/processed_{fname}_peptide_report.txt", fname=RPT_NAMES)

ASSEMBLY_NAMES=os.path.join("","assembly_names.txt")
METAP_SAMPLE_INFO = os.path.join(PROCESSED_REPORTS_DIR,"sample_info.csv")
ASSEMBLY_NAME=[line.strip() for line in open(ASSEMBLY_NAMES).readlines()]
GFF_FILE = expand("PROCESSED_REPORTS_DIR/results/{aname}.gff",aname=Assemblies)

# output folders
SEARCHGUI_OUTPUT = os.environ.get("SEARCHGUI_OUTPUT", config["output"]["searchgui_folder"])
PEPTIDERSHAKER_OUTPUT = os.environ.get("PEPTIDERSHAKER_OUTPUT", config["output"]["peptidershaker_folder"])

# tools
THERMO_EXE = os.path.join(BINDIR, "ThermoRawFileParser/ThermoRawFileParser.exe")
SEARCHGUI_JAR = os.path.join(BINDIR, "SearchGUI-4.0.41/SearchGUI-4.0.41.jar")
SEARCHGUI_PAR_PARAMS = " ".join(["-%s %s" % (k, "'%s'" % v if isinstance(v, str) else str(v)) for k, v in config["searchgui"]["par"].items()])
PEPTIDESHAKER_JAR = os.path.join(BINDIR, "PeptideShaker-2.0.33/PeptideShaker-2.0.33.jar")

PYTHON_SPT = os.path.join("","assembly_metadata.py")
PYTHON_SPT1 = os.path.join('metagenomics_db',"main.py")
PYTHON_SPT2 = os.path.join('gff_generation',"main.py")

##################################################
# RULES
# Each subsequent output file needs to have its target path specified at the beginning.
##################################################
rule ALL:
    input:
        # dynamic(expand("assemblies/databases/unique_{iname}_cluster_set_{{PART}}.faa", iname=STUDY)),
        # database=[DATABASE_FILE, OUTPUT_FILE, PROTEIN_FILE],
        # thermo=[THERMORAW, THERMOMGF],
        # searchgui=[PROTEINS_DECOY, SEARCHGUI_PAR, SEARCHGUI_ZIP]
        report=[PROTEIN_RPT, PEPTIDE_RPT],
        peptideshaker=PEPTIDESHAKER_MZID
        # assembly_list=ASSEMBLY_NAMES,
        # processed=PROCESSED_RPT
        # gff_files=GFF_FILE



#########################
# Generate protein search database
#########################
rule generate_db:
    input:
        # script=PYTHON_SPT1,
        sample_metadata=SAMPLEINFO_FILE
    output:
        # db_file=DATABASE_FILE,
        contigs_dir=OUTPUT_FILE,
        protein_file=PROTEIN_FILE
    params:
        study=STUDY,
        ver=VERSION,
        input_dir=OUTPUTDIR,
        db_size=DB_SIZE
    log:
        expand("logs/{iname}_db_generate.log", iname=STUDY)
    threads: 1
    message:
        "DB_generate: {input.sample_metadata} -> {output.db_file}"
    shell:
        "python metagenomics_db/main.py -s {params.study} -v {params.ver} -i {params.input_dir} -m {input.sample_metadata} -b {params.db_size} &> {log}"


#########################
# ThermoRawFileParser
#########################
# https://github.com/compomics/ThermoRawFileParser
# rule fetch_raw_files:
#     input:
#         RawURLs
#     output:
#         THERMORAW
#     log:
#         expand("logs/{fname}_fetch_raw_files.log",fname=PRIDE_ID)
#     shell:
#         "wget -P input/Raw -i {input}"


rule thermorawfileparser:
    input:
        exe=THERMO_EXE,
        info=SAMPLEINFO_FILE
    output:
        raw=THERMORAW,
        mgf=THERMOMGF
    params:
        folder=THERMOFOLD
    # log:
        # expand("logs/{fname}_thermorawfileparser.log",fname=PRIDE_ID)
    threads: 1
    message:
        "ThermoRawFileParser: {input.info} -> {output.mgf}"
    shell:
        "python coping_raw_files.py -exe {input.exe} -info {input.info} -out {params.folder}"
    # shell:
    #     "mono {input.exe} -d=$(dirname {input.raws[0]}) -o=$(dirname {output[0]}) -f=1 -m=0 &> {log}"


#########################
# SearchGUI
#########################
rule searchgui_decoy:
    input:
        faa=DATABASE_FILE,
        human_db=HUMAN_FASTA,
        crap_db=CRAP_FASTA,
        jar=SEARCHGUI_JAR
    output:
        PROTEINS_DECOY
    log:
        expand("logs/{fname}_SearchGUI_decoy.log",fname=PRIDE_ID)
    params:
        tmpdir = TMPDIR,
        logdir = "logs/SearchGUI_decoy"
    threads: 1
    conda:
        os.path.join(ENVDIR, "IMP_proteomics.yaml")
    message:
        "SearchGUI decoy: {input.faa} -> {output}"
    # run:
    #     for protein in input.faa:
    #         shell("java -cp {input.jar} eu.isas.searchgui.cmd.FastaCLI -in {protein} -decoy -temp_folder {params.tmpdir} -log {params.logdir} &> {log}")
    shell:
        "for protein in {input.faa}; do cat {input.human_db} {input.crap_db} >> $protein; "
        "java -cp {input.jar} eu.isas.searchgui.cmd.FastaCLI -in $protein "
        "-decoy -temp_folder {params.tmpdir} -log {params.logdir} &> {log}; done "


rule searchgui_config:
    input:
        jar=SEARCHGUI_JAR
    output:
        SEARCHGUI_PAR
    log:
        expand("logs/{fname}_SearchGUI_params.log",fname=THERMOFOLD)
    params:
        params = SEARCHGUI_PAR_PARAMS,
        tmpdir = TMPDIR,
        logdir = "logs/SearchGUI_params"
    threads: 1
    conda:
        os.path.join(ENVDIR, "IMP_proteomics.yaml")
    message:
        "SearchGUI parameters: {input} -> {output}"
    shell:
        "java -cp {input.jar} eu.isas.searchgui.cmd.IdentificationParametersCLI -out {output} "
        "{params.params} -temp_folder {params.tmpdir} -log {params.logdir} &> {log}"


rule searchgui_search:
    input:
        par=SEARCHGUI_PAR,
        # faa=PROTEINS_DECOY,
        # mgf=THERMOMGF,
        jar=SEARCHGUI_JAR,
        info=SAMPLEINFO_FILE
    output:
        SEARCHGUI_ZIP
    # log:
        # expand("logs/{fname}_SearchGUI_search.log",fname=PRIDE_ID)
    params:
        # name=expand("{fname}_searchgui", fname=PRIDE_ID),
        # tmpdir = TMPDIR,
        logdir = "logs/SearchGUI_search"
    threads: 10
    conda:
        os.path.join(ENVDIR, "IMP_proteomics.yaml")
    message:
        "SearchGUI search: {input.par} -> {output}"
    shell:
        "python searchgui_search.py -s -jar {input.jar} -in {input.info} "
        "-out $(dirname {output[0]}) -par {input.par}"
    # shell:
    #     """
    #     java -cp {input.jar} eu.isas.searchgui.cmd.SearchCLI \
    #         -spectrum_files $(dirname {input.mgf[0]}) \
    #         -fasta_file {input.faa} \
    #         -output_folder $(dirname {output}) \
    #         -id_params {input.par} \
    #         -xtandem 1 \
    #         -msgf 1 \
    #         -comet 0 \
    #         -andromeda 0 \
    #         -threads {threads} \
    #         -output_default_name {params.name} \
    #         -output_option 0 \
    #         -output_data 1 \
    #         -output_date 0 \
    #         -log {params.logdir} \
    #         &> {log} && touch {output}
    #     """


#########################
# PeptideShaker
#########################
# http://compomics.github.io/projects/peptide-shaker
rule peptideshaker_load:
    input:
        # searchgui=SEARCHGUI_ZIP,
        jar=PEPTIDESHAKER_JAR,
        info=SAMPLEINFO_FILE
    output:
        protein=PROTEIN_RPT,
        peptide=PEPTIDE_RPT,
        mzid=PEPTIDESHAKER_MZID
    params:
        outputdir=PEPTIDERSHAKER_OUTPUT,
        fn=FIRST_NAME,
        ln=LAST_NAME,
        ce=EMAIL,
        ca=ADDRESS,
        on=ORG_NAME,
        oe=ORG_EMAIL,
        oa=ORG_ADDRESS
    log:
        expand("logs/{fname}_PeptideShaker_load.log",fname=Samples)
    threads: 10
    conda:
        os.path.join(ENVDIR, "IMP_proteomics.yaml")
    message:
        "PeptideShaker load SearchGUI results: {input.info} -> {output.mzid}, {output.protein}, {output.peptide}"
    shell:
        "python searchgui_search.py -p -jar {input.jar} -in {input.info} "
        "-out {params.outputdir} -fn {params.fn} -ln {params.ln} -ce {params.ce} -ca {params.ca} "
        "-on {params.on} -oe {params.oe} -oa {params.oa}"
    # shell:
    #     "for search in {input.searchgui}; do java -cp {input.jar} eu.isas.peptideshaker.cmd.PeptideShakerCLI "
    #     "-reference 'peptideshaker_peptideshaker_1' "
    #     "-identification_files $search "
    #     "-out_reports $(dirname {output.protein[0]}) -reports 6,9 "
    #     "-report_prefix $(cut -d'_' -f1 <<<${search##*/}) "
    #     "-output_file {output.mzid[0]} -contact_first_name 'Shengbo' -contact_last_name 'Wang' "
    #     "-contact_email 'shengbo_wang@ebi.ac.uk' -contact_address 'EBI' -organization_name 'EBI' "
    #     "-organization_email 'test@ebi.ac.uk' -organization_address 'Cambridge'; "
    #     "-threads {threads} &> {log}; done"


#########################
# generate a list of assembly names from sample_info fil
#########################
rule assembly_list:
    input:
        info_file=METADATA_FILE
    output:
        ASSEMBLY_NAMES="assembly_names.txt"
    run:
        import pandas as pd
        df = pd.read_csv(input.info_file)
        assembly_list=list(set(input.info_file['analysis_accession'].to_list()))
        with open(output.ASSEMBLY_NAMES, 'w') as f_in:
                for item in assembly_list:
                        f_in.write(item +'\n')


#########################
# Gff format file
#########################
rule gff_format_file:
    input:
        script=PYTHON_SPT2,
        metap_sample_info=METAP_SAMPLE_INFO,
        reports_dir=PROCESSED_REPORTS_DIR,
        metag_dir=CONTIG_INFO_FILE
    output:
        GFF_FILE
    params:
        pride_id=PRIDE_ID
    log:
        expand("logs/{aname}_gff_generate.log", aname=ASSEMBLY_NAME)
    threads: 1
    message:
        "Generating GFF format file: {input.metap_sample_info} -> {output}"
    shell:
        "python {input.script} -s {input.metap_sample_info} -r {input.reports_dir} "
        "-m {input.metag_dir} -p {params.pride_id} &> {log}"


########################
# Generate post processing reports
########################
rule post_processing:
    input:
        SAMPLEINFO_FILE
    output:
        PROCESSED_RPT
    params:
        PRIDE_ID
    log:
        expand("logs/{fname}_post_processing.log", fname=PRIDE_ID)
    threads: 1
    message:
        "Post-processing: {input} -> {output}"
    shell:
        "python post_report_generation/main.py -s {input} -p {params} &> {log}"
