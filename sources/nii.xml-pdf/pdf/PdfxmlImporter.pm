use strict;
use warnings;

use KyotoCabinet;
use XML::LibXML;
use JSON;
use Encode;

package pdf::PdfxmlImporter;

sub new
{
    my ($class, $dbPath) = @_;

    unless(defined($dbPath)) {
	die 'db path not specified.';
    }

    my $db = new KyotoCabinet::DB();

    $db->open($dbPath,
	      KyotoCabinet::DB::OCREATE |
	      KyotoCabinet::DB::OWRITER)
	or die $db->error;
      
    return bless {
	db => $db
    }, $class;
}

sub DESTROY
{
    my ($self) = @_;
    if(defined($self->{db})) {
	$self->{db}->close();
    }
}

sub convert
{
    my ($self, $pdfxmlStr, $scale) = @_;

    unless(defined($scale)) {
	$scale = 2.0;
    }

    my $articleInfo = {'pages'=>[]};

    # NOTICE: currently (0.24), pdftohtml generates malformed XML
    # in which un-nested <b> and <i> tags appear.
    # ex. <b><i>...</b>...</i>
    # WORKAROUND: eliminates <i></i><b></b> before parsing as XML.

    $pdfxmlStr =~ s/<\/?[bi]>//g;

    my $dom = XML::LibXML->load_xml(string => $pdfxmlStr);

    my $boundaryID = 1;

    # - each page
    foreach my $pageNode ($dom->documentElement()->childNodes()) {

	next unless($pageNode->nodeName eq 'page');

	my $pageInfo = { boundaries => [] };
	push(@{$articleInfo->{pages}}, $pageInfo);

	# - page info
	foreach my $key ('number') {
	    $pageInfo->{$key} = $pageNode->getAttribute($key);
	};
	# - page info (scaled)
	foreach my $key ('top', 'left', 'height', 'width') {
	    $pageInfo->{$key} = $pageNode->getAttribute($key) / $scale;
	};

	# - fontspec
	my $fontspecNodeXPath = new XML::LibXML::XPathExpression('.//fontspec');

	my @fontspecs;
	foreach my $fontspecNode ($pageNode->findnodes($fontspecNodeXPath)) {
	    my $fontspecInfo = { };
	    foreach my $key ('family', 'color') {
		$fontspecInfo->{$key} = $fontspecNode->getAttribute($key);
	    };
	    foreach my $key ('size') {
		$fontspecInfo->{$key} = $fontspecNode->getAttribute($key) / $scale;
	    };

	    $fontspecs[$fontspecNode->getAttribute('id')] = $fontspecInfo;
	}
	# - boundaries
	my $textNodeXPath = new XML::LibXML::XPathExpression('.//text');

	my $seq = 0;
	foreach my $textNode ($pageNode->findnodes($textNodeXPath)) {
	    my $textInfo = { 'type'=>'text', 'sequence'=>$seq++};
	    push(@{$pageInfo->{boundaries}}, $textInfo);

	    foreach my $key ('top', 'left', 'height', 'width') {
		$textInfo->{$key} = $textNode->getAttribute($key) / $scale;
	    };

	    $textInfo->{text} = $textNode->textContent;
	    $textInfo->{font} = $fontspecs[$textNode->getAttribute('font')];
	    $textInfo->{page} = $pageInfo->{number};
	    $textInfo->{id} = $boundaryID++;
	}
    }

    return $articleInfo;
}

sub store # TODO: this should be a method of AbstractImporter.
{
    my ($self, $articleID, $articleInfo) = @_;

    unless($self->{db}->set($articleID, JSON::encode_json($articleInfo))) {
	die $self->{db}->error;
    }
}
1;
