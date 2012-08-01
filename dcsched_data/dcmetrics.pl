#!/opt/cpkg/current/perl/current/bin/perl

use warnings;
use Getopt::Long;
use Date::Parse;
use HTTP::Date;
use Time::Local;
use Chart::Pie;
use Chart::StackedBars;
use List::Util 'max';
use Chart::Mountain;
use Switch 'Perl5', 'Perl6';

my $debug = 0;

my %oh = ();
$oh{verbose} = '';
$oh{all}     = '';
$oh{date}    = '';
$oh{group}   = '';
my $command = ' ';

GetOptions(
	'verbose' => \$oh{verbose},
	'all'       => \$oh{all},
	'date=s'    => \$oh{date},
	'group'	=> \$oh{category},
  );

if ( $oh{all} ) {
	$all = '-a';
	print "all set\n";
	$command .= ' ' . $all . ' ';
}

if ( $oh{date} ) {
	$date = $oh{date};
	print "date set\n";
	$command .= ' -' . $date . ' -s ' . '-' . $date . ' ';
}

my $extraArgs;
print "Unprocessed by Getopt::Long\n" if $ARGV[0];
foreach (@ARGV) {
	print $_."\n";
	$extraArgs .= ' '.$_;
}

$command .= "-v" . $extraArgs;

printf "|%s|\n", $command;

#end of argument Processing________________

# Perl trim function to remove whitespace from the start and end of the string
sub trim($) {
	my $string = shift;
	$string =~ s/^\s+//;
	$string =~ s/\s+$//;
	return $string;
}

# Left trim function to remove leading whitespace
sub ltrim($) {
	my $string = shift;
	$string =~ s/^\s+//;
	return $string;
}

# Right trim function to remove trailing whitespace
sub rtrim($) {
	my $string = shift;
	$string =~ s/\s+$//;
	return $string;
}

# the following three functions map various parameters to Release Buckets.
# Blaine Ebling (bce) is the Final Authority on the correctness of this section.

#Currently it is configured for the DEV group in dcsched.

my $CLEother = 'CLE other';
my $admin = 'admin';
my $p22 = '2.2';
my $p31 = '3.1';
my $p40 = '4.0';
my $p41 = '4.1';
my $p50 = '5.0';
my $p51 = 'DEVSP2';
my $reserv = '1'; #if required to look at reservation OS
my $notes = '2'; #if required to look at Notes field
my $skip = 'skip'; #if you want to disreguard a field
sub CLEversion{
	switch ($_) {
		case m/devadmins/  		{return $admin}
		case m/ops/				{return $admin}
		case m/CLE-3.1/			{return $p31}
		case m/CLE-4.1/			{return $p41}
		case m/CLE-Dev/			{return $p41}
		case m/CLE-shared/ 		{return $p22}
		case m/CLE-Shared/		{return $p22}
		case m/upgrade/			{return $admin}
		case m/admin/			{return $admin}
		case m/Admin Time/ 		{return $admin}
		case m/lustre-test/ 	{return $p51}
		case m/CLE-4.1 w\/LSF/	{return $p41}
		case m/CLE-DevSP2/ 		{return $p51}
		case m/preempt/			{return $admin}
		case m/CLE-4.0/			{return $p40}
		case m/vers_res_test/ 	{return $notes}
		case m/ostest/ 			{return $reserv}
		case m/petest/			{return $notes}
		case m/vers/ 			{return $notes}
		case m/ded/				{return $reserv}
		case m/bench-ded/  		{return $reserv}
		case m/os-ded/			{return $reserv}
	}
	print "WARNING: unhandled DCSCHED category:" . $_ ;
	print "CLE OTHER may now be incorrect\n\n";
	return $CLEother
}

sub NotesHandler { #Handles Notes Field
	switch ($_) {
		case m/devadmins/  		{return $admin}
		case m/ops/				{return $admin}
		case m/CLE-3.1/			{return $p31}
		case m/CLE-4.1/			{return $p41}
		case m/CLE-Dev/			{return $p41}
		case m/CLE-shared/ 		{return $p22}
		case m/upgrade/			{return $admin}
		case m/admin/			{return $admin}
		case m/Admin Time/ 		{return $admin}
		case m/lustre-test/ 	{return $p51}
		case m/CLE-4.1 w\/LSF/	{return $p41}
		case m/CLE-DevSP2/ 		{return $p51}
		case m/preempt/			{return $admin}
		case m/CLE-4.0/			{return $p40}
		case m/CLE-DEV/ 		{return $p41}
		case m/4.1/				{return $p41}
		case m/4.0/				{return $p40}
	}
	print "WARNING: unhandled Notes field:" . $_ ;
	print "CLE OTHER may now be incorrect\n\n";
	return $CLEother;
}

sub DedOSversion { #Handles Reservation OS Field
	switch ($_) {
		case m/CLE-2.2/			{return $p22}
		case m/CLE-3.1/			{return $p31}
		case m/CLE-4.0/			{return $p40}
		case m/CLE-4.1/			{return $p41}
		case m/CLE-dev/			{return $p41}
		case m/CLE-devSP2/ 		{return $p51}
		case m/No OS/			{return $CLEother}
		case m/CLE-5.0/			{return $p50}
	}
	print "WARNING: unhandled Reserved OS field:" . $_ ;
	print "CLE OTHER may now be incorrect\n\n";
	return $CLEother;
}

sub categoryCombine(@) { #Not actually used, but can be useful in the future....
	my($source, $destination, %hash) = @_;
	$hash{$destination} += $hash{$source};
	delete($hash{$source});
	return %hash;
}

#Do the command___
open( DCPIPE, "/sw/sdev/dcsched/dcsched $command |" );
$i = 0;
%timeHash = ();
%osHash = ();
%mHash = ();
my $time1;
my $time2;
my $category;
my $reservedOS;
my $notesOS;
my $userToggle = 0;
my $devadminOverflow = 0;
my $startTime;
undef $startTime;
my $endTime;
while (<DCPIPE>) {
	if ($debug > 2 ) {print $_;}
	if ( $_ =~ m/until/ ) {
		$userToggle = 0;
		$devadminOverflow = 0;
		if ($_ =~ m/\)$/ ) {$userToggle = 1} #checking if it is a user slot (look for ')' )
		if ($userToggle == 1 && $_ =~ m/devadmins/) {$devadminOverflow = 1} #for times when an admin schedules more devadmin time manually
		if ($debug > 1) {
			print trim($_)."\n";
		}
		undef $time1;
		undef $time2;
		undef $reservedOS;
		undef $category;
		undef $notesOS;

		while (<DCPIPE>) { ##check for key-value pairs you want to store and store them somewhere.
			if ($debug > 0) {print $_;}
			$temp = trim($_);
			my @col = split /=/, $temp;
			if ($col[0] =~ m/StartDate/) {$time1 = Date::Parse::str2time($col[1]);
				if (!(defined $startTime) ) {$startTime = $col[1];}
			}

			if ($col[0] =~ m/EndDate/) 		{$time2 = Date::Parse::str2time($col[1]);
				$endTime = $col[1];}
			if ($col[0] =~ m/SkSlotName/) 	{$category = CLEversion(trim($col[1]));}
			if ($col[0] =~ m/SkNotes/)		{$notesOS = NotesHandler($col[1]);}
			if ($col[0] =~ m/UrOsVersion/) 	{$reservedOS = DedOSversion(trim($col[1]));}
			if ($userToggle == 0) {last if $col[0] =~ m/SkSoftwareTypes/; # last item in First half
			}
			elsif ($userToggle == 1) {last if $col[0] =~ m/UrSurrender/; #last item in Second Half
			}
		}

		##process your keyvalue pairs before the next machine comes up here

		$timeDiff = ($time2-$time1)/60/60; #convert to hours

		if ($devadminOverflow == 1) {
			$category = 'admin';
		}

		($ss1,$mm1,$hh1,$day1,$month1,$year1,$zone1) = strptime(time2str($time1));
		my $dateValue = $month1."-".$day1;

	 # if a reservation goes past midnight into the next day,
	 # the data is considered to belong to the start time of the reservation
	 # this currently only applies to the Mountain Graph, but may also apply to
	 # different Composition-changing-OverTime graphs.
	 # see this website for graph suggestions
	 # http://extremepresentation.typepad.com/files/choosing-a-good-chart-09.pdf

		switch ($category) {
			case ('skip') {
				last;
			}
			case ('1') {if ($reservedOS) {
					$timeHash{$reservedOS} += $timeDiff;
					$mHash{$reservedOS}{$dateValue} += $timeDiff;
					for $date (keys %{values %mHash} ) {
						$mHash{$reservedOS}{$date} += 0;
					}
				}
			}
			case ('2') {if ($notesOS) {
					$timeHash{$notesOS} += $timeDiff;
					$mHash{$notesOS}{$dateValue} += $timeDiff;
					for $date (keys %{values %mHash} ) {
						$mHash{$notesOS}{$date} += 0;
					}
				}
			}
			else {$timeHash{$category} += $timeDiff;
				$mHash{$category}{$dateValue} += $timeDiff;
				for $date (keys %{values %mHash} ) {
					$mHash{$category}{$date} += 0;
				}
			}
		}

		for $op (keys %mHash ) {
			$mHash{$op}{$dateValue} += 0;
		}

		if ($reservedOS) {
			$osHash{$reservedOS} += $timeDiff;
		}

		if ($reservedOS) {$output[$i] ="Time: ".$timeDiff. " category: " . $category . " os: ". $reservedOS. " \n";}
		else {$output[$i] ="Time: ".$timeDiff. " category: " . $category. " \n";}
		if ($debug > 0) {print $output[$i];}
		$i++;
	}
}

while ( ( $key, $value ) = each(%timeHash) ) {
	print $key. ", " . $value . "\n";
}

close DCPIPE;

$dateRange = $startTime ." - " . $endTime;

##create your charts here. see http://search.cpan.org/~chartgrp/Chart-2.4.5/Chart.pod for chart::type usage

my $chart = Chart::Mountain->new(2000,2000);
$chart->set('title' => $extraArgs . " daily distribution from" . $dateRange);
my @tempKeys;
my @tempVals;
my @labels;
$KeysPushed = 0;
foreach $key (sort (keys(%mHash))) {
	push (@labels, $key);
	%tempHash = %{$mHash{$key}};
	my @tempData;
	undef @tempData;

	foreach $date (sort (keys(%tempHash))) { #this sorts the data by date, but then you have to extract it and put it somewhere
		push (@tempKeys, $date);
		push (@tempData, $tempHash{$date});
	}
	if ($KeysPushed == 0) { #only add the keys (x axis date label) the first time
		$chart->add_dataset(@tempKeys);
		if ($debug > 0){print "keys: ". @tempKeys. "\n";}
		$KeysPushed = 1;
	}
	$chart->add_dataset(@tempData);
	if ($debug > 0 ) {print "data: ". @tempData. "\n";}
}
$chart->set('y_label' => 'total hours ammong machineRange in one day');
$chart->set('x_label' => 'Date');
$chart->set('legend_labels' => \@labels);
$chart->png(time.'_output_mountain.png');

my $chart2 = Chart::Pie->new (900,900);
$chart2->set('title' => $extraArgs . " usage information from ". $dateRange);
undef @tempKeys;
undef @tempVals;
foreach $key (sort (keys(%timeHash))) {
	push (@tempKeys, $key); {
		push (@tempVals, $timeHash{$key})
	}
}
$chart2->add_dataset( @tempKeys );
$chart2->add_dataset( @tempVals );
$chart2->png(time.'_output_machine.png');

my $chart3 = Chart::Pie->new (900,900);
$chart3->set('title' => $extraArgs . " OS information from " . $dateRange);
undef @tempKeys;
undef @tempVals;
foreach $key (sort (keys(%osHash))) {
	push (@tempKeys, $key); {
		push (@tempVals, $osHash{$key})
	}
}
$chart3->add_dataset( @tempKeys );
$chart3->add_dataset( @tempVals );
$chart3->png(time.'_output_OS.png');

print "machine Done!";
