#!/usr/bin/perl -w -T

use strict;

$ENV{"MIBS"}="CISCO-CONFIG-COPY-MIB";

use SNMP;
use Socket;
use Time::HiRes qw ( sleep );

$SNMP::debugging = 0;

my $tftpservernat = "192.168.0.10\n";
my $rwcomm = "private";
my $timeout = 30;
my $error = 0;

my $hostname = shift;
my $ip = gethostbyname($hostname);
my $ipstr = inet_ntoa($ip);

my $arg = shift || "-";
my $outfile;
if ($arg =~ /^(.*)$/){
  $outfile = $1;
};

open(FH, "<$outfile");

my $tftproot = "/tftpboot";
my $jobid = $$;
my $filename = $jobid . "-confg";
my $fqfilename = "$tftproot/$filename";

# Make a tftp-able copy of the desired config input
open(FILE,">$fqfilename") or die "Failed to open file for tftp";
while(<FH>){
  print FILE $_
};
# add a trailing config close just for the hell of it
print FILE "!\n";
close(FILE);
chmod(0666, $fqfilename);

my $sess = new SNMP::Session(DestHost => $hostname,
                            Version => "2c",
                            Community => $rwcomm);

# copy the config to running config
my $setup_vars = new SNMP::VarList(
 ["ccCopySourceFileType", $jobid , 1 ],
 ["ccCopyDestFileType", $jobid , 4 ],
 ["ccCopyServerAddress", $jobid , $tftpservernat ],
 ["ccCopyFileName", $jobid , $filename ],
 ["ccCopyEntryRowStatus", $jobid , 4 ]);
my @setup_vals = $sess->set($setup_vars) or die "Setup of copy job failed:\n" . $sess->ErrorStr;

my $check_vars = new SNMP::VarList(
 ["ccCopyState",$jobid]);
my $copyState = 0;
my $timecount = 0;
while($copyState < 3){
 if($timecount > $timeout){
   $error = 1;
   last;
 }
 my @check_vals = $sess->get($check_vars);
 $copyState =  $check_vars->[0]->[2];
 sleep 0.25;
 $timecount += 0.25;
};

if ($copyState != 3) {
 print STDERR "Copy Failed\n";
 $error = 1;
}

my $destroy_vars = new SNMP::VarList(
 ["ccCopyEntryRowStatus" , $jobid , 6 ]);
my @destroy_vals = $sess->get($destroy_vars) or die "Removal of copy job failed:\n" . $sess->ErrorStr;

# rm $fqfilename
unlink($fqfilename) or die "Failed to unlink tftp file";

exit $error;
