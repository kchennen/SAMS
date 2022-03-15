#!/usr/bin/perl

$| = 1;
use strict;
use CGI qw(:standard);
use CGI::Cookie;
use CGI::Carp ('fatalsToBrowser');
use Data::Dumper;
use JSON::Create 'create_json';
use lib '../lib/';
use SAMS qw(OrderPhenopacketKeys);
use common;

my @visitArray=();

my $cgi = new CGI;
my $sams = new SAMS($cgi);
$sams->Log("P2D_".join (",",%{$sams->{input}}));
$sams->CheckAccess;
my $user_no =	$sams->{user_no};
my $pat_no = $sams->{input}->{'pat_no'};
$sams->CheckPatientAccess if $pat_no;

my $write2db=1 if $pat_no and $user_no;
my $export_phenopacket=1 if $sams->{input}->{export_phenopacket} or $sams->{input}->{onthefly};
$write2db=0 if $export_phenopacket;



my @errors=();

my %data = ();# Stores symptoms to insert by source and id.
my %insert = ();# Stores blank insert statements for later.

my $title="Check phenotype data";
my $visit_number;
my $deprecation = 0;
my $warning;
my @phenotype = ();
my $date=$sams->{input}->{date};
$sams->PegOut("No diseases or signs specified.") unless $sams->{input}->{"phenotypeboxarea"};
$sams->PegOut("Examination date must be specified") unless $date;



my ($year, $month, $day) = ($1, $2, $3) if $date =~ /^(\d+)-(\d+)-(\d+)$/;

$sams->PegOut("Error", "Incorrect date format: $date. Format must be: YYYY-MM-DD")
	unless $year and $month and $date;
$sams->PegOut("Error", "Examination date is invalid: $date. Format must be: YYYY-MM-DD.")
	if $year < 1950 or $month < 1 or $month > 12 or $day < 1 or $day > 31;

my ($cyear, $cmonth, $cday) = getDateValues();
$sams->PegOut("Error", "Examination date is in the future: $date. Today is: " . getDate() . " (YYYY-MM-DD).")
	if $year > $cyear or ($year == $cyear and $month > $cmonth) or ($year == $cyear and $month == $cmonth and $day > $cday);

my $phenopacketdate = $date . "T00:00:00Z";

my %source2table= (
	"HPO" => ["sams_userdata.visits_mxn_hpo",  "hpo_id"],
	"DIMDI" => ["sams_userdata.visits_mxn_alphacodes",  "alpha_number"],
	"OMIM" => ["sams_userdata.visits_mxn_omim",  "mim"],
	"Orphanet" => ["sams_userdata.visits_mxn_orphanet",  "disorder_id"]);


my %prefix2source= (
	"HP" => 'HPO',
	"ALPHA" => 'DIMDI',
	"OMIM" => 'OMIM',
	"ORPHA" => 'Orphanet');

foreach my $term (split /\n/, $sams->{input}->{"phenotypeboxarea"}) {
	my $source      = $prefix2source{$1}      if ($term =~ /\((\w+):/);
	my $id          = int($1) if ($term =~ /\w+:(\d+)/);
	my $state       = $1      if ($term =~ /\w+:\d+\s(\w+)/);
	my $description = $1      if ($term =~ /\):\s*(.*)/);
	push @errors, "line '$term': no state" unless $state;
	push @errors, "line '$term: $state': invalid state"
		unless $state eq 'PRESENT' or $state eq 'ABSENT' or $state eq 'REMOVE';
	push @errors, "line '$term': no term ID"     unless $id;
	push @errors, "line '$term': no data source" unless $source;

	$data{$source}->{$id} = [$state, $description] unless ($state eq 'REMOVE');
}

$sams->PegOut("Error", {list => \@errors}) if @errors;


# Checks if there is an equal visit date of this patient.

if ($write2db) {
	my $sql="SELECT number FROM sams_userdata.visits WHERE pat_number=? AND visit_date=?";
	my $deprecation=$sams->QueryValue(\$sql,[$pat_no, $date]);
	if ($sams->{input}->{"confirmed"}) {
		if ($deprecation) {
			my $set_dep = $sams->{dbh}->prepare("UPDATE sams_userdata.visits SET deprecated = true WHERE pat_number = ? AND visit_date = ?")
			  || die($DBI::errstr);
			$set_dep->execute($pat_no, $date) || die($pat_no, $date, $DBI::errstr);
		}
		my $sql="INSERT INTO sams_userdata.visits (submit_date,created_by,pat_number, visit_date, deprecated) VALUES (NOW(),?,?,?,false) RETURNING number";
		$visit_number = $sams->QueryValue(\$sql, [$user_no,$pat_no, $date]);
		$title        = "SAMS - Phenotype data entered";
	} else {
		$visit_number = "new";
		$title        = "SAMS - Enter phenotype data?";
	}
}

$write2db=0 unless $sams->{input}->{"confirmed"};

my @hpoidlist=keys %{$data{'HPO'}};

my $hpo_parents=$data{'HPO'}?FindHPOparents([@hpoidlist]):0;

$sams->Log("write $write2db");
# Performs plausability check, adding columns 
my @datalist;

foreach my $source (keys %data) {
	if ($write2db) {
		unless ($insert{$source}) {
			my ($table,$attrib)=@{$source2table{$source}};
			my $sql="INSERT INTO $table (visit_number, status, $attrib) VALUES (?,?,?)";
		  $insert{$source} = $sams->{dbh}->prepare($sql) || die($DBI::errstr);
		}
	}
	foreach my $id (keys %{$data{$source}}) {
		my ($state, $description) = @{$data{$source}->{$id}};
		my @messages=();
		if ($source eq 'HPO' and $hpo_parents) {
			if ($state eq 'PRESENT') {
		OTHERHPOIDS:foreach my $hpoid (@hpoidlist) {
					next unless $hpo_parents->{$id}->{$hpoid};
					next if $hpoid==$id;
					if ($data{$source}->{$hpoid}->[0] eq 'PRESENT')  {
						push @messages,"HPO $hpoid is marked as present - this is not necessary because it is a parent...";
					} elsif ($data{$source}->{$hpoid}->[0] eq 'ABSENT')  {
						push @messages,
						qq !<B class="red">HPO $hpoid is marked as absent - this is impossible because it is a parent.</B>!;
					}
				}
			}
		}
		print STDERR "ID $id/$source\n";
		my $term = $sams->GetTerm($id, $source);
		$description =~ s/\s+$//;
		my ($prettyid) = $sams->prettifyID($source, $id);
		if ($write2db)  {
			$sams->Log("S $source / $insert{$source}");
			$insert{$source}->execute($visit_number, lc $state, $id) || die ("S $source; V $visit_number; state lc $state; ID $id --- $DBI::errstr") ;
		}
		elsif ($export_phenopacket) {
			my $date = 'TODAY';
			push @visitArray, {
				status => $state eq "PRESENT" ? 2 : 0,
				id => $prettyid,
				term => $term
			};
		}
		my $col2="";
		
		my %row_inner = ('source', $source, 'idplain', $id, 'id', $prettyid, 'col', join ("<BR>",@messages), 'status', $sams->status2number($state) , 'col2', $col2, 'term', $term);
		push @datalist, \%row_inner;
	}
}
$sams->Log("D $date $write2db");
my %row = ('date', $date, 'symps', \@datalist);
push @phenotype, \%row;

$warning .= "An examination for the date $date has already been entered.<br>Clicking on \"Save entries\" will overwrite it." if $deprecation;

if ($write2db) {
	$sams->Commit ;
	$warning.="Phenotype stored.";
}
elsif ($export_phenopacket){
	my %phenopacketHash = (
		symps => \@visitArray,
		date => $date
	);
	my @phenopacketArray = ();
	push @phenopacketArray, \%phenopacketHash;
	my $phenopacket;
	if ($sams->{input}->{"onthefly"}) {
		$phenopacket = $sams->ExportPhenopacket(undef,undef,@phenopacketArray);
	} else {
		$phenopacket = $sams->ExportPhenopacket($pat_no,undef,@phenopacketArray);
	}
	print "Content-type: application/json; charset=UTF-8\n\n";	
	my $jc = JSON::Create->new (indent => 1, sort => 1);
	$jc->cmp (\&OrderPhenopacketKeys);
	print $jc->run($phenopacket);
	exit 0;
}

$warning=qq !<B class="red">You must click on save or export.</B>! unless $warning;
$sams->production(
	$title,
	$sams->{input}->{"external_id"},
	'pheno_table.tmpl',
	{ TITLE            => $title,
		warning          => $warning,
		SYMPS_ARR        => \@phenotype,
		CONFIRMED        => $sams->{input}->{confirmed},
		ROLEISDOC        => $sams->{input}->{role} eq 'doc',
		PATIENTTERM      => $sams->{input}->{"patientterm"},
		PHENOTYPEBOXAREA => $sams->{input}->{"phenotypeboxarea"},
		PHENOTYPE_TO_DB  => 1,
		WRITE2DB => 1,
		PAT_NO => $pat_no,
		DATE => $date,
		
	}
);

sub FindHPOparents {
	my $idlist=shift;
	return unless @$idlist;
	my $sql='SELECT id, parents_path FROM sams_data.hpo_parents WHERE id IN ('.join (', ' , ('?') x @$idlist).')';
	my $hporesults=$sams->Query(\$sql,$idlist);
	my %parents=();
	foreach my $tuple (@$hporesults) {
		print DEBUG "$tuple->[0]/$tuple->[1]\n";
		foreach my $parent (split /,/,$tuple->[1]) {
			$parents{$tuple->[0]}->{$parent}=1 unless $parents{$tuple->[0]}->{$parent};
		}
	}
	return \%parents;
}
__END__
