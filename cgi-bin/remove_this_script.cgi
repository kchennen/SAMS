#!/usr/bin/perl

$| = 1;
use strict;
use CGI;
use lib '../lib/';
use SAMS;

my $cgi = new CGI;
my $sams = new SAMS($cgi);

die unless $sams->{input}->{code}==1141;
my $sql="SELECT * FROM sams_userdata.share2doc order by creation_date DESC limit 3;";
my $r=$sams->Query(\$sql);

print "Content-Type: text/plain\n\n";

foreach (@$r){
	print join ("\t",@$_),"\n";
}
print "OK!";
exit 0;


