# frozen_string_literal: true

require_relative 'entities'
require_relative 'corporation'
require_relative 'map'
require_relative 'meta'
require_relative '../base'

module Engine
  module Game
    module G18HN
      class Game < Game::Base
        include_meta(G18HN::Meta)
        include G18HN::Entities
        include G18HN::Map

        GAME_END_CHECK = { bankrupt: :immediate, bank: :current_or }.freeze

        CURRENCY_FORMAT_STR = '%sM'

        STARTING_CASH = { 3 => 800, 4 => 600, 5 => 500 }.freeze

        SELL_AFTER = :after_sr_floated

        SELL_MOVEMENT = :down_block

        SELL_BUY_ORDER = :sell_buy

        CERT_LIMIT = { 3 => 29, 4 => 21, 5 => 17 }.freeze

        HOME_TOKEN_TIMING = :operate

        RIGHT_COST = 40
        MUST_BUY_TRAIN = :always

        CORPORATIONS_OPERATING_RIGHTS = {
          'FWN' => %w[KAS WAL],
          'FHB' => 'KAS',
          'LTB' => 'NAS',
          'WEG' => 'NAS',
          'MWB' => %w[KAS DAR],
          'WLB' => %w[WAL KAS],
          'SB' => 'DAR',
          'HLB' => 'DAR',
          'MNB' => 'DAR',
          'VB' => 'DAR',
        }.freeze

        NATIONAL_REGION_HEXES = {
          'KAS' => %w[A18 B17 C16 C18 C20 D17 D19 D21 E14 E16 E18 E20 F13 F15 F19 F21 G20 H19 I16 I18 J15],
          'HKC' => %w[A18 B17 C16 C18 C20 D17 D19 D21 E14 E16 E18 E20 F13 F15 F19 F21 G20 H19 I16 I18 J15],
          'WAL' => %w[B15 C12 C14 D13 D15],
          'DAR' => %w[f11 F17 G12 G14 G16 G18 H11 H13 H15 H17 I12 I14 K4 K6 K8 K10 K12 K14 L5 L7 L9 L11 L13 M6 M8 M10 M12 N7 N9
                      N11 N13 O12],
          'NAS' => %w[F5 F7 F9 F11 G4 G6 G8 H3 H5 H7 H9 I4 I6 I8 J5 J7 J9],
          'ALL' => %w[B11 B19 E10 E22 F23 G22 G2 G10 J3 J11 J13 K16 N5 O8 O10],
        }.freeze

        MARKET = [
          ['', '', '85', '90', '100p', '110', '120', '130', '140', '160', '180', '200', '225', '250', '275', '300', '325', '350',
           '375', '400'],
          ['', '75', '80', '85', '90p', '100', '110', '120', '130', '140', '160', '180', '200', '225', '250', '275', '300', '325',
           '350', '375'],
          %w[65 70 75 80 85p 90 100 110 120 130 140 160 180 200 225 250 275 300],
          %w[60 65 70 75 80p 85 90 100 110 120 130 140 160 180 200],
          %w[55 60 65 70 75p 80 85 90 100 110 120 130],
          %w[50 55 60 65 70p 75 80 85 90 100],
          %w[45 50 55 60 65 70 75 80],
          %w[40 45 50 55 60 65],
        ].freeze

        PHASES = [
          {
            name: '2',
            train_limit: 4,
            tiles: [:yellow],
            operating_rounds: 1,
          },
          {
            name: '3',
            on: '3',
            train_limit: 4,
            tiles: %i[yellow green],
            operating_rounds: 2,
          },
          {
            name: '4',
            on: '4',
            train_limit: 3,
            tiles: %i[yellow green],
            operating_rounds: 2,
          },
          {
            name: '5',
            on: '5',
            train_limit: 2,
            tiles: %i[yellow green brown],
            operating_rounds: 3,
          },
          {
            name: '6',
            on: '6',
            train_limit: 2,
            tiles: %i[yellow green brown],
            operating_rounds: 3,
          },
        ].freeze

        TRAINS = [
          {
            name: '2',
            distance: 2,
            price: 80,
            rusts_on: '4',
            num: 9,
            variants: [
              {
                name: '2+2',
                distance: [{ 'nodes' => ['town'], 'pay' => 2, 'visit' => 2 },
                           { 'nodes' => %w[city offboard town], 'pay' => 2, 'visit' => 2 }],
                price: 100,
              },
            ],
          },
          {
            name: '3',
            distance: 3,
            price: 150,
            rusts_on: '6',
            num: 6,
            variants: [
              {
                name: '3+3',
                distance: [{ 'nodes' => ['town'], 'pay' => 3, 'visit' => 3 },
                           { 'nodes' => %w[city offboard town], 'pay' => 3, 'visit' => 3 }],
                price: 180,
              },
            ],
          },
          {
            name: '4',
            distance: 4,
            price: 320,
            num: 5,
            variants: [
              {
                name: '4+4',
                distance: [{ 'nodes' => ['town'], 'pay' => 4, 'visit' => 4 },
                           { 'nodes' => %w[city offboard town], 'pay' => 4, 'visit' => 4 }],
                price: 400,
              },
            ],
          },
          {
            name: '5',
            distance: 5,
            price: 450,
            num: 4,
            events: [{ 'type' => 'close_companies' }],
            variants: [
              {
                name: '5+5',
                distance: [{ 'nodes' => ['town'], 'pay' => 5, 'visit' => 5 },
                           { 'nodes' => %w[city offboard town], 'pay' => 5, 'visit' => 5 }],
                price: 550,
              },
            ],
          },
          {
            name: '6',
            distance: 6,
            price: 600,
            num: 11,
            variants: [
              {
                name: '6+6',
                distance: [{ 'nodes' => ['town'], 'pay' => 6, 'visit' => 6 },
                           { 'nodes' => %w[city offboard town], 'pay' => 6, 'visit' => 6 }],
                price: 720,
              },
            ],
          },
        ].freeze
        def corporation_show_individual_reserved_shares?
          false
        end

        def umtausch?(entity)
          umtausch.include?(entity)
        end

        def nassau
          @nassau ||= company_by_id('NC')
        end

        def darmstadt
          @darmstadt ||= company_by_id('HDC')
        end

        def kassel
          @kassel ||= company_by_id('HKC')
        end

        def waldeck
          @waldeck ||= company_by_id('WC')
        end

        def frankfurt
          @frankfurt ||= company_by_id('FC')
        end

        def seidler_variant?
          @seidler_variant ||= @optional_rules&.include?(:Seidler)
        end

        def initial_auction_companies
          @companies.select { |company| company.meta[:start_packet] }
        end

        def init_companies(_players)
          companies = super
          companies.reject! { |c| c.sym == 'SS' } unless seidler_variant?
          companies
        end

        def cash_by_options
          case seidler_variant?
          when true
            { 3 => 810, 4 => 610, 5 => 510 }
          else
            { 3 => 800, 4 => 600, 5 => 500 }
          end
        end

        def nassau?(corporation)
          corporation.all_abilities.any? { |ability| ability.description.include?('Nassau') }
        end

        def darmstadt?(corporation)
          corporation.all_abilities.any? { |ability| ability.description.include?('Darmstadt') }
        end

        def kassel?(corporation)
          corporation.all_abilities.any? { |ability| ability.description.include?('Kassel') }
        end

        def waldeck?(corporation)
          corporation.all_abilities.any? { |ability| ability.description.include?('Waldeck') }
        end

        def frankfurt?(corporation)
          corporation.all_abilities.any? { |ability| ability.description.include?('Frankfurt') }
        end

        def buy_nassau_right(entity)
          seller = nassau.owner
          seller_name = nassau.owner.name
          @log << "#{entity.name} buys a Nassau Right from #{seller_name} for #{format_currency(RIGHT_COST)}"
          entity.spend(RIGHT_COST, seller)

          grant_right(entity, nassau)
        end

        def buy_darmstadt_right(entity)
          seller = darmstadt.owner
          seller_name = darmstadt.owner.name
          @log << "#{entity.name} buys a Darmstadt Right from #{seller_name} for #{format_currency(RIGHT_COST)}"
          entity.spend(RIGHT_COST, seller)

          grant_right(entity, darmstadt)
        end

        def buy_kassel_right(entity)
          seller = kassel.owner
          seller_name = kassel.owner.name
          @log << "#{entity.name} buys a Kassel Right from #{seller_name} for #{format_currency(RIGHT_COST)}"
          entity.spend(RIGHT_COST, seller)

          grant_right(entity, kassel)
        end

        def buy_waldeck_right(entity)
          seller = waldeck.owner
          seller_name = waldeck.owner.name
          @log << "#{entity.name} buys a Waldeck Right from #{seller_name} for #{format_currency(RIGHT_COST)}"
          entity.spend(RIGHT_COST, seller)

          grant_right(entity, waldeck)
        end

        def buy_frankfurt_right(entity)
          seller = frankfurt.owner
          seller_name = frankfurt.owner.name
          @log << "#{entity.name} buys a Frankfurt Right from #{seller_name} for #{format_currency(RIGHT_COST)}"
          entity.spend(RIGHT_COST, seller)

          grant_right(entity, frankfurt)
        end

        def grant_right(corporation, type)
          ability = Ability::Base.new(
            type: 'consession',
            description: type.name.to_s,
            corporations: type.id,
          )
          corporation.add_ability(ability)
          @log << "#{corporation.name} claims the #{type.name}"
        end

        def can_buy_nassau_right?(entity)
          return false unless entity.corporation?

          !nassau?(entity) && buying_power(entity) >= RIGHT_COST
        end

        def can_buy_darmstadt_right?(entity)
          return false unless entity.corporation?

          !darmstadt?(entity) && buying_power(entity) >= RIGHT_COST
        end

        def can_buy_kassel_right?(entity)
          return false unless entity.corporation?

          !kassel?(entity) && buying_power(entity) >= RIGHT_COST
        end

        def can_buy_waldeck_right?(entity)
          return false unless entity.corporation?

          !waldeck?(entity) && buying_power(entity) >= RIGHT_COST
        end

        def can_buy_frankfurt_right?(entity)
          return false unless entity.corporation?

          !frankfurt?(entity) && buying_power(entity) >= RIGHT_COST
        end

        def init_starting_cash(players, bank)
          cash = cash_by_options[players.size]
          players.each do |player|
            bank.spend(cash, player)
          end
        end

        def setup_preround
          # Make sure the start player order is randomized
          @players.sort_by! { rand }
        end

        def new_auction_round
          Round::Auction.new(self, [
            Engine::Step::SelectionAuction,
          ])
        end

        # Stock Round 1 is least_cash
        # Stock Round 2ff is after_last_to_act
        def next_round!
          @round =
            case @round
            when Round::Stock
              @operating_rounds = @phase.operating_rounds
              reorder_players
              new_operating_round
            when Round::Operating
              if @round.round_num < @operating_rounds
                or_round_finished
                new_operating_round(@round.round_num + 1)
              else
                @turn += 1
                or_round_finished
                or_set_finished
                new_stock_round
              end
            when init_round.class
              init_round_finished
              reorder_players(:least_cash)
              new_stock_round
            end
        end

        def operating_round(round_num)
          Round::Operating.new(self, [
            G18HN::Step::SpecialBuy,
            G18HN::Step::Track,
            Engine::Step::SpecialTrack,
            G18HN::Step::Token,
            G18HN::Step::Route,
            Engine::Step::Dividend,
            Engine::Step::DiscardTrain,
            Engine::Step::BuyTrain,
          ], round_num: round_num)
        end

        def national_hexes(corporation_id)
          self.class::NATIONAL_REGION_HEXES[corporation_id].dup
        end

        def operating_right(corporation)
          # im feld corporations stehen die einzelnen konzessionen (pro konzession eine ability).
          # diese müssen ausgelesen werden und dann erfolgt der Abgleich hex_operating_rights?
          # abilities will return an array if many or an Ability if one. [*foo(bar)] gets around that
          corporation.all_abilities.select(&:corporations)
          #          corporation.abilities.flat_map { |a| a.corporations.any? }
        end

        def operating_rights(entity)
          # welche concession hat die Gesellchaft
          rights = self.class::CORPORATIONS_OPERATING_RIGHTS[entity.id]
          corporation_rights = rights.is_a?(Array) ? rights.dup : [rights]
          corporation_rights.uniq
        end

        def hex_operating_rights?(entity, hex)
          nationals = operating_rights(entity)
          nationals.any? { |national| national_hexes(national).include?(hex.name) }
        end

        def check_distance(route, visits)
          entity = route.corporation

          unless visits_operating_rights?(entity, visits)
            raise GameError, 'The director need operating rights to operate in the selected regions'
          end

          super
        end

        def visits_operating_rights?(entity, visits)
          nationals = operating_rights(entity)

          count = visits.count do |v|
            nationals.any? do |national|
              national_hexes(national).include?(v.hex.name) || national_hexes('ALL').include?(v.hex.name)
            end
          end

          count == visits.size
        end
        # modify to include variable value cities and route bonus
        
        def revenue_for(route, stops)
          stops.sum { |stop| stop.route_revenue(route.phase, route.train) } +
            connection_bonus(route, stops) 

        end

        def connection_bonus(route, _stops)
          visited_location_names = route.visited_stops.map { |stop| stop.tile.location_name }.compact
          return 0 if visited_location_names.count < 2

          LOGGER.debug { "connection_bonus >> visited_location_names: #{visited_location_names}" }
          revenue = 0
          revenue += 40 if visited_location_names.include?('Rheinland') && visited_location_names.include?('Südwestfalen')
          revenue += 80 if visited_location_names.include?('Rheinland') && visited_location_names.include?('Ostwestfalen')
          revenue += 80 if visited_location_names.include?('Rheinland') && visited_location_names.include?('Hannover')
          revenue += 70 if visited_location_names.include?('Rheinland') && visited_location_names.include?('Thüringen')
          revenue += 60 if visited_location_names.include?('Rheinland') && visited_location_names.include?('Franken')
          revenue += 40 if visited_location_names.include?('Rheinland') && visited_location_names.include?('Baden')
          revenue += 30 if visited_location_names.include?('Rheinland') && visited_location_names.include?('Pfalz')
          revenue += 40 if visited_location_names.include?('Südwestfalen') && visited_location_names.include?('Ostwestfalen')
          revenue += 40 if visited_location_names.include?('Südwestfalen') && visited_location_names.include?('Hannover')
          revenue += 40 if visited_location_names.include?('Südwestfalen') && visited_location_names.include?('Thüringen')
          revenue += 40 if visited_location_names.include?('Südwestfalen') && visited_location_names.include?('Franken')
          revenue += 50 if visited_location_names.include?('Südwestfalen') && visited_location_names.include?('Baden')
          revenue += 40 if visited_location_names.include?('Südwestfalen') && visited_location_names.include?('Pfalz')
          revenue += 30 if visited_location_names.include?('Ostwestfalen') && visited_location_names.include?('Hannover')
          revenue += 40 if visited_location_names.include?('Ostwestfalen') && visited_location_names.include?('Thüringen')
          revenue += 70 if visited_location_names.include?('Ostwestfalen') && visited_location_names.include?('Franken')
          revenue += 80 if visited_location_names.include?('Ostwestfalen') && visited_location_names.include?('Baden')
          revenue += 80 if visited_location_names.include?('Ostwestfalen') && visited_location_names.include?('Pfalz')
          revenue += 30 if visited_location_names.include?('Hannover') && visited_location_names.include?('Thüringen')
          revenue += 60 if visited_location_names.include?('Hannover') && visited_location_names.include?('Franken')
          revenue += 80 if visited_location_names.include?('Hannover') && visited_location_names.include?('Baden')
          revenue += 80 if visited_location_names.include?('Hannover') && visited_location_names.include?('Pfalz')
          revenue += 50 if visited_location_names.include?('Thüringen') && visited_location_names.include?('Franken')
          revenue += 50 if visited_location_names.include?('Thüringen') && visited_location_names.include?('Baden')
          revenue += 60 if visited_location_names.include?('Thüringen') && visited_location_names.include?('Pfalz')
          revenue += 30 if visited_location_names.include?('Franken') && visited_location_names.include?('Baden')
          revenue += 40 if visited_location_names.include?('Franken') && visited_location_names.include?('Pfalz')
          revenue += 20 if visited_location_names.include?('Baden') && visited_location_names.include?('Pfalz')
          revenue
        end
      end
    end
  end
end
