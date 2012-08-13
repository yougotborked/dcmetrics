#!/usr/bin/perl -w

use strict;
use CGI qw(:standard);
use CGI::Carp qw(fatalsToBrowser);
use File::Basename;
use Cwd;
my $cgi = new CGI();
sub acceptableExtension{
	my $ext = lc shift;
	return (($ext eq '.png') or ($ext eq '.bmp') or ($ext eq '.jpg') or ($ext eq '.jpeg') or ($ext eq '.gif'))
}
my $myPhotos = "MyPhotos";
mkdir $myPhotos, 0755 unless -d $myPhotos;
my %images = ();
print $cgi->header();
opendir (my $UPLOAD, $myPhotos);
foreach (readdir $UPLOAD){
	my ($name, $path, $extension) = fileparse($_, '\..*');
	if (&acceptableExtension($extension))	{
		$images{$name} = {'image' => '', 'description' => ''} unless exists $images{$name};
		$images{$name}->{'image'} = "$myPhotos/$_";
	}
	elsif ($extension eq ".txt")	{
		$images{$name} = {'image' => '', 'description' => ''} unless exists $images{$name};
		open my $DESCFILE, "$myPhotos/$_";
		$images{$name}->{'description'} = join '', <$DESCFILE>;
		close $DESCFILE;
	}
}
closedir $UPLOAD;
my $imagesjs = join ',', map { "{image: '" . $_->{'image'} . "', description: '" . $_->{'description'} . "'}" } values %images;
print <<HTML_DOCUMENT;
<!DOCTYPE htmlnext>
<HTML>
<HEAD>
<TITLE>Borkx026 Assignment 3 - CGI Programming</TITLE>
<STYLE type="text/css">
body {
	font-family: sans-serif;
}
button {
	font-family: sans-serif;
	border: thin;
}
select {
	font-family: sans-serif;
	border: thin;
}
h1 {
	font-weight: bold;
	font-size: 20pt;
}
</STYLE>
</HEAD>
<BODY>
<BUTTON onclick="select(0);return false">Start</BUTTON>
<BUTTON onclick="select(_current_+1);return false">Next</BUTTON>
<BUTTON onclick="select(_current_-1);return false">Previous</BUTTON>
<BR />
Select Information Type:
<SELECT id="infotype" onchange="detailType = this.value;select()">
	<OPTION value="none">None</OPTION>
	<OPTION value="description" selected="selected">Description</OPTION>
</SELECT>
<FORM action="scripts.cgi" method="post">
<P id="thumbs"></P>
<P style="clear: both"><INPUT type="hidden" name="delete" value="1" />
<BUTTON id="delete-button" disabled="disabled">Delete</BUTTON>
</P>
</FORM>
<P id="upload-form-button">
<BUTTON onclick="toggleUpload();return false">Upload an image</BUTTON>
</P>
<FORM id="upload-form" action="scripts.cgi" method="post"
	enctype="multipart/form-data"
	style="display: none; border: 1px solid #BBBBBB; padding: 8px 15px">
File: <INPUT type="file" name="filename" id="filename"
	onchange="uploadFile()" /> Description: <INPUT type="text"
	name="description" />
<BUTTON type="submit"><STRONG>Upload</STRONG></BUTTON>
<BUTTON onclick="toggleUpload();return false">Cancel</BUTTON>
</FORM>
<HR />
<BUTTON onclick="start();return false" id="start-button">Start
Slide Show</BUTTON>
<BUTTON onclick="stop();return false" disabled="disabled"
	id="stop-button">Stop Slide Show</BUTTON>
<BR />
<DIV>
<P id="image" style="float: left; width: 420px"><IMG width="400"
	height="400" src="" alt="" /></P>
<DIV id="details" style="margin-left: 440px">
<H1>Image Information:</H1>
</DIV>
<DIV style="clear: both"></DIV>
</DIV>
<SCRIPT>

function \$(a) { 
return document.getElementById(a); 
}
var Timer = null;
var _current_ = 0;
var detailType = 'description';
var ImageInfo = [$imagesjs];
function start(){
	if (Timer)	{
		alert("Slide show in progress.");
	}
	else	{
		Timer = setTimeout(next, 1000);
		\$('start-button').disabled = true;
		\$('stop-button').disabled = false;
	}
}
function stop(){
	if (Timer) clearTimeout(Timer);
	Timer = null;
	\$('start-button').disabled = false;
	\$('stop-button').disabled = true;
}
function next(){
	Timer = null;
	_current_++;
	if (!ImageInfo[_current_]) _current_ = 0;
	select();
	Timer = setTimeout(next, 1000);
}
function refresh(){
	var atLeastOneChecked = false;
	var atLeastOneUnchecked = false;
	for (var i=0; i<ImageInfo.length; i++){
		var curData = ImageInfo[i];
		if (\$('checkbox-'+curData.image).checked){
			atLeastOneChecked = true;
		}
		else		{
			atLeastOneUnchecked = true;
		}
	}
	\$('delete-button').disabled = !atLeastOneChecked;
}
function uploadFile(){
	var fname = \$('filename').value;
	switch (fname.split('.').pop())	{
	case 'bmp':
	case 'gif':
	case 'png':
	case 'jpg': case 'jpeg':
		break;
	default:
		alert('ERROR: filetype not allowed: PNG, GIF, JPEG, BMP');
		\$('filename').value = '';
	}
}

function toggleUpload(){
	switch (\$('upload-form').style.display)	{
	case 'none':
		\$('upload-form').style.display = 'inline';
		\$('upload-form-button').style.display = 'none';
		break;
	default:
		\$('upload-form').style.display = 'none';
		\$('upload-form-button').style.display = 'inline';
		break;
	}
}
function select(image){
	if (typeof image === 'undefined' || !ImageInfo[image]) {
	image = _current_;
	}
	_current_ = image;
	var data = ImageInfo[image];
	if (!data) data = {};
	var thumbs = '';
	for (var i=0; i<ImageInfo.length; i++)	{
		var curData = ImageInfo[i];
		thumbs += '<div style="float:left;text-align:center;'+(i==image?'border:2px solid red':'padding:2px')+'"><input type="checkbox" name="img-'+curData.image+'" id="checkbox-'+curData.image+'" onchange="refresh()"'+(\$('checkbox-'+curData.image)&&\$('checkbox-'+curData.image).checked?' checked="checked"':'')+' /><br /><img src="'+curData.image+'" width="50" height="50" onclick="select('+i+')" /></div> ';
	}
	\$('thumbs').innerHTML = thumbs;
	\$('image').innerHTML = '<img src="'+data.image+'" width="400" height="400" />';
	var details = '<h1>Image Information:</h1>';
	switch (detailType)	{
	case 'description':
		details += '<h1>Description: '+data.description+'</h1>';
		break;
	}
	\$('details').innerHTML = details;
}
select();
refresh();
	</SCRIPT>
</BODY>
</HTML>
HTML_DOCUMENT
;
