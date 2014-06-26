#############################################################################
#
# Template Library
#
#	Simple helpers for mixing script with HTML layout.
#
#############################################################################

package TMPL;

#---------------------------------------------------------------------------
#	$fh = TMPL::Open ('path');
#
#	  The file is a html document, with some #xxx tags inside that can be
#	  replaced with perl output. See other Template functions.
#---------------------------------------------------------------------------
sub Open {
	local *FH;
    open (FH, $_[0]) or die "Cannot open template '$_[0]': $!";
    return *FH;
}

#---------------------------------------------------------------------------
#	TMPL::Rewind ($fh)
#
#	  Rewind template file (so you can parse again)
#---------------------------------------------------------------------------
sub TMPL::Rewind {
	my $fh = shift;
	seek $fh, 0, 0;
}

#---------------------------------------------------------------------------
#	TMPL::CopyTo ($fh, '#xxxx', *OUTPUTFILEHANDLE)
#
#	  Copy every line from template file to the output file, until
#	  the tag #xxxx is found in the line. When it is found the functions
#	  returns, the line with the tag is NOT output.
#---------------------------------------------------------------------------
sub CopyTo {
	my $fh = shift;
	my $tag = shift;
	my $fout = shift;
	while (<$fh>) {
		last if ( /$tag/ );
		print $fout $_;
	}
}

#---------------------------------------------------------------------------
#	TMPL::Flush ($fh, *OUTPUTFILEHANDLE)
#	Copy every line from template file until the end of the template file.
#---------------------------------------------------------------------------
sub Flush {
	my $fh = shift;
	my $fout = shift;
	while (<$fh>) {
		print $fout $_;
	}
}

1;
