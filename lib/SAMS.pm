package SAMS;
$| = 1;
use HTML::Entities;
use HTML::Template::Pro;
use strict;
use CGI::Cookie;
use DBI;
use JSON::WebToken;
use Crypt::Misc ':all';
use 5.10.0;
use Data::Dumper;
use Switch;
use lib '../lib';
use common;
use parent 'database';

use parent qw(Exporter);
our @EXPORT_OK = qw(OrderPhenopacketKeys);


my $cookie_name='SAMSI-SieWarSoWeich';
my $debug_file='/raid/tmp/sams_debug.txt';  # NEW: debug output is written to this file

# todo: sollten in new ins SAMS-Objekt geschrieben werden
our %source2id = ("HPO" => "hpo_id", "DIMDI" => "alpha_number", "OMIM" => "mim", "Orphanet" => "disorder_id");
our %sympTerm = ("HPO" => "term", "DIMDI" => "text", "OMIM" => "title", "Orphanet" => "title");
our %sympIDName = ("HPO" => "id", "DIMDI" => "alpha_number", "OMIM" => "mim", "Orphanet" => "disorder_id");
our %dbVisit = (
	"HPO"    => "sams_userdata.visits_mxn_hpo",
	"DIMDI" => "sams_userdata.visits_mxn_alphacodes",
	"OMIM"  => "sams_userdata.visits_mxn_omim",
	"Orphanet" => "sams_userdata.visits_mxn_orphanet"
);
our %hyperlinks= (
	"HPO"    => "https://hpo.jax.org/app/browse/term/HP:",
	"DIMDI" => "https://www.dimdi.de/dynamic/de/klassifikationen/downloads/?dir=alpha-id/",
	"OMIM"  => "https://omim.org/entry/",
	"Orphanet" => "https://www.orpha.net/consor/cgi-bin/Disease_Search.php?lng=EN&data_id="
);
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
#our $cgi_base='https://www.genecascade.org/sams-cgi/';


sub Log {
	state $file_open=0;
	shift @_ if ref $_[0] eq 'SAMS';
	unless ($file_open) {
		open (OUT,'>>',$debug_file) or die ($!);
		$file_open=1;
	}
	say OUT join("\n", @_);
#	say STDERR join("\n", @_);
}

####constructor
sub new {
	my ($class,  $cgi) = @_;  #arguments to object may be a hash containing variables needed by methods in this package
	my $obj_ref = {};
	bless $obj_ref, $class;
	$obj_ref->Connect;
	$obj_ref->{user_no} = 0;                   # not logged in
	if (ref $cgi eq 'CGI') {
		my %FORM=$cgi->Vars();
		# get rid of leading/trailing whitespaces
		foreach my $key (keys %FORM) {
			$FORM{$key}=~s/^\s+//;
			$FORM{$key}=~s/\s+$//;
			$obj_ref->{input}  = {%FORM};
		}
		$obj_ref->{cgi}=$cgi;
	}
	$obj_ref->{dbID} = {
		HPO    => "sams_data.hpo_terms",
		DIMDI => "sams_data.alpha_codes",
		OMIM  => "sams_data.omim",
		Orphanet => "sams_data.orphanet"
	};    # use for access with $obj_ref->{dbID}->{Database} -> should be a global variable and passed as %source2tabl
	$obj_ref->{source2table}=\%source2table;
	$obj_ref->{prefix2source}=\%prefix2source;
	return $obj_ref;
}

sub getCGIbase {
    my ($class, $url) = @_;
    $url =~ /^http.*sams\-cgi\//;
	return $&;
}

sub Authenticate {
	my ($self) = @_;
	my ($userid,$passwd)=@{$self->{input}}{qw/email password/};
	say STDERR "SAMS-AUTH";
	say STDERR "UID $userid,$passwd";
	unless ($userid and $passwd) {
	#	$self->PrintPage('index.cgi');
		$self->{email} ='no_user';
		$self->{name}='not logged in';
		$self->{user_no}=1;
		$self->{experimental_features}=0;
		return 0;
	} else {
		my $sql="SELECT email,number,password,role,experimental_features FROM sams_userdata.users WHERE UPPER(email)=UPPER(?) AND deleted IS NULL";
		my ($email,$user_no,$hashed_password,$role,$experimental_features)=$self->QueryValues(\$sql,[$userid]);
		$self->PegOut ("Wrong credentials") unless $email;
	#	$self->Log("$email,$user_no,$hashed_password,$role");
		unless ($hashed_password eq (crypt $passwd, substr($hashed_password, 0, 2))) {
			$self->PegOut ("Wrong credentials");
		}
		$self->{email}   = $email;
		$self->{user_no} = $user_no;
		$self->{role} = $role;
		$self->{name}    = (split /\@/,$email)[0] ;
		$self->{experimental_features}=$experimental_features;
	}
	$self->SetCookie();

	return $self->{user_no};
}

sub CheckAccess {
  my $self = shift;
  say STDERR "SAMS-C-ACCESS";
  my %cookies = CGI::Cookie->fetch;
  if ($cookies{$cookie_name}) {
    my $sessionid = $cookies{$cookie_name}->value;
    return $self->CheckCookie($sessionid) if $sessionid;
  }
  say STDERR "SAMS-C-ACCESS NO COOKIE";
  $self->Authenticate();
}

sub CheckCookie {
  my ($self,$sessionid)=@_;
   say STDERR "SAMS-C-COOKIE";
  my $sql="SELECT number,name,email,role,experimental_features,expires FROM sams_userdata.sessions WHERE session_id=?";
  my $q = $self->{dbh}->prepare($sql) || $self->PegOut('DB error', {list => $DBI::errstr});    #AND password=?
  $q->execute($sessionid) || $self->PegOut('DB error', {list => [$DBI::errstr]});
  $q = $q->fetchrow_arrayref;
  unless ($q and $q->[1]) {
    die ("$sessionid - Access denied. Please log in again");
  }
  else {

    @{$self}{qw /user_no name email role experimental_features/}=@$q;
	 $self->Log("DUMP",Dumper($self));
    return $q->[0];
  }
}

sub SetCookie {
  my $self = shift;
   say STDERR "SAMS-S-COOKIE";
  die ("no user 2") unless $self->{user_no};
  my $sql="SELECT nextval('sams_userdata.sessions_sequence')";
  my $sessionid=$self->QueryValue(\$sql,[]).'_'.int(rand(1e14));
  $sql="INSERT INTO sams_userdata.sessions (expires,number,name,email,role,experimental_features,session_id) VALUES ((current_timestamp+interval '4 hours'),?,?,?,?,?,?)";
  my $q = $self->{dbh}->prepare($sql) || $self->PegOut('DB error', {list => $DBI::errstr});    #AND password=?
  $self->Log("Cookie set1");
  $q->execute(@{$self}{qw /user_no name email role experimental_features/},$sessionid) || $self->PegOut('DB error', {list => [$DBI::errstr]});
  $self->Log("Cookie set2");
  $self->{dbh}->commit || $self->PegOut('DB error', {list => [$DBI::errstr]});
  say STDERR "Cookie set3";
  my $cookie1 = new CGI::Cookie(
    -name    => $cookie_name,
    -value   => $sessionid,
    -expires => '+4h'
  );
  print "Set-Cookie: $cookie1\n";
  say STDERR "Cookie set4";
}

sub DeleteCookie {
  my $self = shift;
  say STDERR "SAMS-D-COOKIE";
  my %cookies = CGI::Cookie->fetch;
#  $self->Log("DeleteCookie search for $cookie_name");
  if ($cookies{$cookie_name}) {
#	$self->Log("DeleteCookie with cookie $cookie_name");
    my $sessionid = $cookies{$cookie_name}->value;
    my $sql="DELETE FROM sams_userdata.sessions WHERE session_id=?";
    my $q = $self->{dbh}->prepare($sql) || $self->PegOut('DB error', {list => $DBI::errstr});    #AND password=?
    $q->execute($sessionid) || $self->PegOut('DB error', {list => [$DBI::errstr]});
    $self->{dbh}->commit || $self->PegOut('DB error', {list => [$DBI::errstr]});
    my $cookie1 = new CGI::Cookie(
      -name    => $cookie_name,
      -value   => '',
      -expires => '-4h'
    );
    print "Set-Cookie: $cookie1\n";
  }
}

sub checkMail {
  my ($self,$email) = @_;
  my $sql="SELECT email FROM sams_userdata.users WHERE UPPER(email)=UPPER(?)";
  my $email = $self->QueryValue(\$sql,[$email]);
  return 1 if $email;
}

sub insertUser {
  my ($self) = @_;

  my $sql="SELECT email FROM sams_userdata.users WHERE UPPER(email)=UPPER(?)";
  my $user_exists=$self->QueryValue(\$sql,[$self->{input}->{email}]);
  if ($user_exists) {
  	$self->PegOut("Name/email '".$self->{input}->{email}."' already in use!");

  }
  my $pw=$self->{input}->{password};
  $pw = crypt $pw, join "",
    ('.', '/', 0 .. 9, 'A' .. 'Z', 'a' .. 'z')[rand 64, rand 64];    # encrypt Password
  my $sql="INSERT INTO sams_userdata.users (password, email, role) VALUES (?,?,?) RETURNING number";
  my $user_no = $self->QueryValue(\$sql,[$pw,$self->{input}->{email},$self->{input}->{role}]);
  die("Error: $DBI::errstr") unless $user_no;
  $self->{user_no}=$user_no;
  return $user_no;
}


sub getExternalID {
  my ($self, $pat_no) = @_;
  $pat_no=$self->{input}->{pat_no} unless $pat_no;
  die unless ($pat_no);
  my $sql="SELECT external_id FROM sams_userdata.patients WHERE number = ?";
  return $self->QueryValue(\$sql,[$pat_no]);
}

sub getSex {
  my ($self, $pat_no) = @_;
  $pat_no=$self->{input}->{pat_no} unless $pat_no;
  die unless ($pat_no);
  my $sql="SELECT sex FROM sams_userdata.patients WHERE number = ?";
  return $self->QueryValue(\$sql,[$pat_no]);
}

sub GetIDHashVal {
  my ($self, $key) = @_;
  return $source2id{$key};
}

sub getDatasources {  # sinnvollerer Name als getHash
  return keys %source2id;
}

sub GetVisit_last_phenos {
  my ($self, $vnum, $vdate, $examinationref) = @_;
  my @datalist;
  my $symps_str;
  foreach my $table (keys %source2id) {
    my $id = $source2id{$table};
	# $self->Log("GVlp: $id");
    my $r_symp = $self->GetIDStatus($table, $vnum);
    foreach (@$r_symp) {
      #todo: ineffizient - alle IDs können in einer Abfrage abgeholt werden
      my ($symp_id, $status) = @$_;
      my $term = $self->GetTerm($symp_id, $table);
      my $fid = $self->prettifyID($table, $symp_id);
      push @datalist, {'id', $fid, 'term', $term, 'status', $self->status2number($status)};
      $symps_str .= sprintf("(%s %s): %s\n", $fid, $status, $term);
    }
  }
  if (@datalist) {
    #todo: Duplikation @datalist und $symps_str
    my %row = ('date', $vdate, 'symps', \@datalist, 'symps_str', $symps_str);
    push @$examinationref, \%row;
  }
}

sub GetVisit_last_visit {
  my ($self, $vnum, $vdate, $symps) = @_;
  foreach my $table (keys(%source2id)) {
	next if $table eq 'DIMDI';
    my $id = $source2id{$table};
    my $r_symp = $self->GetIDStatus($table, $vnum);
    foreach (@$r_symp) {
      my ($symp_id, $status) = @$_;
      my $term = $self->GetTerm($symp_id, $table);
      my $fid = $self->prettifyID($table, $symp_id);
      push @{$symps->{$vdate}}, $fid, $term, $status;
    }
  }
}

sub GetIDStatus {
  my ($self, $table, $vnum) = @_;
  my $sql="SELECT $source2id{$table}, status FROM $dbVisit{$table}
			WHERE visit_number = $vnum";
  my $q_symp = $self->{dbh}->prepare($sql ) || $self->PegOut($DBI::errstr);
# $self->Log("GetID $sql");
  $q_symp->execute() || $self->PegOut($DBI::errstr);
  my $r_symp = $q_symp->fetchall_arrayref;
  return $r_symp;
}

sub status2number {
  my ($self, $status) = @_;
  $status = lc $status;
  return $status eq 'present' ? 2 : ($status eq 'absent' ? 0 : 1);
}

sub prettifyID {
  my ($self, $source, $symp_id) = @_;
  return sprintf("HP:%07d", $symp_id) if $source eq 'HPO';
  return "ORPHA:$symp_id" if $source eq 'Orphanet';
  return $source . ":$symp_id"; #if ($source eq "ALPHA" or $source eq "OMIM" or $source eq "ORPHA")
}

sub GetAllVisits {
  my ($self, $pat_no, $user_no) = @_;
  my $sql="SELECT v.number, v.visit_date FROM sams_userdata.visits v
    WHERE v.pat_number = ? AND (v.created_by = ? OR pat_number IN (
    SELECT pat_no FROM sams_userdata.pat2doc WHERE doc_no=?)) AND v.deprecated IS NOT true
    ORDER BY v.visit_date DESC";
	print STDERR Dumper($self->Query(\$sql,[$pat_no, $user_no , $user_no]));
  return $self->Query(\$sql,[$pat_no, $user_no , $user_no]);
}

sub GetVisitExaminations {
	my ($self, $examinationsref) = @_;
	my @examinations=();
	my %record=();
	my @visit_numbers=map {$_->[0]} @$examinationsref;
	my %visit_date=();
	my %symps_str=();
	@visit_date{@visit_numbers}=map {$_->[1]} @$examinationsref;
	foreach my $table (keys %source2id) {
		my $sql="SELECT visit_number, $source2id{$table}, status FROM $dbVisit{$table} WHERE visit_number IN (".join (', ' , ('?') x @visit_numbers).')';
		my $results=$self->Query(\$sql,[@visit_numbers]);
		foreach my $tuple (@$results) {
			my ($visit_number, $id, $status) = @$tuple;
			my $term = $self->GetTerm($id, $table);
			my $fid = $self->prettifyID($table, $id);
			push @{$record{$visit_number}},{'id', $fid, 'term', $term, 'status', $self->status2number($status)};
			$symps_str{$visit_number} .= sprintf("(%s %s): %s\n", $fid, $status, $term);
		}
	}
	foreach my $visit_number (@visit_numbers) {
		push @examinations, {'date'=> $visit_date{$visit_number}, 'symps' => $record{$visit_number}, 'symps_str' => $symps_str{$visit_number}};
	}
	print STDERR "examinations:\n".Dumper(@examinations);
	return \@examinations;
}



sub GetTerm {
  my ($self, $symp_id, $table) = @_;
  my $dbID   = $self->{dbID}->{$table};
  my $q_onto = $self->{dbh}->prepare("SELECT $sympTerm{$table} FROM $dbID t WHERE $sympIDName{$table} = $symp_id")
    || $self->PegOut($DBI::errstr);
  $q_onto->execute() || $self->PegOut($DBI::errstr);
  my $r_onto = $q_onto->fetchall_arrayref || $self->PegOut($DBI::errstr);
  my $term = $r_onto->[0]->[0];
  return $term;
}

sub getTranslatedHPOSynonyms {
	# give hpo-synonyms in specific language mixed with english
  my $self = shift;
  my $lang   = $self->{lang_id};
  my $query  = "(SELECT id, synonym FROM sams_data.hpo_synonyms syn WHERE
						language_id=$lang OR language_id=0)";
  return $query;
}


sub getLanguageID {
	# returns lang_id for input string and sets lang_id variable in self
	# not in use !
  my ($self, $lang) = @_;
  my $sql="SELECT id FROM sams_data.languages WHERE UPPER(language)=UPPER(?)";
  my $lang_id = $self->QueryValue(\$sql,[$lang]);
  $self->{lang_id} = $lang_id;
  return $lang_id;
}

sub PegOut {
	# HTML based variant of die
	my $self=shift;
	my $data=pop @_ if ref $_[-1] eq 'HASH'; # take hash ref out of @_
	my $title=shift || ''; # when there's something left, it must be a title
	my @data=@_;
  my $content;
  if (ref $data->{list} eq 'ARRAY' and @{$data->{list}}){
		$content .= "<ul>\n";
		foreach my $line (@{$data->{list}}){
			$content .= "<li>$line</li>\n";
		}
		$content .= "</ul>\n";
	}
	elsif ($data->{list}){
		print "<li>$data->{list}</li>\n";
	}

	if (ref $data->{text} eq 'ARRAY' and @{$data->{text}}){
		$content .= join ("<br>",
			map {
				s /\n/<br>/g;
				s/\t/ /g;
			$_ }
		@{$data->{text}});
	}
	if (@data){
		$content .= join ("<br>",
			map {
				s /\n/<br>/g;
				s/\t/ /g;
			$_ }  @data);
	}
	say STDERR "SAMS died: $title";
	say STDERR "caller: ".join (",",caller());
	say STDERR "data: ".join (",",@data);
	$self->production("Error!", 0, 'error.tmpl', {CONTENT => '<h1>'.$title.'</h1>'.$content });
#	die ("PegOut2",$title,join (",",caller()),join (",",@data));
}

###############################################################################
###############################################################################

sub PrintPage {
	my ($self,$target)=@_;
	$self->Log("PrintPage: ",caller,$target);
	print STDERR "PrintPage: ",caller,$target,"\n";
	print $self->{cgi}->redirect($target);
	exit 0;
}

# param() w/o arguments needs to return a list of parameters.
# param('name') needs to return value. Multiple arguments (list) are not allowed.
# sub param {
# 	return;
# 	my ($self, @p) = @_;
# 	$self->Log("Param ".join (",",@p));
# 	return () unless $self->{user_no};
# 	return ("name", "role", "notice") unless @p; #"email",  #"user_no", "date", "phenotypeboxarea"
# 	return $self->{$p[0]} || $self->{input}->{$p[0]};
# }

sub production {
  my ($self, $page_title, $external_id, $fname, $params) = @_;
  my $cgi=$self->{cgi};
  my $template = HTML::Template->new(
    path              => "../templates/",
    filename          => $fname,
  	#associate         => $self,
    global_vars       => 1,
    die_on_bad_params => 0
  );
 #
 $self->{notice}.=qq !<b class="red">You are not logged in - your input is not permanently stored and anyone can access it.</B>! unless $self->{user_no}>2;
  $template->param($params);
  $template->param(
    HEAD_TITLE => $page_title,
    PAGE_TITLE => $page_title . ($external_id ? " (Patient $external_id)" : ""),
	  EXTERNAL_ID     => $external_id,
    REALUSER => ($self->{user_no}>2?1:0),
    NAME       => $self->{name},
    ROLE       => $self->{role},
	  NOTICE     => $self->{notice},
    #DATE       => $date,
    #PHENOTYPE  => $phenotype,

    #PAT_NO     => $self->{pat_no}.
  );
  print "Content-Type: text/html\n\n", $template->output;
  exit 0;
}

sub CheckPatientAccess {
	my ($self,$pat_no)=@_;
		$self->Log("R0 ".join (",",$pat_no,$self->{user_no}));
	# tests whether a user has access to a patient
	# $pat_no can override the SAMS 'pat_no' data
	unless ($pat_no) {
		$pat_no=$self->{input}->{'pat_no'} if $self->{input}->{'pat_no'};
	}
	$self->Log("R0a ".join (",",$pat_no,$self->{user_no}));
	print $self->{cgi}->redirect(-url => 'logout.cgi')  unless ($self->{user_no}); # hier sollte eine Fehlerseite aufgerufen werden!
	my $sql="SELECT number FROM sams_userdata.patients WHERE number=? AND  created_by=?";
	my $res=$self->QueryValue(\$sql,[$pat_no,$self->{user_no}]);
	$self->Log("R2 ".join (",",$res,$pat_no,$self->{user_no}));
	return 'own' if $res;
	$sql="SELECT pat_no FROM sams_userdata.pat2doc WHERE pat_no=? AND doc_no=?";
	$res=$self->QueryValue(\$sql,[$pat_no,$self->{user_no}]);
	$self->Log("R1 ".join (",",$res,$pat_no,$self->{user_no}));
	return 'shared' if $res;
	$self->PrintPage('logout.cgi')  unless $res; # hier sollte eine Fehlerseite aufgerufen werden!
}

sub CreateHyperlink {
	my ($self,$datasource,$id)=@_;
	return $hyperlinks{DIMDI} if $datasource eq 'DIMDI';
	return $hyperlinks{HPO}.sprintf ("%07d", $id) if $datasource eq 'HPO';
	return $hyperlinks{$datasource}.$id;
}

sub DeletePatient {
	my ($self,$pat_no,$user_no)=@_;
	my $sql="SELECT count(*) FROM sams_userdata.patients WHERE created_by = ?  AND number = ?";
	my $ownpatient = $self->QueryValue(\$sql,[$user_no,$pat_no]);
	die unless $user_no,$pat_no;
	unless ($ownpatient) {
		$self->PegOut("This is NOT your patient.");
	}
	$sql="DELETE FROM sams_userdata.pat2doc WHERE pat_no = ?";
	my $q_del = $self->{dbh}->prepare($sql)  || $self->PegOut($DBI::errstr);
	$q_del->execute($pat_no) || $self->PegOut($DBI::errstr);

	$sql="DELETE FROM sams_userdata.share2doc WHERE pat_no=?";
	my $q_del = $self->{dbh}->prepare($sql)  || $self->PegOut($DBI::errstr);
	$q_del->execute($pat_no) || $self->PegOut($DBI::errstr);

  #if not, delete patient permanently
	my $sql="SELECT number FROM sams_userdata.visits WHERE pat_number = ?";
	my $visit_numbers = $self->Query(\$sql,[$pat_no]);

	if (@$visit_numbers) {
		foreach my $table (qw /visits_mxn_hpo visits_mxn_alphacodes visits_mxn_omim visits_mxn_orphanet visits /) {
			my $number=($table eq 'visits'?'number':'visit_number');
			my $delete = $self->{dbh}->prepare('DELETE FROM sams_userdata.'.$table.' WHERE '.$number.'=?') || $self->PegOut($DBI::errstr);
			foreach my $visref (@$visit_numbers) {
				$delete->execute($visref->[0]) || $self->PegOut($DBI::errstr);
			}
		}
	}
	my $q_pat = $self->{dbh}->prepare("DELETE FROM sams_userdata.patients WHERE number = ?") || $self->PegOut($DBI::errstr);
	$q_pat->execute($pat_no) || $self->PegOut($DBI::errstr);
}

sub ExportPhenopacket {
	my ($self,$pat_no,$external_id,@onthefly_visit)=@_;
	my $sex;
	my $external_id;
	my $creator;
	my $visits_ref;
	my $visit_data_ref;

	if (defined($pat_no)) {
		$self->CheckPatientAccess($pat_no) if $pat_no;
		$sex = $self->getSex($pat_no);
		$external_id=$self->getExternalID unless $external_id;
		$creator = $self->{email};
		$creator = '?' if $creator eq 'no_user';
		$visits_ref = $self->GetAllVisits($pat_no, $self->{user_no});
		$self->PegOut("No visits") unless @$visits_ref;
		$visit_data_ref=$self->GetVisitExaminations($visits_ref);
	}

	switch ($sex) {
		case "w"     { $sex = "FEMALE"; }
		case "m"     { $sex = "MALE"; }
		case "other" { $sex = "OTHER_SEX"; }
		else         { $sex = "UNKNOWN_SEX"; }
	}

	my $datestring = $self->getTime;
	my @resourcesArray = ();
	my @phenotypicFeaturesArray = ();
	my @diseasesArray = ();
	my $hpoIncluded = 0;
	my $orphaIncluded = 0;
	my $omimIncluded = 0;
	my %resourceHPO = (
		id => "hp",
		name => "human phenotype ontology",
		url => "http://purl.obolibrary.org/obo/hp.obo",
		version => "placeholder",
		namespacePrefix => "HP",
		iriPrefix => "http://purl.obolibrary.org/obo/HP_",
	);
	my %resourceORPHA = (
		id => "orphanet",
		name => "orphanet rare disease ontology",
		url => "http://www.orpha.net",
		version => "placeholder",
		namespacePrefix => "ORPHA",
		iriPrefix => "https://www.orpha.net/consor/cgi-bin/Disease_Search.php?lng=EN&data_id=",
	);
	my %resourceOMIM = (
		id => "omim",
		name => "online mendelian inheritance in man",
		url => "https://omim.org",
		version => "placeholder",
		namespacePrefix => "OMIM",
		iriPrefix => "https://omim.org/entry/",
	);
	
	#print STDERR defined(@onthefly_visit) ? "onthefly:\n".Dumper(@onthefly_visit) : "visitData:\n".Dumper($visit_data_ref);
	#print STDERR "onthefly defined: ".defined(@onthefly_visit)."\n";
	#print STDERR "visitData:\n".Dumper($visit_data_ref);

	#add id and label as hash to corresp. array
	foreach my $examinationsref (@onthefly_visit ? @onthefly_visit : @$visit_data_ref) {
		foreach my $symptomref (@{$examinationsref->{symps}}) {
			my $id = $symptomref->{id};
			my $label = $symptomref->{term};
			my $status = $symptomref->{status} == 2 ? "false" : ($symptomref->{status} == 0 ? "true" : "error");
			my $date = $examinationsref->{date} . "T00:00:00Z";

			#separate disease from phenotypicFeature
			if ($id =~ /HP:/) {
				if ($hpoIncluded == 0) {
					push @resourcesArray, \%resourceHPO;
					$hpoIncluded = 1;
				}
				push @phenotypicFeaturesArray, $status eq "false" ?
					{type => {id => $id, label => $label}, onset => {timestamp => $date}} :
					{type => {id => $id, label => $label}, onset => {timestamp => $date},excluded => $status};
			} else {
				if ($id =~ /ORPHA:/ && $orphaIncluded == 0) {
					push @resourcesArray, \%resourceORPHA;
					$orphaIncluded = 1;
				} elsif ($id =~ /OMIM:/ && $omimIncluded == 0) {
					push @resourcesArray, \%resourceOMIM;
					$omimIncluded = 1;
				} elsif ($id =~ /ALPHA:/) {
					#TODO implement Alpha-ID
				}
				push @diseasesArray, $status eq "false" ?
					{term => {id => $id, label => $label}, onset => {timestamp => $date}} :
					{term => {id => $id, label => $label}, onset => {timestamp => $date}, excluded => $status};
			}

		}
	}

	#create json string
	my %phenopacketHash =
	(id => "arbitrary.id",
	 subject => {id => $external_id, sex => $sex},
	 phenotypicFeatures => [@phenotypicFeaturesArray],
	 diseases => [@diseasesArray],
	 metadata => {
		created => $datestring,
		createdBy => $creator,
		resources => [@resourcesArray],
		phenopacketSchemaVersion => "2.0" });
	delete $phenopacketHash{phenotypicFeatures} if !@phenotypicFeaturesArray;
	delete $phenopacketHash{diseases} if !@diseasesArray;
	delete $phenopacketHash{subject} if !$phenopacketHash{subject}{id};
	$phenopacketHash{metadata}{createdBy} = "no_user" if !$phenopacketHash{metadata}{createdBy};
	return \%phenopacketHash;

}

sub OrderPhenopacketKeys {
    my ($elem1, $elem2) = @_;

    # digits correspond to level
    # order from https://phenopacket-schema.readthedocs.io/en/latest/phenopacket.html
    my %elementOrder = (
        id => -1, #id always first
        subject => 1,
          sex => 11,
        phenotypicFeatures => 2,
        diseases => 3,
          type => 12,
          term => 13,
            label => 101,
          onset => 14,
          resolution => 15,
            timestamp => 102,
            interval => 103,
              start => 1001,
              end => 1002,
          excluded => 16,
        metadata => 4,
          created => 17, #metaData
          createdBy => 18,
          resources => 19,
            name => 104,
            url => 105,
            version => 106,
            namespacePrefix => 107,
            iriPrefix => 108,
          phenopacketSchemaVersion => 20);
    return $elementOrder{$elem1} > $elementOrder{$elem2} ? 1 : -1;
}

return 1;


__END__
