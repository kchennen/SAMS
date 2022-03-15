#!/usr/bin/perl

$| = 1;
use strict;
use CGI qw(:standard);
use CGI::Cookie;
use lib '../lib/';
use SAMS;

my $cgi = new CGI;
my $sams = new SAMS($cgi);

$sams->CheckAccess;
my $user_no =	$sams->{user_no};

$sams->PegOut("No patient specified.") unless $sams->{input}->{'pat_no'};
$sams->CheckPatientAccess;

my $sql="SELECT p.sex, p.consanguinity FROM sams_userdata.patients p
		WHERE p.number = ?";
my $data=$sams->Query(\$sql,[$sams->{input}->{pat_no}]);
print "Content-type: application/json; charset=UTF-8\n\n";
print JSON::to_json($data);
