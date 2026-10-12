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
      end
    end
  end
end
