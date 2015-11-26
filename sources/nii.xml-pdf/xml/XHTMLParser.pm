
package xml::XHTMLParser;

use strict;
use warnings;
use vars qw($VERSION);
$VERSION = '1.00';

use XML::LibXML;
use XML::LibXML::Error;

my $ret;
my @stack = ();

sub parse
{
    my ($xhtmlStr) = @_;
    my $parser = XML::LibXML->new();
    my $dom;
    eval { 
        $dom = $parser->parse_string($xhtmlStr);
    };
    if ($@) {
         die $@;
    }
    my @parsed = ();
    my $doctype = $dom->internalSubset();
    if ($doctype =~ /^\s*<!DOCTYPE\s*([^>]+)>/) {
        push(@parsed, {'DOCTYPE' => $1});
    }
    else {
        push(@parsed, {});
    }
    my $topnode = {};
    my $root = $dom->documentElement();
    $topnode->{'node name'} = $root->nodeName();
    my @attributelist = $root->attributes();
    if (scalar(@attributelist)) {
        foreach my $ns (@attributelist) {
             $topnode->{$ns->nodeName()} = $ns->getData();
        }
    }
    @stack = ();
    my @result = ();
    $ret = \@result;
    push(@stack, $ret);
    &traverse($root);
    push(@parsed, [$topnode, @result]);

    return \@parsed;
}

sub traverse {
    my($root)= @_;
    for (my $fc = $root->firstChild(); $fc; $fc = $fc->nextSibling()) {
        my $node = {};
        if ($fc->nodeType() == XML_ELEMENT_NODE) {
            $node->{'node name'} = $fc->nodeName();
            my @attributelist = $fc->attributes();
            if (scalar(@attributelist)) {
                foreach my $ns (@attributelist) {
                    $node->{$ns->nodeName()} = $ns->nodeValue();
                }
            }
            push(@$ret, [$node]);
            push(@stack, $ret);
            $ret = $ret->[-1];
            &traverse($fc);
        }
        elsif ($fc->nodeType() == XML_TEXT_NODE) {
            my $data = $fc->nodeValue();
            chomp $data;
            $data =~ s/^\s*$//g;
            if ($data ne '') {
                push(@$ret, $data);
            }
        }
    }
    $ret = pop(@stack);
}

1;
