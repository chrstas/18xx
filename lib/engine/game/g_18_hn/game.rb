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
        # 9. Varianten: the optional eighth private adds 10M to every player
        SEIDLER_EXTRA_CASH = 10

        SELL_AFTER = :first

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
        }.deep_freeze

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

        # grant_right's ability is display only; @granted_rights is authoritative
        def granted_right?(corporation, concession_id)
          @granted_rights[corporation.id].include?(concession_id)
        end

        def buy_right(entity, concession_id)
          concession = concession_companies[concession_id]
          seller = concession.owner
          entity.spend(RIGHT_COST, seller)
          grant_right(entity, concession)
          @log << "#{entity.name} buys the #{concession.name} from #{seller.name} for #{format_currency(RIGHT_COST)}"
          # 8.4.3: a route through another country counts once the concession is bought
          check_obligations!
        end

        def grant_right(corporation, concession_company)
          @granted_rights[corporation.id] << concession_company.id
          ability = Ability::Base.new(
            type: 'base',
            description: "#{concession_company.name} Rights",
          )
          corporation.add_ability(ability)
          clear_graph_for_entity(corporation)
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
          return super unless seidler_variant?

          cash = self.class::STARTING_CASH[players.size] + self.class::SEIDLER_EXTRA_CASH
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
          @obligations_met = Set.new
          @founded_in_brown = Set.new
          # 5.3 / 8.4.4: FHB's second free station waits for Hanau, whose slot stays reserved until then
          fhb = corporation_by_id('FHB')
          fhb.tokens << Engine::Token.new(fhb, type: :hanau)
          hex_by_id(self.class::HANAU_HEX).tile.add_reservation!(fhb, 0)
        end

        def new_auction_round
          Engine::Round::Auction.new(self, [
            Engine::Step::SelectionAuction,
          ])
        end

        # Stock Round 1 is least_cash
        # Stock Round 2ff is after_last_to_act
        def next_round!
          @round =
            case @round
            when Engine::Round::Stock
              @operating_rounds = @phase.operating_rounds
              reorder_players
              new_exchange_round(Engine::Round::Operating)
            when G18HN::Round::Exchange
              if @round_after_exchange == Engine::Round::Stock
                new_stock_round
              else
                new_operating_round(@round.round_num)
              end
            when Engine::Round::Operating
              if @round.round_num < @operating_rounds
                or_round_finished
                new_exchange_round(Engine::Round::Operating, @round.round_num + 1)
              else
                @turn += 1
                or_round_finished
                or_set_finished
                new_exchange_round(Engine::Round::Stock)
              end
            when init_round.class
              init_round_finished
              reorder_players(:least_cash)
              new_stock_round
            end
        end

        def stock_round
          Engine::Round::Stock.new(self, [
            Engine::Step::DiscardTrain,
            G18HN::Step::BuySellParShares,
          ])
        end

        def operating_round(round_num)
          Engine::Round::Operating.new(self, [
            Engine::Step::Bankrupt,
            G18HN::Step::ExchangeTrack,
            G18HN::Step::SpecialBuy,
            G18HN::Step::SpecialTrack,
            Engine::Step::HomeToken,
            G18HN::Step::Track,
            G18HN::Step::Token,
            G18HN::Step::Route,
            G18HN::Step::Dividend,
            Engine::Step::DiscardTrain,
            G18HN::Step::BuyTrain,
          ], round_num: round_num)
        end

        # 8.1: in the green phase the owners of BE, FB, TB and OB may exchange between rounds
        def new_exchange_round(next_round, round_num = 1)
          @round_after_exchange = next_round
          exchange_round(round_num)
        end

        def exchange_round(round_num)
          G18HN::Round::Exchange.new(self, [
            G18HN::Step::Exchange,
            G18HN::Step::ExchangeTrack,
          ], round_num: round_num)
        end

        def exchange_order
          @companies.select { |company| !company.closed? && abilities(company, :exchange) }
        end

        def exchange_share(company)
          return unless (ability = abilities(company, :exchange))

          exchange_corporations(ability).first.reserved_shares.first
        end

        def exchange_private!(company)
          share = exchange_share(company)
          @share_pool.buy_shares(company.owner, share.to_bundle, exchange: company)
          # 7.1: an exchanged reserved share is ordinary stock and must be buyable from the pool
          share.buyable = true
          # 5.3: FB gives FHB its second home station in Hanau
          place_hanau_token! if abilities(company, :token, time: 'exchange')
        end

        def place_hanau_token!
          fhb = corporation_by_id('FHB')
          hex = hex_by_id(self.class::HANAU_HEX)
          hex.tile.cities.first.place_token(fhb, fhb.find_token_by_type(:hanau), free: true, check_tokenable: false)
          clear_graph_for_entity(fhb)
          @log << "#{fhb.name} places its second home station on #{hex.name}"
        end

        # 5.3 / 8.5: BE, TB and OB are exchanged at the end of the OR in which others built all their hexes
        def or_round_finished
          exchange_order.each do |company|
            next unless special_hexes_built?(company)

            @log << "#{company.name} must be exchanged"
            exchange_private!(company)
            company.close!
          end
        end

        # 5.3 / 8.1: at the start of brown the remaining exchange privates are exchanged, unpaid this OR
        def event_close_companies!
          exchange_order.each do |company|
            owner = company.owner
            corporation = exchange_share(company).corporation
            @log << "#{company.name} must be exchanged"
            exchange_private!(company)
            @round.non_paying_shares[owner][corporation] += 1
            # BE, TB and OB stay open for their special tile, see close: never in entities.rb
            if special_hexes_built?(company)
              company.close!
            elsif abilities(company, :tile_lay, time: 'exchange')
              @round.exchanged_companies << company
            end
          end
          super
        end

        # 7.1: a player may hold more than 60 percent through exchange or the open market
        def can_hold_above_corp_limit?(_entity)
          true
        end

        def special_hexes_built?(company)
          return false unless (ability = abilities(company, :tile_lay, time: 'exchange'))

          Array(ability.hexes).all? { |id| hex_by_id(id).tile.color != :white }
        end

        def after_phase_change(name)
          clear_graph
          # 8.4.3: from brown on (phase 5) a route through another country needs no concession
          check_obligations! if name == '5'
        end

        def obligation_met?(corporation)
          @obligations_met.include?(corporation)
        end

        # 7.3: a company founded after brown starts gets its full capital when it floats
        def after_par(corporation)
          super
          @founded_in_brown << corporation if borders_gone?
        end

        # 7.3: five times par on float, the other five once the obligation is met
        def float_corporation(corporation)
          @log << "#{corporation.name} floats"
          shares = @founded_in_brown.include?(corporation) || obligation_met?(corporation) ? 10 : 5
          @bank.spend(corporation.par_price.price * shares, corporation)
          @log << "#{corporation.name} receives #{format_currency(corporation.cash)}"
        end

        # 8.4.3: any build can complete the obligation of any company
        def check_obligations!
          @corporations.each do |corporation|
            next if obligation_met?(corporation) || !obligation_complete?(corporation)

            @obligations_met << corporation
            @log << "#{corporation.name} completes its obligated track route"
            next if !corporation.floated? || @founded_in_brown.include?(corporation)

            amount = corporation.par_price.price * 5
            @bank.spend(amount, corporation)
            @log << "#{corporation.name} receives #{format_currency(amount)}"
          end
        end

        def obligation_complete?(corporation)
          if (hexes = self.class::BUILT_OBLIGATIONS[corporation.id])
            return hexes.all? { |id| hex_by_id(id).tile.color != :white }
          end

          # 8.4.3: a city full of other companies' stations blocks a stop, an off-board area never does
          stops = self.class::OBLIGATIONS[corporation.id].map do |ids|
            ids.flat_map { |id| hex_by_id(id).tile.nodes }.reject { |node| node.city? && node.blocks?(corporation) }
          end
          return false if stops.any?(&:empty?)

          first, *rest = stops
          skip_paths = graph_skip_paths(corporation)
          first.any? { |node| route_from?(node, rest, corporation, skip_paths, {}, {}) }
        end

        # 8.4.3: one route an unlimited train could run, through the stops in printed order
        def route_from?(node, stops, corporation, skip_paths, visited, visited_paths)
          return true if stops.empty?

          targets, *later = stops
          ahead = visited.merge(later.flatten.to_h { |later_node| [later_node, true] })
          # this leg starts at the stop reached last, which must not count as visited
          ahead.delete(node)
          node.walk(corporation: corporation, skip_paths: skip_paths, visited: ahead,
                    visited_paths: visited_paths.dup) do |path, paths, nodes|
            (path.nodes & targets).each do |target|
              return true if route_from?(target, later, corporation, skip_paths, nodes.dup, paths.dup)
            end
          end
          false
        end

        def national_hexes(corporation_id)
          self.class::NATIONAL_REGION_HEXES[corporation_id]
        end

        def operating_rights(entity)
          rights = Array(self.class::CORPORATIONS_OPERATING_RIGHTS[entity.id])
          rights += @granted_rights[entity.id].filter_map { |id| self.class::CONCESSION_REGIONS[id] }
          (rights + ['ALL']).uniq
        end

        # 8.4.1: from the brown phase on the borders are gone and concessions are meaningless
        def borders_gone?
          @phase.tiles.include?(:brown)
        end

        # 8.4.1: hexes the entity may operate in, nil once the borders are gone
        def operating_hexes(entity)
          return nil if borders_gone?

          operating_rights(entity).flat_map { |national| national_hexes(national) }.to_set
        end

        def hex_operating_rights?(entity, hex)
          return true if borders_gone?

          nationals = operating_rights(entity)
          nationals.any? { |national| national_hexes(national).include?(hex.name) }
        end

        # 8.4.1: track in a country without a concession must not be used to reach hexes elsewhere
        def graph_skip_paths(entity)
          return nil unless entity&.corporation?

          # 8.4.5: the local line is barred without the Frankfurt right, brown shortcut or not
          frankfurt = granted_right?(entity, 'FC')
          hexes = operating_hexes(entity)
          skip_paths = {}
          @hexes.each do |hex|
            rights = hexes.nil? || hexes.include?(hex.name)
            hex.tile.paths.each do |path|
              skip_paths[path] = true if !rights || (!frankfurt && path.track == :narrow)
            end
          end
          skip_paths.empty? ? nil : skip_paths
        end

        # the base class places the home token without clearing the graph cache
        def place_home_token(corporation)
          super
          clear_graph_for_entity(corporation)
        end

        def token_blocked_hex?(hex)
          self.class::TOKEN_BLOCKED_HEXES.include?(hex.name)
        end

        # the F/W and F/E labels also bind private companies, which lay with special = true
        def upgrades_to?(from, to, special = false, selected_company: nil)
          frankfurt = self.class::FRANKFURT_HEXES.include?(from.hex&.name)
          return false if frankfurt && !upgrades_to_correct_label?(from, to)
          # special skips the base town and city count; only the Frankfurt tiles may change it
          return false if special && !frankfurt &&
                          (from.towns.size != to.towns.size || from.cities.size != to.cities.size)

          super
        end

        # in yellow and green phases only the FL private may build Frankfurt
        def frankfurt_track_blocked?(hex)
          self.class::FRANKFURT_HEXES.include?(hex.name) && !@phase.tiles.include?(:brown)
        end

        # reserved shares of unexchanged privates are ignored
        def sold_out?(corporation)
          corporation.player_share_holders.values.sum == 100 - corporation.reserved_shares.sum(&:percent)
        end

        # 7.2: only shares of corporations that are in operation may be sold
        def check_sale_timing(_entity, bundle)
          bundle.corporation.floated? && super
        end

        # 7.2: shares of an unfloated corporation are worth nothing, one that never operated counts one step below
        def liquidity(player, emergency: false)
          return super if emergency
          return player.cash unless sellable_turn?

          player.shares_by_corporation.sum(player.cash) do |corporation, shares|
            next 0 if shares.empty? || !corporation.floated?

            bundles = bundles_for_corporation(player, corporation)
            unless corporation.operated?
              price = @stock_market.find_share_price(corporation, :down).price
              bundles.each { |bundle| bundle.share_price = price }
            end
            bundles.select { |b| can_dump?(player, b) && @share_pool&.fit_in_bank?(b) }.max_by(&:price)&.price || 0
          end
        end

        # 7.2: a corporation that has never operated drops one step before the seller is paid
        def sellable_bundles(player, corporation)
          return super if corporation.operated? || !corporation.ipoed
          return [] unless @round.active_step.respond_to?(:can_sell?)

          # price first, then filter: the emergency step decides against the price
          bundles = bundles_for_corporation(player, corporation)
          price = @stock_market.find_share_price(corporation, :down).price
          bundles.each { |bundle| bundle.share_price = price }
          bundles.select { |bundle| @round.active_step.can_sell?(player, bundle) }
        end

        def num_certs(entity)
          super - entity.companies.count { |company| self.class::CONCESSIONS.include?(company.id) }
        end

        # 8.4.1: operating rights cover every hex a route runs through, stop or not
        def check_other(route)
          entity = route.corporation
          # 8.4.5: the local line between both Frankfurt stations needs the Frankfurt transit right
          if !granted_right?(entity, 'FC') && route.paths.any? { |path| path.track == :narrow }
            raise GameError, "#{entity.name} needs the Frankfurt transit right to use the local line"
          end

          missing = route.all_hexes.reject { |hex| hex_operating_rights?(entity, hex) }
          return if missing.empty?

          raise GameError, "#{entity.name} needs operating rights for #{missing.map(&:name).sort.join(', ')}"
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
