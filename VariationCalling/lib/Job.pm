package Job;

# Author: Yancong Zhang  <zhangyc@mail.bnu.edu.cn>
# Perl module for Job on CMB cluster
# Program Version 1.0    2013-01-03

require Exporter;

use Carp;
use Cwd;
use POSIX qw( WIFEXITED strftime );
use FindBin qw($Bin);
use File::Path qw(mkpath);
use Data::Dumper;
use List::MoreUtils qw( uniq );

use Shell;
use PBS;

use version;	our $VERSION = qv(1.0);
our @ISA = qw(Exporter);
our @EXPORT = qw( taskTrigger taskWaiter );
our $JMS = "JMS";
our $SYS = "SYS";

sub initParameter{
	my $p = shift;

	my $err = 0;
	my $input_no = 0;
	my $output_no = 0;
	$p->{PWD} = "./" if( !$p->{PWD} );
	if( $p->{CMD} ){
		# more check here
		my @tmp = $p->{CMD} =~ /{I\d+}/g;
		$input_no = uniq @tmp;
		@tmp = $p->{CMD} =~ /{O\d+}/g;
		$output_no = uniq @tmp;
	}else{
		$err++;
	}
	if( $p->{INPUT} ){
		# replace command line
		if(@{$p->{INPUT}} > 0 && @{$p->{INPUT}} >= $input_no){
			for(my $i=1;$i<=@{$p->{INPUT}};$i++){
				my $in = $p->{INPUT}->[$i-1];
				$p->{CMD} =~ s/{I$i}/$in/g;
			}
		}else{
			$err++;
		}
	}else{
		$err++;
	}
	if( $p->{OUTPUT} && @{$p->{OUTPUT}} >= $output_no){
		# replace command line
		for(my $i=1;$i<=@{$p->{OUTPUT}};$i++){
			my $in = $p->{OUTPUT}->[$i-1];
			$p->{CMD} =~ s/{O$i}/$in/g;
		}
	}else{
		$err++;
	}
	$p->{DESC} = "NULL" if( !$p->{DESC} );
	if( $p->{TYPE} ){
		$err++ unless( $p->{TYPE} =~ /($JMS:\d+:\d+)|($SYS)/ );
	}else{
		$err++;
	}
	my $post = $task->{POST};
	if( $p->{POST} ){
		$err++ unless( $p->{POST} =~ /(WAIT)|(GO)/ );
	}else{
		$err++;
	}
	
	croak "Inererror: key data structure void\n" if( $err > 0 );
	return $err;
}

sub taskTrigger{
	my $count = shift;
	my $task = shift;
#init parameters
	&initParameter($task);
	&logCMD($task);

	my $pwd = $task->{PWD};
	my $cmd = $task->{CMD};
	my $input = $task->{INPUT};
	my $output = $task->{OUTPUT};
	my $desc = $task->{DESC};
	my $type = $task->{TYPE};
	my $post = $task->{POST};
	my $cwd = getcwd();
#check input and output
	unless(-e $pwd){
		croak "Working dir is missing\n" unless(mkpath($pwd));
	}
	croak "Change working dir failed\n" unless(chdir($pwd));

	my $jobId = 0;
	if(!&uptodate($input,$output)){
		print STDERR "[DAEMON] Step $count start at ".strftime("%b %e %H:%M:%S", localtime)."\n";
		print STDERR "============  $desc  ==============\n";

		if($type =~ /$JMS:(.*)/){
			$jobId = &submitPBSJob($cmd, "step-$count", $1);
			if($jobId eq "-1"){
				print STDERR "[ERROR] submit PBS job failed\n";
			}else{
				&waitPBSJob($jobId) if($post eq "WAIT");
			}
		}
		if($type =~ /$SYS/){
			if($post eq "GO"){
				$jobId = &submitShellJob($cmd);
			}else{
				&runShell($cmd);
			}
		}
		print STDERR "[DEAMON] Step $count ........................................... done\n" if($post eq "WAIT");
	}else{
		print STDERR "[DEAMON] Step $count ........................................... skiped\n";
	}
	carp "Change working dir failed\n" unless(chdir($cwd));

	return $jobId;
}

sub taskWaiter {
	my $jobList = shift;
	my @List = grep { $_ ne 0 } @{$jobList};

	for(my $i=0;$i<@List;$i++){
		&waitPBSJob($List[$i]);
	}
}

###################################################################################
# uptodate
# check whether output files are up to date with respect to input files
# all output files must exist and not be older than any input file
###################################################################################

sub uptodate {
    my $input = shift;    # reference to list of input file names
    my $output = shift;   # reference to list of input file names
    my $earliestOutMtime; # earliest modification time of an output file
    my $latestInMtime;    # latest modification time an any input file
    my @stat;             # holds info about file

    return 1 if (@{$input} == 0); # no input is always older than output files
    # check existence and times of input files
    foreach my $if (@{$input}){
	if (! -f $if){ # ignore if input file does not exist
	    print STDERR "Warning: $if missing.\n";# TODO, remove or correct this later
	    return 1;
	}
	@stat = stat($if);
	$latestInMtime = $stat[9] if(!defined($latestInMtime) || $stat[9] > $latestInMtime);
    }

    return 1 if (@{$output} == 0); # no output is always up to date
    # check whether all output files exist
    foreach my $of (@{$output}){
	return 0 if (! -f $of); # if output file does not exist, up to data
	@stat = stat($of);
	$earliestOutMtime = $stat[9] if(!defined($earliestOutMtime) || $stat[9] < $earliestOutMtime);
    }
    return ($latestInMtime <= $earliestOutMtime);
}

sub logCMD {
	my $t = shift;

	print "## ".$t->{DESC}."\n";
	print "cd ".$t->{PWD}."\n";
	$t->{CMD} =~ s/;/\n/g;
	print $t->{CMD}."\n";
	my $cwd = getcwd();
	print "cd $cwd\n";
	print "\n";
}

1;
