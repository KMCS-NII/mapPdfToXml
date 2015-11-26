
package map::Index;

use strict;
use warnings;
use vars qw($VERSION);

$VERSION = '1.10';

use KyotoCabinet;
use JSON;

sub new {
    my $class = shift;
    my $db = shift || die "An argument required map::Index::new()\n";
#   if (ref($db) ne 'KyotoCabinet::DB') {
#       die "Invalid argument map::Index::new()\n";
#   }
    return bless {
        db => $db,
        result => (),
        attrs => ()
    }, $class;
}

sub build()
{
    my($self, $articleUUID, $article, $attr, $id, $page) = @_;

    unless (defined($articleUUID) &&
	    defined($article) &&
	    defined($attr) &&
	    defined($id) &&
	    defined($page)) {
        die "5 arguments required map::Index::build()\n";
    }
    my $db = $self->{db};
#    if (!$db->clear) {
#        die "db clear failure: ".$db->error."\n";
#    }
    $self->{result} = ();
    $self->{attrs} = ();
    $self->_build($article, $attr, $id, $page);

    for my $key (keys %{$self->{result}}) {
        my @value = @{$self->{result}{$key}};
        @value = sort do { my %h; grep { !$h{$_}++ } @value };
        if (!$db->set($articleUUID."\0".$key, JSON::encode_json(\@value))) {
            die "db set error: ".$db->error."\n";
        }
    }
    return 0;
}

sub _build()
{
    my($self, $article, $attr, $id, $page) = @_;

    my $pushed = 0;
    for my $element (@$article) {

        if (ref($element) eq 'HASH' && exists($element->{$attr})) {
            push(@{$self->{attrs}}, $element->{$attr});
	    $pushed = 1;
        }
	elsif (ref($element) eq 'HASH' && exists($element->{$page})) {
	    if (!exists($element->{$id})) {
		warn "WARN: boundary without id.\n";
		next;
	    }
	    for my $class (@{$self->{attrs}}) {
		my $key = $element->{$page}."\0$class";
		push(@{$self->{result}{$key}}, $element->{$id});
	    }
	}
        elsif (ref($element) eq 'ARRAY') {
	    $self->_build($element, $attr, $id, $page);
	}
    }
    if($pushed) {
	pop(@{$self->{attrs}});
    }
}

sub gatherForValues()
{
    my $self = shift;
    my $db = $self->{db};
    $self->{result} = ();
    my $cur = $db->cursor;
    $cur->jump;
    while (my ($key, $value) = $cur->get(1)) {
        my ($articleUUID, undef, $attr) = split(/\0/, $key);
        $value = JSON::decode_json($value);
        push(@{$self->{result}{"$articleUUID\0\0$attr"}}, @$value);
    }
    $cur->disable;
    for my $key (keys %{$self->{result}}) {
        my @value = @{$self->{result}{$key}};
        @value = sort do { my %h; grep { !$h{$_}++ } @value };
        if (!$db->set($key, JSON::encode_json(\@value))) {
            die "db set error: ".$db->error."\n";
        }
    }
    return 0;
}

sub gatherForPages()
{
    my $self = shift;
    my $db = $self->{db};
    $self->{result} = ();
    my $cur = $db->cursor;
    $cur->jump;
    while (my ($key, $value) = $cur->get(1)) {
        my ($articleUUID, $id, undef) = split(/\0/, $key);
        $value = JSON::decode_json($value);
        push(@{$self->{result}{"$articleUUID\0$id\0"}}, @$value);
        push(@{$self->{result}{"$articleUUID\0\0"}}, @$value);
    }
    $cur->disable;
    for my $key (keys %{$self->{result}}) {
        my @value = @{$self->{result}{$key}};
        @value = sort do { my %h; grep { !$h{$_}++ } @value };
        if (!$db->set($key, JSON::encode_json(\@value))) {
            die "db set error: ".$db->error."\n";
        }
    }
    return 0;
}

sub get()
{
    my $self = shift;
    my $articleUUID = shift;
    unless(defined($articleUUID)) {
	die "article UUID required for map::Index::get()\n";
    }
    my $value = shift;
    unless(defined($value)) {
	$value = '';
    }
    my $page = shift;
    unless(defined($page)) {
	$page = '';
    }
    my $db = $self->{db};
    my $result = $db->get("$articleUUID\0$page\0$value");
    if ($result) {
        return JSON::decode_json($result);
    }
    elsif ($db->error <=> KyotoCabinet::Error::NOREC) {
        die "db error: ".$db->error."\n";
    }
    return [];
}

1;
