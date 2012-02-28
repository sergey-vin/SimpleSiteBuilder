package SRGB::XSPT;
# <?perl ?> --> data: XSPT transformer
# @autor Sergey Vinogradov <svinogradov@nvidia.com>

require Exporter;

@ISA = qw(Exporter);

@EXPORT_OK = qw(
  TransformFromVarRefToItself
  TransformFromFileToFie
  TransformFromVarToVar
  TransformFromVarToFile
  TransformPathAbsoluteToRelative
);

@EXPORT = @EXPORT_OK;

use strict;
use Data::Dumper qw(Dumper);
use List::Util qw(min max);


#########################
## util funcs

sub DataValidateVars($$)
{
  # ref to hash {var_name => ref_to_var}
  my $vars = shift or
    die "parameter 'vars' should present";

  my $data = shift or
    die "parameter 'data' should present";


  for (split /[\s;,]+/, $data)
  {
    next unless $_;
    die "parameter '$_' required by XSPT not exported by XS source"
      unless (exists $vars->{$_});
  }
  '';
}

sub DataProcess($$)
{
  my $vars = shift or 
    die "parameter 'vars' should present";
  my $code = shift or
    die "parameter 'code' should present";

  # @todo add check eval before eval!
  for my $var (keys %$vars)
  {
    #print "$var :", ref $vars->{$var}, " \n"; # @todo differ based on type? 
    $code =~ s#([^a-z_])$var([^a-z_])#$1vars->{$var}$2#ig;
  }

  #print STDERR Dumper($code);
  #print STDERR Dumper(eval ($code));
  eval $code;
}


#########################
## exported funcs

sub TransformFromVarRefToItself($$;$)
{
  my $vars = shift or
    die "parameter 'vars' should present";
  #print Dumper($vars);

  my $data = shift or
    die "parameter 'data' should present";
  ref $data eq 'SCALAR' or
    die "parameter 'data' should be a scalar reference";

  $_[0] and shift =~ /^disable/i and return '';

  my $EOL  = '(?:\r\n|\r|\n|\n\r)';
  # or '?' instead of '{0,1}'
  my $EOLe = "${EOL}{0,2}"; 
  my $EOLb = "${EOL}{0,0}"; 
  
  # validation, if any
  $$data =~ s#<\?XSPT(.*?)\?>$EOLe#DataValidateVars ($vars, $1), ''#seg;

  # evaluation
  $$data =~ s#$EOLb<\?perl(.*?)\?>$EOLe#DataProcess ($vars, $1)#seg;

  return $$data;
}

sub TransformFromVarToVar($$;$)
{
  my $vars = shift or
    die "parameter 'vars' should present";
  #print Dumper($vars);

  my $inData = shift or
    die "parameter 'inData' should present";

  $_[0] and shift =~ /^disable/i and return '';
  
  my $outData = $inData;
  TransformFromVarRefToItself($vars, \$outData);

  return $outData;
}


sub TransformFromFileToFile($$$;$)
{
  my $vars = shift or
    die "parameter 'vars' should present";
  #print Dumper($vars);

  my $inFileName = shift or
    die "parameter 'inFileName' should present";

  my $outFileName = shift or
    die "parameter 'outFileName' should present";

  $_[0] and shift =~ /^disable/i and return '';

  my $data;
  open XSTempl, $inFileName
    and $data = join '', <XSTempl>
    and close XSTempl
    or die "I/O error with [$inFileName] file: $!";

  TransformFromVarRefToItself($vars, \$data);

  open XSRes, ">" . $outFileName
    and print XSRes $data
    and close XSRes
    or die "I/O error with [$outFileName] file: $!";

  return $data;
}


sub  TransformFromVarToFile($$$;$)
{
  my $vars = shift or
    die "parameter 'vars' should present";
  #print Dumper($vars);

  my $data = shift or
    die "parameter 'data' should present";

  my $outFileName = shift or
    die "parameter 'outFileName' should present";

  $_[0] and shift =~ /^disable/i and return '';

  TransformFromVarRefToItself($vars, \$data);

  open XSRes, ">" . $outFileName
    and print XSRes $data
    and close XSRes
    or die "I/O error with [$outFileName] file: $!";

  return $data;
}



sub TransformPathAbsoluteToRelative($$)
{
  my $absBase = shift or
    die "parameter 'absBase' should present";

  my $absCur = shift or
    die "parameter 'absCur' should present";

  my @baseList = grep {$_ ne '' } split /[\/\\]+/, $absBase;
  my @curList = grep {$_ ne '' } split /[\/\\]+/, $absCur;
  my $rel = "";
  my $i = 0;
  #print STDERR Dumper(@baseList);
  #print STDERR "-------------END\n";

  while ($i++ < min(scalar@baseList,scalar@curList))
  {
    if ( !defined $baseList[$i]
      || !defined $curList[$i]
      || $baseList[$i] ne $curList[$i])
    {
      $rel = "../" x (@baseList - $i);
      last;
    }
  }
  $rel = "./" unless $rel;
  $rel .= join "/", @curList[$i .. @curList - 1];
  
  #print STDERR "\n>> $rel <<\n";
  return $rel;
}


sub _int_test()
{

  use FindBin '$Bin';
  use lib "$Bin/..";
  use SRGB::XSPT::PatternAquaConfigXML;

  use FindBin qw($Bin);
  use Data::Dumper;

  use Test;

  eval { plan tests => 7 };

  ################################################################################
  ### Globals
  ################################################################################

  my $res;


  my $config =
    {
      XSp4path => '//sw/devrel/GFE/client/agent/research-autogen',
      XSname => 'Agent',
      XSver => 'research-autogen',

      XSbuildPath => 'build',
      XScmdBuild => 'build.pl',
      XScmdConfig => 'configure.pl',
      XScmdTest => 'test.pl',
      XSemail => 'GFE-dev-builds@exchange.nvidia.com',

      XSproject => [
        {
          name => 'GFE-Common-Libs',
          var => 'GFE_COMMON_LIB_PATH',
          p4path => '//sw/devrel/GFE/common/gfelib/main',
        },
        {
          name => 'GFE-External-Libs',
          var => 'EXTERNAL_LIB_PATH',
          p4path => '//sw/devrel/GFE/common/externallib/release',
        },
        {
          name => 'GFE-SHIM',
          var => 'GFE_SHIM_PATH',
          p4path => '//sw/devrel/GFE/client/SHIM/main',
        },
        {
          name => 'GFE-gfeAPI',
          var => 'GFE_gfeAPI_PATH',
          p4path => '//sw/devrel/GFE/client/gfeAPI/research-autogen'
        },
      ],
    };

  my $res1 = <<'END';
<GTLCONFIG>
 
  <!-- Name of the project -->
  <PROJECT_NAME>Agent</PROJECT_NAME>

  <!-- Project version -->
  <VERSION>research-autogen</VERSION>

  <CMD_CONFIG>configure.pl</CMD_CONFIG>
  <CMD_BUILD>build.pl</CMD_BUILD>
  <CMD_TEST>test.pl</CMD_TEST>
 
  <BUILD_PATH>build</BUILD_PATH>

  <DEPENDENCY name='GFE-Common-Libs'>
    <P4PATH>//sw/devrel/GFE/common/gfelib/main</P4PATH>
  </DEPENDENCY>

  <DEPENDENCY name='GFE-External-Libs'>
    <P4PATH>//sw/devrel/GFE/common/externallib/release</P4PATH>
  </DEPENDENCY>

  <DEPENDENCY name='GFE-SHIM'>
    <P4PATH>//sw/devrel/GFE/client/SHIM/main</P4PATH>
  </DEPENDENCY>

  <DEPENDENCY name='GFE-gfeAPI'>
    <P4PATH>//sw/devrel/GFE/client/gfeAPI/research-autogen</P4PATH>
  </DEPENDENCY>

  <EMAIL_RECIPIENTS>
    <ADDRESS>GFE-dev-builds@exchange.nvidia.com</ADDRESS>
  </EMAIL_RECIPIENTS>
  
</GTLCONFIG>
END

  ################################################################################
  ### Tests
  ################################################################################

  my $a = TransformFromVarToVar(
    $config, 
    $SRGB::XSPT::PatternAquaConfigXML::Pattern );

  ok($a eq $res1);

  # $config & patter are unchanged
  $a = TransformFromVarToVar(
    $config, 
    $SRGB::XSPT::PatternAquaConfigXML::Pattern,
    'not-disabled');

  ok($a eq $res1);

  $a = TransformFromVarToVar(
    $config, 
    $SRGB::XSPT::PatternAquaConfigXML::Pattern,
    'disabled');
  ok($a eq '');

   

  ok(
    SRGB::XSPT::TransformPathAbsoluteToRelative('//1','//1'),
    './',
    );
  ok(
    SRGB::XSPT::TransformPathAbsoluteToRelative('//1/3/5','//1/2/5/6'),
    '../../2/5/6',
    );
  ok(
    './6',
    SRGB::XSPT::TransformPathAbsoluteToRelative('//1/3/5','//1/3/5/6'),
    );
  ok(
    SRGB::XSPT::TransformPathAbsoluteToRelative('//1/3/5','//1'),
    '../../',
    );
  ok(
    SRGB::XSPT::TransformPathAbsoluteToRelative('//1','//1/../2'),
    './../2',
    );

}

BEGIN { _int_test() };

1;
