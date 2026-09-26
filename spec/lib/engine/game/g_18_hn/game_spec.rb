# frozen_string_literal: true

require 'spec_helper'
require_relative 'spec_helpers'

module Engine
  module Game
    module G18HN
      describe Game do
        include G18HNSpecHelpers

        let(:game) { build_game }

        # Finds a train by name among the upcoming trains of a fresh depot.
        def depot_train(name)
          game.depot.upcoming.find { |train| train.name == name }
        end

        context 'setup' do
          it 'deals the starting cash for each player count' do
            expect(build_game(players: 3).players.map(&:cash)).to eq([800] * 3)
            expect(build_game(players: 4).players.map(&:cash)).to eq([600] * 4)
            expect(build_game(players: 5).players.map(&:cash)).to eq([500] * 5)
          end

          it 'leaves the bank at 9600 after paying out three players' do
            expect(game.bank.cash).to eq(9_600)
          end

          it 'sets the certificate limit for each player count' do
            expect(build_game(players: 3).cert_limit).to eq(28)
            expect(build_game(players: 4).cert_limit).to eq(21)
            expect(build_game(players: 5).cert_limit).to eq(17)
          end

          it 'drops Seidler & Siebrecht from the company list by default' do
            expect(game.companies.size).to eq(12)
            expect(game.initial_auction_companies.map(&:id)).to eq(%w[HB BR FL BE FB TB OB])
          end

          it 'adds Seidler & Siebrecht and 10M per player with the optional rule' do
            seidler = ->(players) { build_game(players: players, optional_rules: [:Seidler]) }

            expect(seidler[3].companies.size).to eq(13)
            expect(seidler[3].initial_auction_companies.map(&:id)).to eq(%w[HB SS BR FL BE FB TB OB])
            expect(seidler[3].players.map(&:cash)).to eq([810] * 3)
            expect(seidler[4].players.map(&:cash)).to eq([610] * 4)
            expect(seidler[5].players.map(&:cash)).to eq([510] * 5)
          end

          it 'derives the same player order from the same game id' do
            first = Engine::Game::G18HN::Game.new(%w[a b c], id: 42)
            second = Engine::Game::G18HN::Game.new(%w[a b c], id: 42)

            expect(second.players.map(&:name)).to eq(first.players.map(&:name))
          end
        end

        context 'phases' do
          it 'runs five phases with their operating rounds and train limits' do
            corporation = game.corporations.first
            seen = []

            loop do
              seen << [game.phase.name, game.phase.operating_rounds, game.phase.train_limit(corporation)]
              break unless game.phase.upcoming

              game.phase.next!
            end

            expect(seen).to eq([['2', 1, 4], ['3', 2, 4], ['4', 2, 3], ['5', 3, 2], ['6', 3, 2]])
          end
        end

        context 'trains' do
          it 'rusts the 2 in phase 4 and the 3 in phase 6' do
            expect(depot_train('2').rusts_on).to eq('4')
            expect(depot_train('3').rusts_on).to eq('6')
            expect(%w[4 5 6].map { |name| depot_train(name).rusts_on }).to all(be_nil)
          end

          it 'closes the companies on the 5 and nowhere else' do
            carriers = game.depot.upcoming.select { |train| train.events.any? { |e| e['type'] == 'close_companies' } }

            expect(carriers.map(&:name)).to eq(['5'])
          end

          it 'stocks the depot with the printed counts and plus variants' do
            expect(game.depot.upcoming.group_by(&:name).transform_values(&:size))
              .to eq('2' => 9, '3' => 6, '4' => 5, '5' => 4, '6' => 11)

            { '2' => 100, '3' => 180, '4' => 400, '5' => 550, '6' => 720 }.each do |name, price|
              variant = depot_train(name).variants["#{name}+#{name}"]

              expect(variant).not_to be_nil, "#{name} is missing its plus variant"
              expect(variant[:price]).to eq(price)
            end
          end
        end

        context 'operating rights across the phases' do
          it 'keeps WLB out of Hessen-Kassel until the borders are gone' do
            wlb = game.corporation_by_id('WLB')
            hex = game.hex_by_id('C16')

            expect(game.phase.name).to eq('2')
            expect(game.hex_operating_rights?(wlb, hex)).to be(false)
            expect(game.borders_gone?).to be(false)

            advance_to_phase(game, '5')

            expect(game.hex_operating_rights?(wlb, hex)).to be(true)
            expect(game.borders_gone?).to be(true)
          end
        end
      end
    end
  end
end
