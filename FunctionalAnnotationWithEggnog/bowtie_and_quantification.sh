module load bowtie2
module load samtools

cd /scratch/project_2005827/$USER

mkdir -p BOWTIE2/
mkdir -p QUANT/

bowtie2-build --threads 1 MEGAHIT/final.contigs.fa BOWTIE2
bowtie2 -p 1 -x BOWTIE2 -1 FASTQ_ANNOT/toy1_R1.fastq.gz -2 FASTQ_ANNOT/toy1_R2.fastq.gz | samtools view -bS | samtools sort > toy1.bam
bowtie2 -p 1 -x BOWTIE2 -1 FASTQ_ANNOT/toy2_R1.fastq.gz -2 FASTQ_ANNOT/toy2_R2.fastq.gz | samtools view -bS | samtools sort > toy2.bam

samtools index toy1.bam
samtools index toy2.bam

singularity pull docker://fischuu/subread
singularity shell -B /scratch subread_latest.sif

featureCounts -p -T 1 -a PRODIGAL/final.contigs.gtf -o QUANT/samples1_fc.txt -t CDS -g ID toy1.bam
featureCounts -p -T 1 -a PRODIGAL/final.contigs.gtf -o QUANT/samples2_fc.txt -t CDS -g ID toy2.bam
