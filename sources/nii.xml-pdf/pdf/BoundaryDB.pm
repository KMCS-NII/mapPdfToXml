
use strict;
use warnings;

use JSON;
use KyotoCabinet;

use id::Manager;

package pdf::BoundaryDB;

sub new
{
    my ($class) = @_;
    return bless {}, $class;
}

sub rebuild
{
    my ($idManager, $pdfDB, $boundaryDB) = @_;

    $boundaryDB->clear();

    my $infoBringer = new pdf::BoundaryDB();
    $infoBringer->{boundaryDB} = $boundaryDB;
    $infoBringer->{pdfDB} = $pdfDB;

    $idManager->doForAll(\&pdf::BoundaryDB::_rebuild, $infoBringer);
#    my $cur = $pdfDB->cursor();
#    $cur->jump;
#    while(my ($articleUUID, $value) = $cur->get(1)) {
#	_rebuild($articleUUID, JSON::decode_json($value), $boundaryDB);
#    }
}

sub _rebuild
{
    my ($self, $articleUUID, $pdfid, $xmlid) = @_;
    #$articleUUID, $articleInfo, $boundaryDB) = @_;

    my $articleInfo = $self->{pdfDB}->get($pdfid);
    return unless(defined($articleInfo));
    $articleInfo = JSON::decode_json($articleInfo);

    foreach my $page (@{$articleInfo->{pages}}) {
	foreach my $boundary (@{$page->{boundaries}}) {
	    my $key = $articleUUID."\0".$boundary->{id};
	    $self->{boundaryDB}->set($key, JSON::encode_json($boundary));
	}
    }
}

1;
