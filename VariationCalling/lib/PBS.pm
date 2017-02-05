package PBS;

# Author: Yancong Zhang  <zhangyc@mail.bnu.edu.cn>
# Perl module for PBS on CMB cluster
# Program Version 1.0    2013-01-03

require Exporter;

use Cwd;
use Carp;
use POSIX qw( WIFEXITED strftime );

use version;	our $VERSION = qv(1.0);
our @ISA = qw(Exporter);
our @EXPORT = qw( submitPBSJob PBSJobStat waitPBSJob );
our $PBS = "/opt/torque/bin/qsub";
our $INTERVAL = 60;

sub submitPBSJob {
	my $cmd  = shift;
	my $name = shift || "qsub_$$";
	my $res  = shift;

	$cmd =~ s/\\/\\\\/g;
	$cmd =~ s/"/\\"/g;
	my ($node, $ppn)  = $res =~ /(\d+):(\d+)/;
	my $path = $ENV{'VAR_PATH'};
	my $cwd = getcwd();

# qsub content
my $qsub_body   = q(
cd $PBS_O_WORKDIR
NPROCS=`wc -l < $PBS_NODEFILE`

export PATH=). $path .q(:$PATH

perlReporter -n $PBS_NODEFILE -p $NPROCS ") .$cmd . q("
);

	# write to qsub script
	my $qsub_script_file = "$name-".time.".sh";
	open my $outfh, ">$qsub_script_file"
		or croak "Couldn't open $qsub_script_file to write!\n$!";
	print $outfh $qsub_body;
	close $outfh;

	# qsub it!
	#if(($status >>=8) != 0){
	my $status = qx|$PBS -l nodes=$node:ppn=$ppn -N $name $qsub_script_file|;
	#my $status = "123.dellcmb.bnu.edu.cn";
	if($! == -1){
		#croak "Couldn't run qsub to submit job ($@)";
		return -1;
	}else{
		if($status =~ /^(\d+)\./){
			print "Job $1 is submited\n";
			sleep(1);
			return "$cwd/*.o$1";
		}else{
			return -1;
		}
	}
}

sub PBSJobStat{
	my $job = shift;
	my $stat = 1;
	my $jobId = 0;

	if($job =~ /.*\.o(\d+)$/){
		$jobId = $1;
		if(-e $job){  #  *.o123 file exist, this job is finished
			my $out = qx|tail -1 $job|;
			if($out eq "Done"){
				$stat = 0;
			}else{
				$stat = -1;
			}
		}else{  # job may be not finished
			my $queue = qx|qstat $jobId \| tail -1|;
			if($queue =~ /^$jobId\S*\s+\S+\s+\S+\s+\S+\s+R\s+.*/){
				$stat = 1; #job is running
			}else{
				print "Job $jobId isn't running!\n";
				print "Job queue:$queue\n";
				$stat = -1; # job isn't running
			}
		}
	}else{
		$stat = -2; # job is not submitted successfully
	}
	print STDERR "[JOBERR] Job $jobId is unknown, please check $job manually\n" if($stat == -2);
	print STDERR "[JOBERR] Job $jobId is error, please check $job manually\n" if($stat == -1);
	print STDERR "[JOBERR] Job $jobId is Done\n" if($stat == 0);
	return $stat;
}

sub waitPBSJob {
	my $job = shift;

	while(&PBSJobStat($job) > 0){ # job is running
		sleep($INTERVAL);
	}
	return 0;
}

return 1;
