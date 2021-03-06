#!/opt/cpkg/current/perl/current/bin/perl

use warnings;
use Getopt::Long;
use Date::Parse;
use Date::Calc;
use Time::Local;
use Chart::Pie;
use Chart::StackedBars;
use List::Util 'max';
use Chart::Mountain;
use Text::CSV_XS;
use Switch 'Perl5', 'Perl6';

my $debug = 0; #currently 0,1 or 2

my %oh = ();
my $command = ' ';
my $superToggle = 'DEV';

GetOptions(
	'verbose' => \$oh{verbose},
	'all'       => \$oh{all},
	'date=s'    => \$oh{date},
	'group'	=> \$oh{category},
	'full' => \$oh{full},
	'workweek' => \$oh{workweek},
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

if ( $oh{full}) {
	print "full set\n";
}

if ( $oh{workweek}) {
	print "workweek set\n";
}

my $extraArgs;
print "Unprocessed arguments passed to cli dcsched:\n" if $ARGV[0];
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

#calculate difference in dates without saturday and sunday
sub Delta_Business_Days {
	my(@date1) = (@_)[0,1,2];
	my(@date2) = (@_)[3,4,5];
	my($minus,$result,$dow1,$dow2,$diff,$temp);

	$minus  = 0;
	$result = Date::Calc::Delta_Days(@date1,@date2);
	if ($result != 0)
	{
		if ($result < 0)
		{
			$minus = 1;
			$result = -$result;
			$dow1 = Date::Calc::Day_of_Week(@date2);
			$dow2 = Date::Calc::Day_of_Week(@date1);
		}
		else
		{
			$dow1 = Date::Calc::Day_of_Week(@date1);
			$dow2 = Date::Calc::Day_of_Week(@date2);
		}
		$diff = $dow2 - $dow1;
		$temp = $result;
		if ($diff != 0)
		{
			if ($diff < 0)
			{
				$diff += 7;
			}
			$temp -= $diff;
			$dow1 += $diff;
			if ($dow1 > 6)
			{
				$result--;
				if ($dow1 > 7)
				{
					$result--;
				}
			}
		}
		if ($temp != 0)
		{
			$temp /= 7;
			$result -= ($temp << 1);
		}
	}
	if ($minus) { return -$result; }
	else        { return  $result; }
}

##### the following 6 functions map various parameters to Release Buckets.
# Blaine Ebling (bce) is the Final Authority on the correctness of this section.

#Currently it is configured for the DEV group in dcsched.

my $CLEother = 'CLE-Other';
my $admin = 'admin';
my $p22 = '2.2';
my $p31 = '3.1';
my $p40 = '4.0';
my $p41 = '4.1';
my $p50 = '5.0';
my $p51 = 'CLE-DEVSP2';
my $reserv = '1'; #if required to look at reservation OS
my $notes = '2'; #if required to look at Notes field
my $skip = 'skip'; #if you want to disreguard a field

sub ariesCLEversion{
	switch ($_) {
		case m/devadmins/  		{return $admin}
		case m/ops/				{return $admin}
		case m/upgrade/			{return $admin}
		case m/admin/			{return $admin}
		case m/Admin Time/ 		{return $admin}
		case m/preempt/			{return $admin}
		case m/cascade_admins/	{return $admin}
		case m/CLE-shared/ 		{return $p22}
		case m/CLE-Shared/		{return $p22}
		case m/CLE-3.1/			{return $p31}
		case m/CLE-4.0/			{return $p40}
		case m/CLE-4.1/			{return $p41}
		case m/CLE-Dev/			{return $p51}
		case m/CLE-4.1 w\/LSF/	{return $p41}
		case m/lustre-test/ 	{return $p51}
		case m/CLE-DevSP2/ 		{return $p51}
		case m/vers-hss/		{return $notes}
		case m/vers_res_test/ 	{return $notes}
		case m/petest/			{return $notes}
		case m/vers/ 			{return $notes}
		case m/ANC\/DPDC/		{return $reserv}
		case m/shared/			{return $reserv}
		case m/Diags/			{return $reserv}
		case m/ostest/ 			{return $reserv}
		case m/ded/				{return $reserv}
		case m/bench-ded/  		{return $reserv}
		case m/os-ded/			{return $reserv}
		case m/shared-trunk/	{return $reserv}
		case m/Aries/			{return $reserv}

		case m/Unavail/			{return $skip}
		case m/unavail/			{return $skip}
		case m/M.E./			{return $skip} #temporary skip, waiting for wendy to look up and tell me what it is 8/14/12
		case m/kevin/			{return $skip} #lol
	}
	print "WARNING: unhandled DCSCHED category:" . $_ ;
	print "Field Skipped\n\n";
	return $skip;
}

sub geminiCLEversion{
	switch ($_) {
		case m/devadmins/  		{return $admin}
		case m/ops/				{return $admin}
		case m/upgrade/			{return $admin}
		case m/admin/			{return $admin}
		case m/Admin Time/ 		{return $admin}
		case m/preempt/			{return $admin}
		case m/cascade_admins/	{return $admin}
		case m/CLE-shared/ 		{return $p22}
		case m/CLE-Shared/		{return $p22}
		case m/CLE-3.1/			{return $p31}
		case m/CLE-4.0/			{return $p40}
		case m/CLE-4.1/			{return $p41}
		case m/CLE-Dev/			{return $p41}
		case m/CLE-4.1 w\/LSF/	{return $p41}
		case m/lustre-test/ 	{return $p51}
		case m/CLE-DevSP2/ 		{return $p51}
		case m/vers-hss/		{return $notes}
		case m/vers_res_test/ 	{return $notes}
		case m/petest/			{return $notes}
		case m/vers/ 			{return $notes}
		case m/ANC\/DPDC/		{return $reserv}
		case m/shared/			{return $reserv}
		case m/Diags/			{return $reserv}
		case m/ostest/ 			{return $reserv}
		case m/ded/				{return $reserv}
		case m/bench-ded/  		{return $reserv}
		case m/os-ded/			{return $reserv}
		case m/shared-trunk/	{return $reserv}
		case m/Aries/			{return $reserv}

		case m/Unavail/			{return $skip}
		case m/unavail/			{return $skip}
		case m/M.E./			{return $skip} #temporary skip, waiting for wendy to look up and tell me what it is 8/14/12
		case m/kevin/			{return $skip} #lol
	}
	print "WARNING: unhandled DCSCHED category:" . $_ ;
	print "Field Skipped\n\n";
	return $skip;
}

sub CLEversion{
	switch ($superToggle) {
		case m/^DEV\/CASCADE$/i	{return ariesCLEversion($_)}
		case m/^DEV$/i			{return geminiCLEversion($_)}
	}
}

sub ariesNotesHandler { #Handles Notes Field
	switch ($_) {
		case m/devadmins/  		{return $admin}
		case m/ops/				{return $admin}
		case m/upgrade/			{return $admin}
		case m/admin/			{return $admin}
		case m/Admin Time/ 		{return $admin}
		case m/preempt/			{return $admin}
		case m/CLE-shared/ 		{return $p22}
		case m/CLE-3.1/			{return $p31}
		case m/CLE-4.0/			{return $p40}
		case m/4.0/				{return $p40}
		case m/CLE-4.1 w\/LSF/	{return $p41}
		case m/CLE-4.1/			{return $p41}
		case m/CLE-Dev/			{return $p51}
		case m/CLE-DEV/ 		{return $p51}
		case m/4.1/				{return $p41}
		case m/CLE-DevSP2/ 		{return $p51}
		case m/lustre-test/ 	{return $p51}
	}
	print "WARNING: unhandled Notes field:" . $_ ;
	print "Field Skipped\n\n";
	return $skip;
}

sub geminiNotesHandler { #Handles Notes Field
	switch ($_) {
		case m/devadmins/  		{return $admin}
		case m/ops/				{return $admin}
		case m/upgrade/			{return $admin}
		case m/admin/			{return $admin}
		case m/Admin Time/ 		{return $admin}
		case m/preempt/			{return $admin}
		case m/CLE-shared/ 		{return $p22}
		case m/CLE-3.1/			{return $p31}
		case m/CLE-4.0/			{return $p40}
		case m/4.0/				{return $p40}
		case m/CLE-4.1 w\/LSF/	{return $p41}
		case m/CLE-4.1/			{return $p41}
		case m/CLE-Dev/			{return $p41}
		case m/CLE-DEV/ 		{return $p41}
		case m/4.1/				{return $p41}
		case m/CLE-DevSP2/ 		{return $p51}
		case m/lustre-test/ 	{return $p51}
	}
	print "WARNING: unhandled Notes field:" . $_ ;
	print "Field Skipped\n\n";
	return $skip;
}

sub NotesHandler{
	switch ($superToggle) {
		case m/^DEV\/CASCADE$/i	{return ariesNotesHandler($_)}
		case m/^DEV$/i			{return geminiNotesHandler($_)}
	}
}

sub ariesDedOSversion { #Handles Reservation OS Field
	switch ($_) {
		case m/CLE-2.2/			{return $p22}
		case m/CLE-3.1/			{return $p31}
		case m/CLE-4.0/			{return $p40}
		case m/CLE-4.1/			{return $p41}
		case m/CLE-dev/			{return $p51}
		case m/CLE-devSP2/ 		{return $p51}
		case m/No OS/			{return $CLEother}
		case m/CLE-5.0/			{return $p50}
	}
	print "WARNING: unhandled Reserved OS field:" . $_ ;
	print "Field Skipped\n\n";
	return $skip;
}

sub geminiDedOSversion { #Handles Reservation OS Field
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
	print "Field Skipped\n\n";
	return $skip;
}

sub DedOSversion{
	switch ($superToggle) {
		case m/^DEV\/CASCADE$/i	{return ariesDedOSversion($_)}
		case m/^DEV$/i			{return geminiDedOSversion($_)}
	}
}

sub ariesORgemini{
	switch ($_) {
		case m/DEV$/i {return 'DEV'}
		case m/DEV\/CASCADE$/i {return 'DEV/CASCADE'}
	}
	print "ERROR: unhandled machine GROUP:" . $_;
	print "Data set to DEV\n\n";
	return 'DEV';
}

#####end BCE section

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
%weekendCounter = ();
my $time1;
my $time2;
my $category;
my $reservedOS;
my $notesOS;
my $userToggle = 0;
my $devadminOverflow = 0;
my $startTime;
my @machineArray =();
undef $startTime;
my $endTime;
while (<DCPIPE>) {
	if ($debug > 2 ) {print $_;}
	if ( $_ =~ m/20??\sCDT$/) {
		$copy = $_ ;
		$copy =~  s/\s+.*//;
		$copy = trim($copy);
		push(@machineArray,$copy);
	}
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
			if ($col[0] =~ m/EndDate/) 		{$time2 = Date::Parse::str2time($col[1]);	$endTime = $col[1];}
			if ($col[0] =~ m/Category/)		{$superToggle = ariesORgemini(trim($col[1]));}
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

		my ($year1,$month1,$day1, $hh1,$mm1,$ss1, $doy1,$dow1,$dst1) = Date::Calc::Localtime($time1);
		my ($year2,$month2,$day2, $hh2,$mm2,$ss2, $doy2,$dow2,$dst2) = Date::Calc::Localtime($time2);

		my $dateValue = $month1."-".$day1;

		if ($oh{workweek}) {
			if ($dow1 > 5) {
				$insert = $year1.$month1.$day1;
				$weekendCounter{$insert} = 1;
			}
			if ($dow2 > 5) {
				$insert = $year2.$month2.$day2;
				$weekendCounter{$insert} = 1;
			}
		}

	  # if a reservation goes past midnight into the next day,
	  # the data is considered to belong to the start time of the reservation
	  # this currently only applies to the Mountain Graph, but may also apply to
	  # different Composition-changing-OverTime graphs.

	 # see this website for graph suggestions
	 # http://extremepresentation.typepad.com/files/choosing-a-good-chart-09.pdf

		switch ($category) {
			case ($skip) {
				last;
			}
			case ('1') {if ($reservedOS) {
					if ($reservedOS ne $skip) {
						$timeHash{$reservedOS} += $timeDiff;
						$mHash{$reservedOS}{$dateValue} += $timeDiff;
						for $date (keys %{values %mHash} ) {
							$mHash{$reservedOS}{$date} += 0;
						}
					}
				}
			}
			case ('2') {if ($notesOS) {
					if ($notesOS ne $skip) {
						$timeHash{$notesOS} += $timeDiff;
						$mHash{$notesOS}{$dateValue} += $timeDiff;
						for $date (keys %{values %mHash} ) {
							$mHash{$notesOS}{$date} += 0;
						}
					}
				}
			}

			else {
				$timeHash{$category} += $timeDiff;
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
close DCPIPE;

my $tempSum;
while ( ( $key, $value ) = each(%timeHash) ) {
	$tempSum += $value;
}

my $machList = '';
my $machI;
foreach $mach (@machineArray) {
	$machI++;
	$machList .= $mach;
	if (length $machList > 2) {
		$machList .= ',';
	}
	if ($machI % 7 == 0) {
		$machList .= '\n';
	}
}

$dateRange = $startTime ." - " . $endTime;
my $totalTime;
$start = Date::Parse::str2time($startTime)/60/60;
$end = Date::Parse::str2time($endTime)/60/60;
$seH = $end - $start;
$numMachines = @machineArray;
$totalTime = $numMachines * $seH;

if ( $oh{full}) {
	$timeHash{unused} = $totalTime-$tempSum;
}

if ( $oh{workweek}) {
	$weekendDays = keys %weekendCounter;
	if ($debug) {print "\n\nweekend Days: ".$weekendDays ."\n";}
	$timeHash{unused} -= $numMachines * 24 *$weekendDays;
	$dateRange .= " excluding weekends";
}

while ( ( $key, $value ) = each(%timeHash) ) {
	print $key. ", " . $value . "\n";
}

##create your charts here. see http://search.cpan.org/~chartgrp/Chart-2.4.5/Chart.pod for chart::type usage
#colors
%colorHash = ('background' => [255,255,255],
	'title'		=> [0,0,0],
	'text'		=> [0,0,0],
	'x_label'	=> [0,0,0],
	'y_label'	=> [0,0,0],
	'misc'		=> [0,0,0],
	'dataset0'	=> [0,63,135], 		#cray blue
	'dataset1'	=> [195,200,200], 	#gray
	'dataset2'	=> [0,173,208], 	#teal
	'dataset3'	=> [253,200,47], 	#yellow
	'dataset4'	=> [255,102,0], 	#orange
	'dataset5'	=> [216,30,5], 		#red
	'dataset6'	=> [105,146,58],);	#green

#CHART PARAMATER HASH
my $font = 'GD::Font->Giant';

%paramHash = (
	'graph_border' 		=> '10',
	'title_font'		=> GD::Font->Giant,
	'x_label'			=> $dateRange,
	'colors'	 		=> \%colorHash,
	'grey_background' 	=> 'false',
  );

###end paramater setting

####Mountain Distribution Chart

print "\nCreating " .$extraArgs . " daily distripbution from " . $dateRange ." Chart \n";
my $chart = Chart::Mountain->new(1300,1200);
$chart->set('title' => $extraArgs . ' daily distribution\n\n' . $machList);
$chart->set(%paramHash);
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
$chart->set('y_label' => 'total hours ammong machineGroup in one day');
$chart->set('x_label' => 'Date');
$chart->set('legend_labels' => \@labels);
$chart->set('max_val' => $totalTime);
$chart->png(time.'_'.$oh{date}.'-day'.'_mountain.png');

####Usage Pie chart

print "\nCreating " .$extraArgs . " usage information from " . $dateRange ." Chart \n";
my $chart2 = Chart::Pie->new (800,800);
$chart2->set('title' => $extraArgs . ' usage information\n\n' . $machList);
$chart2->set(%paramHash);
undef @tempKeys;
undef @tempVals;

my $csv = Text::CSV_XS->new ({ binary => 1, eol => $/ });
open my $fh, ">", 'tbl.csv' or die 'tbl.csv: $!';

my $col_names = [ qw( "OS" "Time" ) ];
$csv->print($fh, ["TITLE"]);
$csv->print($fh , $col_names);

foreach $key (sort (keys(%timeHash))) {##so they are in Release Order
	push (@tempKeys, $key);
	push (@tempVals, $timeHash{$key});
	$csv->print ($fh,[$key, $timeHash{$key}]) or $csv->error_diag;

}
$chart2->add_dataset( @tempKeys );
$chart2->add_dataset( @tempVals );
$chart2->png(time.'_'.$oh{date}.'-day'.'_machine.png');

close $fh or die "tbl.csv: $!";

####OS Pie chart

print "\nCreating " .$extraArgs . " OS information from " . $dateRange ." Chart \n";
my $chart3 = Chart::Pie->new (800,800);
$chart3->set('title' => $extraArgs . ' OS information\n\n' . $machList);
$chart3->set(%paramHash);
undef @tempKeys;
undef @tempVals;
foreach $key (sort (keys(%osHash))) {
	push (@tempKeys, $key);
	push (@tempVals, $osHash{$key});
}
$chart3->add_dataset( @tempKeys );
$chart3->add_dataset( @tempVals );
$chart3->png(time.'_'.$oh{date}.'-day'.'_OS.png');

###Custom Translation Table
#must be modified for new slot types

my $TranslationTable = Chart::Pie->new (900,900);
$TranslationTable->set('title' => 'DCsched Slot --> Release Buckets\n'.
	  'For "notes" the notes field is scanned for hints of an os (4.1,4.0,etc...)\n'.
	  'For "reserv" the user selects an OS in DCsched to use for their time slot (NO OS is a choice)');
$TranslationTable->set(%paramHash);
$TranslationTable->set('legend' => 'left');
$TranslationTable->set('text_space'=> '10');
$TranslationTable->set('x_label' => 'Pie Slice ammounts are Meaningless');
$TranslationTable->set('label_values' => 'none');
$TranslationTable->set('legend_label_values' => 'none');
$TranslationTable->set('sub_title' => '');
%colorHash = (
	'dataset0'	=> [0,63,135], 		#cray blue
	'dataset1'	=> [0,63,135], 		#cray blue
	'dataset2'	=> [0,63,135], 		#cray blue
	'dataset3'	=> [0,63,135], 		#cray blue
	'dataset4'	=> [0,63,135], 		#cray blue
	'dataset5'	=> [0,63,135], 		#cray blue
	'dataset6'	=> [195,200,200], 	#gray
	'dataset7'	=> [195,200,200], 	#gray
	'dataset8'	=> [0,173,208], 	#teal
	'dataset9'	=> [253,200,47], 	#yellow
	'dataset10'	=> [255,102,0], 	#orange
	'dataset11'	=> [255,102,0], 	#orange
	'dataset12'	=> [255,102,0], 	#orange
	'dataset13'	=> [216,30,5], 		#red
	'dataset14'	=> [216,30,5], 		#red
	'dataset15'	=> [105,146,58],	#green
	'dataset16'	=> [105,146,58],	#green
	'dataset17'	=> [105,146,58],	#green
	'dataset18'	=> [95,158,160],	#green
	'dataset19'	=> [95,158,160],	#green
	'dataset20'	=> [95,158,160],	#green
	'dataset21'	=> [95,158,160],	#green
	'dataset22' => [1,1,1],
	'dataset23' => [1,1,1]);
$TranslationTable->set('colors'	 		=> \%colorHash);
$TranslationTable->add_dataset((
		'devadmins --> admin'
		,'ops --> admin'
		,'upgrade --> admin'
		,'admin --> admin'
		,'Admin Time --> admin'
		,'preempt --> admin'
		,'CLE-shared --> 2.2'
		,'CLE-Shared --> 2.2'
		,'CLE-3.1 --> 3.1'
		,'CLE-4.0 --> 4.0'
		,'CLE-4.1 --> 4.1'
		,'CLE-Dev --> 4.1'
		,'CLE-4.1 w/LSF --> 4.1'
		,'lustre-test --> CLE-DEVSP2'
		,'CLE-DevSP2 --> CLE-DEVSP2'
		,'vers_res_test --> notes'
		,'petest --> notes'
		,'vers --> notes'
		,'ostest --> reserv'
		,'ded --> reserv'
		,'bench-ded --> reserv'
		,'os-ded --> reserv'
		,'NO OS --> CLE-other'
		,'Unparseable Notes --> Skipped'
	));
$TranslationTable->add_dataset(4,4,3,2,2,3,2,2,3,4,4,3,2,3,2,2,2,4,4,5,3,4,2,3);
$TranslationTable->png('TranslationTable.png');
###end custom table

print "Graphs Done!";
