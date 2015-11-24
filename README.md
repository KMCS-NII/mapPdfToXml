# mapXmlAndPdf

**PDFからレイアウト情報を抽出してXMLに埋め込みます**

mapXmlAndPdfは文章のレイアウト情報をXMLに埋め込むためのツールです。
例えばXHTMLドキュメントと、それをPDF形式で保存したファイルを指定すると、
XHTMLの要素に対応するPDFの文字列領域を探して領域の座標、ページ番号、
フォント情報などを元のXHTMLの要素に埋め込んだファイルを生成します。

## インストール

### Ubuntu 14

### CentOS 7

### CentOS 6

### それ以外

* 適当なディレクトリにファイル群を展開してください
* 以下の依存パッケージを導入してください。
  * [poppler & poppler-data](http://poppler.freedesktop.org/)
  * [KyotoCabinet](http://fallabs.com/kyotocabinet/)
  * perl
    * [List::BinarySearch::XS](http://search.cpan.org/~davido/List-BinarySearch-XS-0.09/lib/List/BinarySearch/XS.pm)
* 展開されたnii.xml-pdfディレクトリを環境変数PERL5LIBに追加してください。
```
例) env PERL5LIB=~/programs/mapXmlAndPdf/nii.xml-pdf/ ~/programs/mapXmlAndPdf/mapXmlAndPdf
```

## 実行方法

XMLファイルとPDFファイルを用意して、コマンドラインから次のように実行します。

```
mapXmlAndPdf (src xml path) (src pdf path) (dst dirpath)
```

出力先のディレクトリが無ければ自動的に作成します。

### 入力XML, PDFにファイル名を指定した場合

入力PDFのファイル名の拡張子を.xmlとしたファイルをdst dirpathに作成します。
既にあれば上書きします。

### 入力XML, PDFにディレクトリ名を指定した場合

ディレクトリを再帰的に探索して全てのXML, PDFの組に対応するファイルがdst dirpath以下に作成します。
既にあれば上書きします。
XMLとPDFは指定したディレクトリからの相対位置が同じで拡張子を除いたファイル名が一致するものが一組として処理します。
たとえば、(src xml path)/2015/1/abc.xmlと(src pdf math)/2015/1/abc.pdfを処理した結果を(dst dirpath)/2015/1/abc.xmlに出力します。

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
(XMLの相対ファイルパス) (PDFの相対ファイルパス)
という対応関係をTSVで記載したファイルを用意して以下のパラメータを指定してください。
--map-file=(ファイルパス) 
「相対ファイルパス」には拡張子まで含めて記述してください。
出力ファイル名はPDFのファイル名の拡張子を変えたものになります。

#### PDFとは対応関係にないXML要素を指定する

XHTMLのhead要素など対応する文字列領域がPDFにないことが分かっている要素を指定することで対応関係推定の間違いを減らすことができます。
```
--skip-conditions=head,title:foo
```
が指定されると、XMLのhead要素と、class="foo"属性を持つtitle要素を対応関係の推定対称から除外します。

## 出力情報の仕様



## ライセンス

mapXmlAndPdfはMITライセンスで公開しています。

The MIT License

Copyright (c) 2015 National Institute of Informatics, Japan.

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

以下に定める条件に従い、本ソフトウェアおよび関連文書のファイル（以下「ソフトウェア」）の複製を取得するすべての人に対し、ソフトウェアを無制限に扱うことを無償で許可します。これには、ソフトウェアの複製を使用、複写、変更、結合、掲載、頒布、サブライセンス、および/または販売する権利、およびソフトウェアを提供する相手に同じことを許可する権利も無制限に含まれます。

上記の著作権表示および本許諾表示を、ソフトウェアのすべての複製または重要な部分に記載するものとします。

ソフトウェアは「現状のまま」で、明示であるか暗黙であるかを問わず、何らの保証もなく提供されます。ここでいう保証とは、商品性、特定の目的への適合性、および権利非侵害についての保証も含みますが、それに限定されるものではありません。 作者または著作権者は、契約行為、不法行為、またはそれ以外であろうと、ソフトウェアに起因または関連し、あるいはソフトウェアの使用またはその他の扱いによって生じる一切の請求、損害、その他の義務について何らの責任も負わないものとします。
