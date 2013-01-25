<div>
	<h1 id="pageTitle">Alignment Editing</h1>
	<p>編集したいAcession番号をクリックしてください。</p>
	<div class="genelist">
	<TMPL_LOOP NAME="GENELIST">
		<a href="./gene.pl?genename=<TMPL_VAR NAME="gene_name">&action=align" ><TMPL_VAR NAME="gene_name"></a>
		<TMPL_IF NAME="new_line"><br /></TMPL_IF>
	</TMPL_LOOP>
	</div>
</div>
