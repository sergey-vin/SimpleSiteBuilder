#!/usr/bin/perl

package SRGB::HTMLMenu;

use FindBin qw($Bin);
# use lib  "$Bin/lib";
use Data::Dumper;
use File::Path;
use File::Basename;
use File::Temp;
use File::Copy;

$VERSION = '0.2';
require Exporter;
@ISA=('Exporter');
@EXPORT    = qw(
  &MenuGetHeader
  &MenuGetFooter
  &MenuOpenElement
  &MenuCloseElement
  &MenuTable
  &ReadFile 
  &WriteFile
  &CopyFile
  &HTMLStub
  &HTMLIFrame
);

use strict;


#----------------------------------------------------------
# globals


#----------------------------------------------------------
# funcs

sub ReadFile($;$)
{
  my $fn = shift;
  my $as_array = shift;

  open F, $fn or die ("Error!!! can't open file for reading [$fn]");
  my $str;
  if ($as_array)
  {
    $str = [<F>];
  }
  else
  {
    $str .= $_ for <F>;
  }
  close F;

  return $str;
}

sub WriteFile($$)
{
  my $fn = shift;

  open F, ">$fn" or die ("Error!!! can't write to file [$fn]");
  print F $_ for @_;
  close F;
}

sub CopyFile($$)
{
  my ($from,$to) = @_;

#   symlink($from, $to) 
#     or die "can't symlink: [$from] -> [$to]: $!";

  link($from, $to) or copy($from, $to)
    or die "can't copy: [$from]->[$to]: $!";

  return 1;
}

sub MenuTable($;$)
{
  my $table = $_[0];
  my $node = $_[1];

  my $add = "<!-- SRGB -->";
  sub TabHdr(;$)
  {
    $add . '<table width="100%" hight="100%"><tbody>' . "\n";
  }
  sub TabFoot(;$)
  {
    $add . "</tbody></table>\n";
  }
  sub TabRowHdr($;$)
  {
    my $pos_y = shift;
    $add . "  <tr valign='top'>\n";
  }
  sub TabRowFoot($;$)
  {
    my $pos_y = shift;
    $add . "  </tr>\n";
  }
  sub TabData($$;$$)
  {
    my $pos_x = shift;
    my $pos_y = shift;
    my $data = shift;
    my $node = shift;

    my $src = HTMLIFrame($node, $data);

# #     my $path = $node->{f_to};
# #     my $path = $node->{r_to};
#     my $path = $node->{r_name};
# #     my $path = $node->{name};
# #     my $path = '#';
# 
#     ## @note if iframe's not supported - you'll see $data
#     my $src = $node->{r_to} # if it's a file
#       ? "<iframe width='100%' height='100%' frameborder='0' src='$path' name='view'/>"
# #       ? "<iframe width='100%' height='100%' frameborder='0' src='$path' name='view'>$data</iframe>"
#       : $data;

    my $res = $pos_x == 0
      ? "    <td width='30%' height='100%'>$data</td>"
      : "    <td width='70%' height='100%'>$src</td>";

    $add . $res . $add . "\n";
  }

  my $res;
  my ($x,$y) = (0) x 2;

  $res .= TabHdr();
  for my $r (@{$table})
  {
    $res .= TabRowHdr($y);
    for my $d (@$r)
    {
      $res .= TabData($x,$y,$d,$node);
      $x++;
    }
    $res .= TabRowFoot($y);
    $y++;
  }
  $res .= TabFoot();

#   print Dumper $res;exit;
  $res;
}


sub MenuOpenElement(@)
{
  my ($Type, $Text, $Link, $Level, $IsOpen, $IsCurrent, $IsRoot, $node) = @_;

  my $pref = '  ' x ($Level - 1);
  my $pref_more = '  ' x ($Level);

  while ($Text =~ s/\.*html?$//ig) {}

  my $pref_cur = $IsCurrent
    ? ' id="srgb_selected_root_dir"'
    : '';
  my $title = $Link
    ? "<a href='$Link'>$Text</a>"
    : $Text;
  $title = $IsCurrent
    ? "<b>[$Text]</b>" # no link for current!
    : $title;
#   ## test
#   $title = $IsOpen
#     ? "<u>+++$Text+++</u>"
#     : "<i>---$title---</i>";
  my $open = $IsOpen
    ? ' rel="open"' #id="srgb_selected_root_dir"'
    : '';

  return $pref . ( $Type eq 'file'
#     ? "<li$open>$title</li>" # no open for files
    ? "<li$pref_cur>$title</li>"
    : $IsRoot
      ? "<ul id=\"$node->{menu_id}\" class=\"treeview\"$open>"
      : "<li>$title\n$pref_more<ul$open>"
    ) . "\n";
#   ' ' x (5*$Level) . "$Text\n";
}

sub MenuCloseElement(@)
{
  my ($Type, $Text, $Link, $Level, $IsOpen, $IsCurrent, $IsRoot, $node) = @_;

  my $pref = '  ' x $Level;
  my $pref_less = '  ' x ($Level - 1);

  $Type eq 'file'
    ? ''
    : $IsRoot
      ? <<E
</ul>


<script type="text/javascript">
  ddtreemenu.createTree("$node->{menu_id}", false)
</script>
E
      : <<E
$pref</ul>
$pref_less</li>
E
}

sub HTMLStub
{
  return <<E;
<html>
  <head>
    <meta name="author" content="Sergey Vinogradov"></meta>
  </head>
  <body>
    @_
  </body>
</html>
E
}

sub HTMLIFrame($;$)
{
  my $node = shift or die;
  my $data = shift;

#   my $path = $node->{f_to};
#   my $path = $node->{r_to};
  my $path = $node->{r_name};
#   my $path = $node->{name};
#   my $path = '#';

  ## @note if iframe's not supported - you'll see $data
  my $src = $node->{r_to} # if it's a file
    ? "<iframe width='100%' height='100%' frameborder='0' src='$path' name='view'>".
      "</iframe>"
#     ? "<iframe width='100%' height='100%' frameborder='0' src='$path' name='view'>$data</iframe>"
    : $data;
  $src;
}

#----------------------------------------------------------
# tests

sub _Test()
{
  use Test;
  eval { plan tests => 33; };
  
  {
#     ok $str;
  }
}

_Test();

1;
