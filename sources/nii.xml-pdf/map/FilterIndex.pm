
package map::FilterIndex;

use strict;
use warnings;

sub new {
    my $class = shift;
    my $db = shift || die "An argument required map::Index::new()\n";

    return bless {
        db => $db,
    }, $class;
}

sub get()
{
    my $self = shift;
    my $articleUUID = shift;
    unless(defined($articleUUID)) {
	die "article UUID required for map::FilterIndex::get()\n";
    }
    my $page = shift;
    unless(defined($page)) {
	$page = '';
    }
    my $db = $self->{db};
    my $result = $db->get("$articleUUID\0$page");
    if ($result) {
        return JSON::decode_json($result);
    }
    elsif ($db->error <=> KyotoCabinet::Error::NOREC) {
        die "db error: ".$db->error."\n";
    }
    return [];
}

1;
