#!/usr/bin/perl

use strict;
use 5.10.0;
use CGI qw(:standard);
use CGI::Cookie;
use CGI::Carp ('fatalsToBrowser');
use JSON::Create 'create_json';
use lib '../lib/';
use SAMS;
use common;

my $cgi = new CGI;
my $sams = new SAMS($cgi);
$sams->CheckAccess;
my $user_no =	$sams->{user_no};
$sams->Log("Uu $user_no,".$sams->{user_no});
my $sql="SELECT p.number ,external_id, (SELECT COUNT(*) FROM sams_userdata.visits v WHERE pat_number=p.number)
  FROM sams_userdata.patients p
	WHERE p.number IN (SELECT pat_no FROM sams_userdata.pat2doc pd
	WHERE doc_no = ?)
	 GROUP BY p.NUMBER, EXTERNAL_ID
	ORDER BY p.number;	 ";

my $result = $sams->Query(\$sql,[$user_no]);
$sams->PegOut("No patients ") unless @$result;
my @phenopackets=();
foreach my $tuple (@$result) {
	my ($pat_no,$ext_id,$visits)=@$tuple;
	$sams->Log("PEV $pat_no,$ext_id,$visits");
	if ($visits) {
		push @phenopackets,$sams->ExportPhenopacket($pat_no,$ext_id,undef);
	}
}
$sams->PegOut("No patients with visits ") unless @phenopackets;

	
print "Content-type: application/json; charset=UTF-8\n\n";	
my $jc = JSON::Create->new ();
$jc->indent(1);
print $jc->run(\@phenopackets);