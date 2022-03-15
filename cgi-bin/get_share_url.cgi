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

unless ($user_no>1) {
	print "Content-type: application/json; charset=UTF-8\n\n";
	print qq !{"url":"You are not logged in - you data will not be saved and cannot be shared."}!;
	exit 0;
}

my $pat_no = $sams->{input}->{'pat_no'};
$sams->CheckPatientAccess if $pat_no;

my $code=int(rand(1e9));
#write code and pat_no to DB
my $sql="INSERT INTO sams_userdata.share2doc (pat_no, security_code, creation_date) VALUES (?,?,NOW())";
my $q_url = $sams->{dbh}->prepare($sql) || $sams->PegOut($DBI::errstr);
$q_url->execute($pat_no,$code) || $sams->PegOut($DBI::errstr);
$sams->Commit();

my $url = SAMS->getCGIbase(url()).'share_patient.cgi?transaction='.$code;

print "Content-type: application/json; charset=UTF-8\n\n";
print qq !{"url":"$url"}!;
