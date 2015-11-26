use strict;
use warnings;

package pdf::Parser;

#use config::PDF;

sub parseFile
{
    my ($filePath, $scale) = @_;
    die 'pdf::Parser::parseFile: file not specified.' unless(defined($filePath));

    open(my $pdfxmlFH, '-|', 'pdftohtml', '-i', '-fontfullname', '-nodrm', '-stdout', '-xml', '-nomerge', '-zoom', $scale, '-q', '-hidden', $filePath)
	or die 'pdftoxml exec failed.';
    binmode $pdfxmlFH;

    my $xmlStr = '';
    while(<$pdfxmlFH>) {
	# NOTICE: currenlty (0.24), pdftohtml outputs
	# font names using the encoding as are in the PDF,
	# not converted even if '-enc' specified.
	# WORKAROUND: re-encode lines with <fontspec>.
	if($_ =~ /<fontspec/) {
	    Encode::from_to($_, 'cp932', 'utf8');
	}

	# pdftohtml generates raw control codes.
	# convert them into U+FFFD (REPLACEMENT CHARACTER).
	# TAB(&#9;) LF(&#xA;) CR(&#xD;) are not converted.
	$_ =~ s/[\x{0}-\x{08}\x{b}\x{c}\x{e}-\x{1f}]/&#xFFFD;/g;

	# pdftohtml generates malformed UTF-8 if the src PDF contains.
	# convert them into U+FFFD (REPLACEMENT CHARACTER).
	$_ = Encode::encode('utf8', Encode::decode('utf-8', $_));
	
	$xmlStr .= $_;

#	for(my $i = 0; $i < length($_); $i++) {
#	    my $c = ord(substr($_, $i, 1));
#	    if($c < 32 && $c != 10) {
#		#$xmlStr .= "&#" . $c . ';';
#		$xmlStr .= "&#xFFFD;";
#	    } else {
#		$xmlStr .= substr($_, $i, 1);
#	    }
#	};
    }
    close($pdfxmlFH);


    return $xmlStr;
}

1;
