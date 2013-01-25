<div>
	<h1 id="pageTitle">環境変数設定</h1>
	<p>値を修正してからUpdateをクリックすると環境変数が新しい値に更新されます。（書き込み権限を与えていませんので、Updateをクリックしても更新されません。）</p>
	<form method="POST" action="./settings.pl">
	<input type="submit" class="button" value="Update" />
	<input type="hidden" name="action" value="update" />
	<table class="sysvars">
		<tr>
			<td class="sysvarsKey">キー</td>
			<td class="sysvarsValue">値</td>
		</tr>
		<TMPL_LOOP NAME="SYSTEM_VARS">
		<tr>
			<td><input type="text" value="<TMPL_VAR NAME="key">" readonly="readonly" /></td>
			<td><input type="text" name="<TMPL_VAR NAME="key">" size="60" value="<TMPL_VAR NAME="value">" /></td>
		</tr>
		</TMPL_LOOP>
	</table>
	</form>
</div>
