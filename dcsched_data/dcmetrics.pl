#!/opt/cpkg/current/perl/current/bin/perl

use warnings;
use Getopt::Long;
use Date::Parse;
use Time::Local;
use Chart::Pie;
use Chart::StackedBars;
use List::Util 'max';

my $debug = 0;

my %oh = ();
$oh{verbose} = '';
$oh{all}     = '';
$oh{date}    = '';
$oh{group}   = '';
$oh{machine} = '';
my $command = ' ';

GetOptions(
	'verbose' => \$oh{verbose},
	'all'       => \$oh{all},
	'date=s'    => \$oh{date},
  );

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

sub categoryCombine(@) {
	my($source, $destination, %hash) = @_;
	$hash{$destination} += $hash{$source};
	delete($hash{$source});
	return %hash;
}



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

##do it again, except differently.
open( DCPIPE, "/sw/sdev/dcsched/dcsched $command |" );
$i = 0;
%timeHash = ();
%osHash = ();
%HoH = ();
my $time1;
my $time2;
my $category;
my $reservedOS;
my $userToggle =0;
my $startTime;
undef $startTime;
my $endTime;
while (<DCPIPE>) {
	if ($debug > 2 ) {print $_;}
	if ( $_ =~ m/until/ ) {
		$userToggle = 0;
		if ($_ =~ m/\)$/ ) {$userToggle = 1} #checking if it is a user slot (look for ')' )
		if ($debug > 1) {
			print trim($_)."\n";
		}
		undef $time1;
		undef $time2;
		undef $reservedOS;
		undef $category;
		while (<DCPIPE>) { ##check for key-value pairs you want to store and store them somewhere.
			if ($debug > 0) {print $_;}
			$temp = trim($_);
			my @col = split /=/, $temp;
			if ($col[0] =~ m/StartDate/) {$time1 = str2time($col[1]);
				if (!(defined $startTime) ) {$startTime = $col[1];}
			}
			
			if ($col[0] =~ m/EndDate/) {$time2 = str2time($col[1]);
				$endTime = $col[1];
			}
			if ($col[0] =~ m/SkSlotName/) {$category = trim($col[1]);}
			if ($col[0] =~ m/UrOsVersion/) {$reservedOS = trim($col[1]);}
			if ($userToggle == 0) {last if $col[0] =~ m/SkSoftwareTypes/; # last item in First half
			}
			elsif ($userToggle == 1) {last if $col[0] =~ m/UrSurrender/; #last item in Second Half
			}
		}
		##process your keyvalue pairs before the next machine comes up here

		$timeDiff = ($time2-$time1)/60/60;
		$timeHash{$category} += $timeDiff;
		if ($reservedOS) {
			$osHash{$reservedOS} += $timeDiff;
			$HoH{$category}{$reservedOS} += $timeDiff;

			for $cat (keys %HoH ) {
				$HoH{$cat}{$reservedOS} += 0;
			}
			for $op (keys %{values %HoH} ) {
				$HoH{$category}{$op} += 0;
			}

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

while ( ( $key, $value) = each(%HoH) ) {
	while (($key2, $value2) = each(%{$value})) {
	print $key. ", " . $key2 .", ". $value2 . "\n";
	}
}

%timeHash = categoryCombine('CLE-4.1 w/PBS', 'CLE-4.1',%timeHash);
%timeHash = categoryCombine('CLE-4.1 w/Moab', 'CLE-4.1' ,%timeHash);



close DCPIPE;

$dateRange = $startTime ." - " . $endTime;

##create your charts here. see http://search.cpan.org/~chartgrp/Chart-2.4.5/Chart.pod for chart::type usage

my $chart2 = Chart::Pie->new (900,900);
$chart2->set('title' => $extraArgs . " usage information from ". $dateRange);
$chart2->add_dataset( keys %timeHash );
$chart2->add_dataset( values %timeHash);
$chart2->png('output_machine.png');

my $chart3 = Chart::Pie->new (900,900);
$chart3->set('title' => $extraArgs . " OS information from " . $dateRange);
$chart3->add_dataset( keys %osHash);
$chart3->add_dataset( values %osHash);
$chart3->png('output_OS.png');

my @labels;
my $chart4 = Chart::StackedBars->new(900,900);
$chart4->set('title' => $extraArgs. " OS and Usage Info from " . $dateRange);
$chart4->add_dataset (keys %osHash);
for $family (sort keys %HoH ) {
	push(@labels,$family);
	print keys %{values %HoH};
	$chart4->add_dataset ( values %{$HoH{$family}} );
}
$chart4->set('y_label' => 'Hours');
$chart4->set('x_label' => 'OS Type');
$chart4->set('legend_labels' => \@labels);
$chart4->png('output_stacked.png');

print "machine Done!";
