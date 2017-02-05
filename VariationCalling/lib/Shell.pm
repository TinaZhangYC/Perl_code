package Shell;

# Author: Yancong Zhang  <zhangyc@mail.bnu.edu.cn>
# by Yan Pengcheng yanpc@bcc.ac.cn
# Perl module for Shell on CMB cluster
# Program Version 1.0    2013-01-03

require Exporter;

use Carp;
use Cwd;

use version;	our $VERSION = qv(1.0);
our @ISA = qw(Exporter);
our @EXPORT = qw( runShell submitShellJob waitShellJob );

sub runShell {
	my $cmd  = shift;

	my $status = system("$cmd");
	if(($status >>=8) != 0){
		#croak "Couldn't run qsub to submit job ($@)";
		print STDERR "[ERROR] Couldn't run :$cmd, please check it manually\n";
	}
}

# This subroutine is not well tested, fork() may cause zombie
sub submitShellJob {
	my $cmd  = shift;

	# submit background shell!
	defined(my $pid=fork()) or die "Fork process failured:$!\n";
	unless($pid){  
		&runShell($cmd);
		sleep(3);
		print STDERR ("Exit child after 3 seconds wait!\n");
	}
	return $pid;
}

# This subroutine is not well tested, may cause zombie and unexpected exit
sub waitShellJob {
	my $job = shift;
	waitpid($job,0);
	return 0;
}
