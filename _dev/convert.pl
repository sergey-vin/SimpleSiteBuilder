#!/usr/bin/perl

use Data::Dumper;
use File::Path;
use Cwd;
use strict;

use FindBin qw($Bin);
use lib  "$Bin/lib";

use SRGB::DirRecurcy;
use SRGB::HTMLMenu;
use SRGB::Args qw(:all);
use SRGB::XSPT;
use SRGB::XSPT::PatternSite01;
use SRGB::XSPT::PatternSite02;
use SRGB::XSPT::PatternSite03;
use SRGB::XSPT::PatternSiteVideo01;

my $gMainDir = "$Bin/../../data/";
my $gPattern = $SRGB::XSPT::PatternSite02::Pattern;
my $gPatternVideo = $SRGB::XSPT::PatternSiteVideo01::Pattern;

if (get_arg_optional("--help","/h","-h"))
{
  print <<USAGE;
  usage: perl $0 [--p-names|+pn] [--p-head|+ph] [--np-wrong|-pw] [--sil]
    +pn     prints all file names thru which program walked
    +ph     prints all header notifications (changes to green wide banner)
    -pw     omits printing of wrong files (correct are media files and .html-s)
    --sil   silent mode = -pn, -ph, -pw
  
  you passed arguments: @ARGV
USAGE
  exit;
}
my $gPrintNames = get_arg_optional("--p-names?","\\+pn");
my $gPrintHeaders = get_arg_optional("--p-head","\\+ph");
my $gNotPrintWrong = get_arg_optional("--np-wrong","-pw");
if (get_arg_optional("--sil"))
{ 
  $gPrintNames = $gPrintHeaders = 0;
  $gNotPrintWrong = 1;
}

my $gTestStartFirefox = 0;
my $gPrefixRealFile = "data_file_";

## copy only
sub IsImage($)
{
  my $file_name = shift;
  $file_name =~ /\.(jpg|jpeg|gif|png|bmp|css|js|swf)$/i
}

## copy + modify 
sub IsData($)
{
  my $file_node = shift;
  my $res = undef;
  if (!$res)
  {
    $res = 1 if $file_node->{name} =~ /\.(html|htm)$/i;
  }

  if (!$res)
  {
    $res = 2 if $file_node->{special_video};
  }

  if (!$res && $file_node->{name} =~ /\.(flv)$/i)
  {
    $file_node->{special_video} = $file_node->{name_to};
    $file_node->{name} =~ s/\.(flv)$/.html/i;
    $file_node->{name_to} =~ s/\.(flv)$/.html/i;
    $file_node->{f_to} =~ s/\.(flv)$/.html/i;
    $res = 2;
  }
  if ($file_node->{name} =~ /index\.htm/i
    && exists $file_node->{info} 
    && exists $file_node->{info}->{index_name} )
  {
    $file_node->{special_index} = $file_node->{name};
    $file_node->{name} = $file_node->{info}->{index_name}  . '.html';
  }
  
  if ($res)
  {
    SetRNames($file_node);
  }

  return $res;
}

sub GetInfoFile($)
{
  my $dir_name = shift;
  my $file_name = "${dir_name}head.txt";
  my ($res, $file);
  if (-s $file_name)
  {
    print "Info reading new header file [$file_name]\n" if $gPrintHeaders;
    $file = ReadFile($file_name, 1); # see also ConvertDir
  }
  if ($file)
  {
    my $cur_var;
    my $cur_val;
    for (@$file, '#') # last item in list - to sync data and finish properly
    {
      if (/^[#\$]/)
      {
        ## save old data to res hash
        if ($cur_var)
        {
          chomp ($cur_val);
          $res->{$cur_var} = $cur_val;
        }

        ## obtain or clear new data
        ($cur_var, $cur_val) = /^\$([^\s]+)\s+(.*)/s;
        $cur_val = '' unless $cur_var;
      }
      else
      {
        ## concat value to old data
        $cur_val .= $_;
      }
    }
  }
  return $res;
}

## only for dir-content analyzing
sub ConvertFile($)
{
  my $file = shift;
  print "file $file->{name}\n" if $gPrintNames;

  unless (IsData($file) or IsImage($file->{name}))
  {
    print "Warn!!! Found not valid file [$file->{name}], skipping\n" 
      unless $gNotPrintWrong;
    FileRemoveFromTree(\$file);
    return;
  }
}

## only to create dest dirs
sub ConvertDir($)
{
  my $dir = shift;
  print "dir $dir->{name} / $dir->{f_to}\n" if $gPrintNames;

  mkpath($dir->{f_to}) unless -d $dir->{f_to};
  

  # populating info from parent to child
  if (exists $dir->{parent} && exists $dir->{parent}->{info})
  {
    print "Warn!!! Cloning to [$dir->{name}] a header info\n" if $gPrintHeaders;
    $dir->{info} = $dir->{parent}->{info}; #link to same hash
  }

  # if own info found, replacing
  my $new_info = GetInfoFile($dir->{d_from});
  if ($new_info)
  {
    print "Warn!!! Adding to [$dir->{name}] a header file\n" if $gPrintHeaders;
    if (exists $dir->{info}) #make new hash, for not to modify parent's hash
    {
      $dir->{info} = {%{$dir->{info}},%$new_info};
    }
    else
    {
      $dir->{info} = $new_info;
    }
    return;
  }
}



sub IsMenuLeafRoute($$)
{
  my ($root, $node) = @_;
#   print Dumper {
#     len => length($root->{f_to}),
#     s1 => substr($node->{f_to},0,length($root->{f_to})),
#     s2 => $root->{f_to},
#   };
  substr($node->{f_to},0,length($root->{f_to})) eq $root->{f_to};
}


## having tree & node in it - constract menu
sub CreateMenu($$$;$)
{
  my ($root, $node, $str, $open_all) = @_;

#   MenuGetHeader($str) unless ($root->{level});

  ## open all leaves en route to $node
  my $IsOpen = $open_all 
    || IsMenuLeafRoute($root, $node) 
    || $root->{level} < 1; #@todo delete - that's too big tree for index file, correct IsMenuLeafRoute too
  my $IsCurr = $IsOpen ? $root == $node : 0;
  my $IsMenu = $root->{type} eq 'file' 
    && IsData($root)
    || $root->{type} eq 'dir'
    && HasChildren(
      $root, 
      1,#$node->{level} > 1, #@note if root - show all (even empty) folders.no need it
      sub { IsData($_[0]) });

#   print Dumper $root->{f_to};
#   print Dumper "IsMenu: $IsMenu";
#   print Dumper "IsOpen: $open_all / $IsOpen";
#   print Dumper $root if $root->{f_to} =~ /Картинки/;

#   # args:
#   ($Type, $Text, $Link, $Level, $IsOpen, $IsCurrent, $IsRoot, $node)
  my @args = (
    $root->{type}, # type
    $root->{name}, # text
    $root->{type} eq 'file' #link
      ? SRGB::XSPT::TransformPathAbsoluteToRelative(
          getcwd . "/$node->{d_to}",
          getcwd . "/" . $root->{f_to})
      : '', # per-dir index.htm?
    $root->{level}, # level
    $IsOpen, # is open
    $IsCurr, # is current
    IsRoot $root, # is root
    $root, # node (for what information? may be it's better to specify additional arg)
  );

  $$str .= MenuOpenElement(@args) if $IsMenu;

  for my $sub_root (@{$root->{children}})
  {
    CreateMenu($sub_root, $node, $str, $open_all);
  }

  $$str .= MenuCloseElement(@args) if $IsMenu;

#   MenuGetFooter($str) unless ($root->{level});
  $$str;
}

sub SetRNames($;$;$)
{
  my ($node, $name, $name_RE) = @_;
  $name = $node->{name_to} unless $name;
  $name =~ $name_RE if $name_RE;

  $node->{r_name} = $gPrefixRealFile . $name;
  $node->{r_to} = $node->{d_to} . $node->{r_name};
  return $node->{r_to};
}

sub InsertMenu($$$;$)
{
  my ($root, $node, $str, $open_all) = @_;

  my $menu;
  CreateMenu($root, $node, \$menu, $open_all);

  ## 2: taking menu and whole design from template, use iframes
  my $transfor_vars = 
    {
      XSStyleRoot => SRGB::XSPT::TransformPathAbsoluteToRelative(
        getcwd . "/$node->{d_to}",
        getcwd . "/$root->{d_to}/templates") . "/",
      XSMenu => $menu,
      XSData => HTMLIFrame($node),
      XSTemp => '',
      XSHeader => [ map 
          {
            my $key = "top_$_";
            exists $node->{info} && exists $node->{info}->{$key}
              ? $node->{info}->{$key}
              : ''
          } qw/left middle right/,
        ],
      XSHeaderInfo => exists $node->{info} && exists $node->{info}->{title}
        ? $node->{info}->{title}
        : '',
#       XSHeaderInfo => "234<br>asdfsadg",
    };
  $$str = TransformFromVarToVar(
    $transfor_vars,
    $gPattern);
  return $transfor_vars;
}

sub SanitizeHTML($;$)
{
  my $str = shift;
  my $node = shift;

  my $need_print = $node->{f_from} =~ /Ex._1.2.ht/;

  printf("Sanitize on %s!\n", $node->{f_from}) if $need_print;
# @todo delete DIGERATTI!!!
#   WriteFile('1', $$str);
  printf("San: init  len = %d\n", length($$str)) if $need_print;
  $$str =~ s/<div[^<>]+(Top|Bottom)NavBar.*?<\/div>//sg;
  printf("San: after RE1 = %d\n", length($$str)) if $need_print;
  $$str =~ s/<button[^<>]+Hint.*?button>//sg;
  printf("San: after RE2 = %d\n", length($$str)) if $need_print;
  $$str =~ s/<p id="Instructions">.*?<\/p>//sg;

#   WriteFile('2', $$str);
}

sub CreateFiles($$)
{
  my $root = shift;
  my $node = shift;

  if ( $node == $root # will be later overridden by index.html if found
    || $node->{name} =~ /index\.htm/i 
    && $node->{parent} == $root )
  {
    my $menu = HTMLStub("<h1>Welcome to index file!</h1>");
#     CreateMenu($root, $node, \$menu, 1); #differ if index.html already present
    InsertMenu($root, $root, \$menu, 0);
#     print "===Index===:\n$menu";
    my $fn = $root->{f_to} . "index.html"; 
    WriteFile($fn, $menu);
    # @todo insert faked 'index' into tree
  }
  
  if ($node->{type} eq 'file')
  {
    if (IsImage($node->{name}))
    {
      print "Only copying $node->{name}\n" if $gPrintNames;
      CopyFile($node->{f_from}, $node->{f_to});
    }
    elsif (IsData($node))
    {
      print "Modifying $node->{name}\n" if $gPrintNames;

      my ($menu, $menu_transform);

      ## @note splitting f_from to 2 file:
      ## r_to with real html (either from f_from, or auto-created video-stub)
      ## f_to with fake html (menu stub)

      ## create menu file, using these "r_xxx" & "f_xxx" fields
      $menu_transform = InsertMenu($root, $node, \$menu, 0); # 1/0 - open menu
      WriteFile($node->{f_to}, $menu);


      # video example:
      # /mnt/stuff/disk/Personal/Documents/OtherPeople/Katy/Katy/video_flv_english
      if ($node->{special_video})
      {
        # flv->html change for fake menu
#         SetRNames($node, '', 's/flv$/html/');

#         print Dumper {%$node, 'parent' => '', 'children' =>''};exit;
        ## copy video file src->dest
        CopyFile($node->{f_from}, $node->{d_to} . $node->{special_video});

        ## create html stub for video
        ### assumption 1: video - in '.', player - in 'templates' dir
#         my $video_path = $node->{d_to} . $node->{special_video};
#         my $video_path = $node->{special_video};

        ### assumption 2: player - in 'templates' dir, video - relatively to player
        my $video_path = 
          SRGB::XSPT::TransformPathAbsoluteToRelative(
            getcwd . "/$root->{d_to}/templates/xxx",
            getcwd . "/$node->{d_to}",
          ) . '/'. $node->{special_video};

        my $str = TransformFromVarToVar(
          {
            XSData=>$video_path,
            XSStyleRoot => SRGB::XSPT::TransformPathAbsoluteToRelative(
              getcwd . "/$node->{d_to}",
              getcwd . "/$root->{d_to}/templates") . "/",
          },
          $gPatternVideo);
        WriteFile($node->{r_to}, $str);
      }
      elsif (1)
      {
        ## reading real file, modifying, saving
        my $str = ReadFile($node->{f_from});
        SanitizeHTML(\$str, $node);
        WriteFile($node->{r_to}, $str);
      }
      else
      { 
        die ("@@ Unhandled file type, please implement it @@");
      }
        



      ## test stuff
  #   `/usr/local/bin/p4v.bin -merge "$node->{f_from}" "$node->{f_to}"`;
      if ($gTestStartFirefox)
      {
        `firefox "$node->{f_to}"` ;
        $gTestStartFirefox = 0;
      } 
    } #if html
  } #if file

  for my $sub_node (@{$node->{children}})
  {
    CreateFiles($root, $sub_node);
  }
}

# @todo think about Linux/Win paths into generated HTMLs
# @todo make bg transparent, not white!
# @todo : min width is 1024 for content, else - 90%
# @todo scroll visible in Win/ correct height 
sub go($)
{
  my $dir = shift or die;
  print "working within dir: $dir\n";

  my $root = 
    {
  #     d_base => "http://localhost/", #@todo?
      d_from => "$dir/src",
      d_to   => "$dir/dest",
      opt_convert_names => 1, # show =~ s/_+/ /g; to =~ /\s+/_/g
    s_file => \&ConvertFile,
    s_dir  => \&ConvertDir,
    menu_id => "treemenu", # @note not-intrusive container ...
  };

  rmtree($root->{d_to}) if -d $root->{d_to} and $root->{d_to} ne '/';
  DirWalk($root);
  CreateFiles($root, $root);
#   `firefox "$dir/dest/index.html"`;
}

my $DirFrom2Search = DirEscape $gMainDir;
go($_) for (<${DirFrom2Search}*>);
