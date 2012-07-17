#!/usr/bin/perl
use warnings;
use Getopt::Long;
use Date::Parse;
use CGI ':standard';
use Chart::Pie;
use GD::Graph::pie;
use List::Util 'max';


my $debuG = 1;

my %oh = ();
$oh{verbose} = '';
$oh{all}     = '';
$oh{date}    = '';
$oh{group}   = '';
$oh{machine} = '';
my $command = '';

GetOptions(
	'verbose!'  => \$oh{verbose},
	'all'       => \$oh{all},
	'date=s'    => \$oh{date},
	'group=s'   => \$oh{group},
	'machine=s' => \$oh{machine}
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
print "Unprocessed by Getopt::Long\n" if $ARGV[0];
foreach (@ARGV) {
	print "$_\n";
}

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

if ( $oh{group} ) {
	$group = $oh{group};
	print "group set\n";
	$command .= ' ' . $group . ' ';
}

if ( $oh{machine} ) {
	$machine = $oh{machine};
	print "machine set\n";
	$command .= ' ' . $machine . ' ';
}

printf "|%s|\n", $command;

@output = ();
open( DCPIPE, "/sw/sdev/dcsched/dcsched $command |" );
$i = 1;
%timeHash = ();

while (<DCPIPE>) {
	if ( $_ =~ m/until/ ) {
		$temp = ltrim($_);
		$temp =~ s/^\*+//;
		$temp =~ s/until\s+//;
		$temp = ltrim($temp);
		
		my @col = split /\s/, $temp;
		
		if ( $debuG > 0 ) {print $col[0]." ".$col[1]." ".$col[2]." ".$col[3]." ".$col[4]." ".$col[5]." ".$col[6]."\n";}
		
		$time1    = str2time( $col[0] . " " . $col[1] . " " . $col[2] );
		$time2    = str2time( $col[3] . " " . $col[4] . " " . $col[5] );
		$category = $col[6];
		
		$timeHash{$category} += $time2 - $time1;
		
		$output[$i] ="time1: " . $time1 . " time2: " . $time2 . " category: " . $category . "\n";
		print $output[$i];
	}
	$i++;
}

while ( ( $key, $value ) = each(%timeHash) ) {
	print $key. ", " . $value . "\n";
}

close DCPIPE;

my @timeData = ([keys %timeHash],[values %timeHash]);

## CReATE THE CHART !!!!!___
#GD

#open( PNGFILE, ">./graph.png" ) || die "Cannot open graph.png for write: $!\n";
#binmode PNGFILE;
#
## Both the arrays should same number of entries.
#my $mygraph = GD::Graph::pie->new( 300, 300 );
#$mygraph->set(
#	title => $oh{machine} . " usage information",
#	#  '3d'          => 1,
#  ) or warn $mygraph->error;
#$mygraph->set_value_font(GD::gdMediumBoldFont);
#
#my $myimage = $mygraph->plot( \@timeData ) or die $mygraph->error;
#
#print "Content-type: image/png\n\n";
#print PNGFILE $myimage->png;
#close(PNGFILE);

#CHART

my $chart = Chart::Pie->new (600,600);
$chart->set('title' => $oh{machine} . " usage information");
$chart->add_dataset( keys %timeHash );
$chart->add_dataset( values %timeHash);

$chart->png('output.png');


#DONE
print "All done!\n";
