#!/usr/bin/perl

$| = 1;
use strict;
use CGI qw(:standard);
use CGI::Cookie;
use CGI::Carp ('fatalsToBrowser');
use Data::Dumper;
use 5.10.0;

use JSON::Parse qw /parse_json valid_json/;
use lib '../lib/';
use SAMS;
use lib '/www/lib/';
use common;

my $handlers=[qw / subject phenotypicFeatures  diseases id/];

my @html=();
my $write2db=1;

my %sex=('MALE' => 'm', 'FEMALE'=>'f');
my %insert=();
my @hpoidlist=();
my @warnings=();
my @errors=();
my $cgi = new CGI;
$CGITempFile::TMPDIRECTORY='/raid/tmp/SAMS/';
my $sams = new SAMS($cgi);



my $user_no = $sams->CheckAccess;
$sams->PrintPage("index.cgi") unless $user_no;

unless ($sams->{input}->{confirmed}) {
	$sams->production("Import Phenopackets", $sams->{input}->{external_id}, "_html_page.tmpl", { IMPORT_WELCOME => 1 });	
	exit 0;
}

my $fh = $cgi->upload('filename');
unless ($fh){
	die("File could not be read.");
};

my $lines=join ("\n",(<$fh>));

$sams->PegOut("Phenopacket not valid","Please check your file for formatting problems, see xxxxx") unless valid_json($lines);
my $json = parse_json($lines);
my @out=();

if ( ref($json) eq "ARRAY") {
	$sams->PegOut("Only single patient phenopackets.","We can only import single patient phenopackets yet");
	 foreach my $phenopacket (@{$json}) {
		ReadPhenopacket($phenopacket);
	 }
}
elsif ( ref($json) eq "HASH") {
	ReadPhenopacket($json);
}

unshift @html,qq !<h3 class="green bold">PATIENT INSERTED.</h3>!;
$sams->Commit;


if (@warnings) {
	unshift @warnings,qq !<B class="red bold">WARNINGS</B>!;
}


$sams->production("Import successful", $sams->{input}->{external_id}, "_html_page.tmpl", {
	HTML  => join ("<BR>\n",@html,@warnings),   
});	
	
sub ReadPhenopacket {

	my $phenopacket=shift;
	my ($person,$created,$creator,$sex);
	my $subject = $phenopacket->{subject};
	my $id = $phenopacket->{id};
	my $metadata = $phenopacket->{metaData};
	my $pheno_features = $phenopacket->{phenotypicFeatures};
	if ($phenopacket->{'metaData'}) {
		if ($phenopacket->{'metaData'}->{'resources'}) {
			foreach my $datasource (@{$phenopacket->{'metaData'}->{'resources'}}) {
				my $dsid=$datasource->{id};
				push @warnings,"SAMS cannot handle data from $dsid yet. These entries were skipped." unless $SAMS::source2id{$dsid};
			}
		}
		$created= dateAsNumber( $phenopacket->{'metaData'}->{created}) if $phenopacket->{'metaData'}->{created};

		$creator=$phenopacket->{'metaData'}->{createdBy};
	}
	if ($phenopacket->{'subject'}){
		$person=$phenopacket->{'subject'}->{id};
		$sex=$phenopacket->{'subject'}->{sex};
	}
	push @html, "This is a phenopacket for $person ($sex) (created by $creator on $created)";
	my %used_dates;
	if ($created) {
		$used_dates{$created}=1;
	} else {
		my $today=dateAsNumber(getDate());
		$used_dates{$today}=1;
	}
	my %interval=();
	my %timestamp=();
	my %notime=();
	my %source=();
	my %term_number=();
	my %label=();
	foreach my $entity (qw /phenotypicFeatures diseases/){
		my %feature_status=();
		if ($phenopacket->{$entity}) {
			FEATURE: foreach my $feature (@{$phenopacket->{$entity}}){
				my $status=$feature->{excluded} eq 'true'?'absent':'present';
				my $id;
				foreach my $schema (qw /term type/) {
					if ($feature->{$schema}) {
						$id=$feature->{$schema}->{id};
						$label{$id}=$feature->{$schema}->{label};
						($term_number{$id},$source{$id})=AddSource($id) unless $term_number{$id};
						unless ($source{$id}) {
							push @warnings,"$id ($label{$id}) skipped - SAMS does not include the data source.";
							next FEATURE;
						}

					}
				}
				if ($feature->{onset}) {
					if ($feature->{onset}->{interval}){
						my %limits=();
						foreach my $dates (qw /start end/) {
							my $date = dateAsNumber($feature->{onset}->{interval}->{$dates});
							$limits{$dates}=$date;
							$used_dates{$date}=1 unless $used_dates{$date};
							die if $feature_status{$id}->{$date};
						}
						push @{$interval{$id}},[$limits{start},$limits{end},$status];
						push @html,"INTERVAL $id\t$status\t$label{$id}\t$limits{start} - $limits{end}";
					}
					elsif ($feature->{onset}->{timestamp}){
						my $date = dateAsNumber($feature->{onset}->{timestamp});
						$used_dates{$date}=1 unless $used_dates{$date};
						$timestamp{$id}->{$date}=$status;
						push @html,"TIMESTAMP $id\t$status\t$label{$id}\t$date";
					}					
				}
				elsif ($feature->{classOfOnset}) {
					if ($feature->{classOfOnset}->{label} eq "Congenital onset") {
					#	$notime{$id}=$status;
						my $date=19000101;
						$used_dates{$date}=1 unless $used_dates{$date};
						$timestamp{$id}->{$date}=$status;
						push @html,"CONGENITAL $id\t$status\t$label{$id}";
					} else {
						$sams->PegOut("Unknown classOfOnset: ".$feature->{classOfOnset}->{label});
					}
				}
				else {
					push @html,"NO TIME $id\t$status\t$label{$id}";
					$notime{$id}=$status;
				}
			}
		}
		
	}
	my @visits=sort keys %used_dates;
	my %visit_index=();
	my $vnum=0;
	foreach my $visit (@visits) {
		$visit_index{$visit}=$vnum++;
	
	}
	push @html, "USED DATES: ",join (", ",@visits);
	
		

	
	
	foreach my $entity (keys %$phenopacket) {
		push @warnings,"SAMS cannot handle $entity data yet - these entries were skipped." unless $entity~~$handlers;
	}

	
	

	
	my $vnum=0;
	foreach my $id (keys %interval) {
		foreach my $interval (@{$interval{$id}}) {
			my ($start,$end,$status)=@$interval;
			for (my $visit_index=$visit_index{$start};$visit_index<=$visit_index{$end};$visit_index++) {
			#	say "$id - $visits[$visit_index] - $status";
				$sams->PegOut ("Format error - timestamp and interval conflict for $id") if $timestamp{$id}->{$visits[$visit_index]};
				$timestamp{$id}->{$visits[$visit_index]}=$status;
			}
		}
	}

	foreach my $id (keys %notime) {
		foreach my $date (@visits){
			$sams->PegOut ("Format error - timestamp and 'no time' conflict for $id") if $timestamp{$id}->{$date};
			$timestamp{$id}->{$date}=$notime{$id};
		}
	}
	my @visitdata=();
	foreach my $id (keys %timestamp) {
		foreach my $date (keys %{$timestamp{$id}}){
			my $visit_index=$visit_index{$date};
			$visitdata[$visit_index{$date}]->{$source{$id}}->{$term_number{$id}}=[$timestamp{$id}->{$visits[$visit_index]},$label{$id}];
	#		say "$visit_index{$date} / $source{$id} / $term_number{$id}";
#			push @phenotype,[$id,$date,$timestamp{$id}->{$date}];
		}
	}
	
	#say join ("\n","++++++++++++++++++","WARNINGS",@warnings,"\n");
	my $hpo_parents=@hpoidlist?FindHPOparents([@hpoidlist]):0;
#	say Dumper(\@visitdata);

	my $pat_no=CreatePatient($person,$sex);
	InsertVisits(\@visits,\@visitdata,$pat_no,$hpo_parents);
	
#	say "\n\nPhenopacket:\n",Dumper($phenopacket),"\n\n";
}

sub InsertVisits {
	my ($visits,$visitdata,$pat_no,$hpo_parents)=@_;
	foreach my $visit_index (0..$#$visitdata) {
		my $sql="INSERT INTO sams_userdata.visits (submit_date,created_by,pat_number, visit_date, deprecated) VALUES (NOW(),?,?,?,false) RETURNING number";
		my $visit_number = $sams->QueryValue(\$sql, [$user_no,$pat_no, $visits->[$visit_index]]);
		push @html, "create VISIT  on $visits->[$visit_index] as $visit_number";
		InsertPhenotype($visitdata->[$visit_index],$visit_number++,$hpo_parents);
	}
}


sub dateAsNumber {
	my $date=shift;
	die ("Wrong date format: ".$date." - should be YYYY-MM-DD.")
			unless $date=~/(\d{4})-(\d{2})-(\d{2})/;
	return sprintf ("%4d%02d%02d",$1,$2,$3);
	
}

sub CreatePatient {
	my ($ext_id,$sex)=@_;
	$sex=$sex{$sex};
	unless ($ext_id) {
		$sams->PegOut("No subject ID - cannot insert.");
	}
	
	my $external_id=substr($ext_id,0,8);
	push @html, "INSERT PATIENT $external_id (sex: $sex)";
	unless ($ext_id eq $external_id) {
		push @warnings,"Subject (patient) ID $ext_id longer than 8 characters, truncated to $external_id";
		push @html,"original ID $ext_id was longer than 8 characters, truncated to $external_id";
	}
	
	my $sql="SELECT number FROM sams_userdata.patients WHERE external_id=? AND created_by=? ";
	my $pat_no=$sams->QueryValue(\$sql,[$external_id,$user_no]);
	$sams->PegOut("Could not insert/update patient!", "Patient $external_id already exists!") if $pat_no;
	my $sql="INSERT INTO sams_userdata.patients (created_by, external_id, sex, creation_date) VALUES (?,?,?,NOW()) RETURNING number";
	my $new_pat_no=$sams->QueryValue(\$sql,[$user_no,$external_id,$sex]);

	$sams->PegOut("Could not insert patient. Did you specify an existing ID?") unless $new_pat_no;
		my $insert_pat2doc = $sams->{dbh}->prepare("INSERT INTO sams_userdata.pat2doc (doc_no, pat_no) VALUES (?, ?)")
			|| push @errors,"Could not assign patient to you.";
		$insert_pat2doc->execute($user_no, $new_pat_no) || push @errors,"Could not assign patient to you.";
	return $new_pat_no;
}

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

sub AddSource {
	my $term=shift;
	my $source  = $sams->{prefix2source}->{$1}      if ($term =~ /(\w+):/);
	return 0 unless $source;
	my $number=int($1) if ($term =~ /\w+:(\d+)/);
	if ($source eq 'HPO') {
		push @hpoidlist,$number;
	}
	return ($number,$source) if $insert{$source};
	my ($table,$attrib)=@{$sams->{source2table}->{$source}};
	my $sql="INSERT INTO $table (visit_number, status, $attrib) VALUES (?,?,?)";
	$insert{$source} = $sams->{dbh}->prepare($sql) || die($DBI::errstr);
	return ($number,$source);

}

sub InsertPhenotype {
	my ($data,$visit_number,$hpo_parents)=@_;
	foreach my $source (keys %$data) {
		foreach my $id (keys %{$data->{$source}}) {
			my ($state, $description) = @{$data->{$source}->{$id}};
			my @messages=();
			if ($source eq 'HPO' and $hpo_parents) {
				if ($state eq 'PRESENT') {
		OTHERHPOIDS:foreach my $hpoid (@hpoidlist) {
						next unless $hpo_parents->{$id}->{$hpoid};
						next if $hpoid==$id;
						if ($data->{$source}->{$hpoid}->[0] eq 'PRESENT')  {
							push @warnings,"HPO $hpoid is marked as present - this is not necessary because it is a parent...";
						} elsif ($data->{$source}->{$hpoid}->[0] eq 'ABSENT')  {
							push @warnings,
							qq !<B class="red">HPO $hpoid is marked as absent - this is impossible because it is a parent.</B>!;
						}
					}
				}
			}

			if ($write2db)  {
		#		say "execute $source, $visit_number, lc $state, $id";
				$insert{$source}->execute($visit_number, lc $state, $id) || die ("$source: Term # $id is not in our database.") ;
			}
			my $col2="";
		#	my %row_inner = ('source', $source, 'idplain', $id, 'id', $prettyid, 'col', join ("<BR>",@messages), 'status', $sams->status2number($state) , 'col2', $col2, 'term', $term);
		#	push @datalist, \%row_inner;
		}
	}
}
__END__
