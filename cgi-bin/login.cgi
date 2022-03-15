#!/usr/bin/perl
$| = 1;
use strict;
use CGI;
use CGI::Carp ('fatalsToBrowser');
use lib '../lib/';
use SAMS;

my $cgi = new CGI;
my $sams = new SAMS($cgi);

if ($sams->{input}->{withoutlogin}) {
	$sams->{input}->{email}='no_user';
	$sams->{input}->{password}='nopassword';
}
elsif (! ($sams->{input}->{email} and $sams->{input}->{password})) {
	 $sams->PegOut("You cannot login without password and name.");
}
# $sams->DeleteCookie;
$sams->CheckAccess;

if ($sams->{role} eq "pat") {
  $sams->PrintPage('previous_visits.cgi');
}
elsif ($sams->{role} eq "doc") {
  $sams->PrintPage('manage_patients.cgi');
}
else {
  $sams->PegOut("Something went very wrong");
}
