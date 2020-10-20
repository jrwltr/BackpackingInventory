use strict;
use File::Basename;
use XML::Simple qw(:strict);
$XML::Simple::PREFERRED_PARSER = 'XML::Parser';
use Socket;
use IO::Select;
use threads;
use threads::shared;

sub Usage($)
{
    print "\n";
    print shift;
    print "\n";
    print "Usage:   ", basename($0), " <xml file name> <browser start command>\n";
    print "Example: ", basename($0), " backpackingdata.xml \"start chrome\"\n";
    print "\n";
    die;
}

my $BackedUp :shared;
$BackedUp = 0;
my $XML :shared;
if (scalar @ARGV == 0) {
    Usage("Missing command line arguments.\n");
} elsif (scalar @ARGV == 1) {
    Usage("Missing browser start command.\n");
} elsif (scalar @ARGV > 2) {
    Usage("Too many command line arguments.\n");
}
my $XMLFileName = $ARGV[0];
my $BrowserCommand = $ARGV[1];

if (!-e $XMLFileName) {
    Usage("Can't find file $XMLFileName.\n");
}
$XML = shared_clone(XMLin($XMLFileName, forcearray => 1, keyattr => ['name']));

my $EditView = 1;

my $CONSUMABLESNAME  = 'Consumables';
my $NOTINPACKNAME    = 'Not In Pack';
my $TOTALNAME        = 'Total';
my $INPACKNAME       = 'In Pack';
my $BASENAME         = 'Base';

my $YES              = 'YES';
my $NO               = 'NO';
my $CARRYTAG         = 'carry';
my $CATEGORYTAG      = 'category';
my $ITEMTAG          = 'item';
my $QUANTITYTAG      = 'quantity';
my $COMPONENTSTAG    = 'components';
my $COMPONENTNAMETAG = 'cname';
my $OUNCESTAG        = 'ounces';

my $PRINTVIEWBUTTONNAME = 'PrintView';
my $SAVEBUTTONNAME      = 'Save Changes';

my $UNCHANGEDCOLORNAME = 'black';
my $CHANGEDCOLORNAME   = 'red';

##############################################################################
# Read in the __DATA__ at the end of this file and perform keyword 
# replacement.  The result will be copied to the HTTP output stream
# when a web page is requested.
#
my @KeyWords = (['CONSUMABLES'   , $CONSUMABLESNAME    ],
                ['NOTINPACK'     , $NOTINPACKNAME      ],
                ['TOTAL'         , $TOTALNAME          ],
                ['INPACK'        , $INPACKNAME         ],
                ['BASE'          , $BASENAME           ],
                ['SAVEBUTTON'    , $SAVEBUTTONNAME     ],
                ['UNCHANGEDCOLOR', $UNCHANGEDCOLORNAME ],
                ['CHANGEDCOLOR'  , $CHANGEDCOLORNAME   ],
               );
my @PageData;
while (<DATA>) {
    foreach my $KeyWord (@KeyWords) {
        $_ =~ s/!!$KeyWord->[0]!!/$KeyWord->[1]/g;
    }
    push @PageData, $_;
}

##############################################################################
# Start the web server, listen for connections, and respond to requests.
#
$|  = 1;

local *S;

my $TCPPort = 8888;

socket     (S, PF_INET   , SOCK_STREAM , getprotobyname('tcp')) or die "couldn't open socket: $!";
setsockopt (S, SOL_SOCKET, SO_REUSEADDR, 1);
bind       (S, sockaddr_in($TCPPort, INADDR_ANY));
listen     (S, 5)                                               or die "don't hear anything:  $!";

my $ss = IO::Select->new();
$ss -> add (*S);

`$BrowserCommand http://localhost:$TCPPort`;
if ($? != 0) {
    Usage("Can't invoke browser with \"$BrowserCommand\".\n");
}

while(1) {
  my @connections_pending = $ss->can_read();
  foreach (@connections_pending) {
    my $fh;
    my $remote = accept($fh, $_);

    my($port,$iaddr) = sockaddr_in($remote);
    my $peeraddress = inet_ntoa($iaddr);

    my $t = threads->create(\&new_connection, $fh);
    $t->detach();
  }
}

##############################################################################
sub new_connection {
  my $fh = shift;

  # Parse the HTTP connection request data.
  binmode $fh;

  my %req;

  $req{HEADER}={}; 

  my $request_line = <$fh>;
  my $first_line = "";

  while ($request_line ne "\r\n") {
     unless ($request_line) {
       close $fh; 
     }

     chomp $request_line;

     unless ($first_line) {
       $first_line = $request_line;

      my @parts = split(" ", $first_line);
       if (@parts != 3) {
         close $fh;
       }

       $req{METHOD} = $parts[0];
       $req{OBJECT} = $parts[1];
     }
     else {
       my ($name, $value) = split(": ", $request_line);
       $name       = lc $name;
       $req{HEADER}{$name} = $value;
     }

     $request_line = <$fh>;
  }

  http_request_handler($fh, \%req);

  close $fh;
}

##############################################################################
sub OuncesToPounds($) {
    my $Ounces = shift;
    return sprintf("%.2f", ($Ounces / 16) + .005);
}

##############################################################################
sub http_request_handler {
    my $fh     =   shift;
    my $req_   =   shift;
    my %req    =   %$req_;
    my $ErrorMessage;

    $req{OBJECT} =~ s/\+/ /g;
    $req{OBJECT} =~ s/%([0-9A-Fa-f]{2})/chr(hex("0x$1"))/ge;
    if ($req{OBJECT} =~ /^\/submit\?$PRINTVIEWBUTTONNAME=/) {
        # Print view button pressed.
        $EditView = 0;
    } elsif ($req{OBJECT} =~ /^\/submit\?$SAVEBUTTONNAME=/) {
        # Save changes button pressed.
        # Parse the request data and update the $XML data
        # structure based on the contents.
        $req{OBJECT} =~ s/^\/submit\?[\w\s]+?=.+?&//;
        foreach my $C ( split('&', $req{OBJECT}) ) {
            $C =~ /(.+)\\(.+)=([01])/;
            my $Category = $1;
            my $Item = $2;
            my $Value = $3;
            my $ItemHashRef = \%{$XML->{$CATEGORYTAG}->{$Category}->{$ITEMTAG}};
            if ($Value eq '0') {
                ($ItemHashRef->{$Item})->{$CARRYTAG} = $NO;
            } elsif ($Value eq '1') {
                ($ItemHashRef->{$Item})->{$CARRYTAG} = $YES;
            }
        }
        # Save the new XML data after making a backup copy of the original file.
        # Only create the backup file once.
        if ($BackedUp || rename($XMLFileName, $XMLFileName."~")) {
            $BackedUp = 1;
            if (open(OUT, '>', $XMLFileName)) {
                print OUT XMLout($XML, keyattr => ['name']);
                close OUT;
            } else {
                $ErrorMessage = "Can't open $XMLFileName for writing.";
            }
        } else {
            $ErrorMessage = "Can't create backup file $XMLFileName", "~.";
        }
    }

    my $TotalPounds = 0;
    my $InPackPounds = 0;
    my $BasePounds = 0;

    my %CategoryPounds;

    # make a pass through the XML to compute the total, pack, and base weights
    foreach my $C (sort keys %{$XML->{$CATEGORYTAG}}) {
        $CategoryPounds{$C} = 0;
        my $ItemHashRef = \%{$XML->{$CATEGORYTAG}->{$C}->{$ITEMTAG}};
        foreach my $I (sort keys %$ItemHashRef) {
            if (!defined(($ItemHashRef->{$I})->{$QUANTITYTAG})) {
                ($ItemHashRef->{$I})->{$QUANTITYTAG} = 1;
            }
            if (($ItemHashRef->{$I})->{$CARRYTAG} eq $YES) {
                if (defined(($ItemHashRef->{$I})->{$COMPONENTSTAG})) {
                    my $ComponentArrayRef = $ItemHashRef->{$I}->{$COMPONENTSTAG}[0]->{$ITEMTAG};
                    $$ItemHashRef{$I}->{$OUNCESTAG} = 0;
                    foreach my $C (@$ComponentArrayRef) {
                        $$ItemHashRef{$I}->{$OUNCESTAG} += $C->{$OUNCESTAG};
                    }
                }
                my $Pounds = OuncesToPounds(($ItemHashRef->{$I})->{$OUNCESTAG} * ($ItemHashRef->{$I})->{$QUANTITYTAG});
                $CategoryPounds{$C} += $Pounds;
                if ($C ne $NOTINPACKNAME) {
                    $InPackPounds += $Pounds;
                }
                if ($C ne $CONSUMABLESNAME && $C ne $NOTINPACKNAME) {
                   $BasePounds += $Pounds;
                }
            }
        }
        $TotalPounds += $CategoryPounds{$C};
    }

    # Generate the web server response...
    print $fh "HTTP/1.0 200 OK\r\n";
    print $fh "Server: adp perl webserver\r\n";
    print $fh "\r\n";

    $\ = "\n";
    print $fh '<html>';
    print $fh '<body>';
    print $fh '<form action="submit">';
    if ($EditView) {
        print $fh '<div class="backgroundgradient">';
    }

    #################################################################
    #Use this code to display the request info from the browser
    #my %header = %{$req{HEADER}};
    #print "Method: $req{METHOD}<br>";
    #print "Object: $req{OBJECT}<br>";
    #foreach my $r (keys %header) {
    #  print $r, " = ", $header{$r} , "<br>";
    #}
    #################################################################

    # generate the web page...

    if (defined $ErrorMessage) {
        print $fh '<br><br>';
        print $fh '<div class="alert">';
        print $fh     '<span class="closebtn">&times;</span>';
        print $fh     "<strong>$ErrorMessage</strong>";
        print $fh '</div>';
    }

    #################################################################
    # Create a table to display total, in pack, and base weights
    print $fh '<br><br>';
    print $fh '<table class="center_table" style="width:80%" border="1">';
    print $fh '<tr>';

    foreach my $A (
                   ( [ $TOTALNAME , $TotalPounds  ], 
                     [ $INPACKNAME, $InPackPounds ],
                     [ $BASENAME  , $BasePounds   ],
                   )
                  )
    {
        print $fh     '<th>';
        print $fh         '<p style="font-size: x-large">';
        print $fh             sprintf('%s <span id="%s">%s</span>', $A->[0], $A->[0], $A->[1]);
        print $fh         '</p>';
        print $fh     '</th>';
    }
    print $fh '</tr>';
    print $fh '</table>';
    print $fh '<br>';

    #################################################################
    # Define the submit buttons
    if ($EditView) {
        print $fh '<div class="center_buttons">';
        print $fh '<input type="submit" class="push_button blue" formtarget="_blank" name="', $PRINTVIEWBUTTONNAME, '" value="Print View" >';
        print $fh '<input type="submit" class="push_button red"  name="', $SAVEBUTTONNAME     , '" value="Save"       style="visibility:hidden">';
        print $fh '</div>';
        print $fh '<br>';
    }

    #################################################################
    # create a table containing the inventory data
    print $fh '<table class="center_table" style="width:80%"border="1">';
    print $fh '<tr>';
    my $CCount = 0;

    my $NumberOfColumns = 4;

    foreach my $C (sort keys %{$XML->{$CATEGORYTAG}}) {
        if ($CCount++ % $NumberOfColumns == 0) {
            print $fh '</tr><tr>';
        }

        print $fh '<td valign="top">';

        # display the category
        print $fh '<p style="font-size: x-large">';
        print $fh sprintf('%s <span id="%s">%s</span> lbs', $C, $C, $CategoryPounds{$C} );
        print $fh '</p>';

        # display the items in the category
        my $ItemHashRef = \%{$XML->{$CATEGORYTAG}->{$C}->{$ITEMTAG}};
        foreach my $I (sort keys %$ItemHashRef) {
            if ($EditView || ($ItemHashRef->{$I})->{$CARRYTAG} eq $YES) {
                print $fh '<div class="parent-check">';
                print $fh     '<input type="hidden" value=0 name="', "$C\\$I", '">';
                print $fh     '<input id="', $C, '" value=1 name="', "$C\\$I", '"';
                if (!$EditView) {
                    print $fh          ' style="visibility:hidden" ';
                }
                print $fh         'type="checkbox"', (($ItemHashRef->{$I})->{$CARRYTAG} eq $YES) ? 'checked' : '', '>';
                print $fh     '<label id="', sprintf(" %.2f", ($ItemHashRef->{$I})->{$OUNCESTAG} * ($ItemHashRef->{$I})->{$QUANTITYTAG}), '" style="color:$UNCHANGEDCOLOR;font-size: large">';

                if (($ItemHashRef->{$I})->{$QUANTITYTAG} != 1) {
                    print $fh ($ItemHashRef->{$I})->{$QUANTITYTAG}, '-';
                }
                print $fh     $I;
                print $fh     '</label>';
                if (defined(($ItemHashRef->{$I})->{$COMPONENTSTAG})) {
                    # display the sub-components of the item
                    my $ComponentArrayRef = $ItemHashRef->{$I}->{$COMPONENTSTAG}[0]->{$ITEMTAG};
                    foreach my $P (@$ComponentArrayRef) {
                        print $fh '<div class="components">';
                        print $fh     '<label>', $P->{$COMPONENTNAMETAG}, '</label>';
                        print $fh '</div>';
                    }
                }
                print $fh '</div>';
            }
        }
    }
    print $fh '</tr>';
    print $fh '</table>';
    print $fh '<br><br>';
    if ($EditView) {
        print $fh '</div>';
    }
    print $fh '</form> ';
    print $fh '</body>';
    print $fh '</html>';

    # copy the __DATA__ section to the output
    foreach my $Line (@PageData) {
        print $fh $Line;
    }
}

##############################################################################
# __DATA__ section contains HTML CSS style definitions and java script.  The
# contents are copied directly to the HTTP connection along with the generated
# XML.  Certain keywords are replaced with the contents of Perl variables.
# These keywords look like this "!!KEYWORD!!".
#
__DATA__
<style id="compiled-css" type="text/css">
/*   ------------------------------------------------------------- */
.center_table {
    margin-left: auto;
    margin-right: auto;
}
.center_buttons {
    display: flex;
    justify-content: center;
    align-items: center;
}

/*   ------------------------------------------------------------- */
/*   CSS code for to provide background color gradient             */

.backgroundgradient {
  background-color: red; /* For browsers that do not support gradients */
  background-image: linear-gradient(lightskyblue, powderblue);
}

/*   ------------------------------------------------------------- */
/*   CSS code for checkboxes with collapsible component lists      */

.components{
  margin-left: 50px;
  display: none;
}

.components.active{
  display: block;
}

/*   ------------------------------------------------------------- */
/*   CSS code for error messages                                   */

.alert {
  padding: 20px;
  background-color: red;
  color: white;
  opacity: 1;
  transition: opacity 0.6s;
  margin-bottom: 15px;
}

.closebtn {
  margin-left: 15px;
  color: white;
  font-weight: bold;
  float: right;
  font-size: 22px;
  line-height: 20px;
  cursor: pointer;
  transition: 0.3s;
}

.closebtn:hover {
  color: black;
}

/*   ------------------------------------------------------------- */
/*   CSS code for pretty buttons                                   */

.push_button {
	position: relative;
	width:220px;
	height:40px;
    font-size: x-large;
	text-align:center;
	line-height:43px;
    margin-bottom: 15px;
    margin-left: 15px;
    margin-right: 15px;
}

.red {
	text-shadow:-1px -1px 0 #A84155;
	background: #D25068;
	border:1px solid #D25068;
	
	background-image:-webkit-linear-gradient(top, #F66C7B, #D25068);
	background-image:-moz-linear-gradient(top, #F66C7B, #D25068);
	background-image:-ms-linear-gradient(top, #F66C7B, #D25068);
	background-image:-o-linear-gradient(top, #F66C7B, #D25068);
	background-image:linear-gradient(to bottom, #F66C7B, #D25068);
	
	-webkit-border-radius:5px;
	-moz-border-radius:5px;
	border-radius:5px;
	
	-webkit-box-shadow:0 1px 0 rgba(255, 255, 255, .5) inset, 0 -1px 0 rgba(255, 255, 255, .1) inset, 0 4px 0 #AD4257, 0 4px 2px rgba(0, 0, 0, .5);
	-moz-box-shadow:0 1px 0 rgba(255, 255, 255, .5) inset, 0 -1px 0 rgba(255, 255, 255, .1) inset, 0 4px 0 #AD4257, 0 4px 2px rgba(0, 0, 0, .5);
	box-shadow:0 1px 0 rgba(255, 255, 255, .5) inset, 0 -1px 0 rgba(255, 255, 255, .1) inset, 0 4px 0 #AD4257, 0 4px 2px rgba(0, 0, 0, .5);
}

.red:hover {
	background: #F66C7B;
	background-image:-webkit-linear-gradient(top, #D25068, #F66C7B);
	background-image:-moz-linear-gradient(top, #D25068, #F66C7B);
	background-image:-ms-linear-gradient(top, #D25068, #F66C7B);
	background-image:-o-linear-gradient(top, #D25068, #F66C7B);
	background-image:linear-gradient(top, #D25068, #F66C7B);
}

.blue {
	text-shadow:-1px -1px 0 #2C7982;
	background: powderblue;
	border:1px solid #379AA4;
	background-image:-webkit-linear-gradient(top, steelblue, powderblue);
	background-image:-moz-linear-gradient(top, steelblue, powderblue);
	background-image:-ms-linear-gradient(top, steelblue, powderblue);
	background-image:-o-linear-gradient(top, steelblue, powderblue);
	background-image:linear-gradient(top, steelblue, powderblue);
	
	-webkit-border-radius:5px;
	-moz-border-radius:5px;
	border-radius:5px;
	
	-webkit-box-shadow:0 1px 0 rgba(255, 255, 255, .5) inset, 0 -1px 0 rgba(255, 255, 255, .1) inset, 0 4px 0 #338A94, 0 4px 2px rgba(0, 0, 0, .5);
	-moz-box-shadow:0 1px 0 rgba(255, 255, 255, .5) inset, 0 -1px 0 rgba(255, 255, 255, .1) inset, 0 4px 0 #338A94, 0 4px 2px rgba(0, 0, 0, .5);
	box-shadow:0 1px 0 rgba(255, 255, 255, .5) inset, 0 -1px 0 rgba(255, 255, 255, .1) inset, 0 4px 0 #338A94, 0 4px 2px rgba(0, 0, 0, .5);
}

.blue:hover {
	background: steelblue;
	background-image:-webkit-linear-gradient(top, powderblue, steelblue);
	background-image:-moz-linear-gradient(top, powderblue, steelblue);
	background-image:-ms-linear-gradient(top, powderblue, steelblue);
	background-image:-o-linear-gradient(top, powderblue, steelblue);
	background-image:linear-gradient(top, powderblue, steelblue);
}

/*   ------------------------------------------------------------- */

</style>

<script type="text/javascript">//<![CDATA[

/*##########################################################################*/
function getStorageName(E) {
    return E.id.concat('_'.concat(E.nextElementSibling.innerHTML));
}

function updatePounds(element, Pounds) {
    element.innerHTML = (parseFloat(element.innerHTML) + Pounds).toFixed(2);
}

var checks = document.querySelectorAll("input[type=checkbox]");
for(var i = 0; i < checks.length; i++){
    /* add an event listener for all checkboxes */
    checks[i].addEventListener( 'change', function() {
        var CheckPounds = Math.round((parseFloat(this.nextElementSibling.id) / 16) * 100) / 100;

        var OriginalCheckState = sessionStorage.getItem(getStorageName(this));
        if (( this.checked && OriginalCheckState == 0) ||
            (!this.checked && OriginalCheckState == 1)
           )
        {
            this.nextElementSibling.style.color = "!!CHANGEDCOLOR!!";
        } else {
            this.nextElementSibling.style.color = "!!UNCHANGEDCOLOR!!";
        }
  
        if(this.checked) {
             /* item was selected, add the weight to the totals
              * and un-hide the children components
              */
             showComponents(this);
        } else {
             /* item was unselected, subtract the weight from the totals
              * and hide the children components
              */
             CheckPounds = -CheckPounds;
             hideComponents(this)
        }

        updatePounds(document.getElementById(this.id), CheckPounds);
        updatePounds(document.getElementById('!!TOTAL!!'), CheckPounds);
        if (this.id != "!!NOTINPACK!!") {
            updatePounds(document.getElementById('!!INPACK!!'), CheckPounds);
            if (this.id != "!!CONSUMABLES!!") {
                updatePounds(document.getElementById('!!BASE!!'), CheckPounds);
            }
        }
  
        /* un-hide the "SAVE" button if changes were made */
        var SaveButton = document.getElementsByName('!!SAVEBUTTON!!');
        SaveButton[0].style.visibility = 'hidden';
        var checks = document.querySelectorAll("input[type=checkbox]");
        for (var i = 0; i < checks.length; i++){
            if (checks[i].nextElementSibling.style.color == "!!CHANGEDCOLOR!!") {
                SaveButton[0].style.visibility = 'visible';
                break;
            }
        }
    });
    /* show or hide the children of a checkbox (components)
     * and save the initial value of the checkboxes
     */
    if (checks[i].checked) {
        sessionStorage.setItem(getStorageName(checks[i]), 1);
        showComponents(checks[i]);
    } else {
        sessionStorage.setItem(getStorageName(checks[i]), 0);
        hideComponents(checks[i]);
    }
}

/*##########################################################################*/
/* un-hide the components of the checkbox that changed */
function showComponents(elm) {
   var pN = elm.parentNode;
   var components = pN.children;
   
  for(var i = 0; i < components.length; i++){
      if(hasClass(components[i], 'components')){
	      components[i].classList.add("active");      
      }
  }
}

/*##########################################################################*/
/* hide the components of the checkbox that changed */
function hideComponents(elm) {
   var pN = elm.parentNode;
   var components = pN.children;
   
  for(var i = 0; i < components.length; i++){
      if(hasClass(components[i], 'components')){
	      components[i].classList.remove("active");      
      }
  }
}

/*##########################################################################*/
function hasClass(elem, className) {
    return new RegExp(' ' + className + ' ').test(' ' + elem.className + ' ');
}

/*##########################################################################*/

var close = document.getElementsByClassName("closebtn");
var i;

for (i = 0; i < close.length; i++) {
  close[i].onclick = function(){
    var div = this.parentElement;
    div.style.opacity = "0";
    setTimeout(function(){ div.style.display = "none"; }, 600);
  }
}

/*##########################################################################*/

//]]></script>

