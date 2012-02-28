package SRGB::XSPT::PatternVersionXML;
our $Pattern = << '#XSPTPatternEND';
<?XSPT
XSname
XSver
?>

<GTLCONFIG>
 
  <!-- Name of the project -->
  <PROJECT_NAME><?perl $XSname ?></PROJECT_NAME>

  <!-- Project version -->
  <VERSION><?perl $XSver ?></VERSION>

</GTLCONFIG>
#XSPTPatternEND
