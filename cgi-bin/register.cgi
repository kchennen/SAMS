#!/usr/bin/perl

$| = 1;
use strict;
use CGI;
use CGI::Carp ('fatalsToBrowser');
#use utf8;
use Encode;
use lib '../lib/';
use SAMS;

my $cgi = new CGI;
my $sams = new SAMS($cgi);

$sams->production( 'Error', 0, 'index.tmpl', {EMAIL_STATE => 1, ERROR => "No password."}) 
	unless $sams->{input}->{password} ;


$sams->production( 'Error', 0, 'index.tmpl', {EMAIL_STATE => 1, ERROR => "Passwords mismatch."}) 
	unless $sams->{input}->{password} eq  $sams->{input}->{password_repeat};

$sams->production( 'Error', 0, 'index.tmpl', {EMAIL_STATE => 1, ERROR => "Please register either as a patient or a physician."}) 
	unless $sams->{input}->{role} eq "doc" or $sams->{input}->{role} eq "pat";

$sams->DeleteCookie;

my @fields = qw/fname lname department email/;
foreach my $field (@fields) {
  $sams->{input}->{$field} = encode("UTF-8", $sams->{input}->{$field});
}

my $mail_exists = $sams->checkMail($sams->{input}->{email});
$sams->production( 'Error', 0, 'index.tmpl',
	{EMAIL_STATE => 1, ERROR =>  "We already have or had an account for ".$sams->{input}->{email}.". Please choose another login name / email address." }) if $mail_exists;
my $user_no = $sams->insertUser;
$sams->production('Error', 0, 'index.tmpl', {EMAIL_STATE => 1, ERROR => 'problem 141'}) unless $user_no;

# required for setting the cookie!
foreach my $variable (qw/ email role/) {
	$sams->{$variable}=	 $sams->{input}->{$variable}
}
$sams->{name}    = (split /\@/,$sams->{input}->{email})[0] ;


if ($sams->{input}->{role} eq "doc") {
  #creates doc account and redirect to managePatient on success
  my $sql="INSERT INTO sams_userdata.doctors (number, firstname, lastname, department) VALUES (?,?,?,?)";
  my $insert_doc = $sams->{dbh}->prepare($sql) || die ("internal error");
  $insert_doc->execute($user_no, @{$sams->{input}}{qw/fname lname department/})  || die ("internal error");
  $sams->SetCookie;
  $sams->Commit or die ("Could not write to DB");
  $sams->PrintPage("manage_patients.cgi");
  
  
}
elsif ($sams->{input}->{role} eq "pat") {
  #create patient account and redirect to lastPhenos on success
  my $sql= "INSERT INTO sams_userdata.patients (external_id, sex, consanguinity,created_by, creation_date) VALUES (?,?,?,?,NOW()) RETURNING number";
  my $pat_no = $sams->QueryValue(\$sql,[$sams->{input}->{email}, $sams->{input}->{sex}, $sams->{input}->{consanguinity},$user_no]);

  die ("Could not insert patient") unless $pat_no;
   $sams->SetCookie;
  $sams->PrintPage("previous_visits.cgi");
  $sams->Commit  or die ("Could not write to DB");
}
else {
	$sams->PegOut("No role (patient/doc) specified");
}
