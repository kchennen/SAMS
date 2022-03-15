#!/usr/bin/perl

use strict;
use 5.10.0;
use CGI qw(:standard);
use CGI::Cookie;
use CGI::Carp ('fatalsToBrowser');
use JSON::Create 'create_json';
use lib '../lib/';
use SAMS qw (OrderPhenopacketKeys);
use common;

my $cgi = new CGI;
my $sams = new SAMS($cgi);
$sams->CheckAccess;
my $user_no =	$sams->{user_no};
my $pat_no = $sams->{input}->{'pat_no'};
my $phenopacket=$sams->ExportPhenopacket($pat_no);

print "Content-type: application/json; charset=UTF-8\n\n";	
my $jc = JSON::Create->new (sort => 1, indent => 1);
$jc->cmp (\&OrderPhenopacketKeys);
print $jc->run($phenopacket);