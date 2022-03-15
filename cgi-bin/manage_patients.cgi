#!/usr/bin/perl

$| = 1;
use strict;
use CGI qw(:standard);
use CGI::Cookie;
use CGI::Carp ('fatalsToBrowser');
use lib '../lib/';
use SAMS;

my $cgi = new CGI;
my $sams = new SAMS($cgi);
$sams->CheckAccess;
my $user_no =	$sams->{user_no};
my $pat_no = $sams->{input}->{'pat_no'};
$sams->CheckPatientAccess if $pat_no;

my $sql="SELECT p.number ,external_id, (SELECT COUNT(*) FROM sams_userdata.visits v WHERE pat_number=p.number), created_by, email
  FROM sams_userdata.patients p, sams_userdata.users u
	WHERE u.number=p.created_by AND
	p.number IN (SELECT pat_no FROM sams_userdata.pat2doc pd
	WHERE doc_no = ?)
	 GROUP BY p.NUMBER, EXTERNAL_ID, email
	ORDER BY p.number;	 ";

my $result = $sams->Query(\$sql,[$user_no]);
my $rownum=1;
my @patients_array=();
foreach my $tuple (@$result) {
	my $own_patient=1;
	my $id=$tuple->[1];
	$own_patient=0 unless ($tuple->[3]==$user_no);
    my $owner = $tuple->[4];

	push @patients_array,{rownum=>$rownum++,pat_no=>$tuple->[0],external_id=>$id,number_visits=>$tuple->[2],own_patient=>$own_patient,sharedby=>$own_patient?undef:$owner,}
}
my $notice='';
$sams->production("Patient management", 0, 'manage_patients.tmpl',
	{PAT_ARR =>\@patients_array, NOTICE => $notice});
