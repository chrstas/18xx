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

        GAME_END_CHECK = { bankrupt: :immediate, bank: :full_or }.freeze

        CURRENCY_FORMAT_STR = '%sM'

        STARTING_CASH = { 3 => 800, 4 => 600, 5 => 500 }.freeze

        SELL_AFTER = :after_sr_floated

        SELL_MOVEMENT = :down_block

        SELL_BUY_ORDER = :sell_buy

        CERT_LIMIT = { 3 => 28, 4 => 21, 5 => 17 }.freeze

        HOME_TOKEN_TIMING = :operate

        RIGHT_COST = 40
        MUST_BUY_TRAIN = :always

        CORPORATION_CLASS = G18HN::Corporation

        CORPORATIONS_OPERATING_RIGHTS = {
          'FWN' => 'KAS',
          'FHB' => 'KAS',
          'LTB' => 'NAS',
          'WEG' => 'NAS',
          'MWB' => 'KAS',
          'WLB' => 'WAL',
          'SB' => 'DAR',
          'HLB' => 'DAR',
          'MNB' => 'DAR',
          'VB' => 'DAR',
        }.freeze

        CONCESSION_REGIONS = { 'WC' => 'WAL', 'HKC' => 'KAS', 'NC' => 'NAS', 'HDC' => 'DAR' }.freeze

        CONCESSIONS = %w[WC HKC NC HDC FC].freeze

        # transit bonus: each region pays its own row's value for the other region's direction
        TRANSIT_REGIONS = {
          'Pfalz' => { dir: :S, S: 10, N: 40, O: 30, W: 20 },
          'Baden' => { dir: :S, S: 10, N: 40, O: 20, W: 30 },
          'Hannover' => { dir: :N, S: 40, N: 20, O: 20, W: 20 },
          'Ostwestfalen' => { dir: :N, S: 40, N: 10, O: 30, W: 10 },
          'Südwestfalen' => { dir: :W, S: 20, N: 20, O: 20, W: 20 },
          'Rheinland' => { dir: :W, S: 10, N: 60, O: 40, W: 20 },
          'Thüringen' => { dir: :O, S: 30, N: 10, O: 20, W: 30 },
          'Franken' => { dir: :O, S: 10, N: 40, O: 30, W: 20 },
        }.freeze

        FRANKFURT_HEXES = %w[J11 J13].freeze

        TOKEN_BLOCKED_HEXES = %w[J11 J13 G10].freeze

        NATIONAL_REGION_HEXES = {
          'KAS' => %w[A18 B17 C16 C18 C20 D17 D19 D21 E14 E16 E18 E20 F13 F15 F19 F21 G20 H19 I16 I18 J15],
          'WAL' => %w[B15 C12 C14 D13 D15 E12],
          'DAR' => %w[F11 F17 G12 G14 G16 G18 H11 H13 H15 H17 I12 I14 K4 K6 K8 K10 K12 K14 L5 L7 L9 L11 L13 M6 M8 M10 M12 N7 N9
                      N11 N13 O12],
          'NAS' => %w[F5 F7 F9 G4 G6 G8 H3 H5 H7 H9 I4 I6 I8 J5 J7 J9],
          'ALL' => %w[B11 B19 E10 E22 F23 G22 G2 G10 H1 I2 I10 J3 J11 J13 K16 N5 O6 O8 O10],
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

        def concession_companies
          @concession_companies ||= self.class::CONCESSIONS.to_h { |id| [id, company_by_id(id)] }
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

        # tracked explicitly: corporations start with same-named exchange abilities
        def granted_right?(corporation, concession_id)
          @granted_rights[corporation.id].include?(concession_id)
        end

        def buy_right(entity, concession_id)
          concession = concession_companies[concession_id]
          seller = concession.owner
          entity.spend(RIGHT_COST, seller)
          grant_right(entity, concession)
          @log << "#{entity.name} buys the #{concession.name} from #{seller.name} for #{format_currency(RIGHT_COST)}"
        end

        def grant_right(corporation, concession_company)
          @granted_rights[corporation.id] << concession_company.id
          ability = Ability::Base.new(
            type: 'base',
            description: "#{concession_company.name} Rights",
          )
          corporation.add_ability(ability)
        end

        def can_buy_right?(entity, concession_id)
          return false unless entity.corporation?
          return false if granted_right?(entity, concession_id)

          concession = company_by_id(concession_id)
          return false if concession.nil? || concession.closed? || concession.owner.nil?

          region = self.class::CONCESSION_REGIONS[concession_id]
          return false if region && operating_rights(entity).include?(region)

          buying_power(entity) >= RIGHT_COST
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

        def setup
          super
          @granted_rights = Hash.new { |h, k| h[k] = Set.new }
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
            Engine::Step::Bankrupt,
            Engine::Step::Exchange,
            G18HN::Step::SpecialBuy,
            Engine::Step::SpecialTrack,
            Engine::Step::HomeToken,
            G18HN::Step::Track,
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

        def operating_rights(entity)
          rights = Array(self.class::CORPORATIONS_OPERATING_RIGHTS[entity.id])
          rights += @granted_rights[entity.id].filter_map { |id| self.class::CONCESSION_REGIONS[id] }
          (rights + ['ALL']).uniq
        end

        def hex_operating_rights?(entity, hex)
          nationals = operating_rights(entity)
          nationals.any? { |national| national_hexes(national).include?(hex.name) }
        end

        def token_blocked_hex?(hex)
          self.class::TOKEN_BLOCKED_HEXES.include?(hex.name)
        end

        # in yellow and green phases only the FL private may build Frankfurt
        def frankfurt_track_blocked?(hex)
          self.class::FRANKFURT_HEXES.include?(hex.name) && !@phase.tiles.include?(:brown)
        end

        # the bank does not pay for the share reserved for a private
        def float_corporation(corporation)
          @log << "#{corporation.name} floats"
          @bank.spend(corporation.par_price.price * corporation.total_ipo_shares, corporation)
          @log << "#{corporation.name} receives #{format_currency(corporation.cash)}"
        end

        # reserved shares of unexchanged privates are ignored
        def sold_out?(corporation)
          corporation.player_share_holders.values.sum == 100 - corporation.reserved_shares.sum(&:percent)
        end

        def num_certs(entity)
          super - entity.companies.count { |company| self.class::CONCESSIONS.include?(company.id) }
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
            nationals.any? { |national| national_hexes(national).include?(v.hex.name) }
          end

          count == visits.size
        end

        def revenue_for(route, stops)
          stops.sum { |stop| stop.route_revenue(route.phase, route.train) } + connection_bonus(route, stops)
        end

        def revenue_str(route)
          str = super
          bonus = connection_bonus(route, route.stops)
          str += " + Transit(#{bonus})" if bonus.positive?
          str
        end

        def connection_bonus(route, _stops)
          regions = route.visited_stops.filter_map { |stop| stop.tile.location_name }
            .uniq.select { |name| self.class::TRANSIT_REGIONS.key?(name) }
          return 0 if regions.size < 2

          regions.combination(2).sum { |a, b| transit_bonus(a, b) }
        end

        def transit_bonus(region_a, region_b)
          a = self.class::TRANSIT_REGIONS[region_a]
          b = self.class::TRANSIT_REGIONS[region_b]
          a[b[:dir]] + b[a[:dir]]
        end
      end
    end
  end
end
