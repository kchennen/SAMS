#!/usr/bin/perl
$| = 1;
use strict;
use CGI;
use CGI::Carp ('fatalsToBrowser');
use lib '../lib/';
use SAMS;
print STDERR "logout\n";
my $cgi = new CGI;
my $sams = new SAMS;
my %FORM  = $cgi->Vars();


$sams->CheckAccess(@FORM{qw/email password/});

$sams->DeleteCookie;

print $cgi->redirect(-url => 'index.cgi')
