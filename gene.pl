#!/usr/bin/perl
use strict;
use CGI;
use CGI::Carp qw(fatalsToBrowser);
use HTML::Template;
use lib::DefArgs;
use lib::Nazuna;
use Data::Dumper;
use File::Copy;
use Bio::SeqIO;

require 'lib/common.ph';

my $cgi = CGI->new;
my $args = DefArgs->new;
my $action = &get_action($cgi);
my $gene_name = $cgi->param('genename');
my $seq_type = $cgi->param('seqType') || 'junctions';
my $fpath = &get_files_path($args->gene_dir.'/'.$cgi->param('genename'));

#die Dumper $seq_type;

if ($action =~ /default/){

	my $template_content = HTML::Template->new( filename => $args->template('gene.tpl') );
	my $template_header = HTML::Template->new( filename => $args->template('header.tpl') );
	my $template_footer = HTML::Template->new( filename => $args->template('footer.tpl') );
	
	my $dirlist = &list_up_dir($args->gene_dir);
	my $genelist = [];
	my $i = 0;
	foreach my $name (sort @{$dirlist}){
		$i++;
		my $gene = {};
		$gene->{gene_name} = $name;
		if ($i % 3 == 0){
			$gene->{new_line} = 1;
		} else {
			$gene->{new_line} = 0;
		}
		push(@{$genelist} , $gene);
	}
	$template_content->param( GENELIST => $genelist );
	
	print "Content-Type: text/html; charset=UTF-8\n\n";
	print $template_header->output;
	print $template_content->output;
	print $template_footer->output;
} else {
	my $template_content = HTML::Template->new( filename => $args->template('align.tpl') );
	my $template_header = HTML::Template->new( filename => $args->template('header.tpl') );
	my $template_footer = HTML::Template->new( filename => $args->template('footer.tpl') );

	if ($action =~ /align/) {
		&reset_files($fpath) if (! -e $fpath->{nazuna});
	} elsif ($action =~ /reset/) {
		&reset_files($fpath);
	} elsif ($action =~ /edit/) {
		&update_nazuna($cgi, $fpath, $seq_type);
	}
	
	my $est_io = Bio::SeqIO->new(
			-file => $fpath->{est},
			-type => "fasta");
	my $genome_io = Bio::SeqIO->new(
			-file => $fpath->{genome},
			-type => "fasta");
	my $nazuna = Nazuna->new(
			align_file => $fpath->{nazuna},
			align_format => "nazuna",
			est_seq => $est_io->next_seq->seq,
			genome_seq => $genome_io->next_seq->seq);

	$nazuna->align_seq;
	my $segments = $nazuna->get_alignments($seq_type, $args->seq_limit);

	# Sidebar [File View]
	my $files = &list_up_files($fpath->{root});
	my $flist = [];
	foreach my $name (sort @{$files}) {
		my $f = {};
		$f->{path} = $args->gene_dir($gene_name).'/'.$name;
		my $rpath = $args->root_path; my $pblic = $args->public_html;
		$f->{path} =~ s/$rpath//;
		$f->{name} = $name;
		push(@{$flist} , $f);
	}

	# Gene name
	$fpath->{root} =~ m/.+\/([^\/]+)$/;
	$gene_name = $1 if ($gene_name ne $1);

	my $chk_junction = $seq_type =~ /junction/ ? 'checked' : '';
	my $chk_exon = $seq_type =~ /exon/ ? 'checked' : '';
	my $chk_intron = $seq_type =~ /intron/ ? 'checked' : '';
	$template_content->param(
		chkJunction => $chk_junction,
		chkExon => $chk_exon,
		chkIntron => $chk_intron,
		seqType => $seq_type,
		SEGMENTS => $segments,
		GENENAME => $gene_name,
		FILELIST => $flist
	);
	
	print "Content-Type: text/html; charset=UTF-8\n\n";
	print $template_header->output;
	print $template_content->output;
	print $template_footer->output;
}


=comment
 Update sequence from CGI paramaters.
=cut
sub update_nazuna {
	my $cgi = shift;
	my $fpath = shift;
	my $seq_type = shift;
 	my @cgiin = $cgi->param;
	my $segs = [];

	foreach my $name (@cgiin) {
		if ($name =~ m/(genomeSeq)_([\d]+)/) {
			$segs->[$2]->{genome_seq} = $cgi->param($name);
		} elsif ($name =~ m/(estSeq)_([\d]+)/) {
			$segs->[$2]->{est_seq} = $cgi->param($name);
		} elsif ($name =~ m/(nodeGenomeStart)_([\d]+)/) {
			$segs->[$2]->{genome_start} = $cgi->param($name);
		} elsif ($name =~ m/(nodeEstStart)_([\d]+)/) {
			$segs->[$2]->{est_start} = $cgi->param($name);
		} elsif ($name =~ m/^seqTepe$/) {
			$seq_type = $cgi->param($name);
		}
	}

	my $est_io = Bio::SeqIO->new(
			-file => $fpath->{est},
			-type => "fasta");
	my $genome_io = Bio::SeqIO->new(
			-file => $fpath->{genome},
			-type => "fasta");
	my $nazuna = Nazuna->new(
			align_file => $fpath->{nazuna},
			align_format => "nazuna",
			est_seq => $est_io->next_seq->seq,
			genome_seq => $genome_io->next_seq->seq);
	$nazuna->align_seq;
	#$nazuna->update_junctions($segs, $args->seq_limit);
	$nazuna->update_seq($seq_type, $segs, $args->seq_limit);
	$nazuna->write_seq($fpath->{nazuna});
}


=comment
 Reset nazuna file.
=cut
sub reset_files {
	my $fpath = shift;
	if (! -d $fpath->{root}) {
		die "No GENE directory. The data has been removed.\n";
	}

	unlink $fpath->{nazuna} if -e $fpath->{nazuna};
	unlink $fpath->{ele} if -e $fpath->{ele};
	unlink $fpath->{eleseq} if -e $fpath->{eleseq};

	my $est_io = Bio::SeqIO->new(
			-file => $fpath->{est},
			-type => "fasta");
	my $genome_io = Bio::SeqIO->new(
			-file => $fpath->{genome},
			-type => "fasta");
	my $nazuna = Nazuna->new(
			align_file => $fpath->{est2genome},
			align_format => 'est2genome',
			est_seq => $est_io->next_seq->seq,
			genome_seq => $genome_io->next_seq->seq);
	$nazuna->align_seq;
	$nazuna->write_seq($fpath->{nazuna});
}


