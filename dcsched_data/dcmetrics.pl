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
my $command = ' -u ';

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

open( DCPIPE, "/sw/sdev/dcsched/dcsched $command |" );
$i = 1;
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

my $chart = Chart::Pie->new (600,600);
$chart->set('title' => $extraArgs . " usage information from ". $dateRange);
$chart->add_dataset( keys %timeHash );
$chart->add_dataset( values %timeHash);

$chart->png('output.png');

#DONE
print "All done!\n";
