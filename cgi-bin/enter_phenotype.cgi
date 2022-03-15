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
my $sql="SELECT COUNT(DISTINCT(visit_date)),MAX(visit_date) FROM sams_userdata.visits WHERE pat_number=? AND NOT deprecated";

my ($vcount,$last_vdate)=$sams->QueryValues(\$sql,[$pat_no]);
$last_vdate='no previous visits' unless $last_vdate;
# $last_vdate makes it clear that we look for the last visit, not the current one
print STDERR "EP fertig $sams->{input}->{onthefly}\n";
$sams->production("Enter phenotype ".$sams->{input}->{external_id}, $sams->{input}->{external_id}, "enter_phenotype.tmpl",
{
	VDATE  => $last_vdate,
	VCOUNT => $vcount,
	PAT_NO=> $pat_no,
	EXPERIMENTAL_FEATURES => $sams->{experimental_features},
	ONTHEFLY=>$sams->{input}->{onthefly}?1:0,
	PHENOTYPEBOXAREA => $sams->{input}->{phenotypeboxarea},
	DATE => $sams->{input}->{date},
  });

__END__
