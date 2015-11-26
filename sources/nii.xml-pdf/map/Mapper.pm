
use strict;
use warnings;

use KyotoCabinet;
use XML::LibXML;
use JSON;
use Unicode::Normalize;
use List::BinarySearch::XS qw( binsearch_pos );
use Data::Dumper;

$|=1;

package DEBUG;

my $config =
  {
   "pdf boundary element"=>
   {
    "name"=>"span",
    "namespace"=>
    {
     "alias"=>"pdf",
     "uri"=>"http://kmcs.nii.ac.jp/#ns"
    },
    "id attr name"=>"boundaryid",
    "page attr name"=>"page"
   },
   "skipConditions"=>
   {
    "head:"=>1,
    "div:navbar"=>1
   }
};

use constant SEARCH => 0;
use constant SEARCH_EXACT_MATCH => 0;
use constant SEARCH_CHAR => 0;

use constant SHOW_WHOLE_TEXT => 0;

use constant INSERT_RANGE_NODE => 0;

use constant DUMP_INSERT_RANGE_MDOE => 0;

use constant STR_DUMP => 0;

use constant RESULT => 0;

# --------------------------------
package CharMap;
use constant ALLOW_LIGATURE => 1; # if Ligature, shift to left

# --------------------------------
package Str;

sub new {
    my ($class, $str, $pos) = @_;
    unless(defined($str)) {
	die "str required.";
    }

    return bless { str=>$str, pos=>$pos, ranges=>[] }, $class;
}

sub mapBoundary {
    my ($self, $range, $boundary) = @_;
    my $p =
	List::BinarySearch::XS::binsearch_pos {
	    ${a} <=> ${b}->[0]
    }
    $range->{pos},
    @{$self->{ranges}};

    splice(@{$self->{ranges}}, $p, 0, [$range->{pos}, $range->{length}, $boundary]);
}

sub fillUnmappedRanges
{
    my ($self) = @_;
    my $nextP = $self->{pos};
    for(my $i = 0; $i < int(@{$self->{ranges}}); $i++) {
	my $curP = $self->{ranges}->[$i]->[0];
	if($curP - $nextP > 0) {

	    splice(@{$self->{ranges}}, $i, 0, [$nextP, $curP - $nextP, undef]);

	    $nextP = $curP + $self->{ranges}->[$i+1]->[1];
	    
	    $i++;

	} elsif($curP - $nextP < 0) {
	    warn YAML::Dump([$self]);
	    die "Conflicted."; # TODO
	} else {
	    $nextP = $curP + $self->{ranges}->[$i]->[1];
	}
    }
    if($nextP < $self->{pos} + length($self->{str})) {
	# warn $self->{pos}." ".length($self->{str})." ".$nextP." ".($self->{pos} + length($self->{str}));
	push(@{$self->{ranges}}, [$nextP, $self->{pos} + length($self->{str}) - $nextP, undef]);
    }
}

sub dump
{
    my ($self, $charMap) = @_; # NOTICE: charMap is TextScanner !

    my $infoArr = [];

#    warn "Str dump\n".Encode::encode('utf-8', $self->{str})."\n";
#    warn Data::Dumper->Dump($self->{ranges}), "\n====\n";

    foreach my $range (@{$self->{ranges}}) {

	my $elm = undef;

	# - convert pos from normalized-base to original-base
	# TODO:

	my $myOrgPos = $charMap->toOrgPos($self->{pos});
	my $rangeOrgPos = $charMap->toOrgPos($range->[0],
					     CharMap::ALLOW_LIGATURE);
	my $rangeOrgTailPos = $charMap->toOrgPos($range->[0] + $range->[1],
						 CharMap::ALLOW_LIGATURE) - 1;
	die unless(defined($myOrgPos));

	my $substr = substr($charMap->{fullText},
			    $rangeOrgPos,
			    $rangeOrgTailPos - $rangeOrgPos + 1);

	if(DEBUG::STR_DUMP) {
#	    warn "my org pos: ".$myOrgPos."-".($myOrgPos+length($self->{str})-1)."\n";
	    warn "range: ".$rangeOrgPos."-".$rangeOrgTailPos."\n";
	    warn Encode::encode('utf-8', $self->{str}),"\n";
	    warn "\n";
#	    warn Encode::encode('utf-8', $substr),"\n";
	}

	if(defined($range->[2])) {

	    $elm = $range->[2];

	    unless(ref($elm) eq 'ARRAY') {
		die Data::Dumper->Dump([$elm]);
	    }

	    push(@$elm,
		 $substr);

	} else {
	    # gap

	    $elm = [
		{
		    'node name'=>'pdf:unmapped'
		},
		$substr
		];
	}

	push(@$infoArr, $elm);
    }

    return $infoArr;
}

# --------------------------------
package TextScanner;

use constant DEBUG_THIS_FILE => 0;

sub toOrgPos
{
    my ($self, $normalizedPos, $allowLigature) = @_;

    if($normalizedPos == length($self->{wholeText})) {
	return length($self->{fullText});
    }
    
    my $pos = 
	List::BinarySearch::XS::binsearch_pos {
	    ${a} <=> ${b}->[1]
    }
    $normalizedPos,
    @{$self->{charMap}};

    my $posInfo = $self->{charMap}->[$pos];

    use YAML;

    die "Unexpected situation $normalizedPos $pos/".int(@{$self->{charMap}})." ".length($self->{wholeText})."\n".YAML::Dump([$self->{charMap}]) unless(defined($posInfo));

#    die "Unexpected situation\n".Encode::encode('utf-8', join("\n", ($posInfo->[1], $normalizedPos, substr($self->{wholeText}, 17175, 10), substr($self->{fullText}, 20488, 10))))."\n".Data::Dumper->Dump([$self->{charMap}]) unless($posInfo->[1] == $normalizedPos);
    unless($posInfo->[1] == $normalizedPos) {
	warn "Ligature problem occured.\n";
	if($allowLigature == CharMap::ALLOW_LIGATURE) {
	    # ok
	} else {
	    return undef;
	}
    }

    return $posInfo->[0];
}

sub applyInsertions
{
    my ($self) = @_;

    for(my $i = int(@{$self->{posVsElm}})-1; $i >= 0; $i--) {

	my $iter = $self->{posVsElm}->[$i];

	my $parent = $iter->[2];
	my $str = $parent->[$iter->[3]];

	$str->fillUnmappedRanges();
#	print "--------------------------------\n", Data::Dumper->Dump($str->dump()), "\n";
	splice(@$parent, $iter->[3], 1, @{$str->dump($self)});
    }
}

sub applyInsertions_inner
{
    my ($self, $articleInfo) = @_;

    for(my $i = 1; $i < int(@$articleInfo); $i++) {

	next if($self->isSkipNode($articleInfo->[$i]));

	if(ref($articleInfo->[$i]) eq 'ARRAY') {
	    $self->applyInsertions_inner($articleInfo->[$i]);

	} else {
	    

	    my $prevPos = length($self->{wholeText});
	    my $normStr = normalizeText($articleInfo->[$i]);
	    $self->{wholeText} .= $normStr;
	    $self->{fullText} .= $articleInfo->[$i];
	    $articleInfo->[$i] = new Str($normStr, $prevPos);
#	    warn "new str ".$i." ".Encode($normStr)." ".$prevPos;
	    push(@{$self->{posVsElm}},
		 [$prevPos,
		  length($self->{wholeText})-1,
		  $articleInfo,
		  $i]);
	}
    }
}

sub isSkipNode
{
    my ($self, $node) = @_;

    return 0 unless(ref($node) eq 'ARRAY');

    my $nodeName = $node->[0]->{'node name'};
    my $class = $node->[0]->{'class'} || '';

    return defined($self->{skipConditions}->{$nodeName.':'.$class});
}

sub extractText
{
    my ($self) = @_;

    $self->{wholeText} = ''; # normalized
    $self->{fullText} = ''; # raw
    $self->{posVsElm} = [];


    $self->extractText_inner($self->{articleInfo});
}

sub extractText_inner
{
    my ($self, $articleInfo) = @_;

    for(my $i = 1; $i < int(@$articleInfo); $i++) {

	next if($self->isSkipNode($articleInfo->[$i]));

	if(ref($articleInfo->[$i]) eq 'ARRAY') {
	    $self->extractText_inner($articleInfo->[$i]);

	} else {
	    my $prevPos = length($self->{wholeText});
	    my $normStr = normalizeText($articleInfo->[$i]);
	    $self->{fullText} .= $articleInfo->[$i];
	    $self->{wholeText} .= $normStr;
	    $articleInfo->[$i] = new Str($normStr, $prevPos);
#	    warn "new str ".$i." ".Encode::encode('utf-8', $normStr)." ".$prevPos;
	    push(@{$self->{posVsElm}},
		 [$prevPos,
		  length($self->{wholeText})-1,
		  $articleInfo,
		  $i]);
	}
    }

#    return ($wholeText, \@posVsElm);
}

sub buildCharMap
{
    my ($str) = @_;

    my @map;
    my $wholeNormalized = normalizeText($str);
    my $prevMatchedLen = 0;

    for(my $p=0; $p <length($str); $p++) {
#	if($p % 1000 == 0) {
#	    warn $p." ".length($str);
#	}

	my $normalized = normalizeText(substr($str, 0, $p+1));
	my $matchedLen = 0;
	my $subA_ = substr($wholeNormalized, 0, $prevMatchedLen);
	my $subA = substr($subA_, -16, 16);
#	print "SUBA ".$subA."\n";
	my $subB_ = substr($normalized, 0, $prevMatchedLen);
	my $subB = substr($subB_, -16, 16);
	unless($subA eq $subB)
	{
#	    die "Unexpected situation.\n".(substr(substr($wholeNormalized, 0, $prevMatchedLen), -16, 16) eq substr(substr($normalized, 0, $prevMatchedLen), -16, 16)).".";
#	    print length(substr(substr($wholeNormalized, 0, $prevMatchedLen), -16, 16)), ".\n";
#	    print length($subA)."\n";
#	    print $subB, ".\n";
	    die "Unexpected situation.";
	};

	$matchedLen = $prevMatchedLen;
	for(my $pt = $prevMatchedLen; $pt < length($normalized); $pt++) {
	    last unless(substr($wholeNormalized, $pt, 1) eq substr($normalized, $pt, 1));
	    $matchedLen++;
	}
	if($prevMatchedLen < $matchedLen) {
	    push(@map, [$p, $prevMatchedLen]);
	    $prevMatchedLen = $matchedLen;
	    next;
	} elsif($prevMatchedLen > $matchedLen) {
	    die "Unexpected situation.";
	}
    }

    # assert
    
    my $mapSize = int(@map);
    if($map[-1]->[0] == length($str)-1) {
	# do nothing
    } else {
	push(@map, [length($str)-1, $prevMatchedLen]);
    }

#    print Data::Dumper->Dump(\@map);

    return \@map;
}

sub new
{
    my ($class, $articleInfo) = @_;
    unless(defined($articleInfo)) {
	die "articleInfo required.";
    }

    my $self =  bless {
	articleInfo => $articleInfo,
	reservations => [],
	skipConditions => $config->{skipConditions},
	config => $config
    }, $class;

    $self->extractText();

    $self->{charMap} = buildCharMap($self->{fullText});

    return $self;
}

sub normalizeText
{

    my ($str) = @_;
    $str = Unicode::Normalize::NFKC($str);
    $str =~ s/ +//g;
    $str =~ s/\n//g;
    $str =~ s/-//g;
    $str =~ s/(?<=[\p{InHiragana}\p{InKatakana}\p{InCJKUnifiedIdeographs}]) (?=[\p{InHiragana}\p{InKatakana}\p{InCJKUnifiedIdeographs}])//g;
    return $str;
}

sub clearReservations
{
    my ($self) = @_;
    $self->{reservations} = [];
}

sub reserve
{
    return;

    my ($self, $range) = @_;
    if($range->{length} < 1) {
	die "assert failed."; 
    }
    my $rangeBeginIndex =
	List::BinarySearch::XS::binsearch_pos {
	    ${a} <=> ${b}->[0]
    }
    $range->{pos},
    @{$self->{reservations}};

    my $rangeEndIndex =
	List::BinarySearch::XS::binsearch_pos {
	    ${a} <=> ${b}->[0]
    }
    $range->{pos} + $range->{length} - 1,
    @{$self->{reservations}};

    my $rangeBefore = $self->{reservations}->[$rangeBeginIndex];
    my $rangeAfter = $self->{reservations}->[$rangeEndIndex];

    while(1) {
	# case: the range before is undef. append the new range at the tail.
	unless(defined($rangeBefore)) {
	    push(@{$self->{reservations}}, [$range->{pos}, $range->{length}]);
	    last;
	}

	# case: the range before index == 0 && range after == 0.
	# insert the new range at the head.
	if($rangeBeginIndex == 0 && $rangeEndIndex == 0) {
	    unshift(@{$self->{reservations}}, [$range->{pos}, $range->{length}]);
	    last;
	}

	# case: range before index == range after index.
	if($rangeBeginIndex == $rangeEndIndex) {
	    if($rangeBefore->[0] + $rangeBefore->[1] <= $range->{pos}) {
		# - case: not conflicted. insert the new range.
		splice(@{$self->{reservations}},
		       $rangeBeginIndex,
		       0,
		       [$range->{pos}, $range->{length}]);
	    } else {
		# - case: conflicted. warn
		warn "Conflicted\n";
		$rangeBefore->[1] = ($range->{pos} + $range->{length}) - $rangeBefore->[0];
	
	    }
	    last;
	}

	# case: others.
	{
	    die "NYI"; # FIXME
	}


	die "Unexpected situation";
    }

}

# return undef if there are multiple match ranges.
sub search_exactMatch
{
    my ($self, $normalizedNeedle) = @_;

    my $scaneeText = $self->{wholeText};

    {
	my $len = length($normalizedNeedle); # TODO: ad-hoc
	if($len < 1) {
	    return undef;
	}
    }

    if(DEBUG::SEARCH_EXACT_MATCH) {
	warn ":::".Encode::encode('utf-8', $normalizedNeedle)."\n";
    }

    my $pos = index($scaneeText, $normalizedNeedle);
    if($pos < 0) {
	return undef;
    }

    if(index($scaneeText, $normalizedNeedle, $pos+1) >= 0) {
	# multiple match
	return undef;
    }

    my $len = length($normalizedNeedle);

    if(DEBUG::SEARCH_EXACT_MATCH) {
	warn "CAN: ".Encode::encode('utf-8', substr($scaneeText, $pos, $len))."\n";
    }
    return {'pos'=>$pos, 'length'=>$len};
}

sub search
{
    my ($self, $needle) = @_;

    $needle = normalizeText($needle);

    return $self->search_exactMatch($needle);
}

sub searchChar
{
    my ($needle, $scanee, $firstOfNeedle) = @_;

    if(DEBUG::SEARCH_CHAR) {
	warn "begin searchChar\n";
	warn "needle ".Encode::encode('utf-8', $needle)."\n";
	warn "scanee ".Encode::encode('utf-8', substr($scanee, 0, length($needle)))."\n";
    }

    my $needleChar = substr($needle, 0, 1);

    my $best = int(length($needle) * .3); #FIXME
    my $len = 0;
    my $pos = 0;

    if($needleChar eq substr($scanee, 0, 1)) {
	if(length($needle) == 1) {
	    if(DEBUG::SEARCH_CHAR > 1) {
		warn "exact matched the last \n";
	    }
	    return (0, 0, 1);
	}
	my ($matched, $p, $l) = searchChar(substr($needle, 1), substr($scanee, 1));

	if(DEBUG::SEARCH_CHAR > 1) {
	    warn "exact matched \n";
	    warn "matched = $matched\n";
	    warn "length = ".($l+1)."\n";
	}
	return ($matched, 0, 1 + $l); # distance, scanee pos of matched, scanee len to the last matched
    }

    if(length($needle) == 1) {
	return (1, 0, 0);
    }
    {
	if(DEBUG::SEARCH_CHAR > 1) {
	    warn "Skip needle\n";
	}
	my ($skipNeedle, $p, $l) = searchChar(substr($needle, 1), $scanee);
	$skipNeedle+=1;
	if($best > $skipNeedle) {
	    $best = $skipNeedle;
	    $len = $l;

	    if(DEBUG::SEARCH_CHAR > 1) {
		warn "SkipN ".$best." ".Encode::encode('utf-8', substr($scanee, $p, $len))."\n";
	    }
	}
    }

    if(DEBUG::SEARCH_CHAR > 1) {
	warn "Skip scanee\n";
	warn "pos ".index($scanee, $needleChar, 1)."\n";
    }
    my $P = index($scanee, $needleChar, 1);
    unless($P >= 0) {
	# this needle not found
	if(DEBUG::SEARCH_CHAR > 1) {
	    warn "Not found\n";
	}
	return (length($needle), 0, 0);
    }

    for(my $p = $P;
	$p >= 0;
	$p = index($scanee, $needleChar, $p+1)) {

	last if((!defined($firstOfNeedle)) && $p > length($needle) * .1);

	my ($skipScanee, $posCandidate, $l) = searchChar($needle, substr($scanee, $p), 1);
	$skipScanee += (defined($firstOfNeedle) ? 0 : $p);
	if($best > $skipScanee) {
	    $best = $skipScanee;
	    $len = $l;
	    $pos = $p; # defined($firstOfNeedle) ? $posCandidate : 0;
	}
	last if($skipScanee > length($needle) * .1);
	
    }

    if(DEBUG::SEARCH_CHAR > 1) {

	warn "ndl: ".Encode::encode('utf-8', $needle)."\n";
	warn "str: ".Encode::encode('utf-8', substr($scanee, $pos, $len))."\n";
	warn "best:".$best. "\n";
    }
    return ($best, $pos, $len);
}

sub insertRangeNode
{
    my ($self, $range, $boundary, $page) = @_;
    my $rangeHeadIndex =
	List::BinarySearch::XS::binsearch_pos {
	    ${a} <=> ${b}->[1]
    }
    $range->{pos},
    @{$self->{posVsElm}};

#    warn "\n";
    if(DEBUG::INSERT_RANGE_NODE) {
	warn "range Head index = ".$rangeHeadIndex."\n";
	warn Encode::encode('utf-8', $boundary->{text})."\n";
	warn Encode::encode('utf-8', $self->{posVsElm}->[$rangeHeadIndex]->[2]->[$self->{posVsElm}->[$rangeHeadIndex]->[3]]->{str})."\n";
	warn "range pos = ".$range->{pos}, "\n";
	warn YAML::Dump($self->{posVsElm}->[$rangeHeadIndex])."\n";
	warn int(@{$self->{posVsElm}})."\n";
    }

    my $isRangeHeadAdjustedToNodeHead =
	$range->{pos} == $self->{posVsElm}->[$rangeHeadIndex]->[0];

    my $rangeTailIndex =
	List::BinarySearch::XS::binsearch_pos {
	    ${a} <=> ${b}->[1]
    }
    $range->{pos} + $range->{length} -1,
    @{$self->{posVsElm}};

    if(DEBUG::INSERT_RANGE_NODE) {
	warn "range Tail index = ".$rangeTailIndex."\n";
	warn "range pos = \n".YAML::Dump($self->{posVsElm}->[$rangeTailIndex]->[2]->[$self->{posVsElm}->[$rangeTailIndex]->[3]])."\n";
    }

    my $isRangeTailAdjustedToNodeTail;
    if($rangeTailIndex == int(@{$self->{posVsElm}})-1) {
	$isRangeTailAdjustedToNodeTail =
	    $range->{pos} + $range->{length} ==
	    length($self->{wholeText});
    } else {
	$isRangeTailAdjustedToNodeTail =
	    $range->{pos} + $range->{length} ==
	    $self->{posVsElm}->[$rangeTailIndex+1]->[0];
    }


    my $ns = $self->{config}->{'pdf boundary element'}->{namespace}->{alias}.':';
    my $info = {
	'node name'=>
	    $ns.$self->{config}->{'pdf boundary element'}->{name}
    };

    if(defined($page)) {
	$info->{$ns.'page'} = $page;
    }

    use constant INFO_NODES =>
	[
	 ['boundarysequence','sequence'],
	 ['left','left'],
	 ['top','top'],
	 ['width','width'],
	 ['height','height'],
	 ['boundarytype','type'],
	 ['text','text'],
	 ['page','page'],
	 ['boundaryid','id']
	];

    foreach my $infoNode (@{INFO_NODES()}) {
	if(defined($boundary->{$infoNode->[1]})) {
	    $info->{$ns.$infoNode->[0]} = $boundary->{$infoNode->[1]};
	}
    }

    use constant INFO_NODES_FONT =>
	[
	 ['fontfamily','family'],
	 ['fontsize','size'],
	 ['fontcolor','color'],
	];

    foreach my $infoNode (@{INFO_NODES_FONT()}) {
	if(defined($boundary->{font}->{$infoNode->[1]})) {
	    $info->{$ns.$infoNode->[0]} = $boundary->{font}->{$infoNode->[1]};
	}
    }


    if($rangeHeadIndex == $rangeTailIndex &&
       $isRangeHeadAdjustedToNodeHead &&
       $isRangeTailAdjustedToNodeTail) {
	# |[    ]|

	my $targetNode = $self->{posVsElm}->[$rangeHeadIndex]->[2]->[$self->{posVsElm}->[$rangeHeadIndex]->[3]];


#	$self->{posVsElm}->[$rangeHeadIndex]->[2]->[$self->{posVsElm}->[$rangeHeadIndex]->[3]] = [
#	    $info,
#	    $targetNode
#	];

	$targetNode->mapBoundary($range, [$info]);

	if(DEBUG::INSERT_RANGE_NODE) {
	    warn "Done";
	}
	return;
    }

    
    if($rangeHeadIndex == $rangeTailIndex) {

	my $targetNode = $self->{posVsElm}->[$rangeHeadIndex]->[2]->[$self->{posVsElm}->[$rangeHeadIndex]->[3]];

	# assert
	{
	    my $type = ref($targetNode);
	    die Data::Dumper->Dump([$targetNode]) if($type ne 'Str');
	}

	if($isRangeHeadAdjustedToNodeHead &&
	   (!$isRangeTailAdjustedToNodeTail)) {
	    # |[  ]..|

	    my $rangeNode = substr($targetNode, 0, $range->{length});

	    if(DEBUG::DUMP_INSERT_RANGE_MDOE) {
		$info->{mode} = 'mode:lefty';
	    }

	    $targetNode->mapBoundary($range, [$info]);

#	    $self->{posVsElm}->[$rangeHeadIndex]->[2]->[$self->{posVsElm}->[$rangeHeadIndex]->[3]] = [
#		$info,
#		$rangeNode
#		];

#	    splice(@{$self->{posVsElm}->[$rangeHeadIndex]->[2]},
#		   $self->{posVsElm}->[$rangeHeadIndex]->[3] + 1,
#		   0,
#		   $rightNode
#		   );

	    if(DEBUG::INSERT_RANGE_NODE) {
		warn "Done";
	    }
	    return;
	    

	} elsif(!$isRangeHeadAdjustedToNodeHead &&
	   ($isRangeTailAdjustedToNodeTail)) {
	    # |..[  ]|

	    my $rangeNode = substr($targetNode, -($range->{length}));

	    if(DEBUG::DUMP_INSERT_RANGE_MDOE) {
		$info->{mode} = 'mode:righty';
	    }

	    $targetNode->mapBoundary($range, [$info]);
#	    $self->{posVsElm}->[$rangeHeadIndex]->[2]->[$self->{posVsElm}->[$rangeHeadIndex]->[3]] = [
#		$info,
#		$leftNode
#		];
#
#	    splice(@{$self->{posVsElm}->[$rangeHeadIndex]->[2]},
#		   $self->{posVsElm}->[$rangeHeadIndex]->[3] + 1,
#		   0,
#		   $targetNode
#		   );



	    if(DEBUG::INSERT_RANGE_NODE) {
		warn "Done";
	    }
	    return;
	    
	} else {
	    # |..[  ]..|
	    my $rangeNode = substr($targetNode, -($range->{length}));

	    # TODO: recalc width for each range

	    if(DEBUG::DUMP_INSERT_RANGE_MDOE) {
		$info->{mode} = 'mode:center';
	    }

	    $targetNode->mapBoundary($range, [$info]);

	    if(DEBUG::INSERT_RANGE_NODE) {
		warn "Done";
	    }
	    return;
	}
    }

    if($isRangeHeadAdjustedToNodeHead &&
       $isRangeTailAdjustedToNodeTail) {
	# |[   |...|    ]|

	if(DEBUG::DUMP_INSERT_RANGE_MDOE) {
	    $info->{mode} = 'mode:multi';
	}
	my $assignedLen = 0;
	my $assignedWidth = 0;
	my $totalWidth = $info->{'pdf:width'};
	my $firstLeft = $info->{'pdf:left'};

	for(my $i = $rangeHeadIndex; $i <= $rangeTailIndex; $i++) {
	    my $targetNode = $self->{posVsElm}->[$i]->[2]->[$self->{posVsElm}->[$i]->[3]];
	    my $len = length($targetNode->{str});
	    $assignedLen += $len;
	    my $_assignedWidth = $assignedLen / $range->{length} * $totalWidth;

	    my $_info = JSON::from_json(JSON::to_json($info));
	    $_info->{'pdf:left'} = $firstLeft + $assignedWidth;
	    $_info->{'pdf:width'} = $_assignedWidth - $assignedWidth;
	    $assignedWidth = $_assignedWidth;

	    $targetNode->mapBoundary
		({'pos'=>$targetNode->{pos},
		  'length'=>$len},
		 [$_info]);
	}

	if(DEBUG::INSERT_RANGE_NODE) {
	    warn "Done";
	}
	die unless($range->{length} == $assignedLen);

	return;
	    
    } elsif($isRangeHeadAdjustedToNodeHead) {
	# |[    |  ]..|

	if(DEBUG::DUMP_INSERT_RANGE_MDOE) {
	    $info->{mode} = 'mode:multi(left)';
	}
#	warn "elm\n".YAML::Dump($self->{posVsElm}->[$rangeHeadIndex]);
#	warn "range\n".YAML::Dump($range);

	my $assignedLen = 0;
	my $assignedWidth = 0;
	my $totalWidth = $info->{'pdf:width'};
	my $firstLeft = $info->{'pdf:left'};

	for(my $i = $rangeHeadIndex; $i < $rangeTailIndex; $i++) {
	    my $targetNode = $self->{posVsElm}->[$i]->[2]->[$self->{posVsElm}->[$i]->[3]];
	    my $len = length($targetNode->{str});
	    $assignedLen += $len;
	    my $_assignedWidth = $assignedLen / $range->{length} * $totalWidth;

	    my $_info = JSON::from_json(JSON::to_json($info));
	    $_info->{'pdf:left'} = $firstLeft + $assignedWidth;
	    $_info->{'pdf:width'} = $_assignedWidth - $assignedWidth;
	    $assignedWidth = $_assignedWidth;

	    $targetNode->mapBoundary
		({'pos'=>$targetNode->{pos},
		  'length'=>$len},
		 [$_info]);
	}

	{
	    my $tailNode = $self->{posVsElm}->[$rangeTailIndex]->[2]->[$self->{posVsElm}->[$rangeTailIndex]->[3]];

	    my $targetNode = $tailNode;
	    my $len = $range->{length} - $assignedLen;
	    $assignedLen += $len;
	    my $_assignedWidth = $assignedLen / $range->{length} * $totalWidth;

	    my $_info = JSON::from_json(JSON::to_json($info));
	    $_info->{'pdf:left'} = $firstLeft + $assignedWidth;
	    $_info->{'pdf:width'} = $_assignedWidth - $assignedWidth;
	    $assignedWidth = $_assignedWidth;

	    # - assert
	    die "$rangeHeadIndex $rangeTailIndex ".$range->{length}." $assignedLen" unless($len);
	    die "$len ".length($targetNode->{str}) unless($len < length($targetNode->{str}));

	    $targetNode->mapBoundary
		({'pos'=>$targetNode->{pos},
		  'length'=>$len},
		 [$_info]);
	}

	if(DEBUG::INSERT_RANGE_NODE) {
	    warn "Done";
	}
	return;
	    
    } elsif($isRangeTailAdjustedToNodeTail) {
	# |..[  |    ]|

	if(DEBUG::DUMP_INSERT_RANGE_MDOE) {
	    $info->{mode} = 'mode:multi(right)';
	}

	my $assignedLen = 0;
	my $assignedWidth = 0;
	my $totalWidth = $info->{'pdf:width'};
	my $firstLeft = $info->{'pdf:left'};

	{
	    my $headNode = $self->{posVsElm}->[$rangeHeadIndex]->[2]->[$self->{posVsElm}->[$rangeHeadIndex]->[3]];

	    my $targetNode = $headNode;
	    my $len = length($targetNode->{str}) - 
		($range->{pos} - $targetNode->{pos});
	    $assignedLen += $len;
	    my $_assignedWidth = $assignedLen / $range->{length} * $totalWidth;

	    my $_info = JSON::from_json(JSON::to_json($info));
	    $_info->{'pdf:left'} = $firstLeft + $assignedWidth;
	    $_info->{'pdf:width'} = $_assignedWidth - $assignedWidth;
	    $assignedWidth = $_assignedWidth;

	    $targetNode->mapBoundary
		({'pos'=>$range->{pos},
		  'length'=>$len},
		 [$_info]);

#	    $range->{pos} += $len;
	}

	for(my $i = $rangeHeadIndex + 1; $i <= $rangeTailIndex; $i++) {
	    my $targetNode = $self->{posVsElm}->[$i]->[2]->[$self->{posVsElm}->[$i]->[3]];
	    my $len = length($targetNode->{str});
	    $assignedLen += $len;
	    my $_assignedWidth = $assignedLen / $range->{length} * $totalWidth;

	    my $_info = JSON::from_json(JSON::to_json($info));
	    $_info->{'pdf:left'} = $firstLeft + $assignedWidth;
	    $_info->{'pdf:width'} = $_assignedWidth - $assignedWidth;
	    $assignedWidth = $_assignedWidth;

	    $targetNode->mapBoundary
		({'pos'=>$targetNode->{pos},
		  'length'=>$len},
		 [$_info]);

#	    $range->{pos} += $len;
	}

	if(DEBUG::INSERT_RANGE_NODE) {
	    warn "Done";
	}
	return;
	    
    } else {
	# |..[ | | ]..|

	# TODO: recalc width for each range
	if(DEBUG::DUMP_INSERT_RANGE_MDOE) {
	    $info->{mode} = 'mode:multi(center)';
	}

	my $assignedLen = 0;
	my $assignedWidth = 0;
	my $totalWidth = $info->{'pdf:width'};
	my $firstLeft = $info->{'pdf:left'};

	{
	    my $headNode = $self->{posVsElm}->[$rangeHeadIndex]->[2]->[$self->{posVsElm}->[$rangeHeadIndex]->[3]];

	    my $targetNode = $headNode;
	    my $len = length($targetNode->{str}) - 
		($range->{pos} - $targetNode->{pos});
	    $assignedLen += $len;
	    my $_assignedWidth = $assignedLen / $range->{length} * $totalWidth;

	    my $_info = JSON::from_json(JSON::to_json($info));
	    $_info->{'pdf:left'} = $firstLeft + $assignedWidth;
	    $_info->{'pdf:width'} = $_assignedWidth - $assignedWidth;
	    $assignedWidth = $_assignedWidth;

	    $targetNode->mapBoundary
		({'pos'=>$range->{pos},
		  'length'=>$len},
		 [$_info]);
#	    $assignedLen += $len;
#	    $range->{pos} += $len;
	}

	for(my $i = $rangeHeadIndex + 1; $i < $rangeTailIndex; $i++) {
	    my $targetNode = $self->{posVsElm}->[$i]->[2]->[$self->{posVsElm}->[$i]->[3]];
	    my $len = length($targetNode->{str});
	    $assignedLen += $len;
	    my $_assignedWidth = $assignedLen / $range->{length} * $totalWidth;

	    my $_info = JSON::from_json(JSON::to_json($info));
	    $_info->{'pdf:left'} = $firstLeft + $assignedWidth;
	    $_info->{'pdf:width'} = $_assignedWidth - $assignedWidth;
	    $assignedWidth = $_assignedWidth;

	    $targetNode->mapBoundary
		({'pos'=>$targetNode->{pos},
		  'length'=>$len},
		 [$_info]);

#	    $assignedLen += $len;
#	    $range->{pos} += $len;
	}
	{
	    my $tailNode = $self->{posVsElm}->[$rangeTailIndex]->[2]->[$self->{posVsElm}->[$rangeTailIndex]->[3]];

	    my $targetNode = $tailNode;
	    my $len = $range->{length} - $assignedLen;
	    $assignedLen += $len;
	    my $_assignedWidth = $assignedLen / $range->{length} * $totalWidth;

	    my $_info = JSON::from_json(JSON::to_json($info));
	    $_info->{'pdf:left'} = $firstLeft + $assignedWidth;
	    $_info->{'pdf:width'} = $_assignedWidth - $assignedWidth;
	    $assignedWidth = $_assignedWidth;

	    # - assert
	    die "$rangeHeadIndex $rangeTailIndex ".$range->{length}." $assignedLen" unless($len);
	    die unless($len < length($targetNode->{str}));

	    $targetNode->mapBoundary
		({'pos'=>$targetNode->{pos},
		  'length'=>$len},
		 [$_info]);
	}

	if(DEBUG::INSERT_RANGE_NODE) {
	    warn "Done";
	}
	return;
    }
    die "unexpected situation";
}

sub insertUnmappedRangeNode
{
    my ($self, $boundary) = @_;
}

sub isSimilar
{
    my ($self, $needle, $pos, $len) = @_;

    my $dist = KyotoCabinet::levdist($needle, substr($self->{wholeText}, $pos, $len), 1);

    if($dist > $len * .3) { # FIXME: ad-hoc
	return undef;
    }

    return {'pos'=>$pos, 'length'=>$len};
}

sub DESTROY
{
    my ($self) = @_;
}

# --------------------------------
package map::Mapper;

sub new {
    my ($class, $dbPath) = @_;

    unless(defined($dbPath)) {
	die 'db path not specified.';
    }

    my $db = new KyotoCabinet::DB();

    $db->open($dbPath,
	      KyotoCabinet::DB::OCREATE |	
	      KyotoCabinet::DB::OWRITER)
	or die $db->error;
      
    return bless {
	db => $db
    }, $class;
}

sub DESTROY
{
    my ($self) = @_;
    if(defined($self->{db})) {
	$self->{db}->close();
    }
}

sub isStored
{
    my ($self, $articleID) = @_;

    return ($self->{db}->check($articleID) > 0);
}

sub store # TODO: this should be a method of AbstractImporter.
{
    my ($self, $articleID, $articleInfo) = @_;

    unless($self->{db}->set($articleID, JSON::encode_json($articleInfo))) {
	die $self->{db}->error;
    }
}

sub cancelConflicts
{
    my ($self, $pdfInfo) = @_;
    {
	# - build sorted array (sort by pos)
	my @all;
	foreach my $pageInfo (@{$pdfInfo->{pages}}) {
	    foreach my $boundary (@{$pageInfo->{boundaries}}) {

		if(defined($boundary->{range})) {
		    my $headP = 
			List::BinarySearch::XS::binsearch_pos {
			    (${a}->{pos} == ${b}->{range}->{pos}) ?
				(${a}->{length} <=> ${b}->{range}->{length}) :
				(${a}->{pos} <=> ${b}->{range}->{pos})
		    }
		    $boundary->{range},
		    @all;
		    splice(@all, $headP, 0, $boundary);
		}
	    }
	}

	my %removalIndexes;

	my $headP = 0;
	my $nextP = 0;
	my $topI = -1;

	for(my $i = 0; $i < int(@all); $i++) {
	    my $_headP = $all[$i]->{range}->{pos};
	    my $_nextP = $_headP + $all[$i]->{range}->{length};

	    if($_headP < $nextP) {
		$removalIndexes{$i} = 1;
		$removalIndexes{$topI} = 1;

	    } else {
		$headP = $_headP;
	    }

	    if($nextP < $_nextP) {
		$nextP = $_nextP;
		$topI = $i;
	    }
	}

	foreach my $i (sort { $b <=> $a } (keys(%removalIndexes))) {
	    delete $all[$i]->{range};
	}
    }
}

sub mapPdfAndXml
{
    my ($self, $xmlInfo, $pdfInfo) = @_;

    # - deep copy
    my $mergedXmlInfo = JSON::from_json(JSON::to_json($xmlInfo));

    my $textScanner = new TextScanner($mergedXmlInfo);
    
    if(DEBUG::SHOW_WHOLE_TEXT) {
	warn "WHOLE: \n".Encode::encode('utf-8', $textScanner->{wholeText})."\n\n";
    }

    #print $textScanner->{wholeText};
    #die;

    $textScanner->clearReservations();
    my $prefPos = 0;
    # for each pdf boundary

    # Phase: exact match: absolutely assignable
    foreach my $pageInfo (@{$pdfInfo->{pages}}) {
	foreach my $boundary (@{$pageInfo->{boundaries}}) {

	    my $normalizedNeedle = TextScanner::normalizeText($boundary->{text});
	    # Ok? Cache normalized text.
	    $boundary->{normalizedText} = $normalizedNeedle;

	    my $range = $textScanner->search_exactMatch($normalizedNeedle);

	    if(defined($range)) {
		if(DEBUG::RESULT) {
		    print "o: ", Encode::encode('utf-8', $boundary->{text}), "\n";
		}

		$boundary->{range} = $range;
		
		$textScanner->reserve($range);
		$prefPos = $range->{pos} + $range->{length};
	    } else {
		if(DEBUG::RESULT) {
		    print "x: ", Encode::encode('utf-8', $boundary->{text}), "\n";
		}
	    }

	}
    }

    # - cancel conflicts
    $self->cancelConflicts($pdfInfo);

    my @all;

    foreach my $pageInfo (@{$pdfInfo->{pages}}) {
	foreach my $boundary (@{$pageInfo->{boundaries}}) {
	    push(@all, $boundary);
	}
    }

    # - try map remaining pdf boundaries by levdist
    #   if its prev & next boundaries are mapped in order
    #   and have a gap.
    {
	for(my $i = 1; $i < int(@all) - 1; $i++) {
	    next if(defined($all[$i]->{range}));

	    my $boundary = $all[$i];

	    next unless(defined($all[$i-1]->{range}) &&
			defined($all[$i+1]->{range}));

	    my $left = $all[$i-1]->{range}->{pos} + $all[$i-1]->{range}->{length};
	    my $right = $all[$i+1]->{range}->{pos} - 1;

	    next unless($left <= $right);

	    my $normalizedNeedle = TextScanner::normalizeText($boundary->{text});
	    my $range = $textScanner->isSimilar($normalizedNeedle, $left, $right - $left + 1);

	    if(defined($range)) {
		if(DEBUG::RESULT) {
		    print "?1: ", Encode::encode('utf-8', $boundary->{text}), "\n";
		}

		$boundary->{range} = $range;
		
		$textScanner->reserve($range);
		$prefPos = $range->{pos} + $range->{length};
	    } else {
		if(DEBUG::RESULT) {
		    print "x1: ", Encode::encode('utf-8', $boundary->{text}), "\n";
		    print "x1; ", Encode::encode('utf-8', substr($textScanner->{wholeText}, $left, $right-$left+1)), "\n";
		}
	    }
	}
    }

    # - cancel conflicts (2)
    $self->cancelConflicts($pdfInfo);

    # - insert range nodes
    foreach my $pageInfo (@{$pdfInfo->{pages}}) {
	foreach my $boundary (@{$pageInfo->{boundaries}}) {

	    if(defined($boundary->{range})) {
		
		$textScanner->insertRangeNode($boundary->{range}, $boundary, $pageInfo->{number});

	    } else { # un-mapped boundary

		$textScanner->insertUnmappedRangeNode($boundary);

	    }
	}
    }

    # - 
    $textScanner->applyInsertions();
    

    # - insert xmlns node
    unless(defined($mergedXmlInfo->[1]->[0]->{'xmlns:'.$config->{'pdf boundary element'}->{namespace}->{alias}})) {
	$mergedXmlInfo->[1]->[0]->{'xmlns:'.$config->{'pdf boundary element'}->{namespace}->{alias}} =
	    $config->{'pdf boundary element'}->{namespace}->{uri};
    }

    return $mergedXmlInfo;
}

sub skipConditions {
    my ($self, $conditions) = @_;
    foreach my $cond (@$conditions) {
	unless($cond =~ /:/) {
	    $cond .= ':';
	}
	$config->{skipConditions}->{$cond} = 1;
    }
}

1;
