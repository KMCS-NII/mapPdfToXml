#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 5;

require_ok 'xml::XHTMLFormatter';

{
    my $info =
      [
       {
	'DOCTYPE'=>'html PUBLIC "-//W3C//DTD XHTML 1.1 plus MathML 2.0//EN" "http://www.w3c.org/TR/MathML2/dtd/xhtml-math11-f.dtd"',
       },
       [
	{
	 'node name'=>'html',
	 'xmlns'=>'http://www.w3.org/1999/xhtml',
	 'xmlns:m'=>'http://www.w3.org/1998/Math/MathML',
	 'xmlns:svg'=>'http://www.w3.org/2000/svg'
	}
       ]
      ];

    my $actual = xml::XHTMLFormatter::format($info);

    ok(open(my $actualFH, '<', \$actual));

    is(<$actualFH>, '<?xml version="1.0" encoding="utf-8"?>'."\n", 'xml header');
    is(<$actualFH>, '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1 plus MathML 2.0//EN" "http://www.w3c.org/TR/MathML2/dtd/xhtml-math11-f.dtd">'."\n", 'doctype');

    my @lines = <$actualFH>;
    close($actualFH);

    my $normalized = '';
    foreach my $line (@lines) {
	chomp($line);
	$line =~ s/^\s+//;
	$line =~ s/\s+$//;
	$normalized .= $line;
    }

    is($normalized, '<html xmlns="http://www.w3.org/1999/xhtml" xmlns:m="http://www.w3.org/1998/Math/MathML" xmlns:svg="http://www.w3.org/2000/svg"/>', 'html');
}
