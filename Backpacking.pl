use strict;

# The Flags string contains "I" if the item is to be included on the hike.
# The Flags string contains "P" if the item is to be carried in the pack.
my %Categories = ( 
                    Hiking              => [
    { Item => "ULA OHM 2.0 63 Liter Pack",                         OZ => 34.50, Flags => "IP" },
    { Item => "Gregory Zulu 40 Liter Pack",                        OZ => 37.00, Flags => " P" },
    { Item => "Jack Wolfskin Yak III 90 Liter Pack",               OZ => 96.00, Flags => " P" },
    { Item => "Large Pack Rain Cover",                             OZ =>  8.00, Flags => " P" },
    { Item => "Osprey  32 Liter Pack",                             OZ => 40.00, Flags => " P" },
    { Item => "Trekking Poles",                                    OZ => 17.00, Flags => "I " },
    { Item => "Compass",                                           OZ =>  0.72, Flags => " P" },
    { Item => "Frog Togs Rain Gear",                               OZ => 14.00, Flags => " P" },
    { Item => "Maps",                                              OZ =>  2.20, Flags => "IP" },
    { Item => "Whistle",                                           OZ =>  0.31, Flags => "IP" },
    { Item => "Watch",                                             OZ =>  0.73, Flags => " P" },
    { Item => "Canon G7X Camera",                                  OZ => 11.30, Flags => "I " },
    { Item => "Hand held GPS",                                     OZ =>  7.00, Flags => "  " },
    { Item => "Cell phone",                                        OZ =>  7.00, Flags => "I " },
    { Item => "GoPro",                                             OZ =>  7.50, Flags => " P" },
                                           ],

                    Home                => [
    { Item => "Nemo Hornet 2 Person Tent",                                      Flags => "IP", 
        Components => { "Tent and fly" => 23,
                        "Poles" => 7.7,
                        "Stakes (6)" => 3.6,
                        "Stuff sacks" => 1.8,
                        "Tie-out chord" => 0.7,
                        "Pole repair tube" => 0.3
                      } },
    { Item => "Nemo Hornet 1 Person Tent",                                      Flags => " P",
        Components => {
                      "Tent and fly" => 18.72,
                      "Poles" => 6.6,
                      "Stakes (6)" => 3.2,
                      "Stuff sacks" => 1.63,
                      "Tie-out chord" => 1.04,
                      "Pole repair tube" => 0.316
                      } },
    { Item => "Hennesy Explorer Hammock",                                       Flags => " P",
        Components => {
                      "Tree straps" => 3.00,
                      "Hammock" => 27.10,
                      "Snake skins" => 3.50,
                      "Asym Tarp" => 10.30,
                      "Stakes (6)" => 2.59,
                      "Stuff sack" => 0.79
                      } },
    { Item => "Hennesy Hex Tarp",                                  OZ => 21.70, Flags => " P" },
    { Item => "Hennesy Supershelter ",                                          Flags => " P",
        Components => {
                      "Undercover" => 9.30,
                      "Foam pad" => 9.70,
                      "Reflective blanket" => 2.08,
                      "Stuff sack" => 0.79
                      } },
    { Item => "Tyvek Tent Footprint for Nemo Hornet 1",            OZ =>  6.30, Flags => " P" },
    { Item => "Tyvek Ground Sheet",                                OZ =>  2.70, Flags => " P" },
    { Item => "Down 40 Degree Quilt",                              OZ => 16.00, Flags => "IP" },
    { Item => "Down Sleeping Bag and Dry Bag",                     OZ => 43.50, Flags => " P" },
    { Item => "Thermolite Sleeping Bag Liner",                     OZ =>  9.00, Flags => " P" },
    { Item => "Hoback 60° Sleeping Bag",                           OZ => 35.00, Flags => " P" },
    { Item => "NeoAir Mattress",                                   OZ => 17.60, Flags => "IP" },
    { Item => "NeoAir Inflater",                                   OZ =>  1.90, Flags => "IP" },
    { Item => "Inflatable pillow",                                 OZ =>  3.11, Flags => "IP" },
    { Item => "Slumberjack pillow",                                OZ =>  5.50, Flags => " P" },
    { Item => "Head lamp",                                         OZ =>  2.17, Flags => "IP" },
    { Item => "Tablet computer for reading",                       OZ => 12.00, Flags => " P" },
    { Item => "Tarp",                                              OZ => 33.00, Flags => " P" },
    { Item => "Thermarest Chair",                                  OZ => 11.25, Flags => " P" },
    { Item => "Alite Monarch Butterfly Chair",                     OZ => 21.60, Flags => "IP" },
                                           ],

                    Kitchen             => [
    { Item => "JetBoil Stove",                                                  Flags => " P",
        Components => {
                      "JetBoil Pot" => 7.50,
                      "Burner" => 6.39,
                      "Plastic cup" => 1.05,
                      "Plastic lid" => 1.01,
                      "Gas can tripod" => 0.99
                      } },
    { Item => "Pop can alcohol stove",                                          Flags => " P",
        Components => {
                      "Stove" => 0.78,
                      "Pot stand" => 1.36,
                      "Wind screen" => 0.62,
                      "Stuff sack" => 0.37
                      } },
    { Item => "BRS Propane Stove",                                              Flags => "IP",
        Components => {
                      "Burner" => 0.88,
                      "Stuff sack" => 0.08
                      } },
    { Item => "Esbit Solid Fuel Stove (no pot)",                                Flags => " P",
        Components => {
                      "Burner" => 2.04,
                      "Stuff sack" => 0.37
                      } },
    { Item => "Esbit Pot",                                                      Flags => "IP",
        Components => {
                      "Pot" => 4.70,
                      "Lid" => 1.44,
                      "Reflectix Coozy" => 0.70,
                      "Stuff sack" => 0.47
                      } },
    { Item => "GSI Cook Kit",                                                   Flags => " P",
        Components => {
                      "Pot Grab" => 2.34,
                      "Large Pot" => 9.00,
                      "Large Lid" => 5.10,
                      "Small Pot" => 5.70,
                      "Small Lid" => 3.90,
                      "Stuff sack" => 1.00
                      } },
    { Item => "MSR Whisperlite Stove",                                          Flags => " P",
        Components => {
                      "Stove" => 9.75,
                      "Pump/Valve" => 1.85,
                      "Heat Reflector Foil" => 0.52,
                      "Wind screen" => 1.78,
                      "Maintenance tools" => 0.88,
                      "Stuff sack" => 0.72
                      } },
    { Item => "Mighty Lite stove stand",                           OZ =>  4.50, Flags => " P" },
    { Item => "Lixada Titanium Wood Stove",                        OZ => 12.20, Flags => " P" },
    { Item => "Wind screen",                                       OZ =>  0.70, Flags => " P" },
    { Item => "Collapsible drinking cup",                          OZ =>  1.56, Flags => "IP" },
    { Item => "Bear Bag",                                          OZ =>  1.53, Flags => "IP" },
    { Item => "Bear Cannister",                                    OZ => 43.60, Flags => " P" },
    { Item => "Platypus Liter Bottle",                  Qty =>  3, OZ =>  0.88, Flags => "IP" },
    { Item => "MSR Dromedary Bag (black)",                         OZ =>  6.50, Flags => " P" },
    { Item => "Pot scrub",                                         OZ =>  0.22, Flags => "IP" },
    { Item => "Dish towel",                                        OZ =>  0.20, Flags => "IP" },
    { Item => "Titanium Silverware",                                            Flags => " P",
        Components => {
                      "Spoon" => 0.54,
                      "Fork" => 0.39,
                      "Knife" => 0.43,
                      "Carabiner" => 0.09
                      } },
    { Item => "Sea to Summit Spoon",                               OZ =>  0.36, Flags => "IP" },
    { Item => "Plastic Spork",                                     OZ =>  0.36, Flags => " P" },
    { Item => "Pot grab",                                          OZ =>  1.54, Flags => " P" },
    { Item => "Blue enamel mug",                                   OZ =>  7.50, Flags => " P" },
    { Item => "Sawyer Squeeze water filter",                                    Flags => " P",
        Components => {
                      "Filter" => 2.53,
                      "Dirty water bottle" => 2.37,
                      "Back-flush adapter" => 0.50,
                      "Stuff sack" => 0.48
                      } },
    { Item => "Neck Knife",                                        OZ =>  2.02, Flags => "IP" },
    { Item => "Gerber Sheath Knife",                               OZ =>  7.50, Flags => " P" },
    { Item => "Gallon Zip-lock for food",                          OZ =>  0.01, Flags => "IP" },
                                           ],

                    Bathroom =>            [
    { Item => "Toothbrush",                                        OZ =>  0.76, Flags => "IP" },
    { Item => "Hand sanitizer",                                    OZ =>  2.17, Flags => "IP" },
    { Item => "Toilet paper",                                      OZ =>  2.50, Flags => "IP" },
    { Item => "Deuce Cat-hole trowel",                             OZ =>  0.60, Flags => "IP" },
    { Item => "Tek Pack Towel",                                    OZ =>  5.25, Flags => " P" },
    { Item => "Pharmaceuticals",                                   OZ =>  0.25, Flags => "IP" },
    { Item => "First aid kit",                                     OZ =>  7.40, Flags => " P" },
                                           ],

                    Clothing =>            [
    { Item => "Dry bag for clothing",                              OZ =>  1.53, Flags => "IP" },
    { Item => "Hiking socks",                                      OZ =>  3.37, Flags => "I " },
    { Item => "Spare socks",                                       OZ =>  3.37, Flags => " P" },
    { Item => "Light wool sweater",                                OZ => 14.00, Flags => "IP" },
    { Item => "Northface DNP Jacket",                              OZ => 12.00, Flags => "IP" },
    { Item => "Sandals",                                           OZ => 21.00, Flags => "IP" },
    { Item => "OR sun hat",                                        OZ =>  3.20, Flags => "  " },
    { Item => "Cotton T Shirt",                                    OZ => 12.00, Flags => "I " },
    { Item => "Underwear",                                         OZ =>  3.50, Flags => "I " },
    { Item => "Zip-off pants/shorts",                              OZ => 14.00, Flags => "I " },
    { Item => "Web Belt",                                          OZ =>  1.50, Flags => "I " },
    { Item => "Hiking boots",                                      OZ => 42.00, Flags => "I " },
                                           ],

                    Consumables =>         [
    { Item => "Liters water",                           Qty =>  2, OZ => 35.20, Flags => "IP" },
    { Item => "Hot Cocoa Mix",                          Qty =>  2, OZ =>  1.43, Flags => "IP" },
    { Item => "Instant Oatmel",                         Qty =>  1, OZ =>  1.66, Flags => "IP" },
    { Item => "Freeze Dried Beef Stroganoff",                      OZ =>  4.50, Flags => " P" },
    { Item => "Freeze Dried Scrambled Eggs",                       OZ =>  3.00, Flags => " P" },
    { Item => "Thin Oreos",                             Qty => 20, OZ => 0.275, Flags => " P" },
    { Item => "Oriental Trail Mix",                                OZ =>  9.50, Flags => " P" },
    { Item => "Cashews",                                           OZ =>  4.75, Flags => " P" },
    { Item => "100 grams JetBoil gas",                             OZ =>  7.00, Flags => "IP" },
    { Item => "16 oz. White gas",                                  OZ => 12.00, Flags => " P" },
    { Item => "13 oz alcohol fuel",                                OZ =>  8.30, Flags => " P" },
    { Item => "12 Esbit 14-gram fuel cubes",            Qty => 12, OZ =>  0.52, Flags => " P" },
    { Item => "22 fl. oz. White Gas bottle",                       OZ =>  5.25, Flags => " P" },
    { Item => "33 fl. oz. White Gas bottle",                       OZ =>  8.00, Flags => " P" },
                                           ],

                    Miscelaneous =>        [
    { Item => "Wallet",                                            OZ =>  5.00, Flags => "I " },
    { Item => "Sunglasses (clip on)",                              OZ =>  1.25, Flags => "I " },
    { Item => "Sunscreen",                                         OZ =>  1.78, Flags => " P" },
    { Item => "Lip Balm",                                          OZ =>  0.31, Flags => " P" },
    { Item => "Mosquito Repellent",                                OZ =>  2.12, Flags => " P" },
    { Item => "Mosquito Head Net",                                 OZ =>  0.25, Flags => " P" },
    { Item => "Spare AAA batteries",                    Qty =>  2, OZ =>  0.43, Flags => "IP" },
    { Item => "Schwinn LED light",                                 OZ =>  0.58, Flags => "IP" },
    { Item => "Fire Starter Kit",                                               Flags => "IP",
        Components => {
                      "Cigarette lighter" => 0.76,
                      "Flint and steel" => 0.92,
                      "Char cloth" => 1.77,
                      "Tinder" => 0.14,
                      } },
    { Item => "Fire blower tube",                                  OZ =>  1.05, Flags => "IP" },
    { Item => "Emergency blanket",                                 OZ =>  1.58, Flags => " P" },
    { Item => "Para-chord",                                        OZ =>  2.08, Flags => "IP" },
    { Item => "Cable ties, safety pins",                           OZ =>  0.95, Flags => "IP" },
    { Item => "Zip-locks for trash",                               OZ =>  0.96, Flags => "IP" },
                                           ],
                 );

my $TotalOunces = 0;
my $InPackOunces = 0;
my $WornOunces = 0;
my $BaseOunces = 0;

my %CategoryOunces;
my $Lines;
my @CategoryLines;
foreach my $C (sort keys %Categories) {
    $Lines = 0;
    $CategoryOunces{$C} = 0;
    foreach my $I (@{$Categories{$C}}) {
        if (index($I->{Flags}, 'I') >= 0) {
            $Lines++;
            if (defined $I->{Components}) {
                $I->{OZ} = 0;
                foreach my $P (keys %{$I->{Components}}) {
                    $Lines++;
                    $I->{OZ} += $I->{Components}->{$P};
                }
            }
            if (!defined $I->{Qty}) {
                $I->{Qty} = 1;
            }
            my $Ounces = $I->{OZ} * $I->{Qty};
            $CategoryOunces{$C} += $Ounces;
            if (index($I->{Flags}, 'P') >= 0) {
                $InPackOunces += $Ounces;
            } else {
                $WornOunces += $Ounces;
            }
            if ($C ne "Consumables" && index($I->{Flags}, 'P') >= 0) {
               $BaseOunces += $Ounces;
            }
        }
    }
    $TotalOunces += $CategoryOunces{$C};
    push @CategoryLines, [ $Lines, $C ];
}

@CategoryLines = sort {$a->[0] <=> $b->[0]} @CategoryLines;

print '<html>';
print '<body">';

print '<table style="width:80%" border="1">';
my @W = ( [ 'Total'     , $TotalOunces , 'black'  ], 
          [ 'In Pack'   , $InPackOunces, 'blue'   ],
          [ 'Worn'      , $WornOunces  , 'green'  ], 
          [ 'Base'      , $BaseOunces  , 'black'  ],
         );

print '<tr>';
foreach my $A (@W) {
    print     '<th>';
    print         '<p style="color:', $A->[2], ';font-size: x-large">';
    printf(       '%s %.2f lbs', $A->[0], $A->[1] / 16);
    print         '</p>';
    print     '</th>';
}
print '</tr>';
print '</table>';
print '<br><br>';

print '<table style="width:80%"border="1">';
print '<tr>';
my $CCount = 0;

my $NumberOfColumns = 3;

while (my $C = pop @CategoryLines) {
    $C = $C->[1];

    if ($CCount++ % $NumberOfColumns == 0) {
        print '</tr><tr>';
    }

    print '<td valign="top">';

    print '<p style="font-size: x-large">';
    printf("%-16s  %.2f lbs\n\n", $C, $CategoryOunces{$C} / 16 );
    print '</p>';
    print '<table style=width:100%>';
    foreach my $I (@{$Categories{$C}}) {
        if (index($I->{Flags}, 'I') >= 0) {
            my $Description;
            if ($I->{Qty} != 1) {
                $Description = sprintf("%d-%s", $I->{Qty}, $I->{Item});
            } else {
                $Description = $I->{Item};
            }
            print '<tr>';
            print     '<td>';
            print         '<p style="color:', index($I->{Flags}, 'P') >= 0 ? 'blue' : 'green', ';font-size: x-large">';
            print           $Description;
            print         '</p>';
            print     '</td>';
            print     '<td>';
            print         '<p style="text-align: right;font-size: x-large">';
            printf(           '%.2f', $I->{OZ} * $I->{Qty});
            print         '</p>';
            print     '</td>';
            print '</tr>';
            if (defined $I->{Components}) {
                foreach my $P (sort keys %{$I->{Components}}) {
                    print '<tr>';
                    print     '<td>';
                    print         '<p style="text-indent: 40px;font-size: x-large">';
                    print             $P;
                    print         '</p>';
                    print     '</td>';
                    print '</tr>';
                }
            }
        }
    }
    print '</table>';
    print '</td>';
}
print '</tr>';
print '</table>';

print '</body>';
print '</html>';

