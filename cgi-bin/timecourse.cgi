#!/usr/bin/perl

$| = 1;
use strict;
use CGI qw(:standard);
use CGI::Cookie;
use CGI::Carp ('fatalsToBrowser');
use 5.10.0;
use lib '../lib/';
use SAMS;
use common;


my $cgi = new CGI;
my $sams = new SAMS($cgi);
$sams->CheckAccess;
my $user_no =	$sams->{user_no};
my $pat_no = $sams->{input}->{pat_no};
$sams->CheckPatientAccess if $pat_no;
die ("No patient!") unless $pat_no;
my $visitsref = $sams->GetAllVisits($pat_no, $user_no);

my $external_id = $sams->getExternalID($pat_no);


my @datasources = $sams->getDatasources; 

my %domitable=();
my %domidates=();

$sams->PegOut ("No visits") unless @$visitsref;

foreach (@$visitsref) { # result is visit number, visit date
	my ($vnum, $vdate) = @$_;
	foreach my $datasource (@datasources) {
		my $visit_data = $sams->GetIDStatus($datasource, $vnum); # gets IDs and statuses of symptoms for visit
		foreach (@$visit_data) {
			my ($symp_id, $status) = @$_;
			$vdate='congenital' if $vdate eq '1900-01-01';
			my $term = $sams->GetTerm($symp_id, $datasource);
			$domitable{$datasource}->{$term}->{$vdate}=$status;
			$domitable{$datasource}->{$term}->{ID}=$symp_id;  # ID in der gleichen Ebene wie die Daten, nicht optimal...
			$domidates{$vdate}=1 unless $domidates{$vdate};
		}
	}
}


my @domidates=sort keys %domidates;

my $html_table = qq !<TABLE><TR><TD style="text-align: left">Data source</TD><TD style="text-align: left">ID</TD><TD style="text-align: left">Term</TD><TD>!
	.join ("</TD><TD>",@domidates)."</TD></TR>";

foreach my $datasource  (sort keys %domitable) {
	foreach my $term (sort keys %{$domitable{$datasource}})  {
		my ($formatted_id,$colour)=$sams->prettifyID($datasource,$domitable{$datasource}->{$term}->{ID});
		my $hyperlink=$sams->CreateHyperlink($datasource,$domitable{$datasource}->{$term}->{ID});
		$html_table.= qq !<TR><TD class="$colour" style="text-align: left">$datasource</TD>
		<TD style="text-align: left"><A href="$hyperlink" target="_blank">$formatted_id</A></TD>
		<TD style="text-align: left">$term</TD>!;
		my @states=();
		foreach my $date (@domidates) {
			my $state=($domitable{$datasource}->{$term} and $domitable{$datasource}->{$term}->{$date})?$domitable{$datasource}->{$term}->{$date}:'';
			if (@states and $state eq $states[-1][0]) {
				$states[-1][1]++;
			}
			else {
				push @states,[$state,0];
			}
		}
		foreach my $stateref (@states) {
			my ($state,$count)=@$stateref;
			if ($count) {
				$html_table.= qq !<TD colspan="!.($count+1).qq !" class="$state">$state</TD>!;
			}
			else {
				$html_table.= qq !<TD class="$state">$state</TD>!;
			}
		}
		$html_table.= qq !</TR>!;
	}
}
$html_table.= qq !</TABLE>!;

$sams->production("Time course", $sams->{input}->{external_id}, "_html_page.tmpl", {
	CSS_ANCHOR => 'timecourse',
	HTML  => $html_table,   
});
