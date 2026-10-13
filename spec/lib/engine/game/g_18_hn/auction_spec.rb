# frozen_string_literal: true

require 'spec_helper'
require_relative 'spec_helpers'

module Engine
  module Game
    module G18HN
      describe Game do
        include G18HNSpecHelpers

        let(:players) { 3 }
        let(:optional_rules) { [] }
        let(:game) { build_game(players: players, id: 1, optional_rules: optional_rules) }
        let(:order) { game.players.dup }

        # process_action swallows GameError, so re-raise it
        def act(action)
          game.process_action(action)
          raise game.exception if game.exception
        end

        def step
          game.round.active_step
        end

        def auctioning
          step.active_auction { |company, _bids| company }
        end

        def company(id)
          game.company_by_id(id)
        end

        def bid(player, id, price)
          act(Action::Bid.new(player, company: company(id), price: price))
        end

        def pass(player)
          act(Action::Pass.new(player))
        end

        # everybody passes on the private until the next short operating round has started
        def everybody_passes(id)
          rounds = short_rounds
          expect(auctioning).to eq(company(id))
          pass(game.current_entity) while short_rounds == rounds
        end

        def short_rounds
          game.log.map(&:message).count('-- Short operating round during the initial auction --')
        end

        def lay_frankfurt(hex_id, tile_name)
          tile = game.tiles.find { |candidate| candidate.name == tile_name }
          act(Action::LayTile.new(company('FL'), tile: tile, hex: game.hex_by_id(hex_id), rotation: 0))
        end

        # the opener bids, everybody else passes
        def sell_to_opener(id, price = company(id).min_bid)
          bid(game.current_entity, id, price)
          pass(game.current_entity) until company(id).owner
        end

        [3, 4, 5].each do |count|
          context "with #{count} players" do
            let(:players) { count }

            it 'opens with the Homburger Bahn and refuses bids on any other private' do
              expect(auctioning).to eq(company('HB'))
              expect(game.current_entity).to eq(order[0])
              expect { bid(order[0], 'BR', 40) }.to raise_error(GameError, /not up for auction/)
            end

            it 'lets the opener rotate with each private' do
              game.initial_auction_companies.each_with_index do |private, index|
                expect(auctioning).to eq(private)
                expect(game.current_entity).to eq(order[index % count])
                sell_to_opener(private.id)
              end
            end

            it 'accepts an opening bid above face value in steps of 5' do
              bid(order[0], 'HB', 25)
              expect(step.min_bid(company('HB'))).to eq(30)
            end

            it 'refuses a bid that is not a multiple of 5' do
              expect { bid(order[0], 'HB', 23) }.to raise_error(GameError, /multiple of 5/)
            end

            it 'refuses a bid below face value' do
              expect { bid(order[0], 'HB', 15) }.to raise_error(GameError, /Minimum bid is 20/)
            end

            it 'puts out whoever passes, the opener too' do
              pass(order[0])
              bid(order[1], 'HB', 20)
              seen = []
              until company('HB').owner
                seen << game.current_entity
                pass(game.current_entity)
              end

              expect(company('HB').owner).to eq(order[1])
              expect(seen).not_to include(order[0])
            end

            it 'sells to the highest bid, and only the winner pays' do
              cash = order.to_h { |player| [player, player.cash] }
              bid(order[0], 'HB', 20)
              bid(order[1], 'HB', 25)
              pass(game.current_entity) until company('HB').owner

              expect(company('HB').owner).to eq(order[1])
              expect(cash[order[1]] - order[1].cash).to eq(25)
              expect(order.reject { |player| player == order[1] }.map { |player| cash[player] - player.cash }).to all(eq(0))
            end

            it 'hands the concession right over with the private' do
              game.initial_auction_companies.each { |private| sell_to_opener(private.id) }

              { 'FL' => 'FC', 'BE' => 'WC', 'FB' => 'HKC', 'TB' => 'NC', 'OB' => 'HDC' }.each do |private, right|
                expect(company(right).owner).to eq(company(private).owner), private
              end
            end

            it 'restarts an unwanted Homburger Bahn until the opener takes it for nothing' do
              cash = order[0].cash
              [15, 10, 5].each do |price|
                pass(game.current_entity) until step.min_bid(company('HB')) == price
                expect(game.current_entity).to eq(order[0])
              end
              pass(game.current_entity) until company('HB').min_bid.zero?

              expect(step.bids[company('HB')].map(&:entity)).to eq([order[0]])
              pass(game.current_entity) until company('HB').owner
              expect(company('HB').owner).to eq(order[0])
              expect(order[0].cash).to eq(cash)
            end

            it 'starts the stock round with the least cash first, ties in auction order' do
              privates = game.initial_auction_companies
              spent = Hash.new(0)
              privates.each_with_index { |private, index| spent[order[index % count]] += private.value }
              rich = spent.max_by(&:last).first
              poor = spent.min_by(&:last).first
              last_of_poor = privates.select.with_index { |_, index| order[index % count] == poor }.last
              # the poorest buyer pays more for its last private to tie with the richest
              prices = { last_of_poor => last_of_poor.value + spent[rich] - spent[poor] }
              privates.each { |private| sell_to_opener(private.id, prices.fetch(private, private.value)) }

              expect(game.round).to be_a(Engine::Round::Stock)
              expect(rich.cash).to eq(poor.cash)
              expect(game.players).to eq(order.sort_by { |player| [player.cash, order.index(player)] })
            end

            context 'with a private nobody opens' do
              it 'pays the sold privates in a short operating round and goes on with the same private' do
                sell_to_opener('HB')
                sell_to_opener('BR')
                cash = order.to_h { |player| [player, player.cash] }
                everybody_passes('FL')

                expect(short_rounds).to eq(1)
                expect(order[0].cash - cash[order[0]]).to eq(5)
                expect(order[1].cash - cash[order[1]]).to eq(10)
                expect(game.round).to be_a(Engine::Round::Auction)
                expect(auctioning).to eq(company('FL'))
                expect(step.min_bid(company('FL'))).to eq(50)
                expect(game.current_entity).to eq(order[2 % count])
              end

              it 'lets FL lay a yellow Frankfurt tile in the short operating round' do
                %w[HB BR FL].each { |id| sell_to_opener(id) }
                fl_owner = company('FL').owner
                everybody_passes('BE')
                expect(game.round).to be_a(G18HN::Round::Operating)
                expect(game.current_entity).to eq(company('FL'))

                cash = fl_owner.cash
                lay_frankfurt('J11', '921')
                expect(fl_owner.cash - cash).to eq(10)
                expect(game.round).to be_a(Engine::Round::Auction)
                expect(auctioning).to eq(company('BE'))
                expect(step.min_bid(company('BE'))).to eq(60)
                expect(game.current_entity).to eq(order[3 % count])
              end

              it 'names the short operating round apart from the regular ones' do
                %w[HB BR FL].each { |id| sell_to_opener(id) }
                everybody_passes('BE')
                expect(game.round_description('Operating')).to eq('Short Operating Round (initial auction)')
                expect(game.round.name).to eq('Short Operating Round')

                pass(company('FL'))
                game.initial_auction_companies.reject(&:owner).each { |private| sell_to_opener(private.id) }
                founder = game.current_entity
                act(Action::Par.new(founder, corporation: game.corporation_by_id('SB'),
                                             share_price: game.stock_market.par_prices.find { |price| price.price == 70 }))
                3.times do
                  pass(game.current_entity) until game.current_entity == founder
                  share = game.corporation_by_id('SB').ipo_shares.select(&:buyable).min_by(&:percent)
                  act(Action::BuyShares.new(founder, shares: share, share_price: share.price, percent: share.percent))
                end
                pass(game.current_entity) until game.round.is_a?(Engine::Round::Operating)

                expect(game.round_description('Operating')).to start_with('Operating Round 1.1')
                expect(game.round.name).to eq('Operating Round')
              end

              it 'ends the short operating round when FL passes' do
                %w[HB BR FL].each { |id| sell_to_opener(id) }
                everybody_passes('BE')
                pass(company('FL'))

                expect(game.round).to be_a(Engine::Round::Auction)
                expect(auctioning).to eq(company('BE'))
              end

              it 'keeps the turn and goes straight on to the first stock round afterwards' do
                turn = game.turn
                sell_to_opener('HB')
                everybody_passes('BR')
                expect(short_rounds).to eq(1)
                expect(game.turn).to eq(turn)

                game.initial_auction_companies.reject(&:owner).each { |private| sell_to_opener(private.id) }
                headers = game.log.map(&:message).grep(/\A-- /)
                expect(headers.grep(/Stock Round|Exchange Round|Operating Round \d/)).to eq(['-- Stock Round 1 --'])
                expect(game.round).to be_a(Engine::Round::Stock)
                expect(game.turn).to eq(turn)
                expect(game.players).to eq(order.sort_by { |player| [player.cash, order.index(player)] })
              end

              it 'lets FL lay again in a second short operating round' do
                %w[HB BR FL].each { |id| sell_to_opener(id) }
                everybody_passes('BE')
                lay_frankfurt('J11', '921')
                everybody_passes('BE')

                expect(short_rounds).to eq(2)
                expect(game.current_entity).to eq(company('FL'))
                lay_frankfurt('J13', '922')
                expect(game.hex_by_id('J13').tile.name).to eq('922')
                expect(auctioning).to eq(company('BE'))
              end
            end

            it 'lets a later player outbid the forced 0 for the Homburger Bahn' do
              pass(game.current_entity) until company('HB').min_bid.zero?
              cash = order[1].cash
              bid(order[1], 'HB', 5)
              pass(game.current_entity) until company('HB').owner

              expect(company('HB').owner).to eq(order[1])
              expect(cash - order[1].cash).to eq(5)
            end

            context 'with the Seidler variant' do
              let(:optional_rules) { [:Seidler] }

              it 'auctions SS second, so BR is opened by the third player' do
                expect(game.initial_auction_companies.map(&:id).first(3)).to eq(%w[HB SS BR])
                sell_to_opener('HB')
                sell_to_opener('SS')
                expect(auctioning).to eq(company('BR'))
                expect(game.current_entity).to eq(order[2 % count])
              end
            end
          end
        end

        context 'with three players who spend everything on the first privates' do
          it 'runs short operating rounds until somebody can open the next private' do
            %w[HB BR FL].each { |id| sell_to_opener(id, 800) }
            rounds = 0
            while game.round.is_a?(G18HN::Round::Operating)
              rounds += 1
              raise 'no end of short operating rounds' if rounds > 50

              pass(game.current_entity)
            end

            expect(short_rounds).to eq(6)
            expect(order.map(&:cash)).to eq([30, 60, 0])
            expect(game.round).to be_a(Engine::Round::Auction)
            expect(game.current_entity).to be_a(Engine::Player)
            expect(game.current_entity.cash).to be >= 60
            expect(auctioning).to eq(company('BE'))
          end
        end

        it 'gives the turn after an overbid back to the front of the row, never to the highest bidder' do
          four = build_game(players: 4, id: 1)
          row = four.players.dup
          hb = four.company_by_id('HB')
          [20, 25, 30, 35].each_with_index do |price, index|
            four.process_action(Action::Bid.new(row[index], company: hb, price: price))
          end
          expect(four.exception).to be_nil
          expect(four.current_entity).to eq(row[0])
          four.process_action(Action::Pass.new(row[0]))
          expect(four.current_entity).to eq(row[1])
          expect(four.current_entity).not_to eq(row[3])
        end
      end
    end
  end
end
