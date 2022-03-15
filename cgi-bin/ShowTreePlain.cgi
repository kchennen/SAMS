#!/usr/bin/perl
use strict;
use CGI;
use CGI::Carp('fatalsToBrowser');
use JSON;
use lib '../lib/';
use SAMS;

my $cgi   = new CGI;
my $sams = new SAMS($cgi);
my $id           = $sams->{input}->{hpoid};
my $query        = $sams->{input}->{term};

my $sql          = qq ~
  SELECT "type",x.id, term, comment,  array_to_string(Array(SELECT synonym from sams_data.hpo_synonyms sy where sy.id=x.id
  and language_id=0
  ), '; '), has_children FROM (
    SELECT 'P' AS "type",terms.id, term, comment,true  AS "has_children" FROM 
    sams_data.hpo_terms terms, sams_data.hpo_terms_mxn_terms c
    WHERE c.parent_id=terms.id AND child_id=?
    UNION
    SELECT 'H' AS "type",id, term, comment,EXISTS (SELECT child_id FROM sams_data.hpo_terms_mxn_terms WHERE parent_id=id) AS "has_children" FROM sams_data.hpo_terms  terms
    WHERE id=?
    UNION
    SELECT 'C' AS "type",terms.id, term, comment,EXISTS (SELECT child_id FROM sams_data.hpo_terms_mxn_terms WHERE parent_id=id) AS "has_children" FROM sams_data.hpo_terms  terms, sams_data.hpo_terms_mxn_terms c
    WHERE c.child_id=terms.id AND parent_id=?) x
  ORDER BY type DESC~;    

my $results = $sams->Query(\$sql,[$id, $id, $id]);
my %done;
my @query_output = ();

foreach my $tuple (@$results) {
  my ($type, $id, $term, $comment, $synonyms, $children) = @$tuple;
  next if $done{$term}->{$id};
  $done{$term}->{$id} = 1;  
  $term =~ s/"/'/g;     #$term=' children:'.$children.'#'.$term;
  my $display_term = $term;
  $display_term =~ s/($query)/<b>$1<\/b>/gi;
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
  push @query_output, [$type, $id, $term, $display_term, $synonyms, $children];
}
push @query_output, ['', $query, ''] unless (@query_output);
print "Content-type: application/json; charset=UTF-8\n\n";
print JSON::to_json(\@query_output);


__END__
