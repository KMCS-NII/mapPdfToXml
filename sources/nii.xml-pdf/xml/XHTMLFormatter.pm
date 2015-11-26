
package xml::XHTMLFormatter;

use strict;
use warnings;
use vars qw($VERSION);
$VERSION = '1.00';

use XML::LibXML;

my $doc;
my $root;
my @stack = ();

sub format
{
    my ($info, $format) = @_;

    $root = undef;
    @stack = ();
    $doc = XML::LibXML::Document->new('1.0', 'utf-8');
    if (exists($info->[0]->{'DOCTYPE'})) {
        my $str = $info->[0]->{'DOCTYPE'};
        $str =~ s/^\s*(\w+)//;
        my $rootnode = $1;
        $str =~ s/^\s*(\w+)\s*//;
        $str =~ s/"([^"]+?)"\s*//;
        my $public = $1 ne '' ? $1 : undef;
        $str =~ s/"([^"]+?)"\s*//;
        my $system = $1 ne '' ? $1 : undef;
        $doc->createInternalSubset($rootnode, $public, $system);
    }
    if (exists($info->[1])) {
        &create($info->[1]);
        if ($root) {
            $doc->setDocumentElement($root);
        }
    }
    return $doc->toString(defined($format) ? 1 : 0);
}

sub create {
    my $info = shift;
    my $node;
    for my $element (@$info) {
        if (ref($element) eq 'HASH') {
            if (exists($element->{'node name'})) {
                $node = $doc->createElement($element->{'node name'});
                for my $key (sort keys %$element) {
                    if ($key ne 'node name') {
                        $node->addChild($doc->createAttribute($key => $element->{$key}));
                    }
                }
                if (!$root) {
                    $root = $node;
                }
                else {
                    $stack[-1]->addChild($node);
                }
            }
        }
        elsif (ref($element) eq 'ARRAY') {
            push(@stack, $node);
            &create($element);
        }
        elsif ($node) {
            $node->addChild($doc->createTextNode($element));
        }
    }
    pop(@stack);
}

1;
