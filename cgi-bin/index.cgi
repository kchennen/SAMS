#!/usr/bin/perl

use strict;
use CGI qw(:standard);
use CGI::Carp ('fatalsToBrowser');
use CGI::Cookie;
use lib '../lib/';
use SAMS;

my $cgi   = new CGI;
my $sams  = new SAMS($cgi);

if ($sams->CheckAccess) {
	print STDERR "XXX",$sams->{user_no},"\n";
	$sams->PrintPage('manage_patients.cgi') if $sams->{role} eq 'doc';
	$sams->PrintPage('previous_visits.cgi') if $sams->{role} eq 'pat';
}

my $template = HTML::Template->new(
  filename          => '../templates/index.tmpl',
  global_vars       => 1,
  die_on_bad_params => 0
);

print "Content-Type: text/html\n\n", $template->output;
