#!/usr/bin/perl -w

use strict;
use CGI qw(:standard);
use CGI::Carp qw(fatalsToBrowser);
use File::Basename;
use Cwd;
$CGI::POST_MAX = 1024 * 5000;
my $filename_chars = "a-zA-Z0-9_.-";
my $myPhotos = "MyPhotos";
my $cgi = new CGI();
if ($cgi->param('delete')){
	my @params = $cgi->param;
	foreach (@params)	{
		next unless (substr($_,0,4) eq "img-");
		my $fname = substr($_,4);
		my $name = fileparse($fname, '\..*');
		unlink foreach ("$fname", "$myPhotos/$name.txt");
	}
	print $cgi->redirect("borkx026A3.cgi\n\n");
}
elsif ($cgi->param('filename')) {
	my $fname = $cgi->param('filename');
	my $desc = $cgi->param('description') || "";
	my ($name, $path, $extension) = fileparse($fname, '\..*');
	$fname = $name . $extension;
	$fname =~ tr/ /-/;
	$fname =~ s/[^$filename_chars]//g;
	my $UPLOADED = $cgi->param("filename");
	if (defined $UPLOADED)	{
		open my $SAVEFILE, ">", "$myPhotos/$fname" or die "$!";
		binmode $SAVEFILE;
		while (<$UPLOADED>)		{
			print $SAVEFILE $_;
		}
		close $SAVEFILE;
	}
	else	{
		print $cgi->header();
		print "ERROR: photo not selected for upload";
		exit;
	}
	open my $DESCFILE, ">", "$myPhotos/$name.txt" or die "$!";
	print $DESCFILE $desc;
	close $DESCFILE;
	print $cgi->redirect("borkx026A3.cgi\n\n");
}
else{
	print $cgi->header();
	print "ERROR: Problem with photo selected for upload, Too large. OR file not selected.";
	exit;
}
