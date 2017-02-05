# Step 1
## Align reads by using BWA ##
bwa index -a is ref.fa
bwa aln  ref  Pair_1.fastq >Pair_1.sai
bwa aln ref Pair_2.fastq >Pair_2.sai
bwa sampe  -r '\@RG\\tID:sample\\tSM:pan' ref  Pair_1.sai Pair_2.sai Pair_1.fastq  Pair_2.fastq >sample.sam

# Step 2
## Generate BAM file from alignment results ##
samtools view -bS sample.sam  1>sample.bam  2>log 
samtools sort  sample.bam  sample.sorted

# Step 3
## Remove PCR duplicates  ##
samtools rmdup sample.sorted.bam sample.sorted.rmdup.bam
samtools index sample.sorted.rmdup.bam

# Step 4
## Satistic mapping results ##
samtools index sample.sorted.bam
samtools index sample.sorted.rmdup.bam
samtools flagstat sample.sorted.bam |sed '2,4d;6q' > sample.all.stats
samtools flagstat sample.sorted.rmdup.bam |sed -n '3p;7,9p' >> sample.all.stats

# Step 5
## Staistic mapping depth ##
samtools depth -Q 20 sample.sorted.rmdup.bam > sample.depth

# Step 6
## detect SNP ##
#samtools mpileup -DSugf  ref.fa  sample.sorted.bam  >sample.var
##samtools mpileup -uf -q 30 -B  ref.fa  sample.sorted.bam  >sample.var
#bcftools view -Ncvg sample.var >sample.var.raw.vcf 
samtools mpileup -uf  ref  sample.sorted.rmdup.bam  >sample.var
bcftools view -bcvg sample.var >sample.var.raw.vcf 
#vcfutils.pl varFilter -D 100 -d 10  sample.var.raw.vcf >sample.var.flt.vcf 
varFilter -a 3 -q 30 -d 10 -D 100 sample.var.raw.vcf >sample.var.flt.vcf 

# Step 7
## detect SV ##
echo -e "sample.sorted.rmdup.bam\t500\tsample\n" > sample.pindel.conf
pindel -f ref -i sample.pindel.conf -o sample
# make VCF format SV results #
pindel2vcf -e 2 -r ref -R ref_version -d ref_date -p sample_D
pindel2vcf -e 2 -r ref -R ref_version -d ref_date -p sample_TD
pindel2vcf -e 2 -r ref -R ref_version -d ref_date -p sample_SI
pindel2vcf -e 2 -r ref -R ref_version -d ref_date -p sample_LI
pindel2vcf -e 2 -r ref -R ref_version -d ref_date -p sample_INV

### Perl sub process ##
#&formatVCF("sample.flt.vcf","SNP");
#&formatVCF("sample_SI.vcf","SI");
#&formatVCF("sample_LI.vcf","LI");
#&formatVCF("sample_INV.vcf","INV");
#&formatVCF("sample_TD.vcf","TD");
#&formatVCF("sample_D.vcf","D");
# formatVCF is defined in /home/zhangyc/programs/tmp/popEcoli_bin/bin/Analysis_pop.pl
