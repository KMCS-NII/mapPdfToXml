use strict;
use warnings;

use KyotoCabinet;
use JSON;

use xml::XHTMLParser;

package xml::Importer;

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
    my ($self, $xmlStr) = @_;

    my $articleInfo = xml::XHTMLParser::parse($xmlStr);

    return $articleInfo;
}

sub store
{
    my ($self, $articleID, $articleInfo) = @_;

    unless($self->{db}->set($articleID, JSON::encode_json($articleInfo))) {
	die $self->{db}->error;
    }
}

sub isStored
{
    my ($self, $articleID) = @_;

    return ($self->{db}->check($articleID) > 0);
}
1;

