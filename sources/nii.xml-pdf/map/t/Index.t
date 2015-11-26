#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 11;

require_ok 'map::Index';

my $articleInfo = JSON::decode_json(<<EOS);
[
  {"class":"paragraph"},
  [
    {"id":"1","page":"1"}
  ],
  [
    {"id":"2","page":"2"}
  ],
  [
    {"class":"equation"},
    [
      {"id":"3","page":"2"}
    ]
  ]
]
EOS

my $db = new KyotoCabinet::DB;
if (!$db->open('*', $db->OWRITER | $db->OCREATE | $db->OTRUNCATE)) {
    die "open error: ".$db->error."\n";
}
my $index = new map::Index($db);
ok( defined $index && $index->isa('map::Index'), 'map::Index constructor' );

{
    my $list = $index->build('doc',$articleInfo, "class", "id", "page");
    my %actual = ();
    &dbToHash($db, \%actual);
    is_deeply(\%actual, 
              {
                "doc\x{0}1\0paragraph" => '["1"]',
                "doc\x{0}2\0paragraph" => '["2","3"]',
                "doc\x{0}2\0equation"  => '["3"]'
              },
              'build()') or diag explain(\%actual);
}

{
    my $list = $index->gatherForValues();
    my %actual = ();
    &dbToHash($db, \%actual);
    is_deeply(\%actual, 
              {
                "doc\x{0}1\0paragraph" => '["1"]',
                "doc\x{0}2\0paragraph" => '["2","3"]',
                "doc\x{0}2\0equation"  => '["3"]',
                "doc\x{0}\0paragraph"  => '["1","2","3"]',
                "doc\x{0}\0equation"   => '["3"]'
              },
              'gatherForValues()') or diag explain(\%actual);
}

{
    my $list = $index->gatherForPages();
    my %actual = ();
    &dbToHash($db, \%actual);
    is_deeply(\%actual, 
              {
                "doc\x{0}1\0paragraph" => '["1"]',
                "doc\x{0}2\0paragraph" => '["2","3"]',
                "doc\x{0}2\0equation"  => '["3"]',
                "doc\x{0}\0paragraph"  => '["1","2","3"]',
                "doc\x{0}\0equation"   => '["3"]',
                "doc\x{0}1\0"          => '["1"]',
                "doc\x{0}2\0"          => '["2","3"]',
                "doc\x{0}\0"           => '["1","2","3"]',

              },
              'gatherForPages()') or diag explain(\%actual);
}

{
    my $actual = $index->get("doc", "paragraph", "2");
    is_deeply($actual, ["2","3"], 'get($value, $page)') or diag explain($actual);
}

{
    my $actual = $index->get("doc", "paragraph");
    is_deeply($actual, ["1","2","3"], 'get($value, undef)') or diag explain($actual);
}

{
    my $actual = $index->get("doc", undef, "2");
    is_deeply($actual, ["2","3"], 'get(undef, $page)') or diag explain($actual);
}

{
    my $actual = $index->get("doc", undef, undef);
    is_deeply($actual, ["1","2","3"], 'get(undef, undef)') or diag explain($actual);
}

{
    my $actual = $index->get("doc", "not", "exists");
    is_deeply($actual, [], 'get() not found') or diag explain($actual);
}

$db->close;

{
    eval {
        my $actual = $index->get('doc');
    };
    if ($@) {
        like($@, '/db error: invalid operation: not opened/', "db error") or diag explain($@);
    } else {
        diag "get() returns without error.";
    }
}

exit 0;

sub dbToHash()
{
    my($db, $hash) = @_;

    my $cur = $db->cursor;
    $cur->jump;
    while (my ($key, $value) = $cur->get(1)) {
        $hash->{$key} = $value;
    }
    $cur->disable;
}
