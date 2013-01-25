#!/usr/bin/perl
use strict;
use CGI;
use CGI::Carp qw(fatalsToBrowser);
use HTML::Template;
use lib::DefArgs;
use Data::Dumper;
require 'lib/common.ph';


#SET UP DEFAULT VALUES.
my $args = DefArgs->new;
my $cgi = CGI->new;

#SET UP PARAM FOR THIS PAGE
my $template_header = HTML::Template->new( filename => $args->template('header.tpl') );
my $template_content = HTML::Template->new( filename => $args->template('settings.tpl') );
my $template_footer = HTML::Template->new( filename => $args->template('footer.tpl') );

my $action = &get_action($cgi);
if($action =~ /update/){
	my @cgiins = $cgi->param;
	foreach my $cgi_key (@cgiins){
		while( my ($key , $value) = each (%{$args})){
			if($key eq $cgi_key){
				$args->{$key} = $cgi->param($cgi_key);
				last;
			}
		}
	}
	$args->update;
}

$args = {};
$args = DefArgs->new;
my $sysvars = [];
while( my ($key , $value) = each(%{$args})){
	my $arg = {};
	$arg->{key} = $key;
	$arg->{value} = $value;
	push(@{$sysvars} , $arg);
}

$template_content->param( SYSTEM_VARS => $sysvars );

print "Content-Type: text/html; charset=UTF-8\n\n";
print $template_header->output;
print $template_content->output;
print $template_footer->output;


