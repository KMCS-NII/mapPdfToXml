#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 4;

require_ok 'xml::XHTMLParser';

{
    my $actual = xml::XHTMLParser::parse(<<EOS);
<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1 plus MathML 2.0//EN" "http://www.w3c.org/TR/MathML2/dtd/xhtml-math11-f.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xmlns:m="http://www.w3.org/1998/Math/MathML" xmlns:svg="http://www.w3.org/2000/svg">
</html>
EOS

    is_deeply($actual,
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
	      ],
	      'DOCTYPE and html')
      or diag explain($actual);
}
{
    my $actual = xml::XHTMLParser::parse(<<EOS);
<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1 plus MathML 2.0//EN" "http://www.w3c.org/TR/MathML2/dtd/xhtml-math11-f.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xmlns:m="http://www.w3.org/1998/Math/MathML" xmlns:svg="http://www.w3.org/2000/svg">
  <head>
    <title>Database of Human Evaluations of Machine Translation Systems for Patent Translation</title>
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>
    <link rel="stylesheet" type="text/css" href="core.css"/>
  </head>
  <body />
</html>
EOS

    is_deeply($actual,
	      [
	       {
		'DOCTYPE'=>'html PUBLIC "-//W3C//DTD XHTML 1.1 plus MathML 2.0//EN" "http://www.w3c.org/TR/MathML2/dtd/xhtml-math11-f.dtd"'
	       },
	       [
		{
		 'node name'=>'html',
		 'xmlns'=>'http://www.w3.org/1999/xhtml',
		 'xmlns:m'=>'http://www.w3.org/1998/Math/MathML',
		 'xmlns:svg'=>'http://www.w3.org/2000/svg'
		},
		[
		 {
		  'node name'=>'head'
		 },
		 [
		  {
		   'node name'=>'title'
		  },
		  "Database of Human Evaluations of Machine Translation Systems for Patent Translation"
		 ],
		 [
		  {
		   'node name'=>'meta',
		   'http-equiv'=>'Content-Type',
		   'content'=>'text/html; charset=utf-8'
		  }
		 ],
		 [
		  {
		   'node name'=>'link',
		   'rel'=>'stylesheet',
		   'type'=>'text/css',
		   'href'=>'core.css'
		  }
		 ]
		],
		[
		 {
		  'node name'=>'body'
		 }
		]
	       ]
	      ],
	      'sub nodes, attr, text')
      or diag explain($actual);

}
{
    my $actual = xml::XHTMLParser::parse(<<EOS);
<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1 plus MathML 2.0//EN" "http://www.w3c.org/TR/MathML2/dtd/xhtml-math11-f.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xmlns:m="http://www.w3.org/1998/Math/MathML" xmlns:svg="http://www.w3.org/2000/svg">
  <body>
    <div>text 1<span>text 2</span>text 3</div>
  </body>
</html>
EOS

    is_deeply($actual,
	      [
	       {
		'DOCTYPE'=>'html PUBLIC "-//W3C//DTD XHTML 1.1 plus MathML 2.0//EN" "http://www.w3c.org/TR/MathML2/dtd/xhtml-math11-f.dtd"'
	       },
	       [
		{
		 'node name'=>'html',
		 'xmlns'=>'http://www.w3.org/1999/xhtml',
		 'xmlns:m'=>'http://www.w3.org/1998/Math/MathML',
		 'xmlns:svg'=>'http://www.w3.org/2000/svg'
		},
		[
		 {
		  'node name'=>'body'
		 },
		 [
		  {
		   'node name'=>'div'
		  },
		  "text 1",
		  [
		   {
		    'node name'=>'span'
		   },
		   "text 2",
		  ],
		  "text 3"
		 ]
		]
	       ]
	      ],
	      'text / span /text')
      or diag explain($actual);
}

exit(0);
