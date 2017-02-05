package Update;

##################################################
# uptodate
# check whether output files are up to date with respect to input files
# all output files must exist and not be older than any input file
##################################################

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

return 1;
