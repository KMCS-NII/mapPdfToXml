use strict;
use warnings;

use KyotoCabinet;
use JSON;

package pdf::Api;

package pdf::Api::Local;

sub new
{
    my ($class, $dbPath) = @_;

    unless(defined($dbPath)) {
	die 'db path not specified.';
    }

    my $db = new KyotoCabinet::DB();

    $db->open($dbPath,
	      KyotoCabinet::DB::OREADER)
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

sub getArticleInfo
{
    my ($self, $pdfid) = @_;
    return JSON::decode_json($self->{db}->get($pdfid));
}

1;
