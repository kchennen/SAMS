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
print STDERR "UO $user_no\n";
unless ($sams->{input}->{'external_id'}){
	$sams->PegOut("Patient ID must not be empty or 0");
}

if (length ($sams->{input}->{'external_id'})>8) {
	$sams->PegOut("Patient ID must not be longer than 8 characters!");
} 
unless ($user_no) {
	die ("NO USER ".$sams->{user_no});
}

my @errors;

$sams->{input}->{consanguinity} =undef unless $sams->{input}->{consanguinity};

unless  ($sams->{input}->{'edit_pat_bool'}) {
	my $sql="SELECT number FROM sams_userdata.patients WHERE external_id=? AND created_by=? ";
	my $pat_no=$sams->QueryValue(\$sql,[$sams->{input}->{external_id},$user_no]);
	$sams->PegOut("Could not insert/update patient!", "Patient ".$sams->{input}->{external_id}." already exists!") if $pat_no;
	my $sql="INSERT INTO sams_userdata.patients (created_by, external_id, sex, consanguinity, creation_date) VALUES (?,?,?,?,NOW()) RETURNING number";
	my $new_pat_no=$sams->QueryValue(\$sql,[$user_no,@{$sams->{input}}{qw /external_id sex consanguinity/}]);
	push @errors,"Could not insert patient. Did you specify an existing ID?" unless $new_pat_no;
	unless (@errors) {
		my $insert_pat2doc = $sams->{dbh}->prepare("INSERT INTO sams_userdata.pat2doc (doc_no, pat_no) VALUES (?, ?)")
			|| push @errors,"Could not assign patient to you.";
		$insert_pat2doc->execute($user_no, $new_pat_no) || push @errors,"Could not assign patient to you.";
	}
}
else {
	die ("No patient") unless $sams->{input}->{pat_no};
	my $owner=$sams->CheckPatientAccess;
	$sams->PegOut("Not your patient!") unless $owner eq 'own';
	my $q_pat = $sams->{dbh}->prepare("UPDATE sams_userdata.patients SET external_id = ?, sex = ?, consanguinity = ? WHERE number = ?")
		|| push @errors,"Could not update patient.";

	$q_pat->execute(@{$sams->{input}}{qw /external_id sex consanguinity pat_no/})
		|| push @errors, (
		"Your input was: '".$sams->{input}->{external_id}."'",
		"You must not use an existing ID.",
		"Please check the ID for special characters.");
 }
  
unless (@errors) {
	$sams->Commit();
}
else {
	$sams->PegOut("Could not insert/update patient!",{list=>\@errors});
}

$sams->PrintPage('manage_patients.cgi');
