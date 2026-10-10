# frozen_string_literal: true

require 'spec_helper'
require_relative 'spec_helpers'

module Engine
  module Game
    module G18HN
      describe Game do
        include G18HNSpecHelpers

        let(:players) { 3 }
        let(:game) { build_game(players: players, id: 1) }
        let(:a) { game.player_by_id('a') }
        let(:b) { game.player_by_id('b') }
        let(:c) { game.player_by_id('c') }

        # process_action swallows GameError, so re-raise it
        def act(action)
          game.process_action(action)
          raise game.exception if game.exception
        end

        def auction_all
          while game.round.is_a?(Engine::Round::Auction)
            step = game.round.active_step
            entity = game.current_entity
            company = step.send(:auctioning)
            if company && step.send(:highest_bid, company)
              act(Action::Pass.new(entity))
            else
              target = company || step.companies.first
              act(Action::Bid.new(entity, company: target, price: step.min_bid(target)))
            end
          end
        end

        def turn_of(entity)
          act(Action::Pass.new(game.current_entity)) until game.current_entity == entity
        end

        def par(entity, id, price)
          share_price = game.stock_market.par_prices.find { |par_price| par_price.price == price }
          act(Action::Par.new(entity, corporation: game.corporation_by_id(id), share_price: share_price))
        end

        def buy(entity, id)
          corporation = game.corporation_by_id(id)
          share = corporation.ipo_shares.select(&:buyable).min_by(&:percent)
          act(Action::BuyShares.new(entity, shares: share, share_price: share.price, percent: share.percent))
        end

        def sell(entity, id, percent)
          bundle = game.sellable_bundles(entity, game.corporation_by_id(id)).find { |candidate| candidate.percent == percent }
          act(Action::SellShares.new(entity, shares: bundle.shares, share_price: bundle.price_per_share,
                                             percent: bundle.percent))
        end

        def finish_round
          round = game.round
          act(Action::Pass.new(game.current_entity)) while game.round.equal?(round)
        end

        def operate(plan = {})
          play_operating_round(plan, nil)
        end

        def advance_to_buy_train(buyer, plan = {}, lays = {})
          play_operating_round(plan, buyer, lays)
        end

        # lays: { corporation => [[hex, tile, rotation], ...] }, one entry per operating turn
        def operate_with_tiles(lays, plan = {}, tokens = {})
          play_operating_round(plan, nil, lays, tokens)
        end

        # tokens: { corporation => hex }, placed in the first token step of that corporation
        def play_operating_round(plan, buyer, lays = {}, tokens = {})
          plan = plan.transform_values(&:dup)
          lays = lays.transform_values(&:dup)
          tokens = tokens.dup
          round = game.round
          while game.round.equal?(round)
            step = game.round.active_step
            entity = game.current_entity
            return if step.is_a?(Engine::Step::BuyTrain) && entity.id == buyer

            actions = step.actions(entity)
            act(if actions.include?('lay_tile') && entity.company?
                  special_tile_action(entity)
                elsif actions.include?('lay_tile') && (lay = lays[entity.id]&.shift)
                  hex, tile, rotation = lay
                  Action::LayTile.new(entity, tile: game.tiles.find { |t| t.name == tile }, hex: game.hex_by_id(hex),
                                              rotation: rotation)
                elsif actions.include?('place_token') && (hex = tokens.delete(entity.id))
                  Action::PlaceToken.new(entity, city: game.hex_by_id(hex).tile.cities.first, slot: 0)
                elsif actions.include?('run_routes')
                  Action::RunRoutes.new(entity, routes: planned_routes(entity))
                elsif actions.include?('dividend')
                  Action::Dividend.new(entity, kind: 'withhold')
                elsif actions.include?('buy_train') && (order = plan[entity.id]&.shift)
                  order.first == :right ? right_action(entity, order.last) : train_action(entity, order)
                elsif actions.include?('discard_train')
                  Action::DiscardTrain.new(entity, train: entity.trains.min_by(&:price))
                else
                  Action::Pass.new(entity)
                end)
          end
        end

        # routes: { corporation => [hexes per train] }, the most expensive train first
        let(:routes) { {} }

        def planned_routes(entity)
          trains = entity.trains.sort_by(&:price).reverse
          planned = routes.fetch(entity.id, []).zip(trains).select(&:last).map do |hexes, train|
            Engine::Route.new(game, game.phase, train, connection_hexes: [hexes], routes: [])
          end
          planned.each { |route| route.routes = planned }
        end

        def par_and_buy(player, id, price, buys)
          turn_of(player)
          par(player, id, price)
          buys.times do
            turn_of(player)
            buy(player, id)
          end
        end

        # order: [:depot] or [seller, price], optionally with the train name, else the cheapest train
        def train_action(entity, order)
          seller, price, name = order
          if seller == :depot
            train = game.depot.min_depot_train
            Action::BuyTrain.new(entity, train: train, price: train.price)
          else
            trains = game.corporation_by_id(seller).trains
            train = name ? trains.find { |candidate| candidate.name == name } : trains.min_by(&:price)
            Action::BuyTrain.new(entity, train: train, price: price)
          end
        end

        def right_action(entity, id)
          step = game.round.steps.find { |candidate| candidate.is_a?(G18HN::Step::SpecialBuy) }
          item = step.buyable_items(entity).find { |candidate| candidate.description == game.company_by_id(id).name }
          Action::SpecialBuy.new(entity, item: item)
        end

        def offer(player, id)
          game.sellable_bundles(player, game.corporation_by_id(id)).map { |bundle| [bundle.percent, bundle.price_per_share] }
        end

        def stock_round_one(with_wlb: true)
          turn_of(b)
          par(b, 'SB', 70)
          if with_wlb
            turn_of(a)
            par(a, 'WLB', 70)
          end
          turn_of(c)
          par(c, 'HLB', 70)
          3.times do
            turn_of(b)
            buy(b, 'SB')
            turn_of(c)
            buy(c, 'HLB')
          end
          if with_wlb
            2.times do
              turn_of(a)
              buy(a, 'WLB')
            end
          end
          turn_of(a)
          par(a, 'MNB', 70)
          3.times do
            turn_of(a)
            buy(a, 'MNB')
          end
        end

        def play_into_green(with_wlb: true)
          stock_round_one(with_wlb: with_wlb)
          finish_round
          operate('SB' => [[:depot]] * 4, 'MNB' => [[:depot]] * 2, 'HLB' => [[:depot]] * 4)
        end

        def exchange_step
          game.round.steps.find { |step| step.is_a?(G18HN::Step::Exchange) }
        end

        # A legal special tile per private, laid right after its exchange
        let(:special_tiles) { { 'BE' => ['D15', '3', 2], 'TB' => ['I4', '7', 2], 'OB' => ['M12', '7', 0] } }

        def special_tile_action(company)
          hex_id, tile_name, rotation = special_tiles[company.id]
          tile = game.tiles.find { |t| t.name == tile_name }
          Action::LayTile.new(company, tile: tile, hex: game.hex_by_id(hex_id), rotation: rotation)
        end

        def lay_special_tile(company)
          act(special_tile_action(company))
        end

        # Answers every open private in the current exchange round, Decline unless planned
        def play_exchange_round(plan = {})
          round = game.round
          expect(round).to be_a(G18HN::Round::Exchange)
          while game.round.equal?(round)
            entity = game.current_entity
            if game.round.actions_for(entity).include?('lay_tile')
              lay_special_tile(entity)
            else
              act(Action::Choose.new(entity, choice: plan.fetch(entity.id, 'Decline')))
            end
          end
        end

        before { auction_all }

        context 'first stock round' do
          [3, 4, 5].each do |count|
            context "with #{count} players" do
              let(:players) { count }

              it 'allows no sale even of a floated corporation' do
                first = game.current_entity
                par(first, 'SB', 70)
                2.times do
                  turn_of(first)
                  buy(first, 'SB')
                end
                buy(game.current_entity, 'SB')
                turn_of(first)

                sb = game.corporation_by_id('SB')
                expect(sb).to be_floated
                expect(game.sellable_bundles(first, sb)).to be_empty
                expect(game.round.active_step.actions(first)).not_to include('sell_shares')
              end
            end
          end
        end

        context 'second stock round' do
          let(:sb) { game.corporation_by_id('SB') }
          let(:mnb) { game.corporation_by_id('MNB') }

          before do
            expect([b, a, c].map(&:cash)).to eq([630, 670, 690])
            expect(b.companies.map(&:id) - Game::CONCESSIONS).to contain_exactly('HB', 'BE', 'OB')
            expect(a.companies.map(&:id) - Game::CONCESSIONS).to contain_exactly('FL', 'TB')
            expect(c.companies.map(&:id) - Game::CONCESSIONS).to contain_exactly('BR', 'FB')
            expect(game.current_entity).to eq(b)

            par(b, 'SB', 70)
            2.times do
              turn_of(b)
              buy(b, 'SB')
            end
            turn_of(a)
            buy(a, 'SB')
            finish_round
            operate('SB' => [[:depot]])

            expect(sb.share_price.price).to eq(65)
            expect(sb).to be_operated
            expect(a.cash).to eq(615)
          end

          it 'values unfloated shares at nothing' do
            turn_of(c)
            par(c, 'MNB', 100)
            turn_of(c)
            buy(c, 'MNB')
            turn_of(c)

            expect(mnb).not_to be_floated
            expect(game.sellable_bundles(c, mnb)).to be_empty
            expect(game.liquidity(c)).to eq(c.cash)
          end

          context 'with MNB floated' do
            before do
              turn_of(c)
              par(c, 'MNB', 100)
              3.times do
                turn_of(c)
                buy(c, 'MNB')
              end
            end

            it 'sells one step below before MNB operates' do
              turn_of(c)
              expect(mnb).to be_floated
              expect(offer(c, 'MNB')).to match_array([[10, 90], [20, 90], [30, 90]])
              expect(game.liquidity(c) - c.cash).to eq(270)

              cash = c.cash
              sell(c, 'MNB', 10)
              expect(c.cash - cash).to eq(90)
              expect(mnb.share_price.price).to eq(90)
              expect(mnb.share_price.coordinates).to eq([1, 4])
            end

            it 'counts shares one step below until MNB operates' do
              expect(mnb.share_price.coordinates).to eq([0, 4])
              finish_round
              expect(game.current_entity).to eq(mnb)
              expect(game.liquidity(c) - c.cash).to eq(270)

              operate('MNB' => [[:depot]])
              expect(mnb).to be_operated
              expect(mnb.share_price.price).to eq(90)
              # 3 x 90 at full price now; one step lower would be 255
              expect(game.liquidity(c) - c.cash).to eq(270)
            end
          end

          it 'sells at full price after operating' do
            turn_of(a)
            cash = a.cash
            sell(a, 'SB', 10)
            expect(a.cash - cash).to eq(65)
            expect(sb.share_price.price).to eq(60)
          end
        end

        context 'exchange round' do
          let(:wlb) { game.corporation_by_id('WLB') }

          [3, 4, 5].each do |count|
            context "with #{count} players" do
              let(:players) { count }

              it 'holds no exchange round in the yellow phase' do
                finish_round

                expect(game.round).not_to be_a(G18HN::Round::Exchange)
                expect(game.log.map(&:message).grep(/exchange/)).to be_empty
              end
            end
          end

          it 'asks the owners of BE, FB, TB and OB in private order' do
            play_into_green

            expect(game.phase.name).to eq('3')
            expect(game.round.entities.map(&:id)).to eq(%w[BE FB TB OB])
            %w[BE FB TB OB].each do |id|
              company = game.company_by_id(id)
              expect(game.current_entity).to eq(company)
              expect(game.round.active_step.actions(company)).to eq(['choose'])
              act(Action::Choose.new(company, choice: 'Decline'))
            end

            expect(game.round).to be_a(Engine::Round::Stock)
            expect(game.turn).to eq(2)
          end

          it 'exchanges each private for the share reserved in its own corporation' do
            play_into_green
            expect(exchange_step.choice_name).to eq('Exchange BE for a WLB share')

            shares = %w[WLB FHB WEG SB].map { |id| game.corporation_by_id(id).reserved_shares.first }
            play_exchange_round('BE' => 'Exchange', 'FB' => 'Exchange', 'TB' => 'Exchange', 'OB' => 'Exchange')

            expect(shares.map { |share| [share.id, share.owner.id] })
              .to eq([%w[WLB_8 b], %w[FHB_8 c], %w[WEG_8 a], %w[SB_8 b]])
            expect(shares.map(&:buyable)).to all(be(true))
            expect(%w[BE FB TB OB].map { |id| game.company_by_id(id) }).to all(be_closed)
          end

          it 'lets the owner exchange beyond the 60 percent limit' do
            { b => 'WLB', a => 'MNB', c => 'HLB' }.each do |player, id|
              turn_of(player)
              par(player, id, 70)
            end
            3.times do
              { b => 'WLB', a => 'MNB', c => 'HLB' }.each do |player, id|
                turn_of(player)
                buy(player, id)
              end
            end
            turn_of(b)
            buy(b, 'WLB')
            expect(b.percent_of(wlb)).to eq(60)
            finish_round
            operate('WLB' => [[:depot]] * 4, 'MNB' => [[:depot]] * 4, 'HLB' => [[:depot]] * 2)

            expect(game.round).to be_a(G18HN::Round::Exchange)
            expect(game.round.active_step.actions(game.company_by_id('BE'))).to eq(['choose'])
            play_exchange_round('BE' => 'Exchange')
            expect(b.percent_of(wlb)).to eq(70)

            expect(game.round).to be_a(Engine::Round::Stock)
            turn_of(b)
            expect(game.round.active_step.actions(b)).to include('pass')
          end

          it 'holds an exchange round before every round in the green phase' do
            play_into_green
            play_exchange_round
            finish_round
            expect(game.round.round_num).to eq(1)
            play_exchange_round
            operate
            expect(game.round.round_num).to eq(2)
            play_exchange_round
          end

          it 'lets a corporation floated by the exchange operate in the next operating round' do
            play_into_green
            play_exchange_round
            finish_round
            cash = b.cash
            play_exchange_round('BE' => 'Exchange')

            expect(game.round).to be_a(Engine::Round::Operating)
            expect(game.round.entities.map(&:id)).to eq(%w[WLB SB HLB MNB])
            # HB and OB still pay b, BE no longer does
            expect(b.cash - cash).to eq(20)
          end

          it 'allows no exchange in an operating round' do
            play_into_green
            play_exchange_round
            finish_round
            play_exchange_round
            expect(game.round).to be_a(Engine::Round::Operating)

            share = wlb.reserved_shares.first
            action = Action::BuyShares.new(game.company_by_id('BE'), shares: share, percent: 10)
            expect { act(action) }.to raise_error(GameError)
            expect(share.owner).to eq(wlb)
          end

          it 'allows no exchange in a stock round' do
            play_into_green
            play_exchange_round
            expect(game.round).to be_a(Engine::Round::Stock)

            share = wlb.reserved_shares.first
            action = Action::BuyShares.new(game.company_by_id('BE'), shares: share, percent: 10)
            expect { act(action) }.to raise_error(GameError)
            expect(share.owner).to eq(wlb)
          end
        end

        context 'share limit' do
          let(:wlb) { game.corporation_by_id('WLB') }

          it 'lets a player buy from the open market beyond 60 percent, but not from the IPO' do
            { b => 'WLB', a => 'MNB', c => 'HLB' }.each do |player, id|
              turn_of(player)
              par(player, id, 70)
            end
            3.times do
              { b => 'WLB', a => 'MNB', c => 'HLB' }.each do |player, id|
                turn_of(player)
                buy(player, id)
              end
            end
            turn_of(b)
            buy(b, 'WLB')
            turn_of(a)
            buy(a, 'WLB')
            finish_round
            operate('WLB' => [[:depot]], 'MNB' => [[:depot]], 'HLB' => [[:depot]])
            turn_of(a)
            sell(a, 'WLB', 10)
            turn_of(b)

            step = game.round.active_step
            expect(step.can_buy?(b, wlb.ipo_shares.find(&:buyable).to_bundle)).to be(false)
            pool_share = game.share_pool.shares_by_corporation[wlb].first
            allow(game).to receive(:cert_limit).and_return(game.num_certs(b))
            expect(step.can_buy?(b, pool_share.to_bundle)).to be(false)
            allow(game).to receive(:cert_limit).and_call_original
            act(Action::BuyShares.new(b, shares: pool_share, share_price: pool_share.price, percent: pool_share.percent))
            expect(b.percent_of(wlb)).to eq(70)
          end
        end

        context 'special tile on exchange' do
          def special_track_actions
            %w[BE TB OB].map { |id| game.round.actions_for(game.company_by_id(id)) & ['lay_tile'] }
          end

          def private_lays
            game.companies.reject(&:closed?).select { |company| game.round.actions_for(company).include?('lay_tile') }
          end

          def exchange_up_to(company)
            act(Action::Choose.new(game.current_entity, choice: 'Decline')) until game.current_entity == company
            act(Action::Choose.new(company, choice: 'Exchange'))
          end

          it 'offers BE, TB and OB no tile lay outside the exchange' do
            expect(game.round).to be_a(Engine::Round::Stock)
            expect(special_track_actions).to all(be_empty)

            stock_round_one
            finish_round
            expect(game.round).to be_a(Engine::Round::Operating)
            expect(special_track_actions).to all(be_empty)
          end

          it 'offers no private a tile lay in a stock round' do
            expect(private_lays).to be_empty

            play_into_green
            play_exchange_round
            expect(game.round).to be_a(Engine::Round::Stock)
            expect(private_lays).to be_empty
          end

          { 'BE' => 'FB', 'TB' => 'OB', 'OB' => nil }.each do |id, following|
            it "lets #{id} lay its tile right after the exchange" do
              play_into_green
              company = game.company_by_id(id)
              owner = company.owner
              exchange_up_to(company)

              expect(game.current_entity).to eq(company)
              expect(game.round.active_step.actions(company)).to eq(['lay_tile'])
              expect(company).not_to be_closed

              cash = owner.cash
              hex_id, tile_name, = special_tiles[id]
              lay_special_tile(company)
              expect(game.hex_by_id(hex_id).tile.name).to eq(tile_name)
              expect(company).to be_closed
              expect(owner.cash).to eq(cash)

              if following
                expect(game.current_entity).to eq(game.company_by_id(following))
              else
                expect(game.round).to be_a(Engine::Round::Stock)
              end
            end
          end

          it 'closes FB right after its exchange' do
            play_into_green
            fb = game.company_by_id('FB')
            exchange_up_to(fb)

            expect(fb).to be_closed
            expect(game.current_entity).to eq(game.company_by_id('TB'))
          end
        end

        context 'forced exchange at the end of an operating round' do
          # WLB builds Korbach and Bad Wildungen, SB builds Darmstadt and one of the three Odenwald hexes
          before do
            turn_of(b)
            par(b, 'SB', 70)
            turn_of(c)
            par(c, 'HLB', 70)
            turn_of(a)
            par(a, 'WLB', 70)
            3.times do
              turn_of(b)
              buy(b, 'SB')
              turn_of(c)
              buy(c, 'HLB')
              turn_of(a)
              buy(a, 'WLB')
            end
            expect([a, b, c].map(&:cash)).to eq([320, 280, 340])
            finish_round

            operate_with_tiles({ 'WLB' => [['C14', '5', 4]], 'SB' => [['L11', '927', 1]] },
                               { 'SB' => [[:depot]], 'HLB' => [[:depot]], 'WLB' => [[:depot]] })
            finish_round
            @wlb_cash = game.corporation_by_id('WLB').cash
            operate_with_tiles({ 'WLB' => [['D15', '3', 2]], 'SB' => [['M12', '7', 1]] })
          end

          it 'exchanges BE once others built D15' do
            share = game.share_by_id('WLB_8')

            expect(game.phase.name).to eq('2')
            expect(game.round).to be_a(Engine::Round::Stock)
            expect(game.turn).to eq(3)
            expect(game.hex_by_id('D15').tile.name).to eq('3')
            expect(@wlb_cash - game.corporation_by_id('WLB').cash).to eq(60)
            expect(game.company_by_id('BE')).to be_closed
            expect(share.owner).to eq(b)
            expect(share.buyable).to be(true)
            expect(game.log.map(&:message)).to include('Baugesellschaft Edertalsperre must be exchanged')
          end

          it 'keeps OB while one of its hexes is still unbuilt' do
            expect(game.hex_by_id('M12').tile.name).to eq('7')
            expect(game.company_by_id('OB')).not_to be_closed
            expect(game.corporation_by_id('SB').reserved_shares.map(&:id)).to eq(['SB_8'])
          end
        end

        context 'Hanau station of FHB' do
          let(:fhb) { game.corporation_by_id('FHB') }
          let(:hanau) { game.hex_by_id('J15').tile.cities.first }

          it 'keeps the Hanau slot and the second free station for the FB exchange' do
            expect(hanau.reserved_by?(fhb)).to be(true)
            expect(hanau.tokenable?(game.corporation_by_id('SB'), free: true)).to be(false)

            stock_round_one
            finish_round
            token_step = game.round.steps.find { |step| step.is_a?(G18HN::Step::Token) }
            expect(token_step.available_tokens(fhb).map(&:type)).to all(eq(:normal))
          end

          it 'keeps a normal FHB station out of Hanau until FB is exchanged' do
            turn_of(c)
            par(c, 'FHB', 70)
            3.times do
              turn_of(c)
              buy(c, 'FHB')
            end
            finish_round
            operate_with_tiles({ 'FHB' => [['G20', '5', 0]] }, { 'FHB' => [[:depot]] })
            [['H19', '9', 0], ['I18', '8', 1], ['I16', '58', 4]].each do |lay|
              finish_round
              operate_with_tiles('FHB' => [lay])
            end
            finish_round
            tile = game.tiles.find { |t| t.name == '5' }
            act(Action::LayTile.new(fhb, tile: tile, hex: game.hex_by_id('J15'), rotation: 2))

            expect(game.round.active_step).to be_a(G18HN::Step::Token)
            expect(game.round.active_step.available_hex(fhb, game.hex_by_id('J15'))).to be_nil
            expect { act(Action::PlaceToken.new(fhb, city: hanau, slot: 0)) }.to raise_error(GameError, /cannot place token/)
          end

          it 'places the station when FB is exchanged, before FHB is founded' do
            play_into_green
            play_exchange_round('FB' => 'Exchange')

            expect(hanau.tokens.compact.map(&:corporation)).to eq([fhb])
            expect(hanau.reserved_by?(fhb)).to be(false)
            expect(fhb.ipoed).to be_falsey

            turn_of(c)
            par(c, 'FHB', 70)
            2.times do
              turn_of(c)
              buy(c, 'FHB')
            end
            finish_round
            play_exchange_round
            operate('FHB' => [[:depot]])
            expect(game.hex_by_id('G20').tile.cities.flat_map(&:tokens).compact.map(&:corporation)).to include(fhb)
          end
        end

        context 'forced exchange when brown starts' do
          def play_until_operating
            until game.round.is_a?(Engine::Round::Operating)
              game.round.is_a?(G18HN::Round::Exchange) ? play_exchange_round : finish_round
            end
          end

          def play_until_stock
            game.round.is_a?(G18HN::Round::Exchange) ? play_exchange_round : operate until game.round.is_a?(Engine::Round::Stock)
          end

          def dividend_step
            game.round.steps.find { |step| step.is_a?(Engine::Step::Dividend) }
          end

          # WLB's tiles in the operating round after its float and in the one in which MNB buys the first 5 train
          let(:wlb_lays) { [[['C14', '5', 4]], []] }

          let(:routes) do
            { 'SB' => [%w[L11 M10 N11]], 'MNB' => [%w[N11 O10], %w[N11 M10 L11]], 'HLB' => [%w[K8 K6 K4]] }
          end

          # Leaves BE, FB, TB and OB open until MNB buys the first 5 train
          def play_into_brown
            { b => 'SB', a => 'MNB', c => 'HLB' }.each do |player, id|
              turn_of(player)
              par(player, id, 100)
            end
            3.times do
              { b => 'SB', a => 'MNB', c => 'HLB' }.each do |player, id|
                turn_of(player)
                buy(player, id)
              end
            end
            finish_round

            operate_with_tiles({ 'SB' => [['L11', '927', 0]], 'MNB' => [['N11', '6', 0]], 'HLB' => [['K6', '9', 1]] },
                               { 'SB' => [[:depot]] * 3, 'MNB' => [[:depot]] * 3, 'HLB' => [[:depot]] * 3 })
            play_until_operating
            operate_with_tiles({ 'SB' => [['M10', '8', 3]], 'HLB' => [['K4', '5', 3]] }, { 'SB' => [[:depot]] })
            12.times do
              play_until_operating
              operate
            end
            expect([a, b, c].map(&:cash)).to eq([380, 620, 540])
            play_until_stock

            par_and_buy(b, 'WLB', 70, 3)
            par_and_buy(c, 'FHB', 70, 3)
            par_and_buy(a, 'WEG', 70, 2)
            finish_round
            play_exchange_round
            operate_with_tiles({ 'WLB' => wlb_lays.first },
                               {
                                 'WLB' => [['SB', 1]],
                                 'FHB' => [['HLB', 1], [:depot]],
                                 'SB' => [[:depot]],
                                 'MNB' => [[:depot]],
                                 'HLB' => [[:depot]] * 2,
                               })
            play_until_operating
            operate('WLB' => [['SB', 1, '3']], 'SB' => [[:depot]], 'MNB' => [[:depot]], 'HLB' => [[:depot]])
            play_until_operating
            operate('SB' => [[:depot]], 'MNB' => [[:depot]])
            play_until_operating
            advance_to_buy_train('MNB', { 'FHB' => [['MNB', 1]] }, { 'WLB' => wlb_lays.last })
            act(train_action(game.current_entity, [:depot]))
          end

          before { play_into_brown }

          it 'exchanges the four remaining privates' do
            expect(game.phase.name).to eq('5')
            expect(game.round.entities.map(&:id)).to eq(%w[WLB FHB SB MNB HLB])

            shares = %w[WLB_8 FHB_8 WEG_8 SB_8].map { |id| game.share_by_id(id) }
            expect(shares.map { |share| share.owner.id }).to eq(%w[b c a b])
            expect(shares.map(&:buyable)).to all(be(true))
            expect(game.company_by_id('FB')).to be_closed
            expect(game.hex_by_id('J15').tile.cities.first.tokens.compact.map(&:corporation))
              .to include(game.corporation_by_id('FHB'))
          end

          it 'makes BE, TB and OB lay their special tile in turn before they close' do
            cash = [a, b].map(&:cash)
            %w[BE TB OB].each do |id|
              company = game.company_by_id(id)
              expect(game.current_entity).to eq(company)
              expect(game.round.active_step.actions(company)).to eq(['lay_tile'])
              lay_special_tile(company)
              expect(company).to be_closed
            end

            expect([a, b].map(&:cash)).to eq(cash)
            expect(game.round.active_step).not_to be_a(G18HN::Step::ExchangeTrack)
          end

          context 'with D15 built in the same operating round' do
            let(:wlb_lays) { [[['C14', '5', 4]], [['D15', '3', 2]]] }

            it 'closes BE without its special tile' do
              company = game.company_by_id('BE')
              expect(game.hex_by_id('D15').tile.name).to eq('3')
              expect(game.share_by_id('WLB_8').owner).to eq(b)
              expect(company).to be_closed
              expect(game.round.exchanged_companies).not_to include(company)
              expect(game.current_entity).to eq(game.company_by_id('TB'))

              lay_special_tile(game.company_by_id('TB'))
              lay_special_tile(game.company_by_id('OB'))
              expect(game.round.active_step).not_to be_a(G18HN::Step::ExchangeTrack)
            end
          end

          it 'pays the full capital on float only to a company founded after brown starts' do
            expect(game.corporation_by_id('WEG').cash).to eq(350)

            operate
            play_until_stock
            par_and_buy(b, 'LTB', 70, 3)
            expect(game.corporation_by_id('LTB').cash).to eq(700)
          end

          it 'lets WEG operate only from the next operating round' do
            weg = game.corporation_by_id('WEG')
            expect(weg).to be_floated
            expect(game.round.entities).not_to include(weg)

            operate
            play_until_operating
            expect(game.round.entities.first.id).to eq('WEG')
          end

          it 'pays no dividend on the exchanged shares in this operating round' do
            fhb = game.corporation_by_id('FHB')
            sb = game.corporation_by_id('SB')
            expect(c.num_shares_of(fhb)).to eq(6)
            expect(dividend_step.dividends_for_entity(fhb, c, 10)).to eq(50)
            expect(dividend_step.dividends_for_entity(sb, b, 10)).to eq(50)

            operate
            play_until_operating
            expect(dividend_step.dividends_for_entity(fhb, c, 10)).to eq(60)
          end
        end

        context 'exchanged reserve share' do
          let(:wlb) { game.corporation_by_id('WLB') }

          it 'goes to the pool as ordinary stock' do
            play_into_green
            share = wlb.reserved_shares.first
            expect(share.id).to eq('WLB_8')
            play_exchange_round('BE' => 'Exchange')
            expect(share.buyable).to be(true)
            expect(wlb).to be_floated

            finish_round
            play_exchange_round
            operate('WLB' => [[:depot]])
            expect(wlb).to be_operated
            play_exchange_round
            operate
            play_exchange_round

            turn_of(b)
            sell(b, 'WLB', 10)
            expect(share.owner).to eq(game.share_pool)
            turn_of(c)
            act(Action::BuyShares.new(c, shares: share, share_price: share.price, percent: 10))
            expect(share.owner).to eq(c)
          end
        end

        context 'obligated track route' do
          def found(player, id)
            turn_of(player)
            par(player, id, 70)
            3.times do
              turn_of(player)
              buy(player, id)
            end
            finish_round
          end

          # one tile per operating round; the first round also buys the forced train
          def lay_in_turn(id, lays)
            lays.each_with_index do |lay, index|
              finish_round unless index.zero?
              operate_with_tiles({ id => [lay] }, index.zero? ? { id => [[:depot]] } : {})
            end
          end

          def met
            game.corporations.select { |corporation| game.obligation_met?(corporation) }.map(&:id)
          end

          it 'completes FHB from Fulda to Bad Hersfeld with the last tile' do
            found(c, 'FHB')
            lay_in_turn('FHB', [['G20', '5', 1], ['F19', '9', 2]])
            expect(met).to be_empty

            finish_round
            operate_with_tiles('FHB' => [['E18', '5', 4]])
            expect(met).to eq(['FHB'])
            expect(game.log.map(&:message)).to include('FHB completes its obligated track route')
          end

          it 'pays half the capital on float and the other half with the obligation' do
            found(c, 'FHB')
            fhb = game.corporation_by_id('FHB')
            expect(fhb.cash).to eq(350)

            lay_in_turn('FHB', [['G20', '5', 1], ['F19', '9', 2]])
            finish_round
            # plus 350 from the obligation, minus 20 for the water at Bad Hersfeld
            expect { operate_with_tiles('FHB' => [['E18', '5', 4]]) }.to change(fhb, :cash).by(330)
          end

          it 'completes HLB from the Rheinland through Bingen and Mainz to the Pfalz' do
            found(c, 'HLB')
            lay_in_turn('HLB', [['K8', '920', 0], ['K6', '9', 1], ['K4', '6', 2], ['L7', '9', 0]])
            expect(met).to be_empty

            finish_round
            operate_with_tiles('HLB' => [['M6', '4', 0]])
            expect(met).to eq(['HLB'])
            expect(game.log.map(&:message).count('HLB receives 350M')).to eq(2)
          end

          context 'with HLB one tile short of its route' do
            let(:hlb) { game.corporation_by_id('HLB') }

            def hlb_legs_connected?
              stops = Game::OBLIGATIONS['HLB'].map { |ids| ids.flat_map { |id| game.hex_by_id(id).tile.nodes } }
              game.legs_connected?(stops, hlb, game.graph_skip_paths(hlb))
            end

            before do
              found(c, 'HLB')
              lay_in_turn('HLB', [['K8', '920', 0], ['K6', '9', 1], ['K4', '6', 2], ['L7', '9', 0]])
              finish_round
            end

            it 'needs every leg connected before it searches a route' do
              expect(hlb_legs_connected?).to be(false)
              operate_with_tiles('HLB' => [['M6', '4', 0]])
              expect(hlb_legs_connected?).to be(true)
            end

            it 'leaves the obligation open when the search reaches its walk limit' do
              stub_const("#{Game}::OBLIGATION_WALK_LIMIT", 10)
              operate_with_tiles('HLB' => [['M6', '4', 0]])
              expect(met).to be_empty
            end
          end

          it 'completes SB once the three Odenwald hexes are built' do
            found(b, 'SB')
            lay_in_turn('SB', [['L11', '927', 1], ['M12', '9', 2], ['N13', '58', 0]])
            expect(met).to be_empty

            finish_round
            operate_with_tiles('SB' => [['O12', '3', 2]])
            expect(met).to eq(['SB'])
          end

          it 'needs one route through the stops in printed order' do
            found(a, 'FWN')
            # Kassel and Bad Karlshafen hang on two branches from Fritzlar, a route would pass Fritzlar twice
            lay_in_turn('FWN', [['C18', '927', 0], ['D17', '3', 2], ['C16', '6', 3], ['B17', '4', 0], ['A18', '3', 5]])
            expect(met).to be_empty
          end

          context 'with FWN building towards Bad Hersfeld' do
            before do
              turn_of(c)
              par(c, 'FHB', 70)
              turn_of(a)
              par(a, 'FWN', 70)
              3.times do
                turn_of(c)
                buy(c, 'FHB')
                turn_of(a)
                buy(a, 'FWN')
              end
              finish_round
              operate_with_tiles({ 'FHB' => [['G20', '5', 1]], 'FWN' => [['C18', '927', 0]] },
                                 { 'FHB' => [[:depot]], 'FWN' => [[:depot]] })
              finish_round
            end

            it 'completes FHB when FWN lays the last tile' do
              operate_with_tiles('FHB' => [['F19', '9', 2]], 'FWN' => [['D17', '58', 3]])
              expect(met).to be_empty
              finish_round
              operate_with_tiles('FWN' => [['E18', '57', 2]])
              expect(met).to eq(['FHB'])
            end

            it 'blocks FHB at Bad Hersfeld once FWN holds its only station' do
              operate_with_tiles('FWN' => [['D17', '58', 3]])
              finish_round
              operate_with_tiles({ 'FWN' => [['E18', '57', 2]] }, {}, { 'FWN' => 'E18' })
              expect(game.hex_by_id('E18').tile.cities.first.tokens.compact.map(&:corporation).map(&:id)).to eq(['FWN'])
              finish_round
              operate_with_tiles('FHB' => [['F19', '9', 2]])
              expect(met).to be_empty
            end
          end
        end

        context 'emergency sale' do
          let(:ltb) { game.corporation_by_id('LTB') }
          let(:mnb) { game.corporation_by_id('MNB') }

          # Plays to MNB's forced train buy in OR 2, the price is what HLB pays for one of MNB's 2 trains
          def emergency(price)
            par_and_buy(a, 'MNB', 80, 4)
            par_and_buy(c, 'HLB', 70, 3)
            par_and_buy(b, 'VB', 70, 3)
            turn_of(c)
            par(c, 'FWN', 70)
            3.times do
              turn_of(b)
              buy(b, 'FWN')
            end
            finish_round

            # MNB spends its capital and hands over all four trains
            operate('MNB' => [[:right, 'HKC'], [:right, 'WC']] + ([[:depot]] * 4),
                    'HLB' => [[:depot], [:depot], ['MNB', price]], 'VB' => [[:depot], [:depot], ['MNB', 1]],
                    'FWN' => [[:depot], ['MNB', 1], ['MNB', 1]])

            turn_of(c)
            par(c, 'LTB', 70)
            turn_of(c)
            buy(c, 'LTB')
            2.times do
              turn_of(a)
              buy(a, 'LTB')
            end
            finish_round

            advance_to_buy_train('MNB')
            step = game.round.active_step
            step.needed_cash(a) - step.available_cash(a)
          end

          {
            1 => [66, [[10, 65], [20, 65]]],
            2 => [65, [[10, 65]]],
            8 => [59, [[10, 65]]],
          }.each do |price, (shortfall, bundles)|
            it "offers #{bundles.map(&:first).join(' and ')} % of LTB at a shortfall of #{shortfall}" do
              expect(emergency(price)).to eq(shortfall)
              expect(ltb).not_to be_operated
              expect(offer(a, 'LTB')).to match_array(bundles)
            end
          end

          it 'sells 20 % in one action at a shortfall of 66' do
            emergency(1)
            expect(mnb.trains).to be_empty
            expect(mnb.cash).to eq(4)
            expect(a.cash).to eq(80)
            expect(game.round.active_step.needed_cash(a)).to eq(150)
            expect(ltb.share_price.coordinates).to eq([5, 4])

            cash = a.cash
            sell(a, 'LTB', 20)
            expect(a.cash - cash).to eq(130)
            expect(ltb.share_price.coordinates).to eq([6, 4])
            expect(ltb.share_price.price).to eq(65)
          end

          it 'rejects 20 % at a shortfall of 65' do
            emergency(2)
            shares = a.shares_of(ltb).first(2)
            action = Action::SellShares.new(a, shares: shares, share_price: 65, percent: 20)
            expect { act(action) }.to raise_error(GameError, /Cannot sell shares of LTB/)
          end
        end

        it 'offers nothing of an exchanged corporation without par price' do
          play_into_green(with_wlb: false)
          wlb = game.corporation_by_id('WLB')
          play_exchange_round('BE' => 'Exchange')
          expect(wlb.ipoed).to be_falsey
          expect(game.sellable_bundles(b, wlb)).to eq([])
        end
      end
    end
  end
end
