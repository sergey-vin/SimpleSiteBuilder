#!/usr/bin/perl

package SRGB::Args;

use Data::Dumper;
use File::Path;
use File::Basename;
use File::Temp;

$VERSION = '0.1';
require Exporter;
@ISA=('Exporter');

@EXPORT = qw( );
%EXPORT_TAGS = (
                 all => [ qw(
                              &get_arg
                              &get_arg_optional
                              &grab_ids_from_pipe
                              $g_die_with_msg_in_usage
                            )],
               );

@EXPORT_OK = 
(
  @{$EXPORT_TAGS{'all'}},
);

use strict;

#--------------------------------------
# global

my $g_die_with_msg_in_usage = 1;


#--------------------------------------
# funcs


sub _int_arg_usage
{
  if (@_)
  {
    my $msg = <<USAGE;
 !!!
    Arguments should contain one of parameters: @_
    You specified: @ARGV
 !!!
USAGE
    if ($g_die_with_msg_in_usage)
    {
      die($msg);
    }
    else
    {
      print STDERR $msg;
      die;
    }
  }
  else
  {
    die "not enough parameters";
  }
}


## _int_arg_usage:
# $ids = grab_ids_from_pipe(<>)
# $ids = grab_ids_from_pipe(<STDIN>)
# $ids = grab_ids_from_pipe(@ARGV)
sub grab_ids_from_pipe(@)
{
  my @ids = grep { /^\d+$/ } map { split /[\s,;]+/ } @_;
  return [@ids];
}

sub get_arg
{
  for my $arg (@ARGV)
  {
    for my $RE (@_)
    {
      next unless  ($arg =~ /$RE/i);
      @ARGV = grep { $_ ne $arg } @ARGV;
      return $arg;
    }
  }
  _int_arg_usage(@_);
}

sub get_arg_optional
{
  for my $arg (@ARGV)
  {
    for my $RE (@_)
    {
      next unless  ($arg =~ /$RE/i);
      @ARGV = grep { $_ ne $arg } @ARGV;
      return $arg;
    }
  }
  return undef;
}



#--------------------------------------
# tests

sub _Test()
{
  use Test;
  eval { plan tests => 68; };
  local @ARGV = @ARGV;

  {
    @ARGV = ("aaaaa","b");
    my $res_a = get_arg("aaa");
    ok $res_a, "aaaaa";
    ok scalar @ARGV, 1;
    ok $ARGV[0], "b";
  }

  {
    @ARGV = ("aaaaa","b");
    $g_die_with_msg_in_usage = 1;
    my $res = eval {get_arg("bbb");};
    ok $@ =~ /!!!/;
    ok $@ =~ /bbb/;

    my $res_b = get_arg_optional("bbb");
    ok $res_b, undef;
    ok scalar @ARGV, 2;
    ok $ARGV[0], "aaaaa";

    my $res_a = get_arg_optional("aaa");
    ok $res_a, "aaaaa";
    ok scalar @ARGV, 1;
    ok $ARGV[0], "b";
  }

  {
    my $ints;
    ok $ints = grab_ids_from_pipe(1,2,"3,5  10");
    ok $ints->[0], 1;
    ok $ints->[1], 2;
    ok $ints->[2], 3;
    ok $ints->[3], 5;
    ok $ints->[4], 10;
    ok scalar @$ints, 5;

    ok $ints = grab_ids_from_pipe(1,2,"323d","22");
    ok $ints->[0], 1;
    ok $ints->[1], 2;
    ok $ints->[2], 22;
    ok scalar @$ints, 3;
  }

}

BEGIN { _Test(); }
# _Test();

1;
