# frozen_string_literal: true

module Engine
  module Game
    module G18HN
      module Map
        TILES = {
          '3' => 4,
          '4' => 6,
          '5' => 4,
          '6' => 6,
          '7' => 4,
          '8' => 14,
          '9' => 10,
          '16' => 1,
          '19' => 1,
          '20' => 1,
          '23' => 3,
          '24' => 3,
          '25' => 3,
          '26' => 1,
          '27' => 1,
          '28' => 1,
          '29' => 1,
          '30' => 1,
          '31' => 1,
          '39' => 1,
          '40' => 1,
          '41' => 1,
          '42' => 1,
          '43' => 1,
          '44' => 1,
          '45' => 2,
          '46' => 2,
          '47' => 2,
          '57' => 5,
          '58' => 8,
          '70' => 1,
          '141' => 3,
          '142' => 3,
          '143' => 3,
          '144' => 3,
          '441' => 3,
          '442' => 3,
          '443' => 3,
          '444' => 3,
          '448' => 3,
          '449' => 2,
          '450' => 3,
          '767' => 4,
          '768' => 3,
          '769' => 3,
          '920' =>
          {
            'count' => 1,
            'color' => 'yellow',
            'code' => 'city=revenue:30;label=MZ;path=a:0,b:_0;path=a:1,b:_0',
          },
          '921' =>
          {
            'count' => 1,
            'color' => 'yellow',
            'code' => 'city=revenue:30;city=revenue:30;city=revenue:30;label=F/W;path=a:1,b:_0;path=a:3,b:_1;path=a:5,b:_2;' \
                      'path=a:4,b:_0,track:narrow;path=a:4,b:_1,track:narrow;path=a:4,b:_2,track:narrow',
          },
          '922' =>
          {
            'count' => 1,
            'color' => 'yellow',
            'code' => 'city=revenue:30;label=F/E;path=a:1,b:_0,track:narrow;path=a:4,b:_0',
          },
          '923' =>
          {
            'count' => 1,
            'color' => 'green',
            'code' => 'city=revenue:50;label=F/W;path=a:1,b:_0;path=a:3,b:_0;path=a:4,b:_0,track:narrow;path=a:5,b:_0',
          },
          '924' =>
          {
            'count' => 1,
            'color' => 'green',
            'code' => 'city=revenue:50;label=F/E;path=a:1,b:_0,track:narrow;path=a:4,b:_0;path=a:5,b:_0',
          },
          '925' =>
          {
            'count' => 1,
            'color' => 'brown',
            'code' => 'city=revenue:60;label=F/W;path=a:0,b:_0;path=a:1,b:_0;path=a:2,b:_0;path=a:3,b:_0;' \
                      'path=a:4,b:_0,track:narrow;path=a:5,b:_0',
          },
          '926' =>
          {
            'count' => 1,
            'color' => 'brown',
            'code' => 'city=revenue:60;label=F/E;path=a:0,b:_0;path=a:1,b:_0,track:narrow;path=a:3,b:_0;path=a:4,b:_0;' \
                      'path=a:5,b:_0',
          },
          '927' =>
          {
            'count' => 1,
            'color' => 'yellow',
            'code' => 'city=revenue:30;label=KGD;path=a:0,b:_0;path=a:3,b:_0;path=a:4,b:_0',
          },
          '928' =>
          {
            'count' => 1,
            'color' => 'yellow',
            'code' => 'city=revenue:30;label=KGD;path=a:0,b:_0;path=a:3,b:_0;path=a:5,b:_0',
          },
          '929' =>
          {
            'count' => 1,
            'color' => 'yellow',
            'code' => 'city=revenue:30;label=KGD;path=a:0,b:_0;path=a:4,b:_0;path=a:5,b:_0',
          },
          '930' =>
          {
            'count' => 1,
            'color' => 'yellow',
            'code' => 'city=revenue:30;label=KGD;path=a:0,b:_0;path=a:2,b:_0;path=a:4,b:_0',
          },
          '931' =>
          {
            'count' => 1,
            'color' => 'green',
            'code' => 'city=revenue:40,slots:2;label=KGD;path=a:0,b:_0;path=a:1,b:_0;path=a:2,b:_0;path=a:3,b:_0',
          },
          '932' =>
          {
            'count' => 1,
            'color' => 'green',
            'code' => 'city=revenue:40,slots:2;label=KGD;path=a:0,b:_0;path=a:2,b:_0;path=a:3,b:_0;path=a:5,b:_0',
          },
          '933' =>
          {
            'count' => 2,
            'color' => 'green',
            'code' => 'city=revenue:40,slots:2;label=KGD;path=a:0,b:_0;path=a:2,b:_0;path=a:3,b:_0;path=a:4,b:_0',
          },
          '934' =>
          {
            'count' => 1,
            'color' => 'green',
            'code' => 'city=revenue:40,slots:2;label=MZ;path=a:0,b:_0;path=a:1,b:_0',
          },
          '935' =>
          {
            'count' => 1,
            'color' => 'brown',
            'code' => 'city=revenue:50,slots:3;label=MZ;path=a:0,b:_0;path=a:1,b:_0',
          },
          '936' =>
          {
            'count' => 3,
            'color' => 'brown',
            'code' => 'city=revenue:50,slots:3;label=KGD;path=a:0,b:_0;path=a:1,b:_0;path=a:2,b:_0;path=a:3,b:_0;path=a:4,b:_0;' \
                      'path=a:5,b:_0',
          },
          '939' =>
          {
            'count' => 1,
            'color' => 'brown',
            'code' => 'town=revenue:10;label=Hom;path=a:0,b:_0;path=a:1,b:_0;path=a:2,b:_0;path=a:4,b:_0;path=a:5,b:_0',
          },
        }.freeze

        LOCATION_NAMES = {
          'A18' => 'Bad Karlshafen',
          'B15' => 'Arolsen',
          'B17' => 'Hofgeismar',
          'C14' => 'Korbach',
          'C18' => 'Kassel',
          'D15' => 'Bad Wildungen',
          'D17' => 'Fritzlar',
          'D21' => 'Eschwege',
          'E14' => 'Frankenberg',
          'E18' => 'Bad Hersfeld',
          'E17' => 'Cleveland',
          'F9' => 'Dillenburg',
          'F11' => 'Biedenkopf',
          'F13' => 'Marburg',
          'F17' => 'Alsfeld',
          'G4' => 'Montabaur',
          'G10' => 'Wetzlar',
          'G12' => 'Gießen',
          'G14' => 'Grünberg',
          'G18' => 'Lauterbach',
          'G20' => 'Fulda',
          'H5' => 'Bad Ems',
          'H7' => 'Limburg',
          'H9' => 'Weilburg',
          'H13' => 'Bad Nauheim',
          'I8' => 'Idstein',
          'I10' => 'Bad Homburg',
          'I12' => 'Friedber',
          'I16' => 'Gellnhausen',
          'J5' => 'Rüdesheim',
          'J9' => 'Wiesbaden',
          'J11' => 'Frankfurt/Main West',
          'J13' => 'Frankfurt/Main Ost',
          'J15' => 'Hanau',
          'K4' => 'Bingen',
          'K8' => 'Mainz',
          'K10' => 'Rüsselsheim',
          'K14' => 'Offenbach',
          'L9' => 'Groß-Gerau',
          'L11' => 'Darmstadt',
          'M6' => 'Alzey',
          'N9' => 'Worms',
          'N11' => 'Bensheim',
          'N13' => 'Michelstadt',
          'O12' => 'Neckarsteinach',
          # Red city names
          'G2' => 'Rheinland',
          'J3' => 'Rheinland',
          'E10' => 'Südwestfalen',
          'B11' => 'Ostwestfalen',
          'B19' => 'Hannover',
          'E22' => 'Thüringen',
          'F23' => 'Thüringen',
          'G22' => 'Thüringen',
          'K16' => 'Franken',
          'N5' => 'Pfalz',
          'O8' => 'Pfalz',
          'O10' => 'Baden',

        }.freeze

        HEXES = {
          white: {
            ['E16'] => 'frame=color:plum',
            ['L5'] => 'frame=color:white',
            ['L13'] => 'frame=color:white',
            ['N7'] => 'frame=color:white',
            ['H13'] => 'town=revenue:0;frame=color:white',
            ['M6'] => 'town=revenue:0;frame=color:white',
            ['C20'] => 'upgrade=cost:20,terrain:water;frame=color:plum',
            ['F19'] => 'upgrade=cost:20,terrain:water;frame=color:plum',
            ['H3'] => 'upgrade=cost:20,terrain:water;frame=color:lightgreen',
            ['C12'] => 'upgrade=cost:40,terrain:mountain;frame=color:yellow',
            ['D19'] => 'upgrade=cost:40,terrain:mountain;frame=color:plum',
            ['E20'] => 'upgrade=cost:40,terrain:mountain;frame=color:plum',
            ['F5'] => 'upgrade=cost:40,terrain:mountain;frame=color:lightgreen',
            ['F7'] => 'upgrade=cost:40,terrain:mountain;frame=color:lightgreen',
            ['F21'] => 'upgrade=cost:40,terrain:mountain;frame=color:plum',
            ['G6'] => 'upgrade=cost:40,terrain:mountain;frame=color:lightgreen',
            ['I4'] => 'upgrade=cost:40,terrain:mountain;label=T;frame=color:lightgreen',
            ['I6'] => 'upgrade=cost:40,terrain:mountain;label=T;frame=color:lightgreen',
            ['M12'] => 'upgrade=cost:40,terrain:mountain;label=O;frame=color:white',
            ['A18'] => 'town=revenue:0;upgrade=cost:20,terrain:water;frame=color:plum',
            ['H5'] => 'town=revenue:0;upgrade=cost:20,terrain:water;frame=color:lightgreen',
            ['G4'] => 'town=revenue:0;upgrade=cost:40,terrain:mountain;frame=color:lightgreen',
            ['O12'] => 'town=revenue:0;upgrade=cost:40,terrain:mountain;label=O;frame=color:white',
            ['N13'] => 'town=revenue:0;upgrade=cost:40,terrain:mountain;label=O;frame=color:white',
            ['E18'] => 'city=revenue:0;upgrade=cost:20,terrain:water;frame=color:plum',
            ['H7'] => 'city=revenue:0;upgrade=cost:20,terrain:water;frame=color:lightgreen',
            ['C18'] => 'city=revenue:0;upgrade=cost:20,terrain:water;label=KGD;frame=color:plum',
            ['B15'] => 'town=revenue:0;frame=color:yellow',
            ['B17'] => 'town=revenue:0;frame=color:plum',
            ['C14'] => 'city=revenue:0;frame=color:yellow',
            ['C16'] => 'city=revenue:0;frame=color:plum',
            ['D13'] => 'upgrade=cost:20,terrain:water;frame=color:yellow',
            ['D15'] => 'town=revenue:0;upgrade=cost:60,terrain:water|mountain;' \
                       'border=edge:0,type:impassable;border=edge:1,type:impassable;frame=color:yellow',
            ['D17'] => 'town=revenue:0;upgrade=cost:20,terrain:water;frame=color:plum',
            ['D21'] => 'city=revenue:0;upgrade=cost:40,terrain:mountain;frame=color:plum',
            ['E12'] => 'upgrade=cost:20,terrain:water;frame=color:yellow',
            ['E14'] => 'city=revenue:0;upgrade=cost:20,terrain:water;border=edge:3,type:impassable;frame=color:plum',
            ['F9'] => 'town=revenue:0;upgrade=cost:20,terrain:water;frame=color:lightgreen',
            ['F11'] => 'town=revenue:0;upgrade=cost:60,terrain:water|mountain;frame=color:white',
            ['F13'] => 'city=revenue:0;upgrade=cost:20,terrain:water;frame=color:plum',
            ['F15'] => 'frame=color:plum',
            ['F17'] => 'city=revenue:10;path=a:5,b:_0;frame=color:white',
            ['G8'] => 'upgrade=cost:40,terrain:mountain;frame=color:lightgreen',
            ['G12'] => 'city=revenue:0;upgrade=cost:20,terrain:water;frame=color:white;label=KGD',
            ['G14'] => 'town=revenue:0;frame=color:white',
            ['G16'] => 'upgrade=cost:40,terrain:mountain;frame=color:white',
            ['G18'] => 'town=revenue:0;upgrade=cost:40,terrain:mountain;frame=color:white',
            ['G20'] => 'city=revenue:0;upgrade=cost:20,terrain:water;frame=color:plum',
            ['H9'] => 'town=revenue:0;upgrade=cost:20,terrain:water;frame=color:lightgreen',
            ['H11'] => 'upgrade=cost:40,terrain:mountain;frame=color:white',
            ['H15'] => 'frame=color:white',
            ['H17'] => 'frame=color:white',
            ['H19'] => 'frame=color:plum',
            ['I8'] => 'town=revenue:0;upgrade=cost:40,terrain:mountain;frame=color:lightgreen;label=T',
            ['I12'] => 'town=revenue:0;frame=color:white',
            ['I14'] => 'frame=color:white',
            ['I16'] => 'town=revenue:0;frame=color:plum',
            ['I18'] => 'frame=color:plum',
            ['J5'] => 'city=revenue:0;border=edge:0,type:water,cost:60;border=edge:5,type:impassable;frame=color:lightgreen',
            ['J7'] => 'border=edge:0,type:impassable;border=edge:5,type:impassable;frame=color:lightgreen',
            ['J9'] => 'city=revenue:0;border=edge:0,type:water,cost:60;border=edge:5,type:water,cost:60;' \
                      'frame=color:lightgreen',
            ['J11'] => 'city=revenue:0;path=a:4,b:_0,track:narrow;label=F/W',
            ['J13'] => 'city=revenue:0;path=a:1,b:_0,track:narrow;label=F/E',
            ['J15'] => 'city=revenue:0;upgrade=cost:20,terrain:water;frame=color:plum',
            ['K4'] => 'city=revenue:0;upgrade=cost:20,terrain:water;border=edge:3,type:water,cost:60;frame=color:white',
            ['K6'] => 'border=edge:2,type:impassable;border=edge:3,type:impassable;frame=color:white',
            ['K8'] => 'city=revenue:10;path=a:1,b:_0;border=edge:3,type:water,cost:60;frame=color:white;' \
                      'border=edge:4,type:water,cost:60;border=edge:5,type:water,cost:60;border=edge:2,type:impassable;label=MZ',
            ['K10'] => 'town=revenue:0;border=edge:1,type:water,cost:60;frame=color:white;' \
                       'border=edge:2,type:water,cost:60',
            ['K12'] => 'frame=color:white',
            ['K14'] => 'city=revenue:0;frame=color:white',
            ['L7'] => 'border=edge:4,type:impassable;frame=color:white',
            ['L9'] => 'town=revenue:0;border=edge:0,type:impassable;border=edge:1,type:impassable;' \
                      'border=edge:2,type:water,cost:60;frame=color:white',
            ['L11'] => 'city=revenue:0;label=KGD;frame=color:white',
            ['M8'] => 'border=edge:3,type:impassable;border=edge:4,type:impassable;frame=color:white',
            ['M10'] => 'border=edge:0,type:impassable;border=edge:1,type:impassable;frame=color:white',
            ['N9'] => 'city=revenue:0;border=edge:3,type:impassable;border=edge:4,type:water,cost:60;frame=color:white',
            ['N11'] => 'city=revenue:0;border=edge:1,type:water,cost:60;frame=color:white',
          },
          red: {
            ['B11'] => 'offboard=revenue:yellow_30|green_40|brown_50;path=a:5,b:_0;icon=image:18_hn/N,sticky:1',
            ['B19'] => 'offboard=revenue:yellow_30|green_40|brown_50;path=a:0,b:_0;path=a:2,b:_0;icon=image:18_hn/N,sticky:1',
            ['E10'] => 'offboard=revenue:yellow_20|green_30|brown_40;path=a:0,b:_0;path=a:5,b:_0;icon=image:18_hn/W,sticky:1',
            ['K16'] => 'offboard=revenue:yellow_20|green_30|brown_50;path=a:1,b:_0;path=a:2,b:_0;icon=image:18_hn/O,sticky:1',
            ['N5'] => 'offboard=revenue:yellow_20|green_30|brown_50,groups:Pfalz,hide:1;path=a:3,b:_0;border=edge:5',
            ['O6'] => 'offboard=revenue:yellow_20|green_30|brown_50,groups:Pfalz;border=edge:2;border=edge:4;'\
                      'icon=image:18_hn/S,sticky:1',
            ['O8'] => 'offboard=revenue:yellow_20|green_30|brown_50,groups:Pfalz,hide:1;path=a:2,b:_0;path=a:3,b:_0;' \
                      'border=edge:1',
            ['E22'] => 'offboard=revenue:yellow_30|green_40|brown_50,groups:Thüringen,hide:1;path=a:2,b:_0;border=edge:5',
            ['F23'] => 'offboard=revenue:yellow_30|green_40|brown_50,groups:Thüringen;path=a:1,b:_0;border=edge:0;border=edge:2;'\
                       'icon=image:18_hn/O,sticky:1',
            ['G22'] => 'offboard=revenue:yellow_30|green_40|brown_50,groups:Thüringen,hide:1;path=a:1,b:_0;border=edge:3',
            ['O10'] => 'offboard=revenue:yellow_30|green_40|brown_50;path=a:3,b:_0;path=a:4,b:_0;icon=image:18_hn/S,sticky:1',
            ['G2'] => 'offboard=revenue:yellow_30|green_50|brown_60,groups:Rheinland,hide:1;path=a:4,b:_0;' \
                      'path=a:5,b:_0;border=edge:0',
            ['H1'] => 'offboard=revenue:yellow_30|green_50|brown_60,groups:Rheinland;border=edge:3;border=edge:5;'\
                      'icon=image:18_hn/W,sticky:1',
            ['I2'] => 'offboard=revenue:0,groups:Rheinland,hide:1;border=edge:2;border=edge:5',
            ['J3'] => 'offboard=revenue:yellow_30|green_50|brown_60,groups:Rheinland,hide:1;path=a:5,b:_0;border=edge:2',
          },
          green: {
            ['I10'] => 'town=revenue:0;upgrade=cost:40,terrain:mountain;label=Hom',
          },
          brown: {
            ['G10'] => 'city=revenue:yellow_20|green_30|brown_40;path=a:2,b:_0;path=a:4,b:_0;path=a:6,b:_0',
          },
        }.freeze
        LAYOUT = :pointy
        def show_map_legend?
          true
        end

        def map_legend(font_color, *_extra_colors)
          [
            # table-wide props
            {
              style: {
                margin: '0.5rem 0 0.5rem 0',
                border: '1px solid',
                borderCollapse: 'collapse',
              },
            },
            # header
            [
              { text: 'Ausland', props: { style: { border: '1px solid' } } },
              { text: 'S', props: { style: { border: '1px solid' } } },
              { text: 'N', props: { style: { border: '1px solid' } } },
              { text: 'O', props: { style: { border: '1px solid' } } },
              { text: 'W', props: { style: { border: '1px solid' } } },
            ],
            # body
            [
              {
                text: 'Pfalz S',
                props: { style: { border: "1px solid #{font_color}", color: 'white', backgroundColor: 'grey' } },
              },
              {
                text: '+10',
                props: {
                  style: {
                    textAlign: 'center',
                    border: "1px solid #{font_color}",
                    color: 'white',
                    backgroundColor: 'grey',
                  },
                },
              },
              {
                text: '+40',
                props: {
                  style: {
                    textAlign: 'right',
                    border: "1px solid #{font_color}",
                    color: 'white',
                    backgroundColor: 'grey',
                  },
                },
              },
              {
                text: '+30',
                props: {
                  style: {
                    textAlign: 'right',
                    border: "1px solid #{font_color}",
                    color: 'white',
                    backgroundColor: 'grey',
                  },
                },
              }, {
                text: '+20',
                props: {
                  style: {
                    textAlign: 'right',
                    border: "1px solid #{font_color}",
                    color: 'white',
                    backgroundColor: 'grey',
                  },
                },
              }
            ],
            [
              {
                text: 'Baden S',
                props: { style: { border: "1px solid #{font_color}", color: 'black', backgroundColor: 'white' } },
              },
              {
                text: '+10',
                props: {
                  style: {
                    textAlign: 'center',
                    border: "1px solid #{font_color}",
                    color: 'black',
                    backgroundColor: 'white',
                  },
                },
              },
              {
                text: '+40',
                props: {
                  style: {
                    textAlign: 'right',
                    border: "1px solid #{font_color}",
                    color: 'black',
                    backgroundColor: 'white',
                  },
                },
              },
              {
                text: '+20',
                props: {
                  style: {
                    textAlign: 'right',
                    border: "1px solid #{font_color}",
                    color: 'black',
                    backgroundColor: 'white',
                  },
                },
              }, {
                text: '+30',
                props: {
                  style: {
                    textAlign: 'right',
                    border: "1px solid #{font_color}",
                    color: 'black',
                    backgroundColor: 'white',
                  },
                },
              }
            ],
            [
              {
                text: 'Hannover N',
                props: { style: { border: "1px solid #{font_color}", color: 'white', backgroundColor: 'grey' } },
              },
              {
                text: '+40',
                props: {
                  style: {
                    textAlign: 'center',
                    border: "1px solid #{font_color}",
                    color: 'white',
                    backgroundColor: 'grey',
                  },
                },
              },
              {
                text: '+20',
                props: {
                  style: {
                    textAlign: 'right',
                    border: "1px solid #{font_color}",
                    color: 'white',
                    backgroundColor: 'grey',
                  },
                },
              },
              {
                text: '+20',
                props: {
                  style: {
                    textAlign: 'right',
                    border: "1px solid #{font_color}",
                    color: 'white',
                    backgroundColor: 'grey',
                  },
                },
              }, {
                text: '+20',
                props: {
                  style: {
                    textAlign: 'right',
                    border: "1px solid #{font_color}",
                    color: 'white',
                    backgroundColor: 'grey',
                  },
                },
              }
            ],
            [
              {
                text: 'Ostwestfalen N',
                props: { style: { border: "1px solid #{font_color}", color: 'black', backgroundColor: 'white' } },
              },
              {
                text: '+40',
                props: {
                  style: {
                    textAlign: 'center',
                    border: "1px solid #{font_color}",
                    color: 'black',
                    backgroundColor: 'white',
                  },
                },
              },
              {
                text: '+10',
                props: {
                  style: {
                    textAlign: 'right',
                    border: "1px solid #{font_color}",
                    color: 'black',
                    backgroundColor: 'white',
                  },
                },
              },
              {
                text: '+30',
                props: {
                  style: {
                    textAlign: 'right',
                    border: "1px solid #{font_color}",
                    color: 'black',
                    backgroundColor: 'white',
                  },
                },
              }, {
                text: '+20',
                props: {
                  style: {
                    textAlign: 'right',
                    border: "1px solid #{font_color}",
                    color: 'black',
                    backgroundColor: 'white',
                  },
                },
              }
            ], [
              {
                text: 'Südwestfalen W',
                props: { style: { border: "1px solid #{font_color}", color: 'white', backgroundColor: 'grey' } },
              },
              {
                text: '+20',
                props: {
                  style: {
                    textAlign: 'center',
                    border: "1px solid #{font_color}",
                    color: 'white',
                    backgroundColor: 'grey',
                  },
                },
              },
              {
                text: '+20',
                props: {
                  style: {
                    textAlign: 'right',
                    border: "1px solid #{font_color}",
                    color: 'white',
                    backgroundColor: 'grey',
                  },
                },
              },
              {
                text: '+20',
                props: {
                  style: {
                    textAlign: 'right',
                    border: "1px solid #{font_color}",
                    color: 'white',
                    backgroundColor: 'grey',
                  },
                },
              }, {
                text: '+20',
                props: {
                  style: {
                    textAlign: 'right',
                    border: "1px solid #{font_color}",
                    color: 'white',
                    backgroundColor: 'grey',
                  },
                },
              }
            ],
            [
              {
                text: 'Rheinland W',
                props: { style: { border: "1px solid #{font_color}", color: 'black', backgroundColor: 'white' } },
              },
              {
                text: '+10',
                props: {
                  style: {
                    textAlign: 'center',
                    border: "1px solid #{font_color}",
                    color: 'black',
                    backgroundColor: 'white',
                  },
                },
              },
              {
                text: '+60',
                props: {
                  style: {
                    textAlign: 'right',
                    border: "1px solid #{font_color}",
                    color: 'black',
                    backgroundColor: 'white',
                  },
                },
              },
              {
                text: '+40',
                props: {
                  style: {
                    textAlign: 'right',
                    border: "1px solid #{font_color}",
                    color: 'black',
                    backgroundColor: 'white',
                  },
                },
              }, {
                text: '+20',
                props: {
                  style: {
                    textAlign: 'right',
                    border: "1px solid #{font_color}",
                    color: 'black',
                    backgroundColor: 'white',
                  },
                },
              }
            ], [
              {
                text: 'Thüringen O',
                props: { style: { border: "1px solid #{font_color}", color: 'white', backgroundColor: 'grey' } },
              },
              {
                text: '+30',
                props: {
                  style: {
                    textAlign: 'center',
                    border: "1px solid #{font_color}",
                    color: 'white',
                    backgroundColor: 'grey',
                  },
                },
              },
              {
                text: '+10',
                props: {
                  style: {
                    textAlign: 'right',
                    border: "1px solid #{font_color}",
                    color: 'white',
                    backgroundColor: 'grey',
                  },
                },
              },
              {
                text: '+20',
                props: {
                  style: {
                    textAlign: 'right',
                    border: "1px solid #{font_color}",
                    color: 'white',
                    backgroundColor: 'grey',
                  },
                },
              }, {
                text: '+30',
                props: {
                  style: {
                    textAlign: 'right',
                    border: "1px solid #{font_color}",
                    color: 'white',
                    backgroundColor: 'grey',
                  },
                },
              }
            ],
            [
              {
                text: 'Franken O',
                props: { style: { border: "1px solid #{font_color}", color: 'black', backgroundColor: 'white' } },
              },
              {
                text: '+10',
                props: {
                  style: {
                    textAlign: 'center',
                    border: "1px solid #{font_color}",
                    color: 'black',
                    backgroundColor: 'white',
                  },
                },
              },
              {
                text: '+40',
                props: {
                  style: {
                    textAlign: 'right',
                    border: "1px solid #{font_color}",
                    color: 'black',
                    backgroundColor: 'white',
                  },
                },
              },
              {
                text: '+30',
                props: {
                  style: {
                    textAlign: 'right',
                    border: "1px solid #{font_color}",
                    color: 'black',
                    backgroundColor: 'white',
                  },
                },
              }, {
                text: '+20',
                props: {
                  style: {
                    textAlign: 'right',
                    border: "1px solid #{font_color}",
                    color: 'black',
                    backgroundColor: 'white',
                  },
                },
              }
            ]
          ]
        end
      end
    end
  end
end
