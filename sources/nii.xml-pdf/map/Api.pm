use strict;
use warnings;

use KyotoCabinet;
use JSON;

package map::Api;

package map::Api::Local;

sub new
{
    my ($class, $dbPath, $boundaryDbPath, $boundaryIndexDbPath, $filterIndexDbPath) = @_;

    my $db;
    if(defined($dbPath)) {
	$db = new KyotoCabinet::DB();
	$db->open($dbPath,
		  KyotoCabinet::DB::OREADER)
	    or die $db->error;
    }

    my $boundaryDb;
    if(defined($boundaryDbPath)) {
	$boundaryDb = new KyotoCabinet::DB();
	$boundaryDb->open($boundaryDbPath,
			  KyotoCabinet::DB::OREADER)
	    or die $boundaryDb->error;
    }

    my $boundaryIndexDb;
    if(defined($boundaryIndexDbPath)) {
	$boundaryIndexDb = new KyotoCabinet::DB();
	$boundaryIndexDb->open($boundaryIndexDbPath,
			       KyotoCabinet::DB::OREADER)
	    or die $boundaryIndexDb->error;
    }

    my $filterIndexDb;
    if(defined($filterIndexDbPath)) {
	$filterIndexDb = new KyotoCabinet::DB();
	$filterIndexDb->open($filterIndexDbPath,
			     KyotoCabinet::DB::OREADER)
	    or die $filterIndexDb->error;
    }
      
    return bless {
	db => $db,
	boundaryDb => $boundaryDb,
	boundaryIndexDb => $boundaryIndexDb,
	filterIndexDb => $filterIndexDb
    }, $class;
}

sub DESTROY
{
    my ($self) = @_;
    if(defined($self->{db})) {
	$self->{db}->close();
    }
    if(defined($self->{boundaryDb})) {
	$self->{boundaryDb}->close();
    }
    if(defined($self->{boundaryIndexDb})) {
	$self->{boundaryIndexDb}->close();
    }
    if(defined($self->{filterIndexDb})) {
	$self->{filterIndexDb}->close();
    }
}

sub getBoundaries {

    my ($self, $articleUUID, $page, $filter) = @_;

    my $filterConditions;
    if(defined($filter)) {
	$filterConditions = [$filter];
    } else {
	$filterConditions = $self->getAvailableFilterConditions($articleUUID, $page);
    }

    my %result;

    foreach my $cond (@$filterConditions) {

	my $_filter = $cond;
	my $ids = $self->getBoundaryIDs($articleUUID, $page, $_filter);

	$result{$cond} =
	    $self->getBoundaryInfo($articleUUID, $ids);
    }

    return \%result;
}

sub getBoundaryInfo {

    my ($self, $articleUUID, $boundaryIDs) = @_;

    my %infos;

    foreach my $boundaryID (@{$boundaryIDs}) {
	my $key = $articleUUID."\0".$boundaryID;
#	warn "KEY $boundaryID\n";
	my $info = $self->{boundaryDb}->get($key);

	next unless(defined($info));

	$infos{$boundaryID} = JSON::decode_json($info);
    }

    return \%infos;
}

sub getBoundaryIDs {

    my ($self, $articleUUID, $page, $filter) = @_;

    require map::Index;
    my $index = new map::Index($self->{boundaryIndexDb});

    my $idArray = $index->get($articleUUID, $filter, $page);

    unless(defined($idArray)) {
	return [];
    }

    return $idArray;
}

sub getArticleAsXML {
}

sub getAvailableFilterConditions
{
    my ($self, $articleUUID, $page) = @_;

    require map::FilterIndex;
    my $index = new map::FilterIndex($self->{filterIndexDb});
    my $idArray = $index->get($articleUUID, $page);

    unless(defined($idArray)) {
	return [];
    }

    return $idArray;
}



1;
