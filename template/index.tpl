<div>
	<h1 id="pageTitle">AlignEditor v0.1.0</h1>
	<p>
	AlignEditorはest2genomeの結果を編集するためのツールです。est2genomeは、ESTをゲノムへマッピングして、
	エキソンとイントロンを予測するプログラムです。イントロンの予測にはGT-AG則を利用します。
	GT-AG則に従わないイントロンも、無理にGT-AG則に合わせようとします。
	これが原因で、エキソンとイントロンの接続点の周りに、不自然なギャップが挿入されます。
	AlignEditorは、こうした不自然のギャップを簡単に編集できるようにします。
	</p>

	<h2><a href="./usage.pl">Usage</a> | Usage</h2>
	<p>
	AlignEditorのコア部分は、NazunaというPerlのモジュールを使用しています。
	このページでは、Nazunaモジュールの使い方を紹介しています。
	</p>

	
	<h2><a href="./settings.pl">Settings</a> | System settings</h2>
	<p>
	システム環境変数を変更することができます。
	</p>


	<!--
	<h2><a href="./mapping.pl">Mapping</a> | Mapping with est2genome</h2>
	<p>
	est2genomeを利用して、EST配列をゲノム配列にマッピングします。
	</p>
	-->

	<h2><a href="./gene.pl">Editor</a> | Editing alignment</h2>
	<p>
	NazunaモジュールをCGI版に応用したものです。
	est2genomeのアラインメント結果をGUI画面で編集することができます。
	</p>

	<h3>利用例（不自然のギャップをなくす）</h3>
	<ol>
	<li>ホームの「Alignment Edit」リンクをクリックします。</li>
	<li>「NM_006204.3」リンクをクリックします。</li>
	<li>「Reset」ボタンをクリックします。（いままで編集した情報をすべて削除します。）</li>
	<li>ページ最上部にある「CHECK」リンクをクリックします。</li>
	<li>ページの真ん中らへん「Lib 27826」のジャンクションのhomology stringsがオレンジ色になります。ここを編集します。</li>
	<li>EST欄にある「ACTC」を切り取ります。代わりに、「....」を入力して、LibとESTの長さが同じになるように修正します。</li>
	<li>「Lib 28411」のジャンクションを編集します。EST欄に「----」が見られますので、「---」を消去し、代わりに「ACTC」を入力します。</li>
	<li>ページ最上部にある「CHECK」リンクをクリックします。</li>
	<li>編集した二箇所は、緑色とオレンジ色になっていなければ、最下部にある「Edit」ボタンをクリックします。</li>
	</ol>

	<h3>利用例（エキソンを増やす）</h3>
	<ol>
	<li>ホームの「Alignment Edit」リンクをクリックします。</li>
	<li>「NM_004181.4」リンクをクリックします。</li>
	<li>「Reset」ボタンをクリックします。（いままで編集した情報をすべて削除します。）</li>
	<li>「Exons」を選択して「View」ボタンをクリックします。</li>
	<li>ページ最上部にある「CHECK」リンクをクリックします。</li>
	<li>1番目のエキソンのhomology stringsがオレンジ色になります。ここを編集します。</li>
	<li>EST欄の塩基の最後の部分の「ATGCTGAACAAA」を切り取ります。</li>
	<li>Lib欄の塩基の最後の部分にギャップ「-」が見られます。この1個のギャップを削除します。</li>
	<li>EST欄の最後の塩基に続いて、イントロンを示す記号「.」を追加します。Lib欄にある塩基と同じになるようにします。編集後は次のようになっているはずです。
<pre>Lib:  前略CGAGGTGAGCGCCAG
EST:  前略CGAG...........</pre>
	</li>
	<li>ページ最上部にある「CHECK」リンクをクリックします。</li>
	<li>編集した1番目のエキソンが、緑色とオレンジ色になっていなければ、最下部にある「Edit」ボタンをクリックします。</li>
	<li>次に、「Introns」を選択して「View」ボタンをクリックします。</li>
	<li>ページ最上部にある「CHECK」リンクをクリックします。</li>
	<li>一番目のイントロンのLib欄から「ATGCTGAACAAA」とマッチングする部分を探します。</li>
	<li>マッチングする部分を見つけたら、その下にあるEST欄の「............」を削除し、に「ATGCTGAACAAA」を書き入れます。編集後は次のようになっているはずです。
<pre>Lib:  前略CCTTTCAGATGCTGAACAAAGTGAGTG後略
EST:  前略........ATGCTGAACAAA.......後略</pre>
</li>
	<li>ページ最上部にある「CHECK」リンクをクリックします。</li>
	<li>編集した1番目のイントロンが、緑色とオレンジ色になっていなければ、最下部にある「Edit」ボタンをクリックします。</li>
	</ol>


</div>
