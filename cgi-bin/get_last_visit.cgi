#!/usr/bin/perl
# noch nicht in Betrieb - Code stimmt auch nicht.
$| = 1;
use strict;
use CGI qw(:standard);
use CGI::Cookie;
use CGI::Carp ('fatalsToBrowser');
use Data::Dumper;
use 5.10.0;
use lib '../lib/';
use SAMS;
use common;
my $cgi = new CGI;
my $sams = new SAMS($cgi);
$sams->CheckAccess;
my $user_no =	$sams->{user_no};

my $pat_no = $sams->{input}->{'pat_no'};
$sams->PegOut("No patient specified.") unless $pat_no;
$sams->CheckPatientAccess;

my $sql=" 	SELECT DISTINCT first_value(number) OVER (PARTITION BY pat_number 
					ORDER BY visit_date DESC),MAX(visit_date)
					OVER (PARTITION BY pat_number 
					ORDER BY visit_date DESC) 
					FROM sams_userdata.visits WHERE pat_number=?";
my ($vnum, $vdate) = $sams->QueryValues(\$sql,[$pat_no]);
$sams->Log('$vnum, $vdate'."$vnum, $vdate");
exit 0 unless $vnum;
my $visit_data_ref={};
$sams->GetVisit_last_visit($vnum, $vdate,$visit_data_ref);
#say STDERR $sql,"*$pat_no";
#$sams->Log(JSON::to_json($visit_data_ref));
#my $visit_data_ref=$sams->GetVisitExaminations([[$vnum, $vdate]]);
print "Content-type: application/json; charset=UTF-8\n\n";	 
print JSON::to_json($visit_data_ref);