package SRGB::XSPT::PatternConfigure;
our $Pattern = << '#XSPTPatternEND';
#!/usr/bin/perl -w
<?XSPT
  XSproject
  XSp4path
  XSbuildPath
?>

################################################################################
# Documentation. Please read before modifying. 
################################################################################
# 
# This script should produce Config.xml file, that then will be taken by
# build.pl for project configuration.
#
# Please go through and fill in missing parts, taking comments as guidance.
################################################################################
use strict;

use FindBin qw($Bin);
use Getopt::Long;

use File::Copy;
use File::Path;

use lib "$Bin";
use lib "$Bin/lib";
use lib "$Bin/../lib";
use lib "$Bin/../../lib";

use SRGB::Config qw(GetConfiguration);
use SRGB::Log qw(LogV);
use SRGB::Log::StderrLogger;
use SRGB::Log::FileLogger;

use SRGB::TempFile qw(GetNewTempFile);

################################################################################
## Globals
################################################################################

my $HelpFlag;
my $ResetFlag;

my %UserSettings;
my $Config;

my $ConfigPath = "$Bin";
my $ConfigFileName = 'Config.xml';

################################################################################
## Parse Options
################################################################################

my $Ret = GetOptions(
                      # Internal
                      "help"          => \$HelpFlag,
                      "reset"         => \$ResetFlag,

                      # Start specifying your options here
                      
                      "target-path=s" => \$UserSettings{TARGET_PATH},

<?perl 
  my $XStmp; 
  my $XStab = '                      ';
  for (@{$XSproject})
  {
    $XStmp.= $XStab . '"' . $_->{name} . '-path=s" => ' . " #auto\n";
    $XStmp.= $XStab . '  \$UserSettings{' . $_->{var} . "},\n";
  }
  $XStmp;
?>
                    );

if ($HelpFlag || !$Ret)
{
  Usage();
}

################################################################################
## Init
################################################################################

$UserSettings{TARGET_PATH} = $ENV{AQUA_TARGET_PATH}
  unless ($UserSettings{TARGET_PATH});

<?perl 
  my $XStmp; 
  for (@{$XSproject})
  {
    $XStmp.= '$UserSettings{' . $_->{var} . "} = ";
    $XStmp.= '$ENV{\'AQUA_DEP_PATH_' . $_->{name} . "'}\n";
    $XStmp.= '  unless $UserSettings{' . $_->{var} . "}; #auto\n";
  }
  $XStmp;
?>
 
$Config = GetConfiguration(
                           # General options - don't touch!!!
                            'PLBUILD', 
                             LOG_THRESHOLD => 5,

                           # Add variables here, i.e.
                           # WITH_GUI      => 0, 
                           # FOO_LIB_PATH  => 'c:/foo', 
                           # ...
                             TARGET_PATH => "$Bin/<?perl $XSbuildPath ?>",

<?perl 
  my $XStmp;
  my $XStab = '                             ';
  for (@{$XSproject})
  {
    $XStmp.= $XStab . $_->{var} . ' => ' . " #auto\n";
    $XStmp.= $XStab . '  "$Bin/' . 
      SRGB::XSPT::TransformPathAbsoluteToRelative($XSp4path, $_->{p4path}) .
      "/build\",\n";
  }
  $XStmp;
?>
                          );

my $LogFile = GetNewTempFile();

SRGB::Log::AddLogger(new NVIDIA::Log::StderrLogger());
SRGB::Log::AddLogger(new NVIDIA::Log::FileLogger($LogFile));
SRGB::Log::SetCurrentModule('PLBUILD');
SRGB::Log::SetLogLevelThreshold($Config->{LOG_THRESHOLD});

foreach (sort (keys (%$Config ) ))
{
   LogV 9, "$_ -> $Config->{$_}";
}

$ENV{NVM_CONFIG_PATH} = "$ConfigPath/$ConfigFileName" unless ($ResetFlag);

################################################################################
## Main
################################################################################

for my $ParamName (keys %UserSettings)
{
  if ($UserSettings{$ParamName})
  {
    $Config->{$ParamName} = $UserSettings{$ParamName};
    LogV 5, "Setting $ParamName to '$UserSettings{$ParamName}'";
  }
}

open FILE, ">$ConfigPath/$ConfigFileName";
print FILE GetConfigText($Config, \%UserSettings);
close FILE;

mkpath($Config->{TARGET_PATH}) unless (-d  $Config->{TARGET_PATH});
SRGB::Log::ClearLoggers();
RelocateLog($LogFile, "$Config->{TARGET_PATH}/configure.log");

################################################################################
## Functions
################################################################################

sub RelocateLog
{
  my $LogFile = shift;
  my $TargetLog = shift;

  unlink($TargetLog) if ($TargetLog);
  move($LogFile, $TargetLog);
}

sub GetConfigText
{
  my $Config = shift;
  my $UserSettings = shift;

  my $ConfigXML = "<GTLCONFIG>\n" . 
                  " <INCLUDE>$Bin/Version.xml</INCLUDE>\n";

  foreach my $ConfigKey (keys %$UserSettings)
  {
    my $ConfigValue = $Config->{$ConfigKey};
    LogV 6, "Out $ConfigKey = $ConfigValue";

    $ConfigXML .= " <$ConfigKey>$ConfigValue</$ConfigKey>\n";
  }

  return $ConfigXML . "</GTLCONFIG>";
}

sub Usage
{

#
# Put any additional command-line options summary in this help output. 
#
  print << "ENDTEXT";
Usage:
  $0 [Options]

Options:
    -target-path <Path>     : path to build directory
    -reset                  : will reset config to defaults
    -help                   : this help

ENDTEXT
}
#XSPTPatternEND
