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

if ($outfile eq "-"){
  *FH = *STDOUT;
} else {
  open(FH, ">", $outfile);
};


my $tftproot = "/tftpboot";
my $jobid = $$;
my $filename = $jobid . "-confg";
my $fqfilename = "$tftproot/$filename";

open(FILE,">$fqfilename") or die "Failed to open file for tftp";
truncate(FILE,0);
close(FILE);
chmod(0666, $fqfilename);

my $sess = new SNMP::Session(DestHost => $hostname,
                            Version => "2c",
                            Community => $rwcomm);

# copy the running config to tftp
my $setup_vars = new SNMP::VarList(
 ["ccCopySourceFileType", $jobid , 4 ],
 ["ccCopyDestFileType", $jobid , 1 ],
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

if ($copyState == 3) {
 # cat $fqfilename
 open(FILE,"<$fqfilename");
 while(<FILE>) {print FH $_};
 close(FILE);
} else {
 print STDERR "Copy Failed\n";
 $error = 1;
}

my $destroy_vars = new SNMP::VarList(
 ["ccCopyEntryRowStatus" , $jobid , 6 ]);
my @destroy_vals = $sess->set($destroy_vars) or die "Removal of copy job failed:\n" . $sess->ErrorStr;

# rm $fqfilename
unlink($fqfilename) or die "Failed to unlink tftp file";

exit $error;
