#!/usr/bin/perl
#-*- coding:utf-8 -*-

use strict;
use warnings;

use utf8;

use Test::More tests => 5;

require_ok( 'map::Mapper' );

{
    my $result = TextScanner::buildCharMap("abc");
    is_deeply([[0,0],[1,1],[2,2]], $result, "without normalization");
}
{
    my $result = TextScanner::buildCharMap("aⅢb");
    is_deeply([[0,0],[1,1],[2,4]], $result, "with normalization");
}
{
    my $result = TextScanner::buildCharMap("Ⅲb");
    is_deeply([[0,0],[1,3]], $result, "with normalization at the head");
}
{
    my $result = TextScanner::buildCharMap("aⅢ");
    is_deeply([[0,0],[1,1]], $result, "with normalization at the tail");
}
exit(0);
