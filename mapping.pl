#!/usr/bin/perl
use Data::Dumper;
use strict;
use CGI;
use HTML::Template;
use lib::DefArgs;
use CGI::Carp qw(fatalsToBrowser);

require 'lib/common.ph';


#SET UP DEFAULT VALUES.
my $args = DefArgs->new;
my $cgi = CGI->new;

#SET UP PARAM FOR THIS PAGE
#print STDERR $args->template('header.tpl');
my $template_header = HTML::Template->new( filename => $args->template('header.tpl') );
my $template_content = HTML::Template->new( filename => $args->template('mapping.tpl') );
my $template_footer = HTML::Template->new( filename => $args->template('footer.tpl') );

my $action = &get_action($cgi);


#SWITCH ACTION MODE WITH $action.
#Main process.
if ($action eq 'default') {
	&print_default;
} else {
	my $fa_est = &upload_file($cgi->param('estFaPath'), $args->temporary_dir);
	my $fa_genome = &upload_file($cgi->param('estGenomePath'), $args->temporary_dir);
	my $opt = "";
	&exec_est2genome($args->{'est2genome_path'}, $fa_est, $fa_genome, $opt);
	
}


sub print_default {
	#PRINT HTML PAGW AFTER ALL PROCESSES.
	print "Content-Type: text/html; charset=UTF-8\n\n";
	print $template_header->output;
	print $template_content->output;
	print $template_footer->output;
}



