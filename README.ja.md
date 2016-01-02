# mapPdfToXml

**PDFからレイアウト情報を抽出してXMLに埋め込みます**

mapPdfToXmlは文章のレイアウト情報をXMLに埋め込むためのツールです。

例えばXHTMLドキュメントと、それをPDF形式で保存したファイルを指定すると、
XHTMLの要素に対応するPDFの文字列領域を探して領域の座標、ページ番号、
フォント情報などを元のXHTMLの要素に埋め込んだファイルを生成します。

▼ http://www.w3.org/TR/2002/REC-xhtml1-20020801/
```html
<?xml version="1.0"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" lang="en" xml:lang="en">
:
:
<h2>
 <a name="status" id="status"></a>
 Status of this document
</h2>

<p>
 <em>
  This section describes the status of this document at the time of its publication. Other documents may supersede this document. The latest status of this document series is maintained at the W3C.
 </em>
</p>
:
```

をブラウザでPDFに変換して出力したものを用意して本ツールで処理すると、次のような結果が得られます。(比較のため入力、出力ともに改行、インデントを追加しています)
```html
<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" lang="en" xml:lang="en" xmlns="http://www.w3.org/1999/xhtml" xmlns:pdf="http://kmcs.nii.ac.jp/#ns" xml:lang="en">
:
:
<h2>
 <a id="status" name="status"></a>
 <pdf:span pdf:boundaryid="59" pdf:boundarysequence="58" pdf:boundarytype="text" pdf:fontcolor="#000000" pdf:fontfamily="CZKWDF+LiberationSans-Bold" pdf:fontsize="13.5" pdf:height="16.5" pdf:left="60" pdf:page="1" pdf:text="Status of this document" pdf:top="583" pdf:width="166.5">Status of this document</pdf:span>
</h2>

<p>
 <em>
  <pdf:span pdf:boundaryid="60" pdf:boundarysequence="59" pdf:boundarytype="text" pdf:fontcolor="#000000" pdf:fontfamily="TCYTND+LiberationSans-Italic" pdf:fontsize="8.5" pdf:height="11" pdf:left="60" pdf:page="1" pdf:text="This section describes the status of this document at the time of its publication. Other documents may supersede" pdf:top="612.5" pdf:width="486">This section describes the status of this document at the time of its publication. Other documents may supersede </pdf:span>
  <pdf:span pdf:boundaryid="61" pdf:boundarysequence="60" pdf:boundarytype="text" pdf:fontcolor="#000000" pdf:fontfamily="TCYTND+LiberationSans-Italic" pdf:fontsize="8.5" pdf:height="11" pdf:left="60" pdf:page="1" pdf:text="this document. The latest status of this document series is maintained at the W3C." pdf:top="624.5" pdf:width="355">this document. The latest status of this document series is maintained at the W3C.</pdf:span>
 </em>
</p>
:
```

## インストール

### Ubuntu 14

1. 管理者権限で以下の内容のファイルを /etc/apt/sources.list.d/nii-xml-pdf.list として作成してください。

        deb https://raw.githubusercontent.com/KMCS-NII/mapPdfToXml/master/ubuntu/14/packages ./
1. 管理者権限で以下のコマンドを実行してください。

        apt-get update
        apt-get install nii-tex-pdf
次のようなメッセージ（署名なしのパッケージをインストールすることの警告）が表示されるのでyを入力してください。

        WARNING: The following packages cannot be authenticated!
          nii-xml-pdf-kyotocabinet-perl nii-xml-pdf
        Install these packages without verification? [y/N]

### CentOS 6, 7

1. 管理者権限で以下のコマンドを実行してください。

        rpm -i https://raw.githubusercontent.com/KMCS-NII/mapPdfToXml/master/centos/nii-xml-pdf-repo-1-1.noarch.rpm
        yum install --enablerepo=nii-xml-pdf nii-xml-pdf
Perlのモジュールのインストールに数分を要します。

### それ以外

1. 適当なディレクトリにsources/以下のファイル群を展開してください。
svnコマンドが利用可能な環境では以下を実行してください。
カレントディレクトリにmapPdfToXmlサブディレクトリが作成されます。

        svn export https://github.com/KMCS-NII/mapPdfToXml/trunk/sources mapPdfToXml
1. 以下の依存パッケージを導入してください。
  * [poppler & poppler-data](http://poppler.freedesktop.org/)
  * [KyotoCabinet & perl module](http://fallabs.com/kyotocabinet/)
  * perl
    * Data::Dumper
    * JSON
    * List::BinarySearch::XS
    * Unicode::Normalize
    * XML::LibXML
1. 展開されたnii.xml-pdfディレクトリを環境変数PERL5LIBに追加してください。

        例) env PERL5LIB=~/programs/mapPdfToXml/nii.xml-pdf/ ~/programs/mapPdfToXml/mapPdfToXml

## 実行方法

XMLファイルとPDFファイルを用意して、コマンドラインから次のように実行してください。

```
mapPdfToXml (src xml path) (src pdf path) (dst dirpath)
```

出力先のディレクトリが無ければ自動的に作成します。

### 入力XML, PDFにファイル名を指定した場合

入力PDFのファイル名の拡張子を.xmlとしたファイルをdst dirpathに作成します。
既にあれば上書きします。

### 入力XML, PDFにディレクトリ名を指定した場合

ディレクトリを再帰的に探索して全てのXML, PDFの組に対応するファイルがdst dirpath以下に作成します。
既にあれば上書きします。

XMLとPDFは指定したディレクトリからの相対位置が同じで拡張子を除いたファイル名が一致するものが一組として処理します。
たとえば、

(src xml path)/2015/1/abc.xml

と

(src pdf path)/2015/1/abc.pdf

を処理した結果を

(dst dirpath)/2015/1/abc.xml

に出力します。

### 詳細な設定

#### ログ出力の抑制

-q が指定されるとログ出力を抑制します。

#### 出力形式の切り替え

--json が指定されると拡張子.jsonのファイルにJSON形式で出力します。

#### 入力XMLの拡張子を指定する

--xml-extention=xyz が指定されると、(src xml path)以下の拡張子.xyzのファイルをXMLファイルとみなして処理します。

既定の動作では、.xml, .xhtml, .html ファイルが処理対象で、もし拡張子を除いたファイル名が同一のファイルがある場合は.xmlファイルを最優先で処理し、無ければ.xhtmlファイルを処理します。

#### XMLとPDFの対応関係を対応リストで指定する。

対応するXMLとPDFのファイル名が異なっている場合、
```
(XMLの相対ファイルパス)(タブ文字)(PDFの相対ファイルパス)
```
という対応関係をTSVで記載したファイルを用意して以下のパラメータを指定してください。
```
--map-file=(対応リストTSVのファイルパス) 
```
TSV中の「相対ファイルパス」には拡張子まで含めて記述してください。
出力ファイル名はPDFのファイル名の拡張子を変えたものになります。

#### PDFとは対応関係にないXML要素を指定する

XHTMLのhead要素など対応する文字列領域がPDFにないことが分かっている要素を指定することで対応関係推定の間違いを減らすことができます。
```
--skip-conditions=head,title:foo
```
が指定されると、XMLのhead要素と、class="foo"属性を持つtitle要素を対応関係の推定対称から除外します。

無指定の場合、headが指定されているものとみなします。
head要素も処理対象に含めたい場合は
```
--skip-conditions=
```
のように空文字列を指定します。

## 出力情報の仕様

* 出力されるXMLは、入力XMLのDOM構造にPDF情報を追加したものです。
* PDFでは文字列をバウンダリ(Boundary)とよばれる矩形の領域の集合として扱っています。
本ツールはバウンダリを単位としてXMLの文字列との対応関係を推定します。
* PDFのバウンダリと対応しているXMLの文字列はpdf:span要素として括り出されます。
名前空間pdfのURIはhttp://kmcs.nii.ac.jp/#ns です。
* pdf:span要素にはレイアウト情報が以下の属性として埋め込まれます。
  * pdf:boundarytype : バウンダリの種類。現状、必ず「text」です。
  * pdf:boundaryid : バウンダリの通し番号（1始まり）。
  * pdf:boundarysequence : ページ内でのバウンダリ番号（0始まり）。
  * pdf:page : ページ番号。
  * pdf:text : 文字列。
  * pdf:left : バウンダリの左端座標。
  * pdf:top : バウンダリの上端座標。
  * pdf:width : バウンダリの幅。
  * pdf:height : バウンダリの高さ。
  * pdf:fontcolor　: 文字列の色。#RRGGBB形式の文字列です。
  * pdf:fontfamily : 「ＭＳ明朝」などのフォント名。
和英の合成フォントの場合、「EDLXCL+RyuminPro-Light-Identity-H」のように「+」を挟んで複数のフォント名が併記されることがあります。
属性自体が無い場合もあります。
  * pdf:fontsize : 文字の大きさ。0の場合や、属性自体がない場合もあります。
* 座標、大きさはポイント単位です。
* 対応する文字列がXML中に見つからなかったPDFバウンダリも、pdf:span要素として埋め込まれます。このpdf:span要素は文字列を含みません。

* 対応するPDFのバウンダリが見つからなかったXMLの文字列はpdf:unmapped要素で囲まれます。

### 出力例

例として、次のXHTMLに対してPDFの領域情報をマッピングさせる場合を考えます。
```
<span>いろはにほへとちりぬるを</span><span>わかよたれそ</span>
```

* XHTML要素とPDFの領域が一致する場合、XHTMLの要素の中にPDFバウンダリ情報の要素を挿入します。

        <span><pdf:span>いろはにほへとちりぬるを</pdf:span></span><span><pdf:span>わかよたれそ</pdf:span></span>

* 複数のXHTML要素と一つのPDFバウンダリが一致する場合、PDFバウンダリを分割してXHTMLの要素の中にPDFバウンダリ情報の要素を挿入します。分割領域の大きさはPDF側で数えた文字数に比例します。

* 一つのXHTML要素と複数のPDFバウンダリが一致する場合、XHTML要素の中にPDFバウンダリ情報の要素を挿入します。

        <span><pdf:span>いろはにほへと</pdf:span><pdf:span>ちりぬるを</pdf:span></span><span><pdf:span>わかよたれそ</pdf:span></span>

* いずれのPDFバウンダリにも一致しないXHTMLの部分文字列は、pdf:unmapped要素となります。

        <span><pdf:unmapped>いろはに</pdf:unmapped><pdf:span>ほへとちりぬるを</pdf:span></span><span><pdf:span>わかよたれそ</pdf:span></span>

* いずれのXHTML文字列にも一致しないPDFバウンダリは、文字列を囲まないpdf:span要素として挿入します。
挿入位置は、直前のPDFバウンダリが一致したXHTML要素の直後とします。

        <span><pdf:span>いろはにほへとちりぬるを</pdf:span></span><pdf:span text="とりなくこえす"/><span><pdf:span>わかよたれそ</pdf:span></span>

## ライセンス

mapPdfToXmlはMITライセンスで公開しています。

The MIT License

Copyright (c) 2015 National Institute of Informatics, Japan.

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

以下に定める条件に従い、本ソフトウェアおよび関連文書のファイル（以下「ソフトウェア」）の複製を取得するすべての人に対し、ソフトウェアを無制限に扱うことを無償で許可します。これには、ソフトウェアの複製を使用、複写、変更、結合、掲載、頒布、サブライセンス、および/または販売する権利、およびソフトウェアを提供する相手に同じことを許可する権利も無制限に含まれます。

上記の著作権表示および本許諾表示を、ソフトウェアのすべての複製または重要な部分に記載するものとします。

ソフトウェアは「現状のまま」で、明示であるか暗黙であるかを問わず、何らの保証もなく提供されます。ここでいう保証とは、商品性、特定の目的への適合性、および権利非侵害についての保証も含みますが、それに限定されるものではありません。 作者または著作権者は、契約行為、不法行為、またはそれ以外であろうと、ソフトウェアに起因または関連し、あるいはソフトウェアの使用またはその他の扱いによって生じる一切の請求、損害、その他の義務について何らの責任も負わないものとします。
