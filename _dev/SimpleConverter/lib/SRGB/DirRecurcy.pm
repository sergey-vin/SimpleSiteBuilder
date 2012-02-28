#!/usr/bin/perl

package SRGB::DirRecurcy;

use Data::Dumper;
use File::Path;
use File::Basename;
use File::Temp;

$VERSION = '0.2';
require Exporter;
@ISA=('Exporter');
@EXPORT    = qw(
  &DirUpdate
  &DirEscape
  &DirWalk_CheckArgs
  &DirWalk
  &FileRemoveFromTree
  &IsRoot
  &HasChildren
);

use strict;

sub DirEscape($)
{
  my $d_name = shift;
  $d_name =~ s/\s/\\ /g;
  return $d_name;
}

## 'll' -> 'll/'; '' -> './'
sub DirUpdate($)
{
  my $p_d_name = shift;

  ($$p_d_name) = map 
  { 
    /\/$/ 
      ? $_ 
      : $_
        ? "$_/"
        : "./"
  } ($$p_d_name);
}

## undef if not enough
sub DirWalk_CheckArgs($;$)
{
  my $a = shift;
  my $check_dir_ex = shift;

  for my $key qw( d_from d_to s_file s_dir )
  {
    return undef
      if not exists $a->{$key}
  }

  for my $key_sub qw( s_file s_dir )
  {
    return undef
      if ref $a->{$key_sub} ne 'CODE';
  }

  return undef # can't copy from ./ to ./ :)
    unless $a->{d_from} or $a->{d_to};

  for my $key qw( d_from d_to )
  {
    DirUpdate(\$a->{$key});
  }

  if ($check_dir_ex && ! -d $a->{d_from})
  {
    die "Error!!! Either Source dir [$a->{d_from}] is a file (error) ".
      "or not exist (check params)\n";
  }

  return 1;
}

## @return [-1, 0, 1] - the same as 'cmp'
## but if you have 'a 1', 'a 2', 'a 11', then order would be correct!
sub SortCmpFlexyNumbers($$)
{
  my ($A,$B) = @_;
#   print Dumper [$A,$B];
  for ($A,$B)
  {
    s/(\d+)/sprintf("\%010d",$1)/ge;
  }
#   print Dumper [$A,$B];
  $A cmp $B;
}

sub SortWithWeights($@)
{
  my $args = shift;

  my $original_names;
  my $weights;

  my @inp = map 
  {
    my $orig = $_;

    my $w = 0;
    my ($name,$path,$suffix) = fileparse($orig);
    $name =~ s/^_(-?\d+(?:\.\d+)?)_\s*// # floats
#     $name =~ s/^_(-?\d+)_\s*// # ints
      and $w = $1;
    $name =~ s/\s+/_/g if $args->{opt_convert_names};

    $path = '' if $path eq './';
    $name = $path . $name;
    $weights->{$name} = 0.0 + $w; #int($w); ## @note to deal w/ floats too
    $original_names->{$name} = $orig;
    $name;
  } @_;
#   print Dumper ['--test SortWithWeights--', [@inp], $weights, $original_names];

  my @res = sort
    {
      my $res = $weights->{$a} <=> $weights->{$b};
      $res = SortCmpFlexyNumbers($a,$b) if $res == 0;
      $res;
    } @inp;
  ($original_names, @res);
}

sub DirPrn($)
{
  my $node = shift;
  print Dumper $node;
}


sub DirWalk($)
{
  ## append '/' to dirs if not present
  my $arg = $_[0];
  DirWalk_CheckArgs($arg);

  $arg->{type} = 'dir';
  $arg->{name} = basename($arg->{d_to}) unless $arg->{name};
  $arg->{f_to} = $arg->{d_to}; # full name
  $arg->{f_from} = $arg->{d_from}; # full name
  &{$arg->{s_dir}}($arg);

  ## get all files within src dir
  my $DirFrom2Search = DirEscape $arg->{d_from};
  my @Files = grep {$_ !~ /_skip_/i} (<${DirFrom2Search}*>);

  ## run callback for files,
  ## go deeper for dirs
  my ($NamesMap, @SortedFiles) = SortWithWeights $arg, @Files;
  for my $File (@SortedFiles)
  {
    my $orig_name = $NamesMap->{$File};
    my $dest_name = basename($File);

    my $show_name = $dest_name;
    $show_name =~ s/_+/ /g if $arg->{opt_convert_names};

    my %arg_new = %$arg;
    $arg_new{name_to} = $dest_name; # path name
    $arg_new{name} = $show_name;    # show name

    $arg_new{parent} = $arg;
    $arg_new{level} ++;
    delete $arg_new{children};
    push @{$arg->{children}}, \%arg_new;

    if (-d $orig_name)
    {
#       $arg_new{d_from} .= $arg_new{name}; #not sorted
      $arg_new{d_from} .= basename($orig_name); #sorted
      $arg_new{d_to} .= $dest_name;
      DirWalk(\%arg_new);
    }
    elsif (-f $orig_name)
    {
      $arg_new{type} = 'file';
      $arg_new{f_from} = $orig_name; # full name #sorted
      $arg_new{f_to} = $arg->{d_to} . $dest_name; # full name
      &{$arg->{s_file}}(\%arg_new);
    }
  } ## for (@Files)
}

sub IsRoot($)
{
  my $node = shift;
  
  return ! exists $node->{parent}
    || ! $node->{parent}  
}

sub HasChildren($;$$)
{
  my $node = shift or die;
  my $empty_dirs_are_not_children = shift;
  my $file_sub = shift;
  
  if (exists $node->{has_children})
  {
    return $node->{has_children};
  }

  my $res = 0;
  if (exists $node->{children}
    && $node->{children}  
    && @{$node->{children}})
  {
    for my $chld (@{$node->{children}})
    {
      if ($chld->{type} eq 'dir') #root => show all?
      {
        $res = $empty_dirs_are_not_children
          ? HasChildren(
            $chld, $empty_dirs_are_not_children, $file_sub)
          : 1; ## by default if sub-dir is present, then we have children
      }
      elsif (defined $file_sub)
      {
        $res = &$file_sub($chld); ## let user-function decide
      }
      else
      {
        $res = 1; ## by default all files count
      }
      last if 0 != $res;
    }
  }
  $node->{has_children} = $res;
  return $node->{has_children};
}


sub FileRemoveFromTree($)
{
  my $file = shift;
  my $root = $$file->{parent}
    ? $$file->{parent}
    : undef;
#   print Dumper ["deleting: ", $$file, 'from: ',$root];
  if ($root)
  {
    $root->{children} = 
    [
      grep
      {
        $_ != $$file;
      } @{$root->{children}}
    ];

    while (exists $root->{has_children})
    {
      delete $root->{has_children};
      $root = $root->{parent};
    }
  }
#   print Dumper ["deleting: ", $$file, 'from: ',$root];

  my $i;
  for (keys %{$$file})
  {
    delete $$file->{$_};
    $i++;
  }
  $$file = undef;

  return $i;
}


sub _Test()
{
  use Test;
  eval { plan tests => 68; };

  { #DirEscape
    my $a = "a b";
    ok "a\\ b", DirEscape $a;
  } #DirEscape

  { ## SortWithWeights
    # default value is 0 if not specified
    my @inp = ('_01_ asd', '_2_ sdfg', 'iii', '_-1_ 234', '_0.9_eee0', '_1.1_eee1');
    my ($names_map, @res) = SortWithWeights({opt_convert_names=>1}, @inp);
    ok join(',', @res), join(',',('234', 'iii', 'eee0', 'asd', 'eee1', 'sdfg'));
    ok $names_map->{'234'}, $inp[3];
    ok $names_map->{'asd'}, $inp[0];
    ok $names_map->{'sdfg'}, $inp[1];
    ok $names_map->{'iii'}, $inp[2];

    ok SortCmpFlexyNumbers(2,2), 0;
    ok SortCmpFlexyNumbers(1,2), -1;
    ok SortCmpFlexyNumbers(2,1), 1;
    ok SortCmpFlexyNumbers(11,2), 1;
    ok SortCmpFlexyNumbers("22","22"), 0;
    ok SortCmpFlexyNumbers("22","11"), 1;
    ok SortCmpFlexyNumbers("2","11"), -1;
    ok SortCmpFlexyNumbers("module 2","module 11"), -1;

    @inp = ('m 11', 'm 2', 'm 1');
    ($names_map, @res) = SortWithWeights({}, @inp);
    ok join(',', @res), join(',',('m 1', 'm 2', 'm 11'));

    @inp = ('m 11', 'm 2', 'm 1');
    ($names_map, @res) = SortWithWeights({opt_convert_names=>0}, @inp);
    ok join(',', @res), join(',',('m 1', 'm 2', 'm 11'));

    @inp = ('m 11', 'm 2', 'm 1');
    ($names_map, @res) = SortWithWeights({opt_convert_names=>1}, @inp);
    ok join(',', @res), join(',',('m_1', 'm_2', 'm_11'));

    @inp = ('_1_ m 3', 'm 11', '_-1_ m 16', 'm_2', 'm 1');
    ($names_map, @res) = SortWithWeights({opt_convert_names=>1}, @inp);
    ok join(',', @res), join(',',('m_16', 'm_1', 'm_2', 'm_11', 'm_3'));
  } ## SortWithWeights


  { #DirUpdate
    my $a = 'wer';
    DirUpdate(\$a);
    ok($a, 'wer/');
    DirUpdate(\$a);
    ok($a, 'wer/');
    $a = '';
    DirUpdate(\$a);
    ok($a, './');
  }

  { #DirWalk_CheckArgs
    sub xxx() {}

    ok DirWalk_CheckArgs(
      {
        d_from => "src",
        d_to   => "dest",
        s_file => \&xxx,
        s_dir  => \&xxx,
      });

    ok undef, DirWalk_CheckArgs(
      {
        d_to   => "dest",
        s_file => \&xxx,
        s_dir  => \&xxx,
      });
    
    ok undef, DirWalk_CheckArgs(
      {
        d_from => "src",
        d_to   => "dest",
        s_file => 'func',
        s_dir  => \&xxx,
      });
      
    ok undef, DirWalk_CheckArgs(
      {
        d_from => "",
        d_to   => "",
        s_file => \&xxx,
        s_dir  => \&xxx,
      });
  
    my $a =
      {
        d_from => "",
        d_to   => "eeeee",
        s_file => \&xxx,
        s_dir  => \&xxx,
      };
    ok DirWalk_CheckArgs($a);
    ok $a->{d_from}, './';

    $a =
      {
        d_from => "sadfsdf",
        d_to   => "",
        s_file => \&xxx,
        s_dir  => \&xxx,
      };
    ok DirWalk_CheckArgs($a);
    ok $a->{d_to}, './';

    eval
    {
      DirWalk_CheckArgs(
        {
          d_from => "non-existant-dir" . rand() . "----" . rand(),
          d_to   => "dest",
          s_file => \&xxx,
          s_dir  => \&xxx,
        },1)
    };
    ok $@ =~ /^error/i;

    eval
    {
      DirWalk_CheckArgs(
        {
          d_from => "non-existant-dir" . rand() . "----" . rand(),
          d_to   => "dest",
          s_file => \&xxx,
          s_dir  => \&xxx,
        })
    };
    ok $@, '';

    $a = {
        d_from => "src",
        d_to   => "dest",
        s_file => \&xxx,
        s_dir  => \&xxx,
      };
    ok DirWalk_CheckArgs($a);
    ok $a->{d_from}, "src/";
    ok $a->{d_to}, "dest/";

  }

  { #DirWalk
    sub yyy
    {
      ok $_[0]->{d_to}, 'dest/';
      ok $_[0]->{type}, 'dir';
    }
    my $dir = File::Temp::tempdir( CLEANUP => 1 );
    my $root = 
      {
        d_from => $dir,
        d_to   => "dest",
        s_file => \&yyy,
        s_dir  => \&yyy,
      };
    DirWalk($root);

    sub yyy_d
    {
      ok $_[0]->{d_to}, 'dest/';
      ok $_[0]->{type}, 'dir';
#       print 'dir: ', Dumper @_;
    }
    sub yyy_f
    {
      ok $_[0]->{d_to}, 'dest/';
      ok $_[0]->{type}, 'file';
      ok $_[0]->{name}, 'fff';
      ok $_[0]->{parent}->{type}, 'dir';
      ok scalar @{$_[0]->{parent}->{children}}, 1;
      ok \%{$_[0]->{parent}->{children}->[0]}, $_[0];
#       print 'file: ', Dumper @_;
    }
    open F, ">$dir/fff" or die ("Error!!! dir [$dir] not writeable");
    print F "test";
    close F;
    $root = 
      {
        d_from => $dir,
        d_to   => "dest",
        s_file => \&yyy_f,
        s_dir  => \&yyy_d,
      };
    DirWalk($root);


    mkpath("$dir/22");
    mkpath("$dir/33");
    open F, ">$dir/22/fff_2" or die ("Error!!! dir [$dir] not writeable");
    print F "test";
    close F;

#     print `tree $dir`, "\n\n\n";
# |-- 22
# |   `-- fff_2
# |-- 33
# `-- fff
# 2 directories, 2 files

    $root = 
      {
        d_from => $dir,
        d_to   => "dest",
        s_file => \&xxx,
        s_dir  => \&xxx,
        opt_convert_names => 1,
      };
    DirWalk($root);
#     DirPrn($root);

    ok '', exists $root->{parent};
    ok IsRoot($root);
    ok ! IsRoot($root->{children}->[0]);
    ok $root->{d_from}, "$dir/";
    ok $root->{d_to}, 'dest/';
    ok 3, scalar @{$root->{children}};

    my @chld_22;
    ok 1, scalar (@chld_22 = grep 
      { 
        my $mod_name = $root->{opt_convert_names}
          ? 'fff 2' : 'fff_2';
        $_->{d_from} eq "$dir/22/" 
          && $_->{d_to} eq "dest/22/"
          && $_->{name} eq '22'
          && $_->{type} eq "dir"
          && exists $_->{children}
          && 1 == scalar @{$_->{children}}
          && $_->{children}->[0]->{f_from} =~ /fff_2$/ # 'fff_2' non modif
          && $_->{children}->[0]->{name} eq $mod_name # 'fff_2' || 'fff 2'
          && $_->{children}->[0]->{level} == 2
          && $_->{level} == 1
      } @{$root->{children}});

    my @chld_33;
    ok 1, scalar (@chld_33 = grep 
      { 
       $_->{d_from} eq "$dir/33/" 
          && $_->{d_to} eq "dest/33/"
          && $_->{name} eq '33'
          && $_->{type} eq "dir"
          && ! exists $_->{children}
          && $_->{level} == 1
      } @{$root->{children}});

    my @chld_fff;
    ok 1, scalar (@chld_fff = grep 
      { 
       $_->{d_from} eq "$dir/" 
          && $_->{d_to} eq "dest/"
          && $_->{name} eq 'fff'
          && $_->{type} eq "file"
          && ! exists $_->{children}
          && $_->{level} == 1
      } @{$root->{children}});

    ok HasChildren($root);

    ## now - delete them!
    ok FileRemoveFromTree(\$chld_fff[0]) >= 4; # 4 - number of min required fields
    ok undef, $chld_fff[0];
    ok 0, scalar (@chld_fff = grep 
      { 
       $_->{d_from} eq "$dir/" 
          && $_->{d_to} eq "dest/"
          && $_->{name} eq 'fff'
          && $_->{type} eq "file"
          && ! exists $_->{children}
          && $_->{level} == 1
      } @{$root->{children}});

    ok HasChildren($root);
    ok FileRemoveFromTree(\$chld_22[0]) >= 4;
    ok undef, $chld_22[0];
    ok 0, scalar (@chld_22 = grep 
      { 
       $_->{d_from} eq "$dir/22/" 
          && $_->{d_to} eq "dest/22/"
          && $_->{name} eq '22'
          && $_->{type} eq "dir"
          && exists $_->{children}
          && 1 == scalar @{$_->{children}}
          && $_->{children}->[0]->{name} eq 'fff_2'
          && $_->{children}->[0]->{level} == 2
          && $_->{level} == 1
      } @{$root->{children}});

    ok HasChildren($root);
    delete $root->{has_children};
    ok ! HasChildren($root, 1); # if we count files only, then
    delete $root->{has_children};
    ok HasChildren($root);

    ok FileRemoveFromTree(\$chld_33[0]) >= 4;
    ok undef, $chld_33[0];
    ok 0, scalar (@chld_33 = grep 
      { 
       $_->{d_from} eq "$dir/33/" 
          && $_->{d_to} eq "dest/33/"
          && $_->{name} eq '33'
          && $_->{type} eq "dir"
          && ! exists $_->{children}
          && $_->{level} == 1
      } @{$root->{children}});
  
    ok ! HasChildren($root);
    ok FileRemoveFromTree(\$root) >= 4;
    ok $root, undef;
#     print Dumper $root;
  } ## DirWalk,FileRemoveFromTree

}

BEGIN { _Test() if $^O =~ /linux/i }
# BEGIN { _Test() }
# _Test();

1;
