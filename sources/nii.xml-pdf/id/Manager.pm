use strict;
use warnings;

use KyotoCabinet;
use JSON;

package id::Manager;

sub new
{
    my ($class, $dbPath) = @_;

    unless(defined($dbPath)) {
	die 'db path not specified.';
    }

    return bless {
	dbPath => $dbPath,
    }, $class;
}

sub openDB
{
    my ($self, $writable) = @_;

    if(defined($self->{db})) {
	return;
    }

    $self->{db} = new KyotoCabinet::DB();

    my $mode = (defined($writable) && $writable)
	?
	(KyotoCabinet::DB::OCREATE |
	 KyotoCabinet::DB::OWRITER)
	:
	KyotoCabinet::DB::OREADER
	;
    $self->{db}->open($self->{dbPath}, $mode)
	or die $self->{db}->error;
}

sub closeDB
{
    my ($self) = @_;
    if(defined($self->{db})) {
	$self->{db}->close();
	$self->{db} = undef;
    }
}

sub DESTROY
{
    my ($self) = @_;
    $self->closeDB();
}

sub register
{
    my ($self, $uid, $pdfid, $xmlid) = @_;
    $self->openDB(1);
    $self->{db}->set($uid, $pdfid."\x{0}".$xmlid);
    $self->closeDB();
}

sub doForAll
{
    my ($self, $proc, $selfForProc) = @_;
    $self->openDB();
    my $cur = $self->{db}->cursor;

    $cur->jump;
    while(my($uid, $value) = $cur->get(1)) {
	my ($pdfid, $xmlid) = split("\x{0}", $value);
	$proc->($selfForProc, $uid, $pdfid, $xmlid); # TODO: error handling
    }

    $self->closeDB();
}

1;
