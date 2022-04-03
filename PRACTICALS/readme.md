# Practicals

Instruction copied and/or modified from Microbial bioinformatics courses held at MBDP Doctoral program by Jenni Hultman, Antti Karkman and Igor S. Pessi in 2017-2022.

__Table of Contents:__
1. [Setting up](#setting-up-the-course-folders)
2. [Interactive use of Puhti](#interactive-use-of-puhti)
3. [QC and trimming for Illumina reads](#qc-and-trimming-for-illumina-reads)
4. 



## Setting up the course folders
The main course directory is located in `/scratch/project_200582`.  
There you will set up your own directory where you will perform all the tasks for this course.  

First list all projects you're affiliated with in CSC.
```
csc-workspaces
```

You should see the course project `LUKE_MG`.
So let's create a folder for you inside the scratch folder, you can find the path in the output from the previous command.

```bash
cd /scratch/project_200582
mkdir $USER
```

Check with `ls`; which folder did `mkdir $USER` create?

This directory (`/scratch/project_200582/your-user-name`) is your working directory.  
Every time you log into Puhti, you should use `cd` to navigate to this directory, and **all the scripts are to be run in this folder**.  

The raw data used on this course can be found in `/scratch/project_200582/COURSE_FILES/RAWDATA_ILLUMINA`.  
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
QC for the raw data takes few minutes, depending on the allocation.  
Go to your working directory and make a folder called e.g. `fastqc_raw` for the QC reports.  

QC does not require lot of memory and can be run on the interactive nodes using `sinteractive`.

Activate the biokit environment and open interactive node:

```bash
sinteractive -A project_200582
module load biokit
```

Now each group will work with their own sequences. Create the variables R1 and R2 to represent the path to your files. Do that just for the strain you will use:

```bash
#### Illumina Raw sequences for the cyanobacteria strain 328
R1=/scratch/project_2005827/COURSE_FILES/RAWDATA_ILLUMINA/A045-328-GGTCCATT-AGTAGGCT-Tania-Shishido-run20211223R_S45_L001_R1_001.fastq.gz
R2=/scratch/project_2005827/COURSE_FILES/RAWDATA_ILLUMINA/A045-328-GGTCCATT-AGTAGGCT-Tania-Shishido-run20211223R_S45_L001_R2_001.fastq.gz

#### Illumina Raw sequences for the cyanobacteria strain 327
R1=/scratch/project_2005827/COURSE_FILES/RAWDATA_ILLUMINA/A044-327-2-CTTGCCTC-GTTATCTC-Tania-Shishido-run20211223R_S44_L001_R1_001.fastq.gz
R2=/scratch/project_2005827/COURSE_FILES/RAWDATA_ILLUMINA/A044-327-2-CTTGCCTC-GTTATCTC-Tania-Shishido-run20211223R_S44_L001_R2_001.fastq.gz

#### Illumina Raw sequences for the cyanobacteria strain 193
R1=/scratch/project_2005827/COURSE_FILES/RAWDATA_ILLUMINA/Oscillatoriales-193_1.fastq.gz
R2=/scratch/project_2005827/COURSE_FILES/RAWDATA_ILLUMINA/Oscillatoriales-193_2.fastq.gz
```


You can check if your variable was set correctly by using:

```bash
echo $R1
echo $R2
```




### Running fastQC
Run `fastQC` to the files stored in the RAWDATA folder. What does the `-o` and `-t` flags refer to?

```bash
fastqc $R1 -o fastqc_raw/ -t 1

fastqc $R2 -o fastqc_raw/ -t 1
```



Copy the resulting HTML file to your local machine with `scp` from the command line (Mac/Linux) or *WinSCP* on Windows.  
Have a look at the QC report with your favourite browser.  

After inspecting the output, it should be clear that we need to do some trimming.  
__What kind of trimming do you think should be done?__

### Running Cutadapt


```bash
# To create a variable to your cyanobacterial strain:
strain=328
```

The adapter sequences that you want to trim are located after `-a` and `-A`.  
What is the difference with `-a` and `-A`?  
And what is specified with option `-p` or `-o`?
And how about `-m` and `-j`?  
You can find the answers from Cutadapt [manual](http://cutadapt.readthedocs.io).

Before running the script, we need to create the directory where the trimmed data will be written:

```bash
mkdir trimmed
```


```bash
cutadapt -a CTGTCTCTTATA -A CTGTCTCTTATA -o trimmed/"$strain"_cut_1.fastq -p trimmed/"$strain"_cut_2.fastq $R1 $R2 --minimum-length 80 > cutadapt.log

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
Like before, the script is provided and can be found in the scripts folder (`/scratch/project_2001499/COURSE_FILES/SBATCH_SCRIPTS/READ_BASED.sh`).  
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
We will run Metaxa2 as an array job in Taito. More about array jobs at CSC [here](https://research.csc.fi/taito-array-jobs).  
Make a folder for Metaxa2 results and direct the results to that folder in your array job script. (Takes ~6 h for the largest files)

```
#!/bin/bash -l
#SBATCH -J metaxa
#SBATCH -o metaxa_out_%A_%a.txt
#SBATCH -e metaxa_err_%A_%a.txt
#SBATCH -t 10:00:00
#SBATCH --mem=15000
#SBATCH --array=1-10
#SBATCH -n 1
#SBATCH --nodes=1
#SBATCH --cpus-per-task=6
#SBATCH -p serial

cd $WRKDIR/Metagenomics2019/Metaxa2
# Metaxa uses HMMER3 and BLAST, so load the biokit first
module load biokit
# each job will get one sample from the sample names file stored to a variable $name
name=$(sed -n "$SLURM_ARRAY_TASK_ID"p ../sample_names.txt)
# then the variable is used in running metaxa2
metaxa2 -1 ../trimmed_data/$name"_R1_trimmed.fastq" -2 ../trimmed_data/$name"_R2_trimmed.fastq" \
            -o $name --align none --graphical F --cpu $SLURM_CPUS_PER_TASK --plus
metaxa2_ttt -i $name".taxonomy.txt" -o $name
```

When all Metaxa2 array jobs are done, we can combine the results to an OTU table. Different levels correspond to different taxonomic levels.  
When using any 16S rRNA based software, be cautious with species (and beyond) level classifications. Especially when using short reads.  
We will look at genus level classification.
```
# Genus level taxonomy
cd Metaxa2
metaxa2_dc -o metaxa_genus.txt *level_6.txt
```
### Functional profiling with EggNOG
