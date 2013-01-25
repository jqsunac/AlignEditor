<h1 id="pageTitle">Alignment Editing</h1>
<h2>GENE: <TMPL_VAR NAME="GENENAME"> </h2>

<div style="margin-top:30px;">
	<table>
		<tr>
			<td>Change Views</td>
			<td>
				<form action="./gene.pl" method="GET">
					<input type="hidden" value="align" name="action" />
					<input type="hidden" value="<TMPL_VAR NAME="GENENAME">" name="genename" />
					<input type="radio" name="seqType" value="junction" <TMPL_VAR NAME="chkJunction">>Junctions</input>
					<input type="radio" name="seqType" value="exon" <TMPL_VAR NAME="chkExon">>Exons</input>
					<input type="radio" name="seqType" value="intron" <TMPL_VAR NAME="chkIntron">>Introns</input> 
					<input type="submit" value="View" class="button" />
				</form>
			</td>
			<td rowspan="3">
				<ul class="filelist">
				<TMPL_LOOP NAME="FILELIST"><li><a href="<TMPL_VAR NAME="path">"><TMPL_VAR NAME="name"></a></li></TMPL_LOOP>
				</ul>
			</td>
		</tr>
		<tr>
			<td>Clear Edited</td>
			<td>
				<form action="./gene.pl" method="GET">
					<input type="submit" value="Clear" class="button clearButton" />
					<input type="hidden" value="align" name="action" />
					<input type="hidden" value="<TMPL_VAR NAME="GENENAME">" name="genename" />
				</form>
			</td>
		</tr>
		<tr>
			<td>Default</td>
			<td>
				<form action="./gene.pl" method="GET">
					<input type="submit" value="Reset" class="button resetButton" />
					<input type="hidden" value="reset" name="action" />
					<input type="hidden" value="<TMPL_VAR NAME="GENENAME">" name="genename" />
				</form>
			</td>
		</tr>
	</table>
</div>


<div>
	<!-- PARAMATERS -->
	<form method="POST" action="./gene.pl">
		<!-- hidden paramaters -->
		<input type="submit" value="Edit" class="button editButton" />
		<input type="hidden" name="action" value="edit" />
		<input type="hidden" name="genename" value="<TMPL_VAR NAME="GENENAME">" />
		<input type="hidden" name="seqType" value="<TMPL_VAR NAME="seqType">" />
		<!-- Segment's border.  -->
		<table class="nodesTable" id="nodesTable">
			<!-- header -->
			<tr>
				<th class="nodesIdx">Nodes</th>
				<th class="nodesDesc">Type</th>
				<th class="nodesDesc">pos.</th>
				<th>Sequence</th>
			</tr>
			<tr class="nodesSeparate"><td colspan="4">&nbsp;</td></tr>

			<!-- Borders -->
			<TMPL_LOOP NAME="SEGMENTS">
			<tr class="nodesSeparate"><td colspan="4">&nbsp;</td></tr>
			<!-- Senment's Number. & Seq of library genome. -->
			<tr>
				<td rowspan="3"><TMPL_VAR NAME="type"></td>
				<td>Lib</td>
				<td><input name="nodeGenomeStart_<TMPL_VAR NAME="index">" type="text" value="<TMPL_VAR NAME="genome_start">" readonly="readonly" size="8" style="text-align:right;"/></td>
				<td>
					<input type="hidden" value="<TMPL_VAR NAME="genome_end">" />
					<input id="genomeSeq_<TMPL_VAR NAME="index">" name="genomeSeq_<TMPL_VAR NAME="index">" class="seq seqChar" type="text" value="<TMPL_VAR NAME="genome_seq">" />
				</td>
			</tr>
			<!-- is matched bar -->
			<tr>
				<td>&nbsp;</td>
				<td><input type="text" size="8" readonly="readonly"></td>
				<td><input id="isMatch_<TMPL_VAR NAME="index">" class="seq seqChar" type="text" value=""  /></td>
			</tr>
			<!-- Seq of est. -->
			<tr>
				<td>EST</td>
				<td><input name="nodeEstStart_<TMPL_VAR NAME="index">" type="text" value="<TMPL_VAR NAME="est_start">" readonly="readonly" size="8" style="text-align:right;" /></td>
				<td>
					<input id="estSeq_<TMPL_VAR NAME="index">" name="estSeq_<TMPL_VAR NAME="index">" class="seq seqChar" type="text" value="<TMPL_VAR NAME="est_seq">" />
					<input type="hidden" value="<TMPL_VAR NAME="est_end">" />
				</td>
			</tr>
			<tr class="nodesSeparate"><td colspan="4">&nbsp;</td></tr>
			</TMPL_LOOP>
			<tr class="nodesSeparate"><td colspan="4">&nbsp;</td></tr>
		</table>
		<input type="submit" value="Edit" class="button editButton" />
	</form>
</div>
