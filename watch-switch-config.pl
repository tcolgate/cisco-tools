#!/usr/bin/perl -w -T

use strict;

use Fcntl;             # for sysopen
use File::Path;
use Sys::Syslog qw( :DEFAULT setlogsock);
use Proc::Daemon;
use SNMP;

Proc::Daemon::Init;

$ENV{"PATH"}="/usr/bin";

chdir("/tftpboot");
my $fpath = "/var/run/watch-switch-config.fifo";

# create a fifo to communicate with rsyslog

setlogsock('unix');
openlog($0,'','user');

#open(STDERR,">/tmp/logfile");

unless (-p $fpath) {   # not a pipe
    if (-e _) {        # but a something else
        die "$0: won't overwrite .signature\n";
    } else {
        require POSIX; POSIX::mkfifo($fpath, 0600) or die "can't mknod $fpath: $!"; warn "$0: created $fpath as a named pipe\n";
    }
}


# This script watches the network devices log for configuration changes. Once
# a configuration has been udpated the conifg is sync'd via tftp and committed
# to SVN

my $rwcomm  = "private";
my $svnuser = "svn_netcfg";
my $svnpass = "svnpasswd";

while(1){
  sysopen(FIFO, $fpath, O_RDONLY) or die "can't read from $fpath: $!";
  while(my $line = <FIFO>){
    my $ciscoconfiged = '%SYS-5-CONFIG_I:';

    if($line =~ /$ciscoconfiged/){
      my @fields = split(' ',$line);
  
      my $fqdn = $fields[1];
      if ($fqdn =~ /^([-\d\w.]+)$/){
        $fqdn = $1;
      } else {
        syslog('err', "Unsafe fqdn parsed from log\n");
        next;
      };

      my $user = $fields[12];
      if ($user =~ /^([-\d\w._]+)$/){
        $user = $1;
      } else {
        syslog('err', "Unsafe user parsed from log\n");
        next;
      };
  
      my $host;
      my $site;
      chomp($fqdn);
      if ($fqdn =~ /^(\d+\.\d+\.\d+\.\d+)/){
        $host = $1;
      } else {
        my @hostdetails = split('\.',$fqdn);
        $host = $hostdetails[0];
        $site = $hostdetails[1];
      };
  
      syslog('info', "Configuration on $host updated by $user");
  
      # We can use this info to vary how we pull data, or where it gets stored.
      my ($sess, $sesserror) = new SNMP::Session(DestHost => $fqdn,
                                                 Version => "2c",
                                                 Community => $rwcomm);

      unless($sess){
	syslog('err', "SNMP::Session creation failed: $sesserror\n");
        next;
      };

      my $hostdetails_vars = new SNMP::VarList(
         ["sysName" , 0 ],
         ["sysLocation" , 0 ]);

      my @hostdetails_vals = $sess->get($hostdetails_vars);
      unless(@hostdetails_vals){
        syslog('err', "Retrieval of host details for $fqdn failed\n");
        next;
      };
  
      my $snmphostname = $hostdetails_vals[0];
      if ($snmphostname =~ /^([-\d\w._]+)$/) {
        $snmphostname = $1; # $code now untainted
      } else {
        syslog('err', "Skipping device reporting iffy host name\n");
        next;
      } 

      # We occasionally hit issues "-confg" files being created, probably during 
      # provisioning new devices
      unless(length($snmphostname) > 0){
        syslog('err', "Skipping device reporting blank host name\n");
        next;
      };

      my $file = $snmphostname . "-confg";
      my $location = $hostdetails_vals[1];
      my @locparts = split(/\;/,$location);
      if (@locparts > 0){
        $location = join('/',@locparts);
        my @created = mkpath($location,1,0666);
        if(@created > 0){
          foreach my $dir (@created){
            my $svnadd = "/usr/bin/svn add --non-interactive --username $svnuser --password $svnpass \"" . $dir . "\"";
            system($svnadd);
            my $commitcommand = "/usr/bin/svn commit --non-interactive --username $svnuser --password $svnpass --message \"Creating directory $dir\" \"$dir\"";
            system($commitcommand);
          };
        };
        $file = $location . '/' . $file;
      };

      my $fileexisted = 0;
      if(-e $file){
        $fileexisted = 1
      };

      my $pullcommand = "/usr/local/scripts/snmp-get-config.pl $fqdn \"$file\"" ;
      syslog('info', "Running $pullcommand");
      system($pullcommand);
      if($? == 0){
        syslog('info', "Retrieved configuration for $host to $file");
        if($fileexisted == 0){
          my $svnadd = "svn add --non-interactive --username $svnuser --password $svnpass \"$file\"";
          system($svnadd);
        }; 
        my $commitcommand = "/usr/bin/svn commit --non-interactive --username $svnuser --password $svnpass --message \"Configuration for host $host updated by $user\" \"$file\"";
        my @svnout = system($commitcommand);
        if($? != 0){
          syslog('err', "Error commiting configurtaion for $host: $!");
          syslog('err', "Error: " . join(@svnout));
        }else{
          syslog('info', "Commited $file to svn");
        };
      }else{
        syslog('err', "Error retrieving configurtaion from $host: $!");
      };
    };
  };
  sleep 10;
  close FIFO;
};

closelog;

exit 0;

