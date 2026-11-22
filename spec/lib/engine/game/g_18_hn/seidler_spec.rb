# frozen_string_literal: true

require 'spec_helper'
require_relative 'spec_helpers'

module Engine
  module Game
    module G18HN
      describe Game do
        include G18HNSpecHelpers

        let(:game) { build_game(players: 3, optional_rules: [:Seidler], id: 1) }
        let(:a) { game.player_by_id('a') }
        let(:b) { game.player_by_id('b') }
        let(:c) { game.player_by_id('c') }
        let(:ss) { game.company_by_id('SS') }
        let(:sb) { game.corporation_by_id('SB') }
        let(:hlb) { game.corporation_by_id('HLB') }
        let(:vb) { game.corporation_by_id('VB') }
        let(:fwn) { game.corporation_by_id('FWN') }

        def act(action)
          game.process_action(action)
          raise game.exception if game.exception
        end

        def auction_all
          while game.round.is_a?(Engine::Round::Auction)
            step = game.round.active_step
            company = step.send(:auctioning)
            if company && step.send(:highest_bid, company)
              act(Action::Pass.new(game.current_entity))
            else
              target = company || step.companies.first
              act(Action::Bid.new(game.current_entity, company: target, price: step.min_bid(target)))
            end
          end
        end

        def turn_of(entity)
          act(Action::Pass.new(game.current_entity)) until game.current_entity == entity
        end

        def found(player, id)
          share_price = game.stock_market.par_prices.find { |par_price| par_price.price == 70 }
          turn_of(player)
          act(Action::Par.new(player, corporation: game.corporation_by_id(id), share_price: share_price))
          3.times do
            turn_of(player)
            share = game.corporation_by_id(id).ipo_shares.select(&:buyable).min_by(&:percent)
            act(Action::BuyShares.new(player, shares: share, share_price: share.price, percent: share.percent))
          end
        end

        def finish_round
          round = game.round
          act(Action::Pass.new(game.current_entity)) while game.round.equal?(round)
        end

        def default_action(entity, actions, trains)
          if actions.include?('run_routes')
            Action::RunRoutes.new(entity, routes: [])
          elsif actions.include?('dividend')
            Action::Dividend.new(entity, kind: 'withhold')
          elsif actions.include?('buy_train') && (entity.trains.empty? || trains[entity.id].to_i.positive?)
            trains[entity.id] = trains[entity.id].to_i - 1
            train = game.depot.min_depot_train
            Action::BuyTrain.new(entity, train: train, price: train.price)
          else
            Action::Pass.new(entity)
          end
        end

        def play_to_track_step(corporation, trains = {})
          until game.current_entity == corporation && game.round.active_step.is_a?(Engine::Step::Track)
            if game.round.is_a?(G18HN::Round::Exchange)
              act(Action::Choose.new(game.current_entity, choice: 'Decline'))
            elsif game.round.stock?
              act(Action::Pass.new(game.current_entity))
            else
              entity = game.current_entity
              act(default_action(entity, game.round.active_step.actions(entity), trains))
            end
          end
        end

        def special_track
          game.round.steps.find { |step| step.instance_of?(G18HN::Step::SpecialTrack) }
        end

        def seidler_hexes
          game.hexes.select { |hex| special_track.available_hex(ss, hex) }.map(&:id)
        end

        def track_hexes(corporation)
          game.hexes.select { |hex| game.round.active_step.available_hex(corporation, hex) }.map(&:id)
        end

        def rotations(entity, step, hex_id)
          hex = game.hex_by_id(hex_id)
          step.potential_tiles(entity, hex).to_h { |tile| [tile.name, step.legal_tile_rotations(entity, hex, tile)] }
        end

        def connected_hexes(corporation)
          game.graph_for_entity(corporation).connected_hexes(corporation).keys.map(&:id)
        end

        before { auction_all }

        context 'with SB directed by the owner of SS' do
          before do
            found(c, 'SB')
            found(b, 'HLB')
            found(a, 'MNB')
            finish_round
          end

          it 'offers a tile lay only to a company the owner of SS directs' do
            expect([ss.owner, sb.owner, hlb.owner]).to eq([c, c, b])
            play_to_track_step(sb)
            expect(special_track.actions(ss)).to include('lay_tile')

            lay(sb, 'L11', '927', 2)
            play_to_track_step(hlb)
            expect(special_track.actions(ss)).to be_empty
          end

          context 'in the second operating round' do
            before do
              play_to_track_step(sb)
              lay(sb, 'L11', '927', 2)
              play_to_track_step(sb)
            end

            it 'lays on a mountain for free, closes and leaves no regular lay' do
              expect(game.hex_by_id('M12').tile.upgrades.map(&:cost)).to eq([40])
              cash = sb.cash

              lay(ss, 'M12', '7', 1)
              expect(sb.cash).to eq(cash)
              expect(ss).to be_closed
              expect { lay(sb, 'K10', '58', 3) }.to raise_error(GameError)
            end

            it 'offers the hexes and rotations of the regular lay' do
              expect(seidler_hexes).to match_array(track_hexes(sb))
              expect(seidler_hexes).to match_array(%w[L11 K10 M10 M12])
              %w[K10 M10 M12].each do |hex_id|
                expect(rotations(ss, special_track, hex_id)).to eq(rotations(sb, game.round.active_step, hex_id))
              end
            end

            it 'offers no hex the company does not reach' do
              expect(connected_hexes(sb)).not_to include('N13')
              expect(seidler_hexes).not_to include('N13')
            end

            it 'offers no Frankfurt hex' do
              lay(sb, 'K10', '58', 3)
              play_to_track_step(sb)
              expect(connected_hexes(sb)).to include('J11')
              expect(track_hexes(sb)).not_to include('J11')
              expect(seidler_hexes).not_to include('J11')
              expect { lay(ss, 'J11', '921', 0) }.to raise_error(GameError, /Frankfurt/)
            end
          end

          it 'upgrades in green' do
            play_to_track_step(sb)
            lay(sb, 'L11', '927', 2)
            play_to_track_step(sb, 'SB' => 4, 'HLB' => 4, 'MNB' => 2)
            expect(game.phase.name).to eq('3')
            expect(special_track.actions(ss)).to include('lay_tile')

            lay(ss, 'L11', '931', 5)
            expect(game.hex_by_id('L11').tile.color).to eq(:green)
            expect(ss).to be_closed
          end
        end

        context 'with VB directed by the owner of SS' do
          before do
            found(c, 'VB')
            found(b, 'HLB')
            finish_round
            play_to_track_step(vb)
            lay(vb, 'F17', '57', 2)
            play_to_track_step(vb)
          end

          it 'offers no hex in another country without its concession' do
            expect(connected_hexes(vb)).to include('E16')
            expect(game.hex_operating_rights?(vb, game.hex_by_id('E16'))).to be(false)
            expect(track_hexes(vb)).not_to include('E16')
            expect(seidler_hexes).not_to include('E16')
            expect { lay(ss, 'E16', '8', 0) }.to raise_error(GameError, /operating rights/)
          end
        end

        context 'with FWN directed by the owner of SS' do
          before do
            found(c, 'FWN')
            found(b, 'HLB')
            finish_round
            play_to_track_step(fwn)
          end

          it 'refuses a tile without the label of the hex' do
            expect(game.hex_by_id('C18').tile.label.to_s).to eq('KGD')
            expect(game.tiles.find { |tile| tile.name == '57' }.label).to be_nil
            expect(rotations(fwn, game.round.active_step, 'C18')).not_to have_key('57')

            expect { lay(ss, 'C18', '57', 0) }.to raise_error(GameError, /not upgradeable/)
            expect(ss).not_to be_closed
          end
        end
      end
    end
  end
end
