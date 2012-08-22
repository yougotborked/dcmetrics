DCmetrics
=============

This Perl script creates various usage graphs over a certain date range

Usage
-------

The Following command line options are supported

	-a 					| all
	-d #  				| past days from today (integer)
	-g GROUP			| TODO
	--full				| toggles whether or not to include Unused time in Pie charts
		|				|
		-	--workweek	| does not include weekends in unused time calculation
	*					| arguments that can be passed to dcsched see 'dcsched -h' for help

Examples

	$ dcmetrics.pl -d 3 DEV										# This command shows the last 3 days of all machines in the DEV category
	$ dcmetrics.pl -d 20 mindy pollux-p1 castor-p2 				# This shows the last 20 days of mindy, pollux-p1 and castor-p2's data
	$ dcmetrics.pl --full --workweek -d 30 DEV DEV/CASCADE 		# This does a full show of the past month of both DEV and DEV/CASCADE not including weekends

Output
-------

Currently the script returns the following:

* *-day_machine.png

This describes the Release Bucket hour totals

* *-day_mountain.png

Shows a daily view of the *-day_machine.png pie chart to get a feel of how it changes over time

* *-day_OS.png

Shows which OS's were reserved by users over the date range. These are NOT release buckets, but reserved OS's

* tbl.csv

A comma seperated value list of *-day_machine.png's data

Notes and Caveats
-------
Because of the custom nature of this script, if new categories are ever added, or different fields need to be supported, they must be added to the script. 

	WARNING: unhandled * : (the unknown data)
	
will show up whenever something is detected the script does not know how to process. 

TODO
------------

1. General Size of the machines, CSV of blade counts

2. update translation table with new DEV/cascade translations. 

Upcoming
------------

1. repurpose pass-through arguments and create groups 
	-g DEV/gemini  = DEV/gemini machines with gemini buckets
	-g DEV/cascade = DEV/cascade machines with cascade buckets
	
2. make csv for all graphs
3. change csv filenames to be more verbose
4. change png filenames to include machine names, or categories
 





