#!/usr/bin/perl
use strict;
use FindBin '$Bin';
use lib "$Bin/..";
use NVIDIA::XSPT;
use NVIDIA::XSPT::PatternConfigure;
use NVIDIA::XSPT::PatternAquaConfigXML;
use NVIDIA::XSPT::PatternVersionXML;

use FindBin qw($Bin);
use Data::Dumper;
use UNIVERSAL qw(isa);
use Cwd;

#use lib "$Bin/../lib/perl";
use lib "$Bin/../";
#use lib "$Bin/../../../../common/perl/release/lib";

use NVIDIA::Test;
use NVIDIA::TempFile;

BEGIN { plan tests => 7 }

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

my  $START_DIR      = getcwd(); # for file tests

################################################################################
### Tests
################################################################################

chdir("${Bin}/t");

my $a = TransformFromVarToVar(
  $config, 
  $NVIDIA::XSPT::PatternAquaConfigXML::Pattern );

ok($a eq $res1);

# $config & patter are unchanged
$a = TransformFromVarToVar(
  $config, 
  $NVIDIA::XSPT::PatternAquaConfigXML::Pattern,
  'not-disabled');

ok($a eq $res1);

$a = TransformFromVarToVar(
  $config, 
  $NVIDIA::XSPT::PatternAquaConfigXML::Pattern,
  'disabled');
ok($a eq '');

 

ok('./' eq 
  NVIDIA::XSPT::TransformPathAbsoluteToRelative('//1','//1'));
ok('../../2/5/6' eq 
  NVIDIA::XSPT::TransformPathAbsoluteToRelative('//1/3/5','//1/2/5/6'));
ok('./6' eq 
  NVIDIA::XSPT::TransformPathAbsoluteToRelative('//1/3/5','//1/3/5/6'));
ok('../../' eq 
  NVIDIA::XSPT::TransformPathAbsoluteToRelative('//1/3/5','//1'));

chdir($START_DIR);

