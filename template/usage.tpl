<div>
	<h1 id="pageTitle">Alignment Editing</h1>

	<h3>Nazuna.pm</h3>
	<p>
		NazunaはPerlで書かれています。BioPerlなどの他のパッケージに依存しません。
	</p>

	<h3>Mehtods</h3>
	<p>
		Nazunaクラスが用意しているパブリックメソッドには次のようなものがあります。
	</p>
	<ul>
		<li>Nazuna::new コンストラクタ。</li>
		<li>Nazuna::align_seq est2genomeの結果を下に、リファレンス配列とEST配列の対応関係を作成します。</li>
		<li>Nazuna::get_nodes エキソンとイントロンの境界線をすべて取り出します。</li>
		<li>Nazuna::update_nodes 編集されたエキソンとイントロンの境界線を元のゲノムとESTに書きこんで、マッピングの位置情報を更新します。</li>
		<li>Nazuna::write_seq 編集後のファイルを書き出します。nazunaフォーマットになります。</li>
	</ul>

	<h3>Quick Start</h3>
	<pre>
use Bio::SeqIO;
use Nazuna;

# Read EST and genome sequence.
my $est_io = Bio::SeqIO->new(
		-file => 'est.fa',
		-type => 'fasta');
my $genome_io = Bio::SeqIO->new(
		-file => 'genome.fa',
		-type => 'fasta');

# Create Nazuna object.
my $nazuna = Nazuna->new(
		align_file => 'result.est2genome',
		aling_format => 'nazuna',
		est_seq => $est_io->seq,
		genome_seq => $genome_io->seq);

$nazuna->align_seq;

my $nodes = $nazuna->get_nodes(20);

#
# Editing nodes in $nodes.
#

$nazuna->update_nodes($nodes, 20);
$nazuna->write_seq('edited.nazuna');
	</pre>


	<h3>Nazuna::new</h3>
	<pre>
# Read est2genome file.
my $nazuna = Nazuna->new(
		align_file => 'result.est2genome',    // The result file outputed from est2genome.
		align_format => 'est2geonme',         // File format.
		est_seq => $est_seq,                  // The EST sequence as string.
		genome_seq => $genome_seq             // The genome sequence as string.
);


# Read nazuna file.
my $nazuna = Nazuna->new(
		align_file => 'result.nazuna',        // The nazuna file.
		align_format => 'nazuna',             // File format.
		est_seq => $est_seq,                  // The EST sequence as string.
		genome_seq => $genome_seq             // The genome sequence as string.
);
	</pre>


	<h3>align_seq</h3>
	<p>
		インスタンスを作成するとき与えた2つの配列は、ギャップなどを含んでいません。
		このメソッドはest2genomeの情報をもとに、2つの配列にギャップやイントロンを挿入していきます。
		次のようなイメージになります。
	</p>
	<pre>
# align_seq 実行前

print $self->{est_seq};
# ACCAGTCGATGCTAGCTAGCTAGTCAGTCGTA

print $self->{genome_seq};
# ACAGTCGATGCTAGCCAGTCGTACTGATGCTATGTGTCATTAGGCTAGTCAGTCGTA


# align_seq 実行後
print $self->{est_seq};
# ACCAGTCGATGCTAGC.........................TA-GCTAGTCAGTCGTA

print $self->{genome_seq};
# AC-AGTCGATGCTAGCCAGTCGTACTGATGCTATGTGTCATTAGGCTAGTCAGTCGTA
	</pre>

	<h3>get_nodes</h3>
	<p>
	ここではエキソンとイントロンの境界線をノードとしています。get_nodeは、そのすべての境界線を取得するメソッドです。
	ノードを取り出す際に、境界線左右にある文字数を指定します。下記の例で12を指定しています、
	この場合は、境界線前後それぞれ12文字ずつ合計24文字ずつ取得されます。
	</p>
	<pre>
$nazuna->align_seq;

my $nodes = $nazuna->get_align(12);

foreach my $node (@{$nodes}) {
	print $node->{'index'};             # 1, 2, 3, ...
	print $node->{'type'};              # I/E or E/I
	print $node->{'est_seq'} . "n";     # ............ACCGCCGA-TGC
	print $node->{'genome_seq'} . "n";  # GGTAGCTAGTACCGCCGATTGC
	print $node->{'est_start'};         # The start position of this node of EST
	print $node->{'genome_start'};      # The start position of this node of genome
}
	</pre>

	<h3>update_node</h3>
	<p>
	est2genomeの予測では、ノードの近くでは精度が低くなります。
	get_nodesメソッドで取得したノード近傍を編集し、その編集結果を反映するためにこのメソッドを利用します。
	このメソッドは2つの引数を必要とします。一つは編集後のノードの情報です。
	もうひとつは、get_nodesでノードを取り出した際に指定した文字数です。
	</p>
	<pre>
my $nodes = $nazuna->get_align(12);

# Edit $nodes.
# substr($nodes->[3]->{'est_seq'}, 4, 2, 'GT');
# substr($nodes->[5]->{'est_seq'}, 6, 1, 'A');
# substr($nodes->[3]->{'genome_seq'}, 8, 4, 'GTAT');

$nazuna->update_nodes($nodes, 12);
	</pre>

	<h3>write_seq</h3>
	<p>
	編集した情報をファイルに書き出す際に利用するメソッドです。
	ファイルのフォーマットはnazunaフォーマットになります。
	</p>
	
	<pre>
$nazuna->align_seq;
my $nodes = $nazuna->get_nodes(12);

# Edit

$nazuna->update($nodes, 12);

$nazuna->write_seq('result.nazuna');
	</pre>

</div>
