package SRGB::XSPT::PatternAquaConfigXML;
our $Pattern = << '#XSPTPatternEND';
<?XSPT
XSproject
XSname
XSver
XSbuildPath
XScmdBuild
XScmdConfig
XScmdTest
XSemail
?>

<GTLCONFIG>
 
  <!-- Name of the project -->
  <PROJECT_NAME><?perl $XSname ?></PROJECT_NAME>

  <!-- Project version -->
  <VERSION><?perl $XSver ?></VERSION>

  <CMD_CONFIG><?perl $XScmdConfig ?></CMD_CONFIG>
  <CMD_BUILD><?perl $XScmdBuild ?></CMD_BUILD>
  <CMD_TEST><?perl $XScmdTest ?></CMD_TEST>
 
  <BUILD_PATH><?perl $XSbuildPath ?></BUILD_PATH>

<?perl 
  my $XStmp; 
  my $XStab = '  ';
  for (@{$XSproject})
  {
    $XStmp.= $XStab . "<DEPENDENCY name='$_->{name}'>\n";
    $XStmp.= $XStab . "  <P4PATH>$_->{p4path}</P4PATH>\n";
    $XStmp.= $XStab . "</DEPENDENCY>\n\n";
  }
  $XStmp;
?>

  <EMAIL_RECIPIENTS>
    <ADDRESS><?perl $XSemail ?></ADDRESS>
  </EMAIL_RECIPIENTS>
  
</GTLCONFIG>
#XSPTPatternEND
