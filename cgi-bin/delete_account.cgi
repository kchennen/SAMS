#!/usr/bin/perl

$| = 1;
use strict;
use CGI qw(:standard);
use CGI::Cookie;
use CGI::Carp ('fatalsToBrowser');
use DBI;
use lib '../lib/';
use SAMS;

my $cgi = new CGI;
my $sams = new SAMS($cgi);
my $user_no = $sams->CheckAccess;
$sams->PegOut("You are not logged in, there's nothing to delete") unless $user_no>3;




my $sql="SELECT external_id,number FROM sams_userdata.patients WHERE created_by=?";
my $patient_list=$sams->Query(\$sql,[$user_no]);

my ($title,$html)=();
my $show_confirm = 0;



if (scalar @$patient_list==1 and $sams->{role} eq 'pat') {
	$sams->DeletePatient($patient_list->[0]->[1],$user_no);
	$patient_list=[];
}

if (@$patient_list) {
	$title="You cannot delete your account";
	$html='You must deleted your patients before you can delete your account.<BR>Patient IDs are:<UL><LI>'.join ("</LI><LI>",map {$_->[0]} @$patient_list).'</LI></UL>';
}
elsif ($sams->{input}->{confirmed}) {
	my $sql="UPDATE sams_userdata.users SET deleted=CURRENT_DATE WHERE number=?";
#	die ("$sql:$user_no");
	my $del=$sams->{dbh}->prepare($sql) || die;
	$del->execute($user_no) || die($DBI::errstr);
	$title="Account deleted";
	$html="Account deleted";
	$sams->Commit;
	$sams->DeleteCookie;
	$sams->PrintPage('index.cgi');
}
else {
	$title="Delete your account?";
	$html="Are you sure?";
	$show_confirm = 1;
}
$sams->production($title,0, "_html_page.tmpl", {
	HTML  => $html,  
	DELETE_SHOW_CONFIRM => $show_confirm,
});


__END__

my $notice    = $sams->{input}->{'notice'};

  #delete from pat2doc
my $q_del = $sams->{dbh}->prepare("DELETE FROM sams_userdata.pat2doc WHERE doc_no = ? AND pat_no = ?")
    || $sams->PegOut($DBI::errstr);
$q_del->execute($user_no,$pat_no) || $sams->PegOut($DBI::errstr);

  #check if there is still a doc holding the patient
my $sql="SELECT count(*) FROM sams_userdata.pat2doc WHERE pat_no = ?";
my $r_counts = $sams->QueryValue(\$sql,[$pat_no]);


  #if not, delete patient permanently
unless ($r_counts) {
	my $sql="SELECT number FROM sams_userdata.visits WHERE pat_number = ?";
	my $r_num = $sams->Query(\$sql,[$pat_no]);
	
	foreach my $table (qw /visits_mxn_hpo visits_mxn_alphacodes visits_mxn_omim visits_mxn_orphanet visits /) {
		my $number=($table eq 'visits'?'number':'visit_number');
		my $delete = $sams->{dbh}->prepare('DELETE FROM sams_userdata.'.$table.' WHERE '.$number.'=?') || $sams->PegOut($DBI::errstr);
		foreach my $visref (@$r_num) {
			$delete->execute($visref->[0]) || $sams->PegOut($DBI::errstr);
		}
	}
	my $q_pat = $sams->{dbh}->prepare("DELETE FROM sams_userdata.patients WHERE number = ?") || $sams->PegOut($DBI::errstr);
	$q_pat->execute($pat_no) || $sams->PegOut($DBI::errstr);
	$sams->Commit;
}

$notice = "Patient $pat_no deleted!";

$sams->PrintPage("index.cgi");