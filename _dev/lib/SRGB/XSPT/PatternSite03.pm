package SRGB::XSPT::PatternSite03; #by me, based on DIVs + tables
our $Pattern = << '#XSPTPatternEND';
<?XSPT
XSStyleRoot
XSMenu
XSData
?>

<html xmlns="http://www.w3.org/1999/xhtml"><head>
<meta http-equiv="content-type" content="text/html; charset=utf-8">
<meta name="author" content="Sergey Vinogradov"></meta>

<!-- menu pre-init -->
<script type="text/javascript">
  var ddtreemenu=new Object()
  ddtreemenu.closefolder="<?perl $XSStyleRoot ?>SRGBDiv/closed.gif"
  ddtreemenu.openfolder="<?perl $XSStyleRoot ?>SRGBDiv/open.gif"
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


</head><body>


<div align="center" width="980" height="100%">
  <div style="width:980px;">
    <div style="background-color:black;font-color:white">
      <!-- header line -->
      header
    </div>
    
    <div>
      <div style="float:left"><img src="<?perl $XSStyleRoot ?>SRGBDiv/logo.jpg" alt="" border="0" height="116" width="281"></div>
      <div style="float:right"><img src="<?perl $XSStyleRoot ?>SRGBDiv/header_right.jpg" alt="" border="0" height="116" width="699"></div>
    </div>
 
    <table style="width:100%;height:80%" cellpadding="0" cellspacing="0">
    <tr>

      <!-- $XSMenu -->
      <td style="width:250px;height:100%;">
      <table style="width:250px;height:100%" cellpadding="0" cellspacing="0">
      <tr><td style="height:45px">
        <img alt="" src="<?perl $XSStyleRoot ?>SRGBDiv/printingnav_top_empty.gif" border="0" height="45" width="100%">
      </td></tr>
      <tr><td style="width:250px;padding: 6px;background-color:#363636;overflow: scroll;">
      <div style="overflow: scroll;">
          <?perl $XSMenu ?>
      </div>
      </td></tr>
      <tr><td style="height:9px">
        <img alt="" src="<?perl $XSStyleRoot ?>SRGBDiv/printingnav_bottom.gif" border="0" height="9" width="100%">
      </td></tr>
      </table>
      </td>

      <td style="background-color: #C0C0C0;width:80%;height:100%;">
        <!-- content -->
        <?perl $XSData ?>
        <!-- $XSData -->
      </td>

    </tr>
    </table>
  </div>
</div>



<!-- menu init -->
<script type="text/javascript">

//ddtreemenu.createTree(treeid, enablepersist, opt_persist_in_days (default is 1))

</script>


</body></html>
#XSPTPatternEND

1;
