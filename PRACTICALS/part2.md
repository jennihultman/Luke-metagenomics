## Assembly
We will assemble all 4 samples indivially using the `MEGAHIT` [assembler](https://github.com/voutcn/megahit).  
In addition, we will use `MetaQUAST` to get some statistics about our assemblies.

`MEGAHIT` is an ultra-fast assembly tool for metagenomics data.  
It is installed to CSC and can be loaded with the following command:

```bash
module load biokit
```

Assembling metagenomic data can be very resource demanding and so we need to do it as a batch job.  
Copy the script called `assembly.sh` from the `COURSE_FILES` folder to your own directory and submit the batch job as previously.  
Then read the Megahit manual and answer what do the following flags mean?

```bash
--min-contig-len 1000
--k-min 27
--k-max 127
--k-step 10
--memory 0.8
--num-cpu-threads 16
```

However, as this is only a three-day course we cannot wait for your assemblies to finish, so let's terminate the running jobs.  
What was the command to view on-going batch jobs?  
You can terminate the sbatch job by typing:

```bash
scancel JOBID
```

Terminate your job and check that it is no longer in your list of jobs.  

## Assembly quality statistics
Let's take a look at the assemblies in a bit more detail with [MetaQUAST](http://bioinf.spbau.ru/metaquast).

Since the assembly would have taken too long to finish, I ran the assembly for you.
The assembly files can be pretty big as well, so you will make a softlink to the assembly folder to save some space.

```bash
cd /scratch/project_2005827/$USER
ln -s -f ../COURSE_FILES/ASSEMBLY_MEGAHIT/
```

What kind of files did you "copy"?  
Please take a look at the log files and answer these questions about the assembly:
* Which version of `MEGAHIT` did we actually use for the assemblies?
* How long did the assemblies take to finish?
* Which sample gave the longest contig?

Then we'll run assembly QC using `MetaQUAST`.
First have a look at the different options that you can specify.

```bash
module load biokit
metaquast.py -h
```

Open an interactive session for QC allocating __1 hour__, __10 Gb of memory__, __4 CPUs/threads__, and __10 Gb of temporary disk area__.  
Then when you're connected to the interactive node, run `MetaQUAST`.

```bash
sinteractive -i

module load biokit

metaquast.py ASSEMBLY_MEGAHIT/*/final.contigs.fa \
             -o METAQUAST_FAST \
             --threads 4 \
             --fast \
             --max-ref-number 0 &> metaquast.fast.log.txt
```

Copy the folder called `METAQUAST_FAST` to your computer.  
You can view the results (`report.html`) in your favorite browser.

Questions about the assembly QC:
* Which assembly has the longest contig when also long reads assemblies are included?
* Which assembly had the most contigs?
* Were the long read assemblies different from the corresponding short read assemblies?
* If yes, in what way?

## Genome-resolved metagenomics with anvi'o

`anvi'o` is an analysis and visualization platform for omics data.  
You can read more from their [webpage](https://anvio.org/).

![alt text](/Figure/Screen%20Shot%202017-12-07%20at%2013.50.20.png "Tom's fault")

First we need to open an interactive session inside a `screen` and then log in again with a tunnel using the computing node identifier.

Mini manual for `screen`:
* `screen -S NAME` - open a screen and give it a session name `NAME`
* `screen` - open new screen without specifying any name
* `screen -ls` - list all open sessions
* `ctrl + a` + `d` - to detach from a session (from inside the screen)
* `screen -r NAME` - re-attach to a detached session using the name
* `screen -rD` - re-attach to a attached session
* `exit` - close the screen and kill all processes running inside the screen (from inside the screen)

So after opening a new `screen`, connect to an interactive node with 4 cores and go to your course folder and make a new folder called `ANVIO`.  
All task on this section are to be done in this folder.

```bash
screen -S anvio
sinteractive -A project_2005827 -c 4 -m 20G

cd /scratch/project_2005827/$USER
mkdir ANVIO
cd ANVIO
```

We need to do some preparation for the contigs before we can use them in `anvi'o`.  
We will do this for one sample to demonstrate the workflow.  
For `anvi'o` you'll need to load `bioconda` and activate the anvio-7 virtual environment.  

```bash
module load bioconda/3
source activate anvio-7
```

### Rename the scaffolds and select those >2500nt.
`anvi'o` wants sequence IDs in your FASTA file as simple as possible.  
Therefore we need to reformat the headers to remove spaces and non-numeric characters.  
Also contigs shorter than 2500 bp will be removed.

```bash
anvi-script-reformat-fasta ../ASSEMBLY/final.contigs.fa \
                           -l 2500 \
                           --simplify-names \
                           --prefix Sample02 \
                           -r REPORT \
                           -o Sample02_2500nt.fa
````

Whenever you need, you can detach from the screen with `Ctrl+a` `d`.  
And re-attach with `screen -r anvio`.

### Generate CONTIGS.db
The contigs database (`Sample02_2500nt_CONTIGS.db`) contains information on contig length, open reading frames (searched with `Prodigal`) and kmer composition.  
See the [anvi'o webpage](http://merenlab.org/2016/06/22/anvio-tutorial-v2/#creating-an-anvio-contigs-database) for more information.  

```bash
anvi-gen-contigs-database --contigs-fasta Sample02_2500nt.fa \
                          --output-db-path Sample02_2500nt_CONTIGS.db \
                          -n Sample02_2500nt \
                          --num-threads 4
```

### Run HMMs to identify single-copy core genes for Bacteria, Archaea and Eukarya, plus rRNAs

First annotate the SCGs.
```bash
anvi-run-hmms --contigs-db Sample02_2500nt_CONTIGS.db --num-threads 4
```

And then run taxonomic annotation based on those
```bash
anvi-run-scg-taxonomy -c Sample02_2500nt_CONTIGS.db -T 4
```

After that's done, detach from the anvi'o screen with `Ctrl+a` `d`

### Mapping the reads back to the assembly
Next thing to do is mapping all the reads back to the assembly. We use the renamed >2500 nt contigs and do it sample-wise, so each sample is mapped separately using the trimmed R1 & R2 reads.  

However, since this would take some days, I have run this for you and the data can be found from `COURSE_DATA/MEGAHIT_BINNING/`
The folder contains the output from mapping all samples against all four assemblies. We will be using only the mappings against assembly from Sample02.
Let's make a softlink to that folder as well. Make sure you make the softlink to your `ANVIO` folder

```bash
ln -s ../../COURSE_FILES/BINNING_MEGAHIT/
```

Next we will build profiles for each sample that was mapped against the assembly. The mapping output from each sample is the `$SAMPLE.bam` file.  
Write an array script for the profiling and submit it to the queue.

__Don't__ do this from the screen and make sure your inside your `ANVIO` folder.

```
#!/bin/bash -l
#SBATCH --job-name array_profiling
#SBATCH --output array_profiling_out_%A_%a.txt
#SBATCH --error array_profiling_err_%A_%a.txt
#SBATCH --partition small
#SBATCH --time 00:20:00
#SBATCH --mem-per-cpu=500
#SBATCH --array=1-4
#SBATCH --nodes 1
#SBATCH --cpus-per-task=20
#SBATCH --account project_2005827

SAMPLE=Sample0${SLURM_ARRAY_TASK_ID}

export PROJAPPL=/projappl/project_2005827
module load bioconda/3
source activate anvio-7

anvi-profile --input-file BINNING_MEGAHIT/$SAMPLE.bam \
               --output-dir PROFILES/$SAMPLE \
               --contigs-db Sample02_2500nt_CONTIGS.db \
               --num-threads 20 &> $SAMPLE.profilesdb.log.txt
```

### Merging the profiles

When the profiling is done, you can merge them with this command.
Remember to re-attach to you screen and run the command in there.

```
anvi-merge PROFILES/*/PROFILE.db \
           --output-dir MERGED_PROFILES \
           --contigs-db Sample02_2500nt_CONTIGS.db \
           --enforce-hierarchical-clustering &> Sample02.merge.log.txt
```

### Tunneling the interactive interafce

Although you can install anvi'o on your own computer (and you're free to do so, but we won't have time to help in that), we will run anvi'o in Puhti and tunnel the interactive interface to your local computer.  
To be able to to do this, everyone needs to use a different port for tunneling and your port number will be given on the course.

Connecting using a tunnel is a bit tricky and involves several steps, so pay special attention.  
Detach from your screen and note on which login node you're on. Then re-attach and note the ID of the computing node your logged in. Then you will also need to remember your port number.

Then you can log out and log in again, but this time in a bit different way.  
You need to specify your `PORT` and the `NODEID` to which you connected and also the `NUMBER` of the login node you where your screen is running. *Also change your username in the command below.*

```bash
ssh -L PORT:NODEID.bullx:PORT USERNAME@puhti-loginNUMBER.csc.fi
```

And in windows using Putty:  
In SSH tab select "tunnels". Add:  
- Source port: PORT  
- Destination: NODEID.bullx:PORT  

Click add and connect to the right login node, login1 or login2.

Then go back to your screen and launch the interactive interface.  
Remember to change the `PORT`.

```
anvi-interactive -c Sample02_2500nt_CONTIGS.db -p MERGED_PROFILES/PROFILE.db -P PORT
```

Then open google chrome and go to address that anvi'o prints on the screen.  
Also this should work: http://localhost:PORT

**Again change XXXX to your port number**

When you're done, close the anvi'o server, close the interactive session, close the screen and log out from Puhti.  
And we're done for today.

### Tuesday

## Genome-resolved metagenomics 

Next step in our analysis is genome-resolved metagenomics using anvi'o. We ran all the steps to produce the files for anvi'o yesterday.


### Tunneling the interactive interafce (recap from yesterday)

Although you can install anvi'o on your own computer (and you're free to do so, but we won't have time to help in that), we will run anvi'o in Puhti and tunnel the interactive interface to your local computer.  
To be able to to do this, everyone needs to use a different port for tunneling and your port will be __8080 + your number given on the course__. So `Student 1` will use port 8081. If the port doesn't work, try __8100 + your number__.  

Connecting using a tunnel is a bit tricky and involves several steps, so pay special attention.  
First we need to open an interactive session inside a screen and then log in again with a tunnel using the computing node identifier.

Mini manual for `screen`:
* `screen -S NAME` - open a screen and give it a session name `NAME`
* `screen` - open new screen without specifying any name
* `screen -ls` - list all open sessions
* `ctrl + a` + `d` - to detach from a session (from inside the screen)
* `screen -r NAME` - re-attach to a detached session using the name
* `screen -rD` - re-attach to a attached session
* `exit` - close the screen and kill all processes running inside the screen (from inside the screen)

So open a normal connection to Puhti and go to your course folder. Take note which login node you were connected.   
Then open an interactive session and specify that you need 8 hours and 10 Gb of memory.  
Other options can stay as they are.  
Note the computing node identifier before logging out.

```bash
cd /scratch/project_2005827/$USER
# Take note whether you were connected to login1 or login2. Screens are login node specific.
screen -S anvio
sinteractive -A project_2005827 -c 4 -m 10G -t 08:00:00
# And after this change the time and memory allocations.
# When your connected to the computing node, check the identifier and detach from the screen
```

Then you can log out and log in again, but this time in a bit different way.  
You need to specify your __PORT__ and the __computing node__ to which you connected and also the __login node__ you were connected the first time.  

```bash
ssh -L PORT:NODEID.bullx:PORT USERNAME@puhti-loginX.csc.fi
```

And in windows using Putty:  
In SSH tab select "tunnels". Add:  
- Source port: PORT  
- Destination: NODEID.bullx:PORT

Click add and connect as usual, making sure you will be connected to the right login node.

Then we can start to work with our tutorial data in anvi'o.  
Activate anvi'o v.7 virtual environment and copy the folder containing the tutorial files to you own course folder.  
Go to the folder and see what it contains.

```bash
screen -r anvio
module load bioconda/3
source activate anvio7
cp -r ../COURSE_FILES/ANVI-TUTORIAL .
cd ANVI-TUTORIAL
ls -l
```
You should have there the `CONTIGS.db` and `PROFILE.db` plus an auxiliary data file called `AUXILIARY-DATA.db`.

First have a look at some basic statistics about the contigs database.  
*__NOTE!__ You need to specify your port.*

```bash
anvi-display-contigs-stats CONTIGS.db -P PORT
```
Now anvi'o tells you to the server address. It should contain your port number. Copy-paste the address to your favourite browser. Chrome is preferred.

One thing before starting the binning, let's check what genomes we might expect to find from our data based on the single-copy core genes (SCGs).

```bash
anvi-estimate-scg-taxonomy -c CONTIGS.db \
                           -p PROFILE.db \
                           --metagenome-mode \
                           --compute-scg-coverages

```

Then you can open the interactive interface and explore our data and the interface.  
*__NOTE!__ You need to specify your port in here as well.*

```bash
anvi-interactive -c CONTIGS.db -p PROFILE.db -P PORT
```

You might notice that it's a bit slow to use sometimes. Even this tutorial data is quite big and anvi'o gets slow to use when viewing the whole data. So next step is to split the data in to ~ 5-8 clusters (__bins__) that we will work on individually.

Make the clusters and store them in a collection called `PreCluster`. Make sure that the bins are named `Bin_1`, `Bin_2`,..., `Bin_N`. (or anything else that's easy to remember).  
Then you can close the server from the command line.

Next we'll move on to manually refine each cluster we made in the previous step. We'll do this to each bin in our collection called `PreCluster`.  

To check your collections and bins you can run `anvi-show-collections-and-bins -p PROFILE.db`

If you know what you have, go ahead and refine all the bins on your collection.
After refining, remember to store the new bins and then close the server from command line and move on to the next one.

```bash
anvi-refine -c CONTIGS.db -p PROFILE.db -C COLLECITON_NAME -b BIN_NAME -P PORT
```

After that's done, we'll rename the bins to a new collection called `PreliminaryBins` and add a prefix to each bin.

```bash
anvi-rename-bins -c CONTIGS.db -p PROFILE.db --collection-to-read PreCluster \
                  --collection-to-write PreliminaryBins --prefix Preliminary \
                  --report-file REPORT_PreliminaryBins
```
Then we can also make a summary of the bins we have in our new collection `PreliminaryBins`.

```bash
anvi-summarize -c CONTIGS.db -p PROFILE.db -C PreliminaryBins -o SUMMARY_PreliminaryBins
```
After that's done, copy the summary folder to your local machine ands open `index.html`.

From there you can find the summary of each of your bins. In the next step we'll further refine each bin that meets our criteria for a good bin but still has too much redundancy. In this case completeness > 80 % and redundancy > 10 %. So refine all bins that are more than 80 % complete and have more than 10 % redundancy.

When you're ready it's time to again rename the bins and run the summary on them.  
Name the new collection `Bins` and use prefix `Sample03`.

Now we should have a collection of pretty good bins out of our data. The last step is to curate each bin to make sure it represent only one population. And finally after that we can call MAGs from our collection. We will call MAGs all bins that are more than 80 % complete and have less than 5 % redundancy.  

```bash
anvi-rename-bins -c CONTIGS.db -p PROFILE.db --collection-to-read Bins \
                  --collection-to-write MAGs --prefix Sample03 --report-file REPORT_MAGs \
                  --call-MAGs --min-completion-for-MAG 80 --max-redundancy-for-MAG 5
```

And finally you can make a summary of your MAGs before moving on.

```bash
anvi-summarize -c CONTIGS.db -p PROFILE.db -C MAGs -o SUMMARY_MAGs
```

Then it's finally time to start working with the full data set from Sample03.

## MAG annotation and downstream analyses
First login to Puhti and go to your working directory:

```bash
cd /scratch/project_2005827/$USER
```

Although you have probably binned some nice MAGs, we will work from now on with MAGs that Antti and Igor have binned.
Let's copy the FASTA files to your working directory:

```bash
cp -r ../COURSE_FILES/MAGs MAGs
```

Let's also take the summary file for each of the four samples:

```bash
for SAMPLE in Sample01 Sample02 Sample03 Sample04; do
  cp ANVIO/BINNING_MEGAHIT/$SAMPLE/MAGsSummary/bins_summary.txt MAGs/$SAMPLE.bins_summary.txt
done
```

And finally, let's also take a couple of files summarizing the abundance of the MAGs across the different samples:

```bash
for SAMPLE in Sample01 Sample02 Sample03 Sample04; do
  cp ANVIO/BINNING_MEGAHIT/$SAMPLE/MAGsSummary/bins_across_samples/mean_coverage.txt MAGs/$SAMPLE.mean_coverage.txt
  cp ANVIO/BINNING_MEGAHIT/$SAMPLE/MAGsSummary/bins_across_samples/detection.txt MAGs/$SAMPLE.detection.txt
done
```

### Taxonomic assignment with GTDBtk
Normally, one thing that we want to learn more about is the taxonomy of our MAGs.  
Although `anvi'o` gives us a preliminary idea, we can use a more dedicated platform for taxonomic assignment of MAGs.  
Here we will use `GTDBtk`, a tool to infer taxonomy for MAGs based on the GTDB database (you can - and probably should - read more about GTDB [here](https://gtdb.ecogenomic.org/)).  

I have prepared a script to run `GTDBtk` for you, so let's copy it and take a look:

```bash
cp ../COURSE_FILES/SBATCH_SCRIPTS/GTDBtk.sh .
```

And submit the script using `sbatch`.

### MAG dereplication with dRep
Because we are doing individual assemblies, it could be that we have obtained a given MAG more than once.  
To remove this redundancy, we perform a step that is called dereplication.  
Here we will use `dRep` for this (to learn more about `dRep` see [here](https://drep.readthedocs.io/)):

```bash
sinteractive -A project_2005827 -c 4

module load bioconda/3
source activate drep

dRep compare DREP \
             --genomes MAGs/*.fa \
             --processors 4
```

Copy the `DREP` folder to your computer and look at the PDF files inside the `figures` folder, particularly the primary and secondary clustering dendrograms.  
Also look at the `Cdb.csv` file inside `data_tables`.  
How many clusters of duplicated (redudant) MAGs do we have?

### Functional annotation
Let's now annotate the MAGs against databases of functional genes to try to get an idea of their metabolic potential.  
As everything else, there are many ways we can annotate our MAGs.  
Here, let's take advantage of `anvi'o` for this as well.  
Annotation usually takes some time to run, so we won't do it here.  
But let's take a look below at how you could achieve this:

```bash
anvi-run-ncbi-cogs --contigs-db CONTIGS.db \
                   --num-threads 4

anvi-run-kegg-kofams --contigs-db CONTIGS.db \
                     --num-threads 4

anvi-run-pfams --contigs-db CONTIGS.db \
               --num-threads 4
```

These steps have been done by us already, and the annotations have been stored inside the `CONTIGS.db` of each assembly in `/scratch/project_2005827/COURSE_FILES/BINNING_MEGAHIT`.  
What we need now is to get our hands on a nice table that we can then later import to R.  
We can achieve this by running `anvi-export-functions`.
If you're not yet in the `sinteractive` session, connect to it, go to your working directory, load `bioconda`, activate the `anvio7` environment, and then:

```bash
for SAMPLE in Sample01 Sample02 Sample03 Sample04; do
  anvi-export-functions --contigs-db ANVIO/BINNING_MEGAHIT/$SAMPLE/CONTIGS.db \
                        --output-file MAGs/$SAMPLE.gene_annotation.txt
done
```

Since we're at it, let's also recover the information about i) the genes found in each split and ii) which splits belong to wihch bin/MAG.  
I don't think there's a straightforward way to get this using `anvi'o` commands, but because `CONTIGS.db` and `PROFILES.db` are [SQL](https://en.wikipedia.org/wiki/SQL) databases, we can access information within them using `sqlite3`:

```bash
for SAMPLE in Sample01 Sample02 Sample03 Sample04; do
  # Get list of gene calls per split
  printf '%s|%s|%s|%s|%s\n' splits gene_callers_id start stop percentage > MAGs/$SAMPLE.genes_per_split.txt
  sqlite3 ANVIO/BINNING_MEGAHIT/$SAMPLE/CONTIGS.db 'SELECT * FROM genes_in_splits' >> MAGs/$SAMPLE.genes_per_split.txt


  # Get splits per bin
  printf '%s|%s|%s\n' collection splits bins > MAGs/$SAMPLE.splits_per_bin.txt
  sqlite3 ANVIO/BINNING_MEGAHIT/$SAMPLE/MERGED_PROFILES/PROFILE.db 'SELECT * FROM collections_of_splits' | grep 'MAGs|' >> MAGs/$SAMPLE.splits_per_bin.txt
done
```
