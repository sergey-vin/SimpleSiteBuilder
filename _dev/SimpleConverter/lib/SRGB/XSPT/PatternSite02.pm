package SRGB::XSPT::PatternSite02; #by me, based on DIVs
our $Pattern = << '#XSPTPatternEND';
<?XSPT
XSStyleRoot
XSMenu
XSData
XSHeader
XSHeaderInfo
?>

<html xmlns="http://www.w3.org/1999/xhtml"><head>
<meta http-equiv="content-type" content="text/html; charset=win-1251">
<meta name="author" content="Sergey Vinogradov"></meta>

<!-- menu pre-init -->
<script type="text/javascript">
  var ddtreemenu=new Object()
  ddtreemenu.closefolder="<?perl $XSStyleRoot ?>SRGBDiv/closed.gif"
  ddtreemenu.openfolder="<?perl $XSStyleRoot ?>SRGBDiv/open.gif"

  function AdjustSizeElement(
    el_main,  // like "outer_bar"
    el_chld,  // like "inner_div"
    what,     // height = 1, width = 2
    delta     // correction, like 12
    )
  {
    var need_to_alert = 0;

    var div_out = document.getElementById(el_main);
    var big = what == 1
      ? div_out.clientHeight
      : div_out.clientWidth;

    var div = document.getElementById(el_chld);
    var small = what == 1
      ? div.clientHeight
      : div.clientWidth;

    if (need_to_alert)
      alert("big " + big +  "small " + small);

    var sum = big + small;
    for (var i = 0; i < div_out.childNodes.length; i++)
    {
      var j = div_out.childNodes.item(i);
      var sz = what == 1
        ? j.clientHeight
        : j.clientWidth;
      if (j.nodeType != 3 && sz > 0)
      {
        sum -= sz;
        if (need_to_alert)
          alert("subtract " + sz + " remains: " +sum);
      }
    }
    sum -= delta;
    if (what == 1)
      div.style.height = sum;
    else
      div.style.width = sum;

    if (need_to_alert)
      alert("big " + big +  "small now: " + what == 1
        ? div.clientHeight
        : div.clientWidth);
  }
  function AdjustSize()
  {
    AdjustSizeElement("srgb_main_div", "srgb_menu_n_content", 1, 0);
    AdjustSizeElement("srgb_menu_bar", "srgb_menu_div", 1, 12);
    AdjustSizeElement("srgb_menu_n_content", "srgb_content_bar", 2, 0);
  }
  function MenuShrink(
    what // shrink = 1, enlarge = 2
  )
  {
    var delta = 40;

    var div = document.getElementById("srgb_menu_bar");
    var sz_old = div.clientWidth;
    if (what == 1 && sz_old < 50 || what == 2 && sz_old > 1000)
      return;
    sz_old += what == 1
      ? -delta
      : delta;
    div.style.width = sz_old;
    AdjustSizeElement("srgb_menu_n_content", "srgb_content_bar", 2, 0);
  }


</script>
<script type="text/javascript" src="<?perl $XSStyleRoot ?>SRGBDiv/simpletreemenu.js">
/***********************************************
* Simple Tree Menu- © Dynamic Drive DHTML code library (www.dynamicdrive.com)
* This notice MUST stay intact for legal use
* Visit Dynamic Drive at http://www.dynamicdrive.com/ for full source code
***********************************************/
</script>
<link rel="stylesheet" type="text/css" href="<?perl $XSStyleRoot ?>SRGBDiv/simpletree.css" />

<!-- main layout init -->
<link rel="stylesheet" type="text/css" href="<?perl $XSStyleRoot ?>SRGBDiv/divs.css" />

<!--
  onresize="AdjustSize();"
  onload="AdjustSize();"
  -->
</head><body 
  onresize="AdjustSize();"
  onload="AdjustSize();"
  background="<?perl $XSStyleRoot ?>SRGBDiv/background.gif">

<div align="center" width="980" id="srgb_main_div">
  <div style="width:980px;">
    <table style="width:100%;background-color:black;color:white;font-style:italic;font-size:small">
    <tr>
      <td align="left"> 
        <?perl $XSHeader->[0] ?>
      </td>
      <td align="center"> 
        <?perl $XSHeader->[1] ?>
      </td>
      <td align="right"> 
        <?perl $XSHeader->[2] ?>
      </td>
    </tr>
    </table>
   
    <div>
      <div style="position:relative;">
        <img onclick="AdjustSize();" src="<?perl $XSStyleRoot ?>SRGBDiv/logo.jpg" alt="" border="0" height="116" width="980">
        <div id="srgb_header_top_right" style="padding:0;width:100%;margin:10px"> 
		<table cellpadding="0px" cellspacing="0px" align="center" border="0" width="100%">
		<tr>
		  <td align="left">
		    <img height="95px" src="<?perl $XSStyleRoot ?>SRGBDiv/title_left.png" />
		  </td>
		  <td width="*" align="center">
		    <?perl $XSHeaderInfo ?>
		  </td>
		  <td align="right" style="padding-right:20px">
		    <img height="95px" src="<?perl $XSStyleRoot ?>SRGBDiv/title_right.png" />
		  <td>
		</tr>
		</table>
        </div>
      </div>
    </div>
  </div>
 
    <div id="srgb_menu_n_content">

      <!-- $XSMenu -->
      <div id="srgb_menu_bar">

        <!-- menu header -->
        <div id="srgb_menu_top">
          <img alt="" src="<?perl $XSStyleRoot ?>SRGBDiv/printingnav_top_empty.gif" border="0" height="45" width="100%">
          <div id="srgb_menu_top_left">
            <img onclick="MenuShrink(1);" alt="" src="<?perl $XSStyleRoot ?>SRGBDiv/stock_first.png" border="0">
          </div>
          <div id="srgb_menu_top_right">
            <img onclick="MenuShrink(2);" alt="" src="<?perl $XSStyleRoot ?>SRGBDiv/stock_last.png" border="0">
          </div>
        </div>

        <!-- menu list-->
        <div id="srgb_menu_div">
          <div id="srgb_menu_rel_div">
          <?perl $XSMenu ?>
          </div>
        </div>

        <!-- menu footer -->
        <img alt="" src="<?perl $XSStyleRoot ?>SRGBDiv/printingnav_bottom.gif" border="0" height="9" width="100%">
      
      </div>

      <!-- content -->
      <div id="srgb_content_bar">
        <?perl $XSData ?>
        <!-- $XSData -->
      </div>


    </div> <!-- menu + content -->

   <div><!-- used to be footer.jpg -->
   	<a href="<?perl $XSStyleRoot ?>/../../About.html"> <img height="15px" alt="about this work" src="<?perl $XSStyleRoot ?>SRGBDiv/about.png" border="0" /> <bold><font size="3"> About </font></bold></a>
   </div>
</div>



<!-- menu init -->
<script type="text/javascript">

//ddtreemenu.createTree(treeid, enablepersist, opt_persist_in_days (default is 1))

</script>


</body></html>
#XSPTPatternEND

1;
