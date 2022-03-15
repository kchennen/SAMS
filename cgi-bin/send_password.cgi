#!/usr/bin/perl

# noch nicht von mir bearbeitet (Dominik)

$| = 1;
use strict;
use CGI;
use CGI::Carp ('fatalsToBrowser');
#use utf8;
use Encode;
use Data::Dumper;
use Crypt::GeneratePassword qw(word);


use lib '../lib/';
use SAMS;
use lib '/www/lib';
use SendMail;

my $cgi = new CGI;
my $sams = new SAMS($cgi);

$sams->PegOut("Sorry, you did not specify an email adress.","Your input was: ".$sams->{input}->{email})
	unless $sams->{input}->{email}=~/\w+@\w+/;
#my $password=int(rand(1e12));
my $password = word( 8, 10 );
my $readable_pw=$password;
my $crypt_pw = crypt $password, join "",
    ('.', '/', 0 .. 9, 'A' .. 'Z', 'a' .. 'z')[rand 64, rand 64]; 

my $sql="UPDATE sams_userdata.users SET password=? WHERE LOWER(email)=?";


my $update=$sams->{dbh}->prepare($sql) || die;
my $val=$update->execute($crypt_pw,lc $sams->{input}->{email}) || die;
$sams->PegOut("Sorry, no account.","We do not have an account for: ".$sams->{input}->{email}) unless ($val==1) ;

SendMail::SendMail('mutation-taster',
			"SAMS - password reset",
			\("Your new password is $password" ),
			$sams->{input}->{email}
		);

my $html="Hello ".$sams->{input}->{email}.".<BR>
<P>A password was sent to this email address.</P>
<P>Please login with the new password.</P>\n";

$sams->Commit;

$sams->production("Account verified", $sams->{input}->{external_id}, "_html_page.tmpl", {
	HTML  => $html,   
});	

