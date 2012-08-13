DCmetrics
=============

This Perl script creates various usage graphs over a certain date range

Usage
-------

The Following command line options are supported

	-a 			| all
	-d ?  		| past days from today (integer)
	-g GROUP	| TODO
	-v			| verbose output (for debuging and such)
	*			| arguments that can be passed to dcsched see 'dcsched -h' for help

Examples

	$ dcmetrics.pl -d 3 DEV							# This command shows the last 3 days of all machines in the DEV category
	$ dcmetrics.pl -d 20 mindy pollux-p1 castor-p2 	# This shows the last 20 days of mindy, pollux-p1 and castor-p2's data

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

TODO
------------

1. repurpose pass-through arguments and create groups 
	-g DEV/gemini  = DEV/gemini machines with gemini buckets
	-d DEV/cascade = DEV/cascade machines with cascade buckets
	
2. make csv for all graphs
3. change csv filenames to be more verbose
 





