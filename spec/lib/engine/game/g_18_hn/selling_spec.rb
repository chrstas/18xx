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
          play_operating_round(plan, false)
        end

        def advance_to_buy_train(plan = {})
          play_operating_round(plan, true)
        end

        def play_operating_round(plan, stop_at_buy_train)
          plan = plan.transform_values(&:dup)
          round = game.round
          while game.round.equal?(round)
            step = game.round.active_step
            return if stop_at_buy_train && step.is_a?(Engine::Step::BuyTrain)

            entity = game.current_entity
            actions = step.actions(entity)
            act(if actions.include?('run_routes')
                  Action::RunRoutes.new(entity, routes: [])
                elsif actions.include?('dividend')
                  Action::Dividend.new(entity, kind: 'withhold')
                elsif actions.include?('buy_train') && (order = plan[entity.id]&.shift)
                  train_action(entity, order)
                else
                  Action::Pass.new(entity)
                end)
          end
        end

        def train_action(entity, order)
          if order.first == :depot
            train = game.depot.min_depot_train
            Action::BuyTrain.new(entity, train: train, price: train.price)
          else
            Action::BuyTrain.new(entity, train: game.corporation_by_id(order.first).trains.first, price: order.last)
          end
        end

        def offer(player, id)
          game.sellable_bundles(player, game.corporation_by_id(id)).map { |bundle| [bundle.percent, bundle.price_per_share] }
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

        context 'exchanged reserve share (E26)' do
          let(:wlb) { game.corporation_by_id('WLB') }

          it 'goes to the pool as ordinary stock' do
            turn_of(a)
            par(a, 'WLB', 70)
            2.times do
              turn_of(a)
              buy(a, 'WLB')
            end
            turn_of(b)
            share = wlb.reserved_shares.first
            act(Action::BuyShares.new(game.company_by_id('BE'), shares: share, percent: 10))
            expect(share.buyable).to be(true)
            expect(wlb).to be_floated

            finish_round
            operate('WLB' => [[:depot]])
            turn_of(b)
            sell(b, 'WLB', 10)
            expect(share.owner).to eq(game.share_pool)
            turn_of(c)
            act(Action::BuyShares.new(c, shares: share, share_price: share.price, percent: 10))
            expect(share.owner).to eq(c)
          end
        end

        context 'emergency sale (E25)' do
          let(:ltb) { game.corporation_by_id('LTB') }
          let(:mnb) { game.corporation_by_id('MNB') }

          # Plays to MNB's forced train buy in OR 3.1 and returns a's shortfall
          def emergency(price)
            { a => 'MNB', c => 'HLB', b => 'VB' }.each do |player, id|
              turn_of(player)
              par(player, id, id == 'MNB' ? 100 : 70)
              3.times do
                turn_of(player)
                buy(player, id)
              end
            end
            turn_of(c)
            par(c, 'FWN', 70)
            3.times do
              turn_of(b)
              buy(b, 'FWN')
            end
            finish_round

            operate('MNB' => [[:depot]] * 3, 'HLB' => [[:depot]] * 2, 'VB' => [[:depot]] * 2, 'FWN' => [[:depot]] * 4)
            finish_round
            operate('MNB' => [['HLB', price]], 'HLB' => [[:depot]] * 3, 'VB' => [[:depot]])
            # first 4: phase 4 rusts the 2s, MNB is left without a train
            operate('VB' => [[:depot]])

            turn_of(c)
            par(c, 'LTB', 70)
            turn_of(c)
            buy(c, 'LTB')
            2.times do
              turn_of(a)
              buy(a, 'LTB')
            end
            finish_round

            advance_to_buy_train
            step = game.round.active_step
            step.needed_cash(a) - step.available_cash(a)
          end

          {
            599 => [69, [[10, 65], [20, 65]]],
            596 => [66, [[10, 65], [20, 65]]],
            595 => [65, [[10, 65]]],
            589 => [59, [[10, 65]]],
          }.each do |price, (shortfall, bundles)|
            it "offers #{bundles.map(&:first).join(' and ')} % of LTB at a shortfall of #{shortfall}" do
              expect(emergency(price)).to eq(shortfall)
              expect(ltb).not_to be_operated
              expect(offer(a, 'LTB')).to match_array(bundles)
            end
          end

          it 'sells 20 % in one action at a shortfall of 69' do
            emergency(599)
            expect(mnb.cash).to eq(161)
            expect(a.cash).to eq(90)
            expect(game.round.active_step.needed_cash(a)).to eq(320)
            expect(ltb.share_price.coordinates).to eq([5, 4])

            cash = a.cash
            sell(a, 'LTB', 20)
            expect(a.cash - cash).to eq(130)
            expect(ltb.share_price.coordinates).to eq([6, 4])
            expect(ltb.share_price.price).to eq(65)
          end

          it 'rejects 20 % at a shortfall of 65' do
            emergency(595)
            shares = a.shares_of(ltb).first(2)
            action = Action::SellShares.new(a, shares: shares, share_price: 65, percent: 20)
            expect { act(action) }.to raise_error(GameError, /Cannot sell shares of LTB/)
          end
        end

        it 'offers nothing of an exchanged corporation without par price' do
          wlb = game.corporation_by_id('WLB')
          act(Action::BuyShares.new(game.company_by_id('BE'), shares: wlb.reserved_shares.first, percent: 10))
          expect(wlb.ipoed).to be_falsey
          expect(game.sellable_bundles(b, wlb)).to eq([])
        end
      end
    end
  end
end
