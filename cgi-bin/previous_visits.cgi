#!/usr/bin/perl

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

my $own_patient=0;
#print "Content-Type: text/plain\n\n";
unless ($pat_no) {
	my $sql="SELECT p.number FROM sams_userdata.patients p WHERE p.created_by = ?";
	$pat_no = $sams->QueryValue(\$sql,[$user_no]);
	$own_patient=1;
}
else {
	$own_patient=1 if $sams->CheckPatientAccess eq 'own';
}


my $visits_ref = $sams->GetAllVisits($pat_no, $user_no);


if (@$visits_ref) {
	my $visit_data_ref=$sams->GetVisitExaminations($visits_ref);
	$sams->Log("$pat_no",Dumper($visit_data_ref));
	$sams->production("Previous visits", $sams->getExternalID($pat_no), 'pheno_table.tmpl', {
		PAT_NO=>$pat_no,SYMPS_ARR => $visit_data_ref,
		OWN_PATIENT => $own_patient,
		PREVIOUS_VISITS => 1,
		ROLEISPAT => $sams->{role} eq 'pat',});
}
else {
	$sams->production("Previous visits", $sams->getExternalID($pat_no), 'pheno_table.tmpl', {
		PAT_NO=>$pat_no,SYMPS_ARR => [],
		OWN_PATIENT => $own_patient,
		PREVIOUS_VISITS => 1,

		ROLEISPAT => $sams->{role} eq 'pat',});
}
