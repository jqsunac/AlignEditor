package DefArgs;
use Data::Dumper;
=comment

 == ACTION ==
 Defained arguments with CONFIG file.
 The CONFIG file has two column, 1st column will be argument's name, 
 the 2nd column will be argument's value. And the delimeter is '\t'.

 == CONFIG ==
 ----------------------------------
 |template_dir	/template
 |gene_dir	/gene
 |root_path	/root/public_html
 |lim	50
 |etc ...
 ---------------------------------- 

 == USE ==
 use DefineArguments;
 my $args = DefineArguments->new;
 //Template dir
 my $template = $args->template_dir.'/index.tmpl';

=cut



sub new {
	my $class = shift;
	my $self = {};
	$self = &_get_args('./CONFIG');
	return bless $self , $class;
}

=comment
 Getter method.
=cut


#Gene access methods.
sub gene_dir {
	my $self = shift;
	if (defined $_[0]) {
		return $self->{gene_dir}.'/'.$_[0];
	} else {
		return $self->{gene_dir};
	}
}
sub set_gene_dir {
	my $self = shift;
	$self->{gene_dir} = shift;
}

#この関数はおかしい。
sub est2genome {
	my $self = shift;
	opendir(my $DIR, $self->{gene_dir}.'/'.$_[0]);
	my $e2g_path = grep(/\.est2genome$/ , readdir($DIR));
	closedir($DIR);
	return $self->{gene_dir}.'/'.$_[0].'/'.$e2g_path;
}





#Template access methods.
sub template_dir {
	my $self = shift;
	return $self->{template_dir};	
}
sub template {
	my $self = shift;
	return $self->{template_dir}.'/'.$_[0];
}
sub temporary_dir {
	my $self = shift;
	return $self->{temporary_dir};	
}
sub temporary {
	my $self = shift;
	return $self->{temporary_dir}.'/'.$_[0];
}
sub set_temporary_dir {
	my $self = shift;
	$self->{temporary_dir} = shift;
}
sub set_template_dir {
	my $self = shift;
	$self->{template_dir} = shift;
}
sub root_path {
	my $self = shift;
	return $self->{root_path};
}
sub set_root_path {
	my $self =shift;
	$self->{root_path} = shift;
}
sub public_html {
	my $self = shift;
	return $self->{public_html};
}
sub set_public_html {
	my $self = shift;
	$self->{public_html} = shift;
}
sub seq_limit {
	my $self = shift;
	return $self->{seq_limit};
}
sub set_seq_limit {
	my $self = shift;
	$self->{seq_limit} = shift;
}
sub est2genome_path {
	my $self = shift;
	return $self->{est2genome_path};
}
sub set_est2genome_path {
	my $self = shift;
	$self->{est2genome_path} = shift;
}



=comment
 DefineArguments method.
=cut



=function _get_args
 Read CONFIG file, and set up paramater to $self object.
 Called from $self->new('./CONFIG') .
=cut
sub _get_args {
	my $args = {};
	$args->{config_path} = shift;
	open(my $conff , '<' , $args->{config_path}) or die "config FILE DOESN'T EXISTS.\n";
	while(my $buff = <$conff>){
		#Skip to blank line.
		#Skip to comment line.
		if (($buff !~ /[a-zA-Z]/) || ($buff =~ /^#/)) { next }
		#Get argument's settings.
		chomp($buff);
		my @tmp = split(/\t/ , $buff , 2);
		$args->{$tmp[0]} = $tmp[1];
	}
	close($conff);
	return $args;
}


=function update
 Update COFNIG file.
=cut
sub update {
	my $self = shift;
	my @file_buff = ();
	my $new_conf_path = $self->{config_path}.'.buff';

	#Get original settings.
	open(my $original_conf , '<' , $self->{config_path})
		or die "DefArgs::Error::FAILED TO OPEN CONFIG FILE.\nSYS_ERR:$!\n";
	@file_buff = <$original_conf>;
	close($original_conf);
	#Make buffer for new settings.
	open(my $new_conf , '>' , $new_conf_path)
		or die "DefArgs::Error::FAILED TO MAKE NEW CONFIG FILE.\nSYS_ERR:$!\n";
	foreach my $buff (@file_buff) {
		if (($buff !~ /[a-zA-Z]/) || ($buff =~ /^#/)) {
			print $new_conf $buff;
		} else {
			my @tmp = split(/\t/ , $buff , 2);
			my $arg_name = $tmp[0];
			print $new_conf $arg_name."\t".$self->{$arg_name}."\n";
		}
	}
	close($new_conf);
	#Refresh new settings.
	if(unlink $self->{config_path}) {
		rename($new_conf_path , $self->{config_path});
	} else {
		die "DefArgs::Error::FAILEDT TO DELETE OLD CONFIG FILE.\nSYS_ERR:$!\n";
	}
}




1;
