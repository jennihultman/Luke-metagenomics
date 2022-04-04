# Practicals

Instruction copied and/or modified from Microbial bioinformatics courses held at MBDP Doctoral program by Jenni Hultman, Antti Karkman and Igor S. Pessi in 2017-2022.

__Table of Contents:__
1. [Setting up](#setting-up-the-course-folders)
2. [Interactive use of Puhti](#interactive-use-of-puhti)
3. [QC and trimming for Illumina reads](#qc-and-trimming-for-illumina-reads)
4. 



## Setting up the course folders
The main course directory is located in `/scratch/project_2005827`.  
There you will set up your own directory where you will perform all the tasks for this course.  

First list all projects you're affiliated with in CSC.
```
csc-workspaces
```

You should see the course project `LUKE_MG`.
So let's create a folder for you inside the scratch folder, you can find the path in the output from the previous command.

```bash
cd /scratch/project_2005827
mkdir $USER
```

Check with `ls`; which folder did `mkdir $USER` create?

This directory (`/scratch/project_2005827/your-user-name`) is your working directory.  
Every time you log into Puhti, you should use `cd` to navigate to this directory, and **all the scripts are to be run in this folder**.  

The raw data used on this course can be found in `/scratch/project_2005827/COURSE_FILES/RAW_DATA`.  
Instead of copying the data we will use links to this folder in all of the needed tasks.  
Why don't we want 14 students copying data to their own folders?


## Interactive use of Puhti

Puhti uses a scheduling system called SLURM. Most jobs are sent to the queue,  but smaller jobs can be run interactively.

Interactive session is launched with `sinteractive`   .   
You can specify the resources you need for you interactive work interactively with `sinteractive -i`. Or you can give them as options to `sinteractive`.  
You always need to specify the accounting project (`-A`, `--account`). Otherwise for small jobs you can use the default resources (see below).

| Option | Function | Default | Max |  
| --     | --       | --      | --  |  
| -i, --interactive | Set resources interactively |  |  |  
| -t,  --time | Reservation in minutes or in format d-hh:mm:ss | 24:00:00 | 7-00:00:00 |
| -m, --mem | Memory in Mb       | 2000     | 76000  |  
| -j, --jobname |Job name       | interactive     |   |  
| -c, --cores     | Number of cores       | 1      | 8  |  
| -A, --account     | Accounting project       |       |  |  
| -d, --tmp     | $TMPDIR size (in GiB)      |  32     | 760  |  
| -g, --gpu     | Number of GPUs       | 0     | 0 |  


[__Read more about interactive use of Puhti.__](https://docs.csc.fi/computing/running/interactive-usage/#sinteractive-in-puhti)   


## QC and trimming for Illumina reads

QC does not require lot of memory and can be run on the interactive nodes using `sinteractive`.

Activate the biokit environment and open interactive node:

```bash
sinteractive -A project_2005827
module load biokit
```

Run `fastQC` to the files stored in the RAWDATA folder. What does the `-o` and `-t` flags refer to? What do you need to do before running the task?

```bash
fastqc /scratch/project_2005827/COURSE_FILES/RAW_DATA/Sample04_NOVASEQ* -o FASTQC/ -t 2
```

Running the QC step on all sequence files would take too long, so they are already done and you can just copy them.
Make sure you're on your own folder before copying.

```bash
cd /scratch/project_2005827/$USER
cp -r /scratch/project_2005827/COURSE_FILES/FASTQC_RAW ./
```

Then combine the reports in FASTQC folder with multiQC:

```bash
module load multiqc
multiqc FASTQC_RAW/* -o FASTQC_RAW --interactive
```

To leave the interactive node, type `exit`.  

Copy the resulting HTML file to your local machine with `scp` from the command line (Mac/Linux) or *WinSCP* on Windows.  
Have a look at the QC report with your favourite browser.  

After inspecting the output, it should be clear that we need to do some trimming.  
__What kind of trimming do you think should be done?__

### Running Cutadapt


The adapter sequences that you want to trim are located after `-a` and `-A`.  
What is the difference with `-a` and `-A`?  
And what is specified with option `-p` or `-o`?
And how about `-m` and `-j`?  
You can find the answers from Cutadapt [manual](http://cutadapt.readthedocs.io).

Before running the script, we need to create the directory where the trimmed data will be written:

```bash
mkdir TRIMMED
```

```
#!/bin/bash
#SBATCH --job-name CUTADAPT
#SBATCH --error CUTADAPT_%A_%a_err.txt
#SBATCH --output CUTADAPT_%A_%a_out.txt
#SBATCH --partition small
#SBATCH --nodes 1
#SBATCH --ntasks 1
#SBATCH --cpus-per-task 4
#SBATCH --mem 4G
#SBATCH --time 4:00:00
#SBATCH --account project_2005827
#SBATCH --array 1-4

SAMPLE=Sample0${SLURM_ARRAY_TASK_ID}

module load biokit

cutadapt ../COURSE_FILES/RAW_DATA/$SAMPLE_NOVASEQ.R1.fastq.gz \
         ../COURSE_FILES/RAW_DATA/$SAMPLE_NOVASEQ.R2.fastq.gz \
         -o TRIMMED/$SAMPLE.NOVASEQ.R1.fastq.gz \
         -p TRIMMED/$SAMPLE.NOVASEQ.R2.fastq.gz \
         -a CTGTCTCTTATACACATCTCCGAGCCCACGAGAC \
         -A CTGTCTCTTATACACATCTGACGCTGCCGACGA \
         -m 50 \
         -j 4 \
         --nextseq-trim 20 > TRIMMED/$SAMPLE.cutadapt.log.txt
CUTADAPT.sh (END)
```


### Running fastQC on the trimmed reads
You could now check the `cutadapt.log` and answer:

* How many read pairs we had originally?
* How many reads contained adapters?
* How many read pairs were removed because they were too short?
* How many base calls were quality-trimmed?
* Overall, what is the percentage of base pairs that were kept?

Then make a new folder (`FASTQC`) for the QC files of the trimmed data and run fastQC and multiQC again as you did before trimming:

```bash
mkdir fastqc_out_trimmed
fastqc trimmed/*.fastq -o fastqc_out_trimmed/ -t 1
```



Copy the resulting HTML file to your local machine as earlier and look how well the trimming went.  
Did you find problems with the sequences?


## Read based analyses
For the read-based analyses, we will use `seqtk`, `DIAMOND`, `MEGAN` and `METAXA`.  
Like before, the script is provided and can be found in the scripts folder (`/scratch/project_2005827/COURSE_FILES/SBATCH_SCRIPTS/READ_BASED.sh`).  
Let's copy the script to your working directory and take a look using `less`.

Since the four samples have been sequenced really deep, we will utilize only a subset of the reads for the read-based analysis.  
The subsampled 2,000,000 sequences represent the total community for this analysis.  
The tool `seqtk` will be used for this.  

We will annotate short reads with `MEGAN` (https://uni-tuebingen.de/fakultaeten/mathematisch-naturwissenschaftliche-fakultaet/fachbereiche/informatik/lehrstuehle/algorithms-in-bioinformatics/software/megan6/) and `METAXA` (https://microbiology.se/software/metaxa2/).  
`MEGAN` uses a tool called `DIAMOND` which is 20,000 times faster than `blast` to annotate reads against the database of interest.  
Here we will use the NCBI nr database which has been formatted for `DIAMOND`.   
Then we will use `MEGAN` to parse the annotations and get taxonomic and functional assignments.  

In addition to `MEGAN`, we will also use another approach (`METAXA`) to get taxonomic profiles.  
`METAXA` runs in two steps: the first command finds rRNA genes among our reads using HMM models and then annotates them using `BLAST` and a reference database.  

All these steps will take a while to run and therefore we will submit the scripts today to have the results ready for tomorrow.  
First, you will need to create the following folders to store the output from the script: `RESAMPLED`, `MEGAN` and `METAXA`.  
Then sumbit the `READ_BASED.sh` script as you did for `Cutadapt` earlier today.  

### Taxonomic profiling with Metaxa2

The microbial community profiling for the samples can alsp be done using a 16S/18S rRNA gene based classification software [Metaxa2](http://microbiology.se/software/metaxa2/).  
It identifies the 16S/18S rRNA genes from the short reads using HMM models and then annotates them using BLAST and a reference database.
We will run Metaxa2 as an array job in Puhti. More about array jobs at CSC [here](https://docs.csc.fi/computing/running/array-jobs/).  
Make a folder for Metaxa2 results and direct the results to that folder in your array job script. (Takes ~6 h for the largest files)

```
#!/bin/bash
#SBATCH --job-name METAXA
#SBATCH --error METAXA_%A_%a_err.txt
#SBATCH --output METAXA_%A_%a_out.txt
#SBATCH --partition small
#SBATCH --nodes 1
#SBATCH --ntasks 1
#SBATCH --cpus-per-task 20
#SBATCH --mem 100G
#SBATCH --time 1-00:00:00
#SBATCH --account project_2005827
#SBATCH --array 1-4

SAMPLE=Sample0${SLURM_ARRAY_TASK_ID}

# Metaxa uses HMMER3 and BLAST, so load the biokit first
module load biokit
source activate metaxa

seqtk sample -s100 TRIMMED/$SAMPLE_NOVASEQ.R1.fastq.gz 2000000 > RESAMPLED/$SAMPLE.R1.fastq
seqtk sample -s100 TRIMMED/$SAMPLE_NOVASEQ.R2.fastq.gz 2000000 > RESAMPLED/$SAMPLE.R2.fastq

# the variable is used in running metaxa2
metaxa2 -1 RESAMPLED/$SAMPLE.R1.fastq \
        -2 RESAMPLED/$SAMPLE.R2.fastq \
        -o METAXA/$SAMPLE \
        --align none \
        --graphical F \
        --cpu 20 \
        --plus &> METAXA/$SAMPLE.metaxa.log.txt
        
metaxa2_ttt -i METAXA/$SAMPLE.taxonomy.txt \
            -o METAXA/$SAMPLE &>> METAXA/$SAMPLE.metaxa.log.txt
          
```
When all Metaxa2 array jobs are done, we can combine the results to an OTU table. Different levels correspond to different taxonomic levels.  
When using any 16S rRNA based software, be cautious with species (and beyond) level classifications. Especially when using short reads.  
We will look at genus level classification.

# Genus level taxonomy

```bash

cd METAXA

metaxa2_dc -o metaxa_genus.txt *level_6.txt
```
### Functional profiling with EggNOG
