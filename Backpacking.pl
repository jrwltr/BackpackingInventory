#???pretty-fy add/delete table
#???add help screen?
#???handle ounces -- don't store ounces if components are present?
#                    etc...
use strict;
use File::Basename;
use XML::Simple qw(:strict);
$XML::Simple::PREFERRED_PARSER = 'XML::Parser';

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

my $XML;
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
$XML = XMLin($XMLFileName, forcearray => 1, keyattr => ['name']);

my $EditView = 1;

my $CONSUMABLESNAME             = 'Consumables';
my $NOTINPACKNAME               = 'Not In Pack';
my $TOTALNAME                   = 'Total';
my $INPACKNAME                  = 'In Pack';
my $BASENAME                    = 'Base';

my $YES                         = 'YES';
my $NO                          = 'NO';
my $CARRYTAG                    = 'carry';
my $CATEGORYTAG                 = 'category';
my $ITEMTAG                     = 'item';
my $QUANTITYTAG                 = 'quantity';
my $COMPONENTSTAG               = 'components';
my $COMPONENTNAMETAG            = 'cname';
my $OUNCESTAG                   = 'ounces';

my $PRINTVIEWBUTTONNAME         = 'PrintView';
my $PRINTVIEWBUTTONVALUE        = 'PrintView';
my $SAVEBUTTONNAME              = 'Save Changes';
my $SAVEBUTTONVALUE             = 'Save';

my $ADDCATEGORYNAME             = 'categoryname';
my $ADDITEMNAME                 = 'itemname';
my $ADDWEIGHTNAME               = 'itemweight';
my $ADDQUANTITYNAME             = 'itemquantity';
my $ADDCOMPONENTNAME            = 'itemcomponent[]';
my $ADDCOMPONENTWEIGHTNAME      = 'itemcomponentweight[]';
my $ADDBUTTONNAME               = 'AddItem';
my $ADDBUTTONVALUE              = 'Add/Update Item';

my $DELITEMNAME                 = 'itemname';
my $DELBUTTONNAME               = 'DeleteItem';
my $DELBUTTONVALUE              = 'Delete Item';

my $UNCHANGEDCOLOR              = 'black';
my $CHANGEDCOLOR                = 'red';

my $ITEM_DEL_CHAR               = '&minus;';
my $ITEM_ADD_CHAR               = '&plus;';

my $ITEMLABEL                   = 'itemlabel';
my $CLOSEBTN                    = 'closebtn';

my $MAXCOMPONENTS               = 10;

##############################################################################
# Read in the __DATA__ at the end of this file and perform keyword 
# replacement.  The result will be copied to the HTTP output stream
# when a web page is requested.
#
my @KeyWords = (
                ['ADDCATEGORYNAME'       , $ADDCATEGORYNAME        ],
                ['ADDCOMPONENTNAME'      , $ADDCOMPONENTNAME       ],
                ['ADDCOMPONENTWEIGHTNAME', $ADDCOMPONENTWEIGHTNAME ],
                ['ADDITEMNAME'           , $ADDITEMNAME            ],
                ['ADDQUANTITYNAME'       , $ADDQUANTITYNAME        ],
                ['ADDWEIGHTNAME'         , $ADDWEIGHTNAME          ],
                ['BASE'                  , $BASENAME               ],
                ['CATEGORYTAG'           , $CATEGORYTAG            ],
                ['CHANGEDCOLOR'          , $CHANGEDCOLOR           ],
                ['CLOSEBTN'              , $CLOSEBTN               ],
                ['COMPONENTSTAG'         , $COMPONENTSTAG          ],
                ['CONSUMABLES'           , $CONSUMABLESNAME        ],
                ['INPACK'                , $INPACKNAME             ],
                ['ITEM_ADD_CHAR'         , $ITEM_ADD_CHAR          ],
                ['ITEM_DEL_CHAR'         , $ITEM_DEL_CHAR          ],
                ['ITEMLABEL'             , $ITEMLABEL              ],
                ['MAXCOMPONENTS'         , $MAXCOMPONENTS          ],
                ['NOTINPACK'             , $NOTINPACKNAME          ],
                ['OUNCESTAG'             , $OUNCESTAG              ],
                ['QUANTITYTAG'           , $QUANTITYTAG            ],
                ['SAVEBUTTON'            , $SAVEBUTTONNAME         ],
                ['TOTAL'                 , $TOTALNAME              ],
                ['UNCHANGEDCOLOR'        , $UNCHANGEDCOLOR         ],
               );
my @PageData;
while (<MyWebServer::DATA>) {
    foreach my $KeyWord (@KeyWords) {
        $_ =~ s/!!$KeyWord->[0]!!/$KeyWord->[1]/g;
    }
    push @PageData, $_;
}

##############################################################################
# Start the web server, listen for connections, and respond to requests.
#
my $TCPPort = 8888;

`$BrowserCommand http://localhost:$TCPPort`;
if ($? != 0) {
    Usage("Can't invoke browser with \"$BrowserCommand\".\n");
}

package MyWebServer;
use HTTP::Server::Simple::CGI;
use base qw(HTTP::Server::Simple::CGI);
 
my %dispatch = (
    '/submit' => \&submit_handler,
    '/' => \&GeneratePage,
    # ...
);
 
sub handle_request {
    my $self = shift;
    my $cgi  = shift;
   
    my $handler = $dispatch{$cgi->path_info()};
 
    if (ref($handler) eq "CODE") {
        print "HTTP/1.0 200 OK\r\n";
        $handler->($cgi);
    } else {
        print "HTTP/1.0 404 Not found\r\n";
        print $cgi->header,
              $cgi->start_html('Not found'),
              $cgi->h1('Not found'),
              $cgi->end_html;
    }
}
 
my $pid = MyWebServer->new($TCPPort)->background();

##############################################################################
sub OuncesToPounds($) {
    my $Ounces = shift;
    return sprintf("%.2f", ($Ounces / 16) + .005);
}

##############################################################################
my $ErrorMessage;
my $BackedUp = 0;

sub BackupAndWriteXMLFile() {
    # Save the new XML data after making a backup copy of the original file.
    # Only create the backup file once.
    if ($BackedUp || rename($XMLFileName, $XMLFileName."~")) {
        $BackedUp = 1;
        if (open(OUT, '>', $XMLFileName)) {
            print OUT XML::Simple::XMLout($XML, keyattr => ['name']);
            close OUT;
        } else {
            $ErrorMessage = "Can't open $XMLFileName for writing.";
        }
    } else {
        $ErrorMessage = "Can't create backup file $XMLFileName", "~.";
    }
}

##############################################################################
sub submit_handler {
    my $cgi  = shift;   # CGI.pm object

    my $Query = $cgi->query_string();

    $Query =~ s/\+/ /g;
    $Query =~ s/%([0-9A-Fa-f]{2})/chr(hex("0x$1"))/ge;
    if ($Query =~ /$PRINTVIEWBUTTONNAME=$PRINTVIEWBUTTONVALUE;{0,1}/) {
        # Print view button pressed.
        $EditView = 0;
    } elsif ($Query =~ /$SAVEBUTTONNAME=$SAVEBUTTONVALUE;{0,1}/) {
        # Save changes button pressed.
        # Parse the request data and update the $XML data
        # structure based on the contents.
        $Query =~ s/$SAVEBUTTONNAME=$SAVEBUTTONVALUE;{0,1}//;
        foreach my $C ( split(';', $Query) ) {
            if ($C =~ /(.+)\\(.+)=(.+)/) {
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
        }
        BackupAndWriteXMLFile();
    } elsif ($Query =~ /$ADDBUTTONNAME=$ADDBUTTONVALUE;{0,1}/) {
        $Query =~ s/$ADDBUTTONNAME=$ADDBUTTONVALUE;{0,1}//;
        my $Category;
        my $Item;
        my $Quantity;
        my $Ounces;
        my @Components;
        my @ComponentWeights;
        foreach my $C ( split(';', $Query) ) {
            if ($C =~ /(.+)=(.+)/) {
                if ($1 eq $ADDCATEGORYNAME) {
                    $Category = $2;
                } elsif ($1 eq $ADDITEMNAME) {
                    $Item = $2;
                } elsif ($1 eq $ADDWEIGHTNAME) {
                    $Ounces = $2;
                } elsif ($1 eq $ADDQUANTITYNAME) {
                    $Quantity = $2;
                } elsif ($1 eq $ADDCOMPONENTNAME) {
                    push @Components, $2;
                } elsif ($1 eq $ADDCOMPONENTWEIGHTNAME) {
                    push @ComponentWeights, $2;
                }
            }
        }
        my $ItemHashRef = \%{$XML->{$CATEGORYTAG}->{$Category}->{$ITEMTAG}};
        ($ItemHashRef->{$Item})->{$CARRYTAG} = $NO;
        ($ItemHashRef->{$Item})->{$OUNCESTAG} = $Ounces;
        ($ItemHashRef->{$Item})->{$QUANTITYTAG} = $Quantity;
        my @ComponentHash;
        for (my $i = 0; $i < scalar @Components; $i++) {
            my %CHash = ( $COMPONENTNAMETAG => $Components[$i], $OUNCESTAG => $ComponentWeights[$i] );
            push @ComponentHash, \%CHash;
        }
        $ItemHashRef->{$Item}->{$COMPONENTSTAG}[0]->{$ITEMTAG} = \@ComponentHash;
        BackupAndWriteXMLFile();
    } elsif ($Query =~ /$DELBUTTONNAME=$DELBUTTONVALUE;{0,1}/) {
        $Query =~ s/$DELBUTTONNAME=$DELBUTTONVALUE;{0,1}//;
        my $Category;
        my $Item;
        foreach my $C ( split(';', $Query) ) {
            if ($C =~ /(.+)=(.+)/) {
                if ($1 eq $ADDCATEGORYNAME) {
                    $Category = $2;
                } elsif ($1 eq $ADDITEMNAME) {
                    $Item = $2;
                }
            }
        }
        my $ItemHashRef = \%{$XML->{$CATEGORYTAG}->{$Category}->{$ITEMTAG}};
        delete($ItemHashRef->{$Item});
        BackupAndWriteXMLFile();
    }
    GeneratePage($cgi);
}

##############################################################################
sub GeneratePage() {
    my $cgi  = shift;   # CGI.pm object
    return if !ref $cgi;

    my $TotalPounds = 0;
    my $InPackPounds = 0;
    my $BasePounds = 0;

    my %CategoryPounds;

    local $\ = "\n";

    # make a pass through the XML to compute the total, pack, and base weights
    foreach my $CategoryName (sort keys %{$XML->{$CATEGORYTAG}}) {
        $CategoryPounds{$CategoryName} = 0;
        my $ItemHashRef = \%{$XML->{$CATEGORYTAG}->{$CategoryName}->{$ITEMTAG}};
        foreach my $ItemName (sort keys %$ItemHashRef) {
            if (!defined(($ItemHashRef->{$ItemName})->{$QUANTITYTAG})) {
                ($ItemHashRef->{$ItemName})->{$QUANTITYTAG} = 1;
            }
            if (defined(($ItemHashRef->{$ItemName})->{$COMPONENTSTAG})) {
                my $ComponentArrayRef = $ItemHashRef->{$ItemName}->{$COMPONENTSTAG}[0]->{$ITEMTAG};
                $$ItemHashRef{$ItemName}->{$OUNCESTAG} = 0;
                foreach my $C (@$ComponentArrayRef) {
                    $$ItemHashRef{$ItemName}->{$OUNCESTAG} += $C->{$OUNCESTAG};
                }
            }
            if (($ItemHashRef->{$ItemName})->{$CARRYTAG} eq $YES) {
                my $Pounds = OuncesToPounds(($ItemHashRef->{$ItemName})->{$OUNCESTAG} * ($ItemHashRef->{$ItemName})->{$QUANTITYTAG});
                $CategoryPounds{$CategoryName} += $Pounds;
                if ($CategoryName ne $NOTINPACKNAME) {
                    $InPackPounds += $Pounds;
                }
                if ($CategoryName ne $CONSUMABLESNAME && $CategoryName ne $NOTINPACKNAME) {
                   $BasePounds += $Pounds;
                }
            }
        }
        $TotalPounds += $CategoryPounds{$CategoryName};
    }

    # Generate the web server response...
    print $cgi->header;
    print $cgi->start_html(($EditView ? "" : "Print ") . "Backpack Inventory");

    if ($EditView) {
        print '<div class="backgroundgradient">';
    }
    print '<form action="submit">';

    if (defined $ErrorMessage) {
        print '<br><br>';
        print '<div class="alert">';
        print     "<span class=\"$CLOSEBTN\">&times;</span>";
        print     "<strong>$ErrorMessage</strong>";
        print '</div>';
    }

    #################################################################
    # Create a table to display total, in pack, and base weights
    print '<br><br>';
    print '<table class="center_table" style="width:80%" border="1">';
    print '<tr>';

    foreach my $A (
                   ( [ $TOTALNAME , $TotalPounds  ], 
                     [ $INPACKNAME, $InPackPounds ],
                     [ $BASENAME  , $BasePounds   ],
                   )
                  )
    {
        print     '<th>';
        print         '<p style="font-size: x-large">';
        print             sprintf('%s <span id="%s">%s</span>', $A->[0], $A->[0], $A->[1]);
        print         '</p>';
        print     '</th>';
    }
    print '</tr>';
    print '</table>';
    print '<br>';

    #################################################################
    # Define the submit buttons
    if ($EditView) {
        print '<div class="center_buttons">';
        print "<input type=\"submit\" class=\"push_button blue\" formtarget=\"_blank\" name=\"$PRINTVIEWBUTTONNAME\" value=\"$PRINTVIEWBUTTONVALUE\" >";
        print "<input type=\"submit\" class=\"push_button red\"  name=\"$SAVEBUTTONNAME\" value=\"$SAVEBUTTONVALUE\" style=\"visibility:hidden\">";
        print '</div>';
        print '<br>';
    }

    #################################################################
    # create a table containing the inventory data
    print '<table class="center_table" style="width:80%"border="1">';
    print '<tr>';
    my $CCount = 0;

    my $NumberOfColumns = 4;

    foreach my $CategoryName (sort keys %{$XML->{$CATEGORYTAG}}) {
        if ($CCount != 0 && $CCount % $NumberOfColumns == 0) {
            print '</tr><tr>';
        }
        $CCount++;

        print '<td valign="top">';

        # display the category
        print '<p style="font-size: x-large">';
        print sprintf('%s <span id="%s">%s</span> lbs', $CategoryName, $CategoryName, $CategoryPounds{$CategoryName} );
        print '</p>';

        sub ItemLabel($$) {
            my $ItemName =  shift;
            my $Quantity =  shift;
            return (($Quantity != 1) ? $Quantity.'-' : '') . $ItemName;
        }

        # display the items in the category
        my $ItemHashRef = \%{$XML->{$CATEGORYTAG}->{$CategoryName}->{$ITEMTAG}};
        foreach my $ItemName (sort keys %$ItemHashRef) {
            my $Carry = ($ItemHashRef->{$ItemName})->{$CARRYTAG} eq $YES;
            if ($EditView || $Carry) {
                my $Quantity = $ItemHashRef->{$ItemName}->{$QUANTITYTAG};
                my $InputName = "$CategoryName\\$ItemName";

                sub StyleVisibility($) {
                    my $IsVisible = shift;
                    return ' style="visibility:', $IsVisible ? 'visible' : 'hidden', '"';
                }

                print '<div>';
                print     "<input type=\"hidden\" value=0 name=\"$InputName\">";
                print     "<input value=1 name=\"$InputName\"";
                print         StyleVisibility($EditView);
                print         ' type="checkbox"', $Carry ? ' checked' : '';
                print         " data-$CATEGORYTAG=\"$CategoryName\"";
                print     '>';
                print     "<label", StyleVisibility($Quantity != 1), ">$ItemHashRef->{$ItemName}->{$QUANTITYTAG}</label>";
                print     "<label class=\"$ITEMLABEL\"";
                print         " data-$OUNCESTAG=\"$ItemHashRef->{$ItemName}->{$OUNCESTAG}\"";
                print         " data-$QUANTITYTAG=\"$ItemHashRef->{$ItemName}->{$QUANTITYTAG}\"";
                print     ">$ItemName</label>";
                if (defined(($ItemHashRef->{$ItemName})->{$COMPONENTSTAG})) {
                    # display the sub-components of the item
                    my $ComponentArrayRef = ($ItemHashRef->{$ItemName})->{$COMPONENTSTAG}[0]->{$ITEMTAG};
                    foreach my $P (@$ComponentArrayRef) {
                        print     "<label class=\"$COMPONENTSTAG\" data-$OUNCESTAG=\"$P->{$OUNCESTAG}\">$P->{$COMPONENTNAMETAG}</label>";
                    }
                }
                print '</div>';
            }
        }
    }
    print '</tr>';
    print '</table>';
    print '<br><br>';
    print '</form> ';

    if ($EditView) {
        # create a form to allow adding, updating and deleting items
        my $OuncesInputAttributes = "type=\"number\" min=\"0.01\" step=\"0.01\"";
        print '<form action="submit" onkeydown="return event.key != \'Enter\';">';
        print '<table class="center_table" style="width:50%" border="1">';
        print '<tr>';
        print     '<td>';
        print     "<label for=\"$ADDCATEGORYNAME\">Category</label>";
        print     '</td>';
        print     '<td>';
        print     "<select id=\"$ADDCATEGORYNAME\" name=\"$ADDCATEGORYNAME\" style=\"width:95%\">";
        foreach my $CategoryName (sort keys %{$XML->{$CATEGORYTAG}}) {
            print "<option value=\"$CategoryName\">$CategoryName</option>";
        }
        print     '</select>';
        print     '</td>';
        print '</tr>';
        print '<tr>';
        print     '<td>';
        print         "<label for=\"$ADDITEMNAME\">Item</label>";
        print     '</td>';
        print     '<td>';
        print         "<label>Name</label>";
        print         "<input type=\"text\" id=\"$ADDITEMNAME\" name=\"$ADDITEMNAME\">";
        print         "<label>Ounces</label>";
        print         "<input $OuncesInputAttributes id=\"$ADDWEIGHTNAME\" name=\"$ADDWEIGHTNAME\">";
        print     '</td>';
        print '</tr>';
        print '<tr>';
        print     '<td>';
        print         "<label for=\"$ADDCOMPONENTNAME\">Components</label>";
        print     '</td>';
        print     '<td>';
        for (my $i = 0; $i < $MAXCOMPONENTS; $i++) {
            print         "<label>Name</label>";
            print         "<input type=\"text\" id=\"$ADDCOMPONENTNAME\" name=\"$ADDCOMPONENTNAME\" >";
            print         "<label>Ounces</label>";
            print         "<input $OuncesInputAttributes id=\"$ADDCOMPONENTWEIGHTNAME\" name=\"$ADDCOMPONENTWEIGHTNAME\">";
            print         "<br>"
        }
        print     '</td>';
        print '</tr>';
        print '<tr>';
        print     '<td>';
        print         "<label for=\"$ADDQUANTITYNAME\">Quantity</label>";
        print     '</td>';
        print     '<td>';
        print         "<input type=\"number\" min=\"1\" id=\"$ADDQUANTITYNAME\" name=\"$ADDQUANTITYNAME\" value=\"1\" style=\"width:95%\">";
        print     '</td>';
        print '</tr>';
        print '</table>';

        print '<br>';
        print '<div class="center_buttons">';
        print         "<input type=\"submit\" class=\"push_button blue\" name=\"$ADDBUTTONNAME\" value=\"$ADDBUTTONVALUE\">";
        print         "<input type=\"submit\" class=\"push_button blue\" name=\"$DELBUTTONNAME\" value=\"$DELBUTTONVALUE\">";
        print '</div>';
        print '</form> ';
        print '<br><br>';
    }

    if ($EditView) {
        print '</div>';
    }

    # copy the __DATA__ section to the output
    foreach my $Line (@PageData) {
        print $Line;
    }
    print $cgi->end_html;
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

.!!COMPONENTSTAG!!{
  margin-left: 50px;
  display: none;
}

.!!COMPONENTSTAG!!.active{
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

.!!CLOSEBTN!! {
  margin-left: 15px;
  color: white;
  font-weight: bold;
  float: right;
  font-size: 22px;
  line-height: 20px;
  cursor: pointer;
  transition: 0.3s;
}

.!!CLOSEBTN!!:hover {
  color: black;
}

/*   ------------------------------------------------------------- */
.!!ITEMLABEL!! {
    color: !!UNCHANGEDCOLOR!!;
    font-size: large;
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
function updatePounds(element, Pounds) {
    element.innerHTML = (parseFloat(element.innerHTML) + Pounds).toFixed(2);
}

function displaySaveButtonMaybe() {
    /* un-hide the "SAVE" button if changes were made */
    var SaveButton = document.getElementsByName('!!SAVEBUTTON!!');
    SaveButton[0].style.visibility = 'hidden';
    var checks = document.querySelectorAll("input[type=checkbox]");
    for (var i = 0; i < checks.length; i++){
        var ChkLabel = checks[i].parentNode.getElementsByClassName("!!ITEMLABEL!!")[0];
        if (ChkLabel.style.color == "!!CHANGEDCOLOR!!") {
            SaveButton[0].style.visibility = 'visible';
            break;
        }
    }
}

var checks = document.querySelectorAll("input[type=checkbox]");
for(var i = 0; i < checks.length; i++){
    /* add an event listener for all checkboxes */
    checks[i].addEventListener( 'change', function() {
        var ChkLabel = this.parentNode.getElementsByClassName("!!ITEMLABEL!!")[0];
        var CheckPounds = Math.round((parseFloat(ChkLabel.dataset.!!OUNCESTAG!!) * parseInt(ChkLabel.dataset.!!QUANTITYTAG!!) / 16) * 100) / 100;

        var OriginalCheckState = sessionStorage.getItem(this.name);
        if (( this.checked && OriginalCheckState == 0) ||
            (!this.checked && OriginalCheckState == 1)
           )
        {
            ChkLabel.style.color = "!!CHANGEDCOLOR!!";
        } else {
            ChkLabel.style.color = "!!UNCHANGEDCOLOR!!";
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

        /* update the category total */
        var Category = this.dataset.!!CATEGORYTAG!!;
        updatePounds(document.getElementById(Category), CheckPounds);

        /* update the total, inpack, and base weights */
        updatePounds(document.getElementById('!!TOTAL!!'), CheckPounds);
        if (Category != "!!NOTINPACK!!") {
            updatePounds(document.getElementById('!!INPACK!!'), CheckPounds);
            if (Category != "!!CONSUMABLES!!") {
                updatePounds(document.getElementById('!!BASE!!'), CheckPounds);
            }
        }
  
        displaySaveButtonMaybe();
    });
    /* show or hide the children of a checkbox (components)
     * and save the initial value of the checkboxes
     */
    if (checks[i].checked) {
        sessionStorage.setItem(checks[i].name, 1);
        showComponents(checks[i]);
    } else {
        sessionStorage.setItem(checks[i].name, 0);
        hideComponents(checks[i]);
    }
}

/*##########################################################################*/
function UpdateAddWeights() {
    var components = document.getElementsByName("!!ADDCOMPONENTNAME!!");
    var componentweights = document.getElementsByName("!!ADDCOMPONENTWEIGHTNAME!!");
    var addweight = document.getElementById("!!ADDWEIGHTNAME!!");
    var totalweight = 0;

    addweight.disabled = false;
    for(var i = 0; i < components.length; i++){
        if (components[i].value !== "") {
            addweight.disabled = true;
            componentweights[i].disabled = false;
            if (componentweights[i].value != "") {
                totalweight += parseFloat(componentweights[i].value);
            }
        } else {
            componentweights[i].value = "";
            componentweights[i].disabled = true;
        }
    }
    if (addweight.disabled) {
        addweight.value = totalweight.toFixed(2);
    }
}

/*##########################################################################*/
var addcomponents = document.getElementsByName("!!ADDCOMPONENTNAME!!");
for(var i = 0; i < addcomponents.length; i++){
    addcomponents[i].addEventListener('change', UpdateAddWeights);
}

/*##########################################################################*/
var addounces = document.getElementsByName("!!ADDCOMPONENTWEIGHTNAME!!");
for(var i = 0; i < addounces.length; i++){
    addounces[i].addEventListener('change', function() {
        var addweight = 0;
        var ComponentWeights = document.getElementsByName("!!ADDCOMPONENTWEIGHTNAME!!");
        for(var j = 0; j < ComponentWeights.length; j++){
            if (ComponentWeights[j].value === "") break;
            addweight += parseFloat(ComponentWeights[j].value);
        }
        document.getElementById("!!ADDWEIGHTNAME!!").value = addweight.toFixed(2);
    });
}

/*##########################################################################*/
var labels = document.getElementsByClassName("!!ITEMLABEL!!");
for(var i = 0; i < labels.length; i++){
    labels[i].addEventListener( 'dblclick', function() {
        var Label = this;
        var ChkBox = Label.parentNode.getElementsByTagName("input")[1];
        var components = Label.parentNode.getElementsByClassName("!!COMPONENTSTAG!!")
        document.getElementById("!!ADDCATEGORYNAME!!").value = ChkBox.dataset.!!CATEGORYTAG!!;
        document.getElementById("!!ADDITEMNAME!!").value = this.innerHTML;
        document.getElementById("!!ADDWEIGHTNAME!!").value = this.dataset.!!OUNCESTAG!!;
        document.getElementById("!!ADDQUANTITYNAME!!").value = this.dataset.!!QUANTITYTAG!!;
        var ComponentNames   = document.getElementsByName("!!ADDCOMPONENTNAME!!");
        var ComponentWeights = document.getElementsByName("!!ADDCOMPONENTWEIGHTNAME!!");
        var j;
        var k = 0;
        for(j = 0; j < components.length; j++){
            ComponentNames[k].value = components[j].innerHTML;
            ComponentWeights[k].value = components[j].dataset.!!OUNCESTAG!!;
            k++;
        }
        while (k < !!MAXCOMPONENTS!!) {
            ComponentNames[k].value = "";
            ComponentWeights[k].value = "";
            k++;
        }
        UpdateAddWeights();
    });
}

/*##########################################################################*/
/* un-hide the components of the checkbox that changed */
function showComponents(ChkBox) {
    var components = ChkBox.parentNode.getElementsByClassName("!!COMPONENTSTAG!!");
   
    for(var i = 0; i < components.length; i++){
      components[i].classList.add("active");      
    }
}

/*##########################################################################*/
/* hide the components of the checkbox that changed */
function hideComponents(ChkBox) {
    var components = ChkBox.parentNode.getElementsByClassName("!!COMPONENTSTAG!!");
   
    for(var i = 0; i < components.length; i++){
      components[i].classList.remove("active");      
    }
}

/*##########################################################################*/

var close = document.getElementsByClassName("!!CLOSEBTN!!");
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

