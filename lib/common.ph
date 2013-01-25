=header
Get the action mode from CGI paramaters.
=cut
sub get_action {
	my $cgi = shift;
	if(defined $cgi->param('action')){
		return $cgi->param('action');
	}else{
		return 'default';
	}
	return 0;
}



=header
Get the all directories in the given directory.
=cut
sub list_up_dir {
	my $dir_path = shift;
	opendir(my $DIR, $dir_path) or die "FAILED TO READ DIR($dir_path).$!\n";
	my @files = grep( /[^\.]$/ , readdir($DIR));
	closedir($DIR);
	return \@files;
}

=header
Get the all files in the given directory.
=cut
sub list_up_files {
	my $dir_path = shift;
	opendir(my $DIR, $dir_path) or die "FAILED TO READ DIR($dir_path).$!\n";
	my @files = grep(/[^\.]$/ , readdir($DIR));
	closedir($DIR);
	return \@files;
}


=comment
Create file path object with given directory.
=cut
sub get_files_path {
	my $gene_dir = shift;
	my $fpath = {};
	if (! -d $gene_dir) {
		$gene_dir =~ s/\/$//;
		$gene_dir =~ m/(.+)\/([^\/]+)\.([0-9]+)$/;
		$gene_dir = $1;
		my $ac = $2;
		my $ver = $3;
		my $s = 0;
		opendir(my $dh, $gene_dir) or die "ERROR CANNOT OPEN [$gene_dir].\n$!\n";
		while(my $dir = readdir($dh)){
			if ($dir =~ /^$ac/){
				$gene_dir .= '/'.$dir;
				$s = 1;
				last;
			}
		}
		closedir($dh);
		$gene_dir = $gene_dir.'/'.$ac.'.'.$ver if $s == 0;
	}

	opendir(my $dh, $gene_dir) or die "ERROR CANNOT OPEN [$gene_dir].\n$!\n";
	my @files = grep( /[^\.]$/ , readdir($dh) );
	closedir($dh);
	foreach my $file (@files) {
		$fpath->{est2genome} = $gene_dir.'/'.$file if $file =~ /\.est2genome$/;
		$fpath->{airi} = $gene_dir.'/'.$file if $file =~ /\.airi$/;
		$fpath->{nazuna} = $gene_dir.'/'.$file if $file =~ /\.nazuna$/;
		$fpath->{genome} = $gene_dir.'/'.$file if $file =~ /\.genome\.fa$/;
		$fpath->{est} = $gene_dir.'/'.$file if $file =~ /\.est\.fa$/;
		$fpath->{sim4} = $gene_dir.'/'.$file if $file =~ /\.sim4$/;
		$fpath->{ele} = $gene_dir.'/'.$file if $file =~ /\.ele$/;
		$fpath->{ele_seq} = $gene_dir.'/'.$file if $file =~ /\.ele.all$/;
		$fpath->{est_gb} = $gene_dir.'/'.$file if $file =~ /\.gb$/;
	}
	$fpath->{root} = $gene_dir;
	$gene_dir =~ m/.*\/([^\/]+)$/;
	$fpath->{genename} = $1;
	$fpath->{est2genome} = $gene_dir.'/'.$fpath->{genename}.'.est2genome' if ! defined $fpath->{est2genome};
	$fpath->{airi} = $gene_dir.'/'.$fpath->{genename}.'.airi' if ! defined $fpath->{airi};
	$fpath->{nazuna} = $gene_dir.'/'.$fpath->{genename}.'.nazuna' if ! defined $fpath->{nazuna};
	$fpath->{genome} = $gene_dir.'/'.$fpath->{genename}.'.genomne.fa' if ! defined $fpath->{genome};
	$fpath->{est} = $gene_dir.'/'.$fpath->{genename}.'.est.fa' if ! defined $fpath->{est};
	$fpath->{sim4} = $gene_dir.'/'.$fpath->{genename}.'.sim4' if ! defined $fpath->{sim4};
	$fpath->{ele} = $gene_dir.'/'.$fpath->{genename}.'.ele' if ! defined $fpath->{ele};
	$fpath->{eleseq} = $gene_dir.'/'.$fpath->{genename}.'.ele.all' if ! defined $fpath->{eleseq};
	$fpath->{est_gb} = $gene_dir.'/'.$fpath->{genename}.'.gb' if ! defined $fpath->{est_gb};
	return $fpath;
}

=header
Execute est2genome.
=cut
sub exec_est2genome {
	my ($path, $fa_est , $fa_genome , $opt , @dummy) = @_;

	$fa_est =~ m/(.*)(\.[a-zA-Z0-9]*)$/;
	my $e2g = $1.'.est2genome';
	my $cmd = $path . '-estsequence ' . $fa_est . ' -genomesequence ' . $fa_genome . ' -outfile ' . $e2g;
	$cmd .= ' ' . $opt if defined $opt;
	system($cmd);
}


=header
Upload file.
=cut
sub upload_file {
	return 1;
}


=header
Read fasta file.
=cut
sub read_fasta {
	my $path = shift;
	my $seq = "";
	open (my $fh, '<', $path) or die;
	while (my $buff = <$fh>) {
		chomp($buff);
		$seq .= $buff if $buff !~ /^>/;
	}
	close($fh);
	return $seq;
}



1;
