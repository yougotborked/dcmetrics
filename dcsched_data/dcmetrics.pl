#!/usr/bin/perl
use warnings;
use Getopt::Long;
use Date::Parse;
use CGI ':standard';
use Chart::Pie;
use GD::Graph::pie;
use List::Util 'max';

my $debug = 1;

my %oh = ();
$oh{verbose} = '';
$oh{all}     = '';
$oh{date}    = '';
$oh{group}   = '';
$oh{machine} = '';
my $command = ' ';

GetOptions(
	'verbose!'  => \$oh{verbose},
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

#foreach (keys %oh) {
# print "$_ = $oh{$_}\n";
#}

if ( $oh{verbose} ) {
	$v = '-v';
	print "verbose Set\n";
	$command .= ' ' . $v . ' ';
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

$command .= $extraArgs;

printf "|%s|\n", $command;

open( DCPIPE, "/sw/sdev/dcsched/dcsched -u $command |" );
%timeHash = ();
my $dateRange;
$extraArgs = trim($extraArgs);
while (<DCPIPE>) {
	if (($_ =~ m/Summary system usage report for/)  || ($_ =~ m/System usage report for ($extraArgs)/)) {
		$dateRange = $_;
		$dateRange =~ s/^[\w\s]+\(/\(/;
		while (<DCPIPE>) {
			if ($_ =~ m/Scheduled time/ || $_ =~ m/Scheduled hours/) {
				while (<DCPIPE>) {
					last if $_ =~ m/Total/;
					if ($_ =~ m/\w\s*\w\s*\w/) {
						if ($debug > 1) {
							print $_;
						}
						$temp = trim($_);
						my @col = split /\s+/, $temp;
						if ( $debug > 0 ) {print $col[0]." ".$col[1]." ".$col[2]."\n";}
						$category = $col[2];
						$time = $col[0];
						$timeHash{$category} += $time
					}
				}
			}
		}
	}
}

while ( ( $key, $value ) = each(%timeHash) ) {
	print $key. ", " . $value . "\n";
}

close DCPIPE;

my @timeData = ([keys %timeHash],[values %timeHash]);

### CReATE THE CHART !!!!!___
##GD
#
#open( PNGFILE, ">./graph.png" ) || die "Cannot open graph.png for write: $!\n";
#binmode PNGFILE;
#
## Both the arrays should same number of entries.
#my $mygraph = GD::Graph::pie->new( 300, 300 );
#$mygraph->set(
#	title => $oh{machine} . " usage information",
#
#	#  '3d'          => 1,
#  ) or warn $mygraph->error;
#$mygraph->set_value_font(GD::gdMediumBoldFont);
#
#my $myimage = $mygraph->plot( \@timeData ) or die $mygraph->error;
#
#print "Content-type: image/png\n\n";
#print PNGFILE $myimage->png;
#close(PNGFILE);

#___CHART

my $chart = Chart::Pie->new (900,900);
$chart->set('title' => $extraArgs . " usage information from ". $dateRange);
$chart->add_dataset( keys %timeHash );
$chart->add_dataset( values %timeHash);

$chart->png('output_usage.png');

#DONE
print "Usage Done!\n";

##do it again, except differently.
open( OTHERPIPE, "/sw/sdev/dcsched/dcsched $command |" );
$i = 0;
%timeHash2 = ();
my $time1;
my $time2;
my $category;
while (<OTHERPIPE>) {
	if ($debug > 1 ) {print $_;}
	if ( $_ =~ m/until/ ) {
		if ($debug > 0) {
			print $_;
		}
		while (<OTHERPIPE>) {
			$temp = trim($_);
			my @col = split /=/, $temp;
			if ($col[0] =~ m/StartDate/) {$time1 = str2time($col[1]);}
			if ($col[0] =~ m/EndDate/) {$time2 = str2time($col[1]);}
			if ($col[0] =~ m/SkSlotName/) {$category = trim($col[1]);}
			last if $_ =~ m/until/;
		}
		$output[$i] ="time1: " . $time1 . " time2: " . $time2 . " category: " . $category . "\n";
		if ($debug > 1) {print $output[$i];}
		print $time1." ".$time2."\n";
		$timeHash2{$category} += ($time2 - $time1)/60/60;
		$i++;
	}
}

while ( ( $key, $value ) = each(%timeHash2) ) {
	print $key. ", " . $value . "\n";
}

close OTHERPIPE;

my @timeDat2 = ([keys %timeHash2],[values %timeHash2]);

my $chart2 = Chart::Pie->new (900,900);
$chart2->set('title' => $extraArgs . " usage information from ". $dateRange);
$chart2->add_dataset( keys %timeHash2 );
$chart2->add_dataset( values %timeHash2);

$chart2->png('output_machine.png');

print "machine Done!";
