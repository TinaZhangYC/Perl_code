#package ParseFasta;
#---------- package -------------#
sub ParseFasta {
    my $filename = shift;
    open (IN, $filename) or die "can't open file $filename: $! \n";
    my $origin = $/;
    $/ = "\n>";

    my %data;
    while (<IN>) {
        chomp;
	if (/^([^\n]+)\n(.*)/ms) {
	    my ($name, $seq) = ($1, $2);

            $name = $1 if ($name =~ /([^\s]+)/);
            $name =~ s/^>//;
	    $seq =~ s/\n//g;

	    $data{$name} = $seq;
	}
    }

    $/ = $origin;
    close (IN);

    return (\%data);
}

#--------------------------------#
return 1;
