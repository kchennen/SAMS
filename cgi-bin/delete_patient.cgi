#!/usr/bin/perl

$| = 1;
use strict;
use CGI qw(:standard);
use CGI::Cookie;
use CGI::Carp ('fatalsToBrowser');
use DBI;
use lib '../lib/';
use SAMS;

my $cgi = new CGI;
my $sams = new SAMS($cgi);
$sams->CheckAccess;
my $user_no =	$sams->{user_no};

my $pat_no = $sams->{input}->{'pat_no'};
$sams->PegOut("No patient to delete!") unless $pat_no;
$sams->CheckPatientAccess;

$sams->DeletePatient($pat_no,$user_no);
$sams->Commit;

$sams->PrintPage("index.cgi");