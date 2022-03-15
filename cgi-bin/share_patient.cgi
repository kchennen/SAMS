#!/usr/bin/perl

use strict;
use CGI;
use CGI::Carp ('fatalsToBrowser');
#use utf8;
use Encode;
use lib '../lib/';
use SAMS;

my $cgi = new CGI;
my $sams = new SAMS($cgi);
$sams->CheckAccess;
my $user_no =	$sams->{user_no};

$sams->PegOut("Not logged in.","You have to be logged in to see shared data. We require this to avoid accidental sharing of private data with the public.") unless $user_no>1 ;


$sams->PegOut("No access code") unless $sams->{input}->{transaction};

my $sql="SELECT pat_no FROM sams_userdata.share2doc WHERE security_code = ? AND (creation_date+'1d')> NOW()";
my $pat_no=$sams->QueryValue(\$sql,[$sams->{input}->{transaction}]);
$sams->PegOut("This access code ".$sams->{input}->{transaction}." is no longer valid.") unless $pat_no ;

my $q_set = $sams->{dbh}->prepare("DELETE FROM sams_userdata.share2doc WHERE security_code = ?") || die;
$q_set->execute($sams->{input}->{transaction}) || $sams->PegOut("This access code ".$sams->{input}->{transaction}." is no longer valid (2).");
$sams->Commit;

$sql="SELECT pat_no FROM sams_userdata.pat2doc WHERE pat_no=? AND doc_no=?";
my $already_there=$sams->QueryValue(\$sql,[$pat_no, $user_no]);
$sams->PegOut("You already have access to this patient.") if $already_there;

$q_set = $sams->{dbh}->prepare("INSERT INTO sams_userdata.pat2doc (pat_no, doc_no) VALUES (?,?)") || die;
$q_set->execute($pat_no, $user_no) || $sams->PegOut("Could not insert sharing for $pat_no, $user_no");
$sams->Commit;

$sams->PrintPage('manage_patients.cgi');
