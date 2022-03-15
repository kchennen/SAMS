#!/usr/bin/perl
# perl /www/MutationDistiller/cgi-bin/phenotype_autocompletion.cgi   term=dyspha
use HTML::Entities;
use JSON;
use DBI;
use CGI;
use CGI::Carp('fatalsToBrowser');
use strict;
use lib '../lib/';
use SAMS;
print "Content-type: application/json; charset=UTF-8\n\n";

my $cgi=new CGI;
my $sams = new SAMS($cgi);
my $dbh = $sams->{dbh};
my $json = JSON->new->convert_blessed(1);
my $lang_id = $sams->{lang_id};

my $query = $sams->{input}->{term};
exit 0 unless (length $query) >= 3;
my @query_output = ();

if  ($sams->{input}->{term}=~/(\w+):(\d+)/) {
	my ($source,$id)=($1,$2);
	my $db_source=$sams->{prefix2source}->{$source};
	my $table=$sams->{dbID}->{$db_source};
	my $term=$sams->GetTerm($id,$db_source);
	push @query_output, [$db_source, $id, $term, $term, ''];
	PrintOutput();
}

my $db_query     = '%' . (uc $query) . '%';
my @query_vals = $db_query;
my $id_query   = ($query =~ /^\d+$/ ? '%' . $query . '%' : 0);
push @query_vals, $id_query if $id_query;

my @colours = ("blue", "magenta ");





if ($sams->{input}->{dimdi}) {
	my $sql = qq ! SELECT alpha_number,text FROM sams_data.alpha_codes	WHERE UPPER(text) LIKE ? !;
	if ($id_query) {
	  $sql .= " OR cast(alpha_number AS TEXT) LIKE ?";
	}
	$sql .= " ORDER BY text LIMIT 200";
	my $q_orpha = $dbh->prepare($sql);
	$q_orpha->execute(@query_vals) || die("F", $DBI::errstr);
	my $results = $q_orpha->fetchall_arrayref || die("F", $DBI::errstr);
	my %done    = ();
	foreach (@$results) {
	  my ($id, $term) = @$_;
	  next if $done{$term}->{$id};
	  $done{$term}->{$id} = 1;
	  my $display_term = $term;
	  $display_term =~ s/($query)/<b>$1<\/b>/gi;
	  push @query_output, ['DIMDI', $id, $term, $display_term, ''];
	}
}

if ($sams->{input}->{hpo}) {
	# add this line before "FROM sams_data.hpo_terms t" to see which HPO terms are in orphanet...:
	# EXISTS (SELECT id FROM sams_data.hpo_hpo_mxn_orphanet WHERE id=t.id)
	my $hpo_synonyms = $sams->getTranslatedHPOSynonyms($lang_id);
	my $sql          = qq ! SELECT t.id, term, comment,array_to_string(array_agg(syn ORDER BY syn), '; '), 
		EXISTS (SELECT child_id FROM sams_data.hpo_terms_mxn_terms WHERE parent_id=t.id)
			FROM sams_data.hpo_terms t, ( 
				SELECT id,  '' AS "syn"   FROM sams_data.hpo_terms terms WHERE UPPER(term) LIKE ? !;
	$sql .= ' OR cast(id AS TEXT) LIKE ? ORDER BY synonym ' if ($id_query);
	$sql .= qq ! UNION
				SELECT id, synonym AS "syn"  FROM sams_data.hpo_synonyms syn  WHERE UPPER(synonym) LIKE ? !;
	$sql .= ' OR cast(id AS TEXT) LIKE ? ORDER BY synonym ' if ($id_query);
	$sql .= qq ! 
 			 ) q
			WHERE t.id=q.id
			GROUP BY t.id, term, comment ORDER BY term LIMIT 200!;
	my $hpo = $dbh->prepare($sql);
	$hpo->execute(@query_vals, @query_vals) || die("F", $DBI::errstr);
	my $results = $hpo->fetchall_arrayref || die("F", $DBI::errstr);
	my %done;
	my %data=();
	my @ids=();
	my %synonyms=();
	foreach (@$results) {
		my ($id, $term, $comment, $synonyms, $child) = @$_;
		$term =~ s/"/'/g;    #"
		my $display_term = $term;
		$display_term =~ s/($query)/<b>$1<\/b>/gi;
		unless ($data{$id}) {
			$data{$id}=[$id, $term, $display_term,$comment,  $child] ;
			push @ids,$id ;
		}
		$synonyms =~ s /layperson//gi; 
		$synonyms =~ s /EXACT layperson \[.*?\]//g;
		$synonyms =~ s /NARROW layperson \[.*?\]//g;
		$synonyms =~ s /RELATED layperson \[.*?\]//g;
		$synonyms =~ s /BROAD layperson \[.*?\]//g;
		$synonyms =~ s /EXACT\s+\[.*?\]//g;
		$synonyms =~ s /NARROW\s+\[.*?\]//g;
		$synonyms =~ s /RELATED\s+\[.*?\]//g;
		$synonyms =~ s /BROAD\s+\[.*?\]//g;
		$synonyms =~ s /EXACT//g;
		$synonyms =~ s /NARROW//g;
		$synonyms =~ s /RELATED//g;
		$synonyms =~ s /BROAD//g;
		$synonyms =~ s/"/'/g;                    #"
		$synonyms =~ s/$term//g;
		$synonyms =~ s/($query)/<b>$1<\/b>/gi;
		$synonyms =~ s/; (; )+/; /g;
		$synonyms =~ s/\[.*?\]//g;
		$synonyms =~ s/''//g;
		$synonyms =~ s/'s'//g;
		$synonyms=~s/;\s*(;\s*)+/; /g;
		$synonyms =~ s/\s+;/;/g;
		$synonyms =~ s/;;+/;/g;
		$synonyms =~ s/^\s*;\s*//;
		$synonyms =~ s/\s*;\s*$//;
		$synonyms =~ s/^\s+//;
		$synonyms =~ s/\s+$//;
		next if $synonyms eq "''";
		push @{$synonyms{$id}},$synonyms if $synonyms;
	}
	foreach my $id (@ids) {
		my ($id, $term, $display_term,$comment,  $child)=@{$data{$id}};
		if ($synonyms{$id}) {
			foreach my $synonym (@{$synonyms{$id}}) {
				push @query_output, ['HPO', $id, $term, $display_term, $synonym, $child];
			}
		} else {
			push @query_output, ['HPO', $id, $term, $display_term, '', $child];
		}
	}
}

if ($sams->{input}->{orphanet}) {
	my $sql = qq ! SELECT disorder_id,title FROM sams_data.orphanet
			WHERE UPPER(title) LIKE ? !;    # OR UPPER(clinical_symptoms) LIKE ? !;
	if ($id_query) {
		$sql .= " OR cast(disorder_id AS TEXT) LIKE ?";
	}
	$sql .= " ORDER BY title LIMIT 200";
	my $q_orpha = $dbh->prepare($sql);
	$q_orpha->execute(@query_vals) || die("F", $DBI::errstr);
	my $results = $q_orpha->fetchall_arrayref || die("F", $DBI::errstr);
	my %done    = ();
	foreach (@$results) {
		my ($id, $term) = @$_;
		next if $done{$term}->{$id};
		$done{$term}->{$id} = 1;
		my $display_term = $term;
		$display_term =~ s/($query)/<b>$1<\/b>/gi;
		$display_term = '<i class="obsolete">' . $display_term . '</i>' if $display_term =~ /OBSOLETE/;
		push @query_output, ['OrphaNet',$id , $term, $display_term, ''];
	}
}

if ($sams->{input}->{omim}) {
	my $sql = qq ! SELECT mim,title FROM sams_data.omim
			WHERE UPPER(title) LIKE ? !;    #OR UPPER(clinical_symptoms) LIKE ? !;
 # WHERE  AND UPPER(title) LIKE ? !; # OR UPPER(clinical_symptoms) LIKE ? !; # from phenotypes
	if ($id_query) {
		$sql .= " OR cast(mim AS TEXT) LIKE ?";
	}
	$sql .= " ORDER BY title LIMIT 200";
	my $q_omim = $dbh->prepare($sql);
	$q_omim->execute(@query_vals) || die("F", $DBI::errstr);
	my $results = $q_omim->fetchall_arrayref || die("F", $DBI::errstr);
	my %done    = ();
	foreach (@$results) {
		my ($id, $term) = @$_;
		next if $done{$term}->{$id};
		$done{$term}->{$id} = 1;
		$term =~ s/^\W\d+//;
		$term =~ s/\n/;/g;
		$term =~ s/;;+/;/g;
		my $display_term = $term;
		$display_term =~ s/($query)/<b>$1<\/b>/gi;
		push @query_output, ['OMIM', $id, $term, $display_term, ''];
	}
}
push @query_output, ['', $query, ''] unless (@query_output);

PrintOutput();

sub PrintOutput {
	print JSON::to_json(\@query_output);
	exit 0;
}

__END__

SELECT t.id, term, definition, comment,
array_to_string(array_agg(syn), '; ') FROM hpo.ontology_terms t,
( SELECT id,  '' AS "syn"   FROM hpo.ontology_terms WHERE UPPER(term) LIKE '%CANCER%'
UNION
SELECT id, synonym AS "syn", ''  FROM
 hpo.synonyms syn  WHERE UPPER(synonym) LIKE '%CANCER%'
WHERE t.id=q.id
GROUP BY t.id, term, definition, comment ORDER BY t.id


SELECT t.id, term, definition, comment,
	array_to_string(array_agg(syn), '; ') FROM hpo.ontology_terms t,
( SELECT id,  '' AS "syn"   FROM hpo.ontology_terms WHERE UPPER(term) LIKE '%!.(uc $query).qq!%'
UNION
SELECT id, synonym AS "syn", ''  FROM
 hpo.synonyms syn  WHERE UPPER(synonym) LIKE '%CANCER%'
WHERE t.id=q.id
GROUP BY t.id, term, definition, comment ORDER BY t.id




