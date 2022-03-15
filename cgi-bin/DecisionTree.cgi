#!/usr/bin/perl

$|=1;
use strict;
use CGI; 
use CGI::Carp ('fatalsToBrowser');
use utf8;
use 5.10.0;
use Data::Dumper;
use Encode; 
use JSON;
use JSON::Parse qw /parse_json assert_valid_json/;
use lib '../lib/';  #/
use SAMS;
use Prediction;

#parameter for Prediction.pm
my $num_of_quest = 3;                       #number of interesting symptoms
my $num_of_dis = 10;                        #number of diorders

my $cgi=new CGI;
my $sams=new SAMS($cgi);
my %FORM=$cgi->Vars();
my $json=$FORM{'hits'};

ExitWithJSON() unless $json;

my %allPheno;   #hash for symptoms
$allPheno{"num_of_quest"} = $num_of_quest;     #number of interesting symptoms
$allPheno{"num_of_dis"} = $num_of_dis;			#number of diorders

eval {
    assert_valid_json ($json);
};

if ($@) {
	ExitWithJSON();
}

my $allPheno=parse_json($json); 

my $prediction_array = disorders_to_syms($allPheno);

if ($prediction_array and @$prediction_array) {
    my $pheno=new SAMS;
    for (my $i = 0; $i <= $#$prediction_array; $i++){
        my $dis = $prediction_array->[$i][0];
        $prediction_array->[$i][1]= $pheno->GetTerm($dis,"Orphanet");
		  my $disease=$pheno->GetTerm($dis,"Orphanet");
		  my $orphaid= $prediction_array->[$i][0];
        $prediction_array->[$i][1]= $disease;
        for (my $j; $j < $num_of_quest; $j++){
            my $sym = $prediction_array->[$i][4][$j];
				my $hpid=sprintf("HP:%07d",$prediction_array->[$i]->[5]->[$j]);
				my $term=$pheno->GetTerm($sym,"HPO");
           $prediction_array->[$i][5][$j] = $term;
        }
    }
}

#convert to json and return to JS
print "Content-type: application/json; charset=UTF-8\n\n";
print EncodeJSON($prediction_array);

sub EncodeJSON {
    my $s = JSON::to_json(shift, { allow_blessed => 1, allow_nonref => 1 });
    $s =~ s{/}{/}g;
    return $s;
}

sub ExitWithJSON {
	print "Content-type: application/json; charset=UTF-8\n\n";
	exit 0;
}
