package SRGB::XSPT::PatternSiteVideo01;
our $Pattern = << '#XSPTPatternEND';
<?XSPT
XSStyleRoot
XSData
?>

<html>
<!-- <html xmlns="http://www.w3.org/1999/xhtml"><head> -->
<meta http-equiv="content-type" content="text/html; charset=utf-8">
<meta name="author" content="Sergey Vinogradov"></meta>

<!-- 
  background="<?perl $XSStyleRoot ?>SRGBDiv/background.gif"
-->

</head><body>
<center>
  <embed src="<?perl $XSStyleRoot ?>SRGBDiv/flvplayer1.swf"
allowfullscreen="true" 
flashvars="file=<?perl $XSData ?>&autostart=false&type=flv" 
height="426" width="540">

</center>
</body></html>
#XSPTPatternEND

1;
