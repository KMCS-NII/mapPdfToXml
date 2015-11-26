#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests=>3;

use LWP::UserAgent;
use JSON;

my $URL = 'http://localhost/pdf-xml/Map';

my $ua = new LWP::UserAgent();

{
    my $q = {
	     'jsonrpc' => '2.0',
	     'method' => 'getArticleAsXML',
	     'params' => { 'articleUID' => '1_1_1' }
	    };
    my $response = $ua->post($URL, Content => JSON::encode_json($q));

    is($response->code, 200, "getArticleAsXML : JSON 2.0 : Status code");
    my $result = JSON::decode_json($response->content);
    is($result->{error}->{code}, 404, " : : Error code");
    is($result->{error}->{message}, "Not found." , " : : Error message");
}


exit(0);
