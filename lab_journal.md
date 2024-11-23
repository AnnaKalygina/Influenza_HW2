This is the lab journal for the project on Influenza vaccines.

### Fetching and inspecting data
The viral sample reads are downloaded from the NCBI Sequence Read Archive

``` bash
wget http://ftp.sra.ebi.ac.uk/vol1/fastq/SRR170/001/SRR1705851/
```

The reference sequence for the hemagglutinin (HA) gene of an Influenza A virus was copied from [NIH](https://www.ncbi.nlm.nih.gov/nuccore/KF848938.1?report=fasta):
``` bash
echo ">KF848938.1 Influenza A virus (A/USA/RVD1_H3/2011(H3N2)) segment 4 hemagglutinin (HA) gene, partial cds
CAAAAACTTCCTGGAAATGACAACAGCACGGCAACGCTGTGCCTTGGGCACCATGCAGTGCCAAACGGAA
CAATAGTGAAAACAATCACGAATGACCAAATTGAAGTTACTAATGCCACTGAGCTGGTTCAGAGTTCCTC
AACAGGTGAAATATGCAACAGTCCTCATCAGATCCTTGATGGAGAAAACTGCACACTAATAGATGCTCTA
TTGGGAGACCCTCAGTGTGATGGCTTCCAAAACAAGAAATGGGACCTTTTTGTTGAACGAAGCAAAGCCC
ACAGCAACTGTTACCCTTATGATGTGCCGGATTATGCCTCCCTTAGGTCACTAGTTGCCTCATCCGGCAC
ACTGGAGTTTAACAATGAAAGCTTCAATTGGACTGGAGTCACTCAAAACGGAACAAGCTCTGCTTGCATA
AGGAGATCTAATAATAGTTTCTTTAGTAGATTGAATTGGTTGACCCACTTAAACTTCAAATACCCAGCAT
TGAACGTGACTATGCCAAACAATGAACAATTTGACAAATTGTACATTTGGGGGGTTCACCACCCGGGTAC
GGACAAGGACCAAATCTTCCTGTATGCTCAAGCAGCAGGAAGAATCACAGTATCTACCAAAAGAAGCCAA
CAAGCTGTAATTCCGAATATCGGATCTAGACCCAGAGTAAGGAATATCCCTAGCAGAGTAAGCATCTATT
GGACAATAGTAAAACCGGGAGACATACTTTTGATTAACAGCACAGGGAATCTAATTGCTCCTAGGGGTTA
CTTTAAAATACGAAGTGGGAAAAGCTCAATAATGAGATCAGATGCACCCATTGGCAAATGCAATTCTGCA
TGCATCACTCCAAATGGAAGCATTCCCAATGACAAACCATTCCAAAATGTAAACAGGATCACATACGGGG
CCTGTCCCAGATATGTTAAGCAAAACACTCTGAAATTGGCAACAGGAATGAGAAATGTACCAGAGAAACA
AACTAGAGGCATATTTGGCGCAATAGCTGGTTTCATAGAAAATGGTTGGGAGGGAATGGTGGATGGTTGG
TACGGTTTCAGGCATCAAAATTCTGAGGGAAGGGGACAAGCAGCAGATCTCAAAAGCACTCAAGCAGCAA
TCGATCAAATCAATGGGAAGCTGAATAGATTGATCGGGAAAACCAACGAGAAATTCCATCAGATTGAAAA
AGAATTCTCAGAAGTCGAAGGGAGAATTCAGGACCTTGAGAAATATGTTGAGGACACTAAAATAGATCTA
TGGTCATACAACGCGGAGCTTCTTGTTGCCCTGGAGAACCAACACACAATTGATCTAACTGACTCAGAAA
TGAACAAATTGTTTGAAAAAACAAAGAAGCAACTGAGGGAAAATGCTGAGGATATGGGCAATGGTTGTTT
CAAAATATACCACAAATGTGACAATGCCTGCATAGGATCAATCAGAAATGGAACTTATGACCACGATGTG
TACAGAGATGAAGCATTAAACAACCGATTCCAGATCAAGGGAGTTGAGCTGAAGTCAGGGTACAAAGATT
GGATCCTATGGATTTCCTTTGCCATATCATGTTTTTTGCTTTGTGTTGCTTTGTTGGGGTTCATCATGTG
GGCCTGCCAAAAAGGCAACATTAGGTGCAACATTTGCATTTGAGTGCATTAATTA
" > HA_influenza.fa
```
Inspecting the quality of reads using FASTQC:
``` bash
fastqc SRR1705851.fastq.gz
```

### Alignment
``` bash
bwa index HA_influenza.fa
bwa mem HA_influenza.fa SRR1705851.fastq.gz | samtools view -S -b - | samtools sort -o alignment_sorted.bam
samtools index alignment_sorted.bam
```

Generating mile.up. We set the depth limit for each position to 35,000, which should be high enough to include all reads:
``` bash 
samtools mpileup -d 35000 -f HA_influenza.fa alignment_sorted.bam > alignment.mpileup
```

### Identifying mutations
We are looking for positions where the most population differs from the reference. Therefore, we use a high minimum variant frequency cut-off (N) to find only those mutants present in most (95% or more = 0.95) of the viral DNA molecules.

```bash
varscan mpileup2snp alignment.mpileup --min-var-freq 0.95 --output-vcf 1 > common_variants.vcf
awk 'NR>23 {print $1, $2, $4, $5, $7}' common_variants.vcf > common_variants_summary.txt

```
Five SNPs were identified. 


Next we want to identify the rare variants. As the population is mostly homogenious, we set the minimum variant frequency to 0.001 (0.1%) to find the rare mutations. 18 SNPs were identified.

``` bash
varscan mpileup2snp alignment.mpileup --min-var-freq 0.001 --output-vcf 1 > rare_variants.vcf
awk 'NR>23 {print $1, $2, $4, $5, $7}' rare_variants.vcf > rare_variants_summary.txt
```

### Inspecting and aligning the control sample sequencing data
Now we inspect the control reaction in which the isogenic viral sample (all virus particles genetically identical) derived from a virus clone that matches the reference sequence is sequenced.
"By looking at the errors in this reference and comparing them to the mutations in your roommate’s sample, you hope you’ll be able to figure out which variants are real. You asked for help, and your friends took the isogenic (100% pure) sample of the standard (reference) H3N2 influenza virus, PCR amplified, and subcloned into a plasmid. They sequenced it three times on an Illumina machine.

Any “mutations” you detect in the control samples which don’t contain any true genetic variants must be due to errors. You can use the frequency of the errors from the control to help figure out what’s an error and what’s a true variant in the data from your roommate."

Downloading the FASTQ files for the control samples from SRA:

```bash 
wget ftp://ftp.sra.ebi.ac.uk/vol1/fastq/SRR170/008/SRR1705858/SRR1705858.fastq.gz
wget ftp://ftp.sra.ebi.ac.uk/vol1/fastq/SRR170/009/SRR1705859/SRR1705859.fastq.gz
wget ftp://ftp.sra.ebi.ac.uk/vol1/fastq/SRR170/000/SRR1705860/SRR1705860.fastq.gz
```

Aligning and indexing:

```bash
bwa mem HA_influenza.fa SRR1705858.fastq.gz | samtools view -S -b - | samtools sort -o SRR1705858_sorted.bam
bwa mem HA_influenza.fa SRR1705859.fastq.gz | samtools view -S -b - | samtools sort -o SRR1705859_sorted.bam
bwa mem HA_influenza.fa SRR1705860.fastq.gz | samtools view -S -b - | samtools sort -o SRR1705860_sorted.bam

samtools index SRR1705858_sorted.bam
samtools index SRR1705859_sorted.bam
samtools index SRR1705860_sorted.bam
```

Let's know derive the rare mutations from the control samples:

``` bash 
samtools mpileup -d 35000 -f HA_influenza.fa SRR1705858_sorted.bam > SRR1705858.mpileup
varscan mpileup2snp SRR1705858.mpileup --min-var-freq 0.001 --output-vcf 1 > control_58_variants.vcf
```