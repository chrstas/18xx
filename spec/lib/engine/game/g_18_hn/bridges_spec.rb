# frozen_string_literal: true

require 'spec_helper'
require_relative 'spec_helpers'
require_relative '../../../../../lib/engine/auto_router'

module Engine
  module Game
    module G18HN
      describe Game do
        include G18HNSpecHelpers

        let(:players) { 3 }
        let(:game) { build_game(players: players, id: 1) }
        let(:hlb) { game.corporation_by_id('HLB') }
        let(:weg) { game.corporation_by_id('WEG') }
        let(:sb) { game.corporation_by_id('SB') }

        # process_action swallows GameError, so re-raise it
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

        # FL passes, nobody runs, a company without a train buys one from the depot
        def default_action(entity, actions)
          if actions.include?('run_routes')
            Action::RunRoutes.new(entity, routes: [])
          elsif actions.include?('dividend')
            Action::Dividend.new(entity, kind: 'withhold')
          elsif actions.include?('buy_train') && entity.trains.empty?
            train = game.depot.min_depot_train
            Action::BuyTrain.new(entity, train: train, price: train.price)
          else
            Action::Pass.new(entity)
          end
        end

        def play_to_track_step(corporation)
          until game.current_entity == corporation && game.round.active_step.is_a?(Engine::Step::Track)
            entity = game.current_entity
            act(default_action(entity, game.round.active_step.actions(entity)))
          end
        end

        def finish_operating_round
          round = game.round
          while game.round.equal?(round)
            entity = game.current_entity
            act(default_action(entity, game.round.active_step.actions(entity)))
          end
        end

        def lay(corporation, hex_id, tile_name, rotation)
          tile = game.tiles.find { |t| t.name == tile_name }
          act(Action::LayTile.new(corporation, tile: tile, hex: game.hex_by_id(hex_id), rotation: rotation))
        end

        def special_buy_step
          game.round.steps.find { |step| step.is_a?(G18HN::Step::SpecialBuy) }
        end

        def bridge_items(corporation)
          special_buy_step.buyable_items(corporation).map(&:description).grep(/\ABridge /)
        end

        def build_bridge(corporation, name)
          item = special_buy_step.buyable_items(corporation).find { |candidate| candidate.description == "Bridge #{name}" }
          act(Action::SpecialBuy.new(corporation, item: item))
        end

        def reload
          data = {
            'id' => 1,
            'title' => game.class.title,
            'players' => %w[a b c d e].first(players).map { |id| { 'id' => id, 'name' => id } },
            'actions' => game.actions.map(&:to_h),
          }
          Engine::Game.load(data, strict: true).maybe_raise!
        end

        def play_to_operating_round
          until game.round.is_a?(Engine::Round::Operating)
            if game.round.is_a?(G18HN::Round::Exchange)
              act(Action::Choose.new(game.current_entity, choice: 'Decline'))
            else
              finish_round
            end
          end
        end

        def water_border?(hex_id, edge)
          game.hex_by_id(hex_id).tile.borders.any? { |border| border.edge == edge && border.type == :water }
        end

        def yellow_exits(corporation, hex_id)
          hex = game.hex_by_id(hex_id)
          step = game.round.active_step
          game.tiles.uniq(&:name).select { |tile| tile.color == :yellow && game.upgrades_to?(hex.tile, tile) }
            .flat_map do |tile|
            step.legal_tile_rotations(corporation, hex, tile).map do |rotation|
              tile.rotate!(rotation)
              tile.exits
            end
          end
        end

        before { auction_all }

        it 'lets no tile lead into the river' do
          found(game.players[0], 'WEG')
          found(game.players[1], 'SB')
          finish_round
          play_to_track_step(weg)
          exits = yellow_exits(weg, 'J9')
          expect(exits).not_to be_empty
          expect(exits.flatten & [0, 5]).to be_empty

          lay(weg, 'J9', '57', 1)
          play_to_track_step(sb)
          lay(sb, 'L11', '927', 2)
          finish_operating_round
          finish_round
          play_to_track_step(sb)
          exits = yellow_exits(sb, 'K10')
          expect(exits).not_to be_empty
          expect(exits.flatten & [1, 2]).to be_empty
        end

        [3, 4, 5].each do |count|
          context "with #{count} players" do
            let(:players) { count }

            it 'lets HLB build the bridge Mainz-Wiesbaden for 60' do
              found(game.players.first, 'HLB')
              finish_round
              play_to_track_step(hlb)
              cash = hlb.cash

              build_bridge(hlb, 'Mainz-Wiesbaden')
              expect(cash - hlb.cash).to eq(60)
              expect(game.graph_for_entity(hlb).connected_hexes(hlb).keys.map(&:id)).to include('J9')
              expect(water_border?('K8', 3)).to be(false)
              expect(water_border?('J9', 0)).to be(false)
              expect(game.log.map(&:message)).to include('HLB builds the bridge Mainz-Wiesbaden for 60M')
            end
          end
        end

        context 'with HLB in Mainz' do
          before do
            found(game.players.first, 'HLB')
            finish_round
            play_to_track_step(hlb)
          end

          it 'builds one bridge per operating round' do
            expect(bridge_items(hlb)).to contain_exactly('Bridge Mainz-Wiesbaden', 'Bridge Mainz-Groß-Gerau',
                                                         'Bridge Mainz-Rüsselsheim')
            build_bridge(hlb, 'Mainz-Wiesbaden')
            expect(bridge_items(hlb)).to be_empty

            finish_operating_round
            finish_round
            play_to_track_step(hlb)
            expect(bridge_items(hlb)).to contain_exactly('Bridge Mainz-Groß-Gerau', 'Bridge Mainz-Rüsselsheim')
          end

          it 'lays track after building a bridge' do
            build_bridge(hlb, 'Mainz-Wiesbaden')
            lay(hlb, 'K6', '9', 1)
            expect(game.hex_by_id('K6').tile.name).to eq('9')
          end

          it 'builds a bridge after laying track' do
            lay(hlb, 'K6', '9', 1)
            build_bridge(hlb, 'Mainz-Wiesbaden')
            expect(game.hex_by_id('K6').tile.name).to eq('9')
            expect(water_border?('K8', 3)).to be(false)
          end

          it 'builds the bridge without the Nassau concession, but runs no further' do
            expect(game.operating_rights(hlb)).not_to include('NAS')
            build_bridge(hlb, 'Mainz-Wiesbaden')

            wiesbaden = game.hex_by_id('J9').tile.cities.first
            expect(game.graph_for_entity(hlb).connected_nodes(hlb)).not_to include(wiesbaden)
          end

          it 'offers no bridge out of reach' do
            expect(bridge_items(hlb)).not_to include('Bridge Worms-Bensheim', 'Bridge Rüdesheim-Bingen')
          end

          it 'keeps the built bridges when the game is loaded again' do
            build_bridge(hlb, 'Mainz-Wiesbaden')
            loaded = reload

            built = ->(g) { Game::BRIDGES.map { |sides| sides.all? { |id, edge| g.hex_by_id(id).tile.exits.include?(edge) } } }
            expect(built.call(loaded)).to eq(built.call(game))
            expect(built.call(loaded)).to eq([true, false, false, false, false, false])
            expect(loaded.corporation_by_id('HLB').cash).to eq(hlb.cash)
          end
        end

        context 'with a yellow tile on the bridge hex Wiesbaden' do
          let(:yellow) { game.hex_by_id('J9').tile }

          before do
            found(game.players[0], 'HLB')
            found(game.players[1], 'WEG')
            finish_round
            play_to_track_step(hlb)
            build_bridge(hlb, 'Mainz-Wiesbaden')
            play_to_track_step(weg)
            lay(weg, 'J9', '57', 1)
          end

          def upgrade_to_green
            yellow
            advance_to_phase(game, '3')
            finish_operating_round
            play_to_operating_round
            play_to_track_step(weg)
            cash = weg.cash
            lay(weg, 'J9', '442', 4)
            cash - weg.cash
          end

          it 'keeps the bridge when the game is loaded again' do
            loaded = reload

            expect(loaded.hex_by_id('J9').tile.exits).to include(0)
            loaded_hlb = loaded.corporation_by_id('HLB')
            expect(loaded.graph_for_entity(loaded_hlb).connected_hexes(loaded_hlb).keys.map(&:id)).to include('J9')
            expect(loaded.corporations.map(&:cash)).to eq(game.corporations.map(&:cash))
          end

          it 'keeps the bridge through a green upgrade that costs nothing for the river' do
            expect(upgrade_to_green).to eq(0)
            expect(game.hex_by_id('J9').tile.name).to eq('442')
            expect(game.hex_by_id('J9').tile.exits).to include(0)
            expect(game.graph_for_entity(hlb).connected_hexes(hlb).keys.map(&:id)).to include('J9')
          end

          it 'returns the yellow tile to the supply without the bridge path' do
            upgrade_to_green
            fresh = game.tiles.find { |tile| tile.name == '57' && !tile.equal?(yellow) }

            expect(game.tiles).to include(yellow)
            expect(yellow.paths.size).to eq(fresh.paths.size)
            expect(yellow.edges.map(&:num).sort).to eq(fresh.edges.map(&:num).sort)
            expect(yellow.exits).not_to include(0)
          end
        end

        context 'with a bridge to a place without a station value' do
          def build_ruesselsheim_bridge
            found(game.players.first, 'HLB')
            finish_round
            play_to_track_step(hlb)
            build_bridge(hlb, 'Mainz-Rüsselsheim')
            finish_operating_round
            finish_round
            play_to_track_step(hlb)
          end

          def hlb_route(connection_hexes)
            route = Engine::Route.new(game, game.phase, hlb.trains.first, connection_hexes: connection_hexes, routes: [])
            route.routes = [route]
            route
          end

          [3, 4, 5].each do |count|
            context "with #{count} players" do
              let(:players) { count }

              it 'runs over the bridge only once Rüsselsheim has a station value' do
                build_ruesselsheim_bridge
                expect(game.hex_by_id('K10').tile.towns.first.max_revenue).to eq(0)
                expect { hlb_route([%w[K8 K10]]).revenue }
                  .to raise_error(GameError, 'The bridge Mainz-Rüsselsheim needs a station value at both ends')

                # HLB reaches Rüsselsheim only over the bridge
                lay(hlb, 'K10', '3', 3)
                ruesselsheim = game.hex_by_id('K10').tile
                expect(ruesselsheim.name).to eq('3')
                expect(ruesselsheim.exits).to include(1)

                mainz = game.hex_by_id('K8').tile.city_towns.first.max_revenue
                expect(hlb_route([%w[K8 K10]]).revenue).to eq(mainz + ruesselsheim.towns.first.max_revenue)
              end
            end
          end

          it 'offers a tile over the bridge in a freshly loaded game' do
            build_ruesselsheim_bridge
            loaded = reload
            hex = loaded.hex_by_id('K10')
            tile = loaded.tiles.find { |candidate| candidate.name == '3' }

            # the first question to the fresh game, before anything has built its graph
            rotations = loaded.round.active_step.legal_tile_rotations(loaded.corporation_by_id('HLB'), hex, tile)
            expect(rotations).not_to be_empty
          end

          it 'lets HLB build nothing over the bridge into Nassau without the concession' do
            found(game.players.first, 'HLB')
            finish_round
            play_to_track_step(hlb)
            build_bridge(hlb, 'Mainz-Wiesbaden')
            finish_operating_round
            finish_round
            play_to_track_step(hlb)

            hex = game.hex_by_id('J9')
            step = game.round.active_step
            expect(step.available_hex(hlb, hex)).to be_nil
            tiles = game.tiles.uniq(&:name).select { |tile| tile.color == :yellow && game.upgrades_to?(hex.tile, tile) }
            expect(tiles).not_to be_empty
            expect(tiles.flat_map { |tile| step.legal_tile_rotations(hlb, hex, tile) }).to be_empty
          end

          it 'proposes no automatic route over the bridge' do
            build_ruesselsheim_bridge
            train_routes, = Engine::AutoRouter.new(game).path(game.route_trains(hlb), hlb)
            bridged = train_routes.values.flatten.select { |route| route.paths.any? { |path| game.bridge_for(path) } }
            expect(bridged).to be_empty
          end
        end

        it 'keeps the bridge when WEG lays a tile in Wiesbaden' do
          found(game.players[0], 'HLB')
          found(game.players[1], 'WEG')
          finish_round
          play_to_track_step(hlb)
          build_bridge(hlb, 'Mainz-Wiesbaden')
          play_to_track_step(weg)
          cash = weg.cash

          lay(weg, 'J9', '57', 1)
          expect(weg.cash).to eq(cash)
          expect(game.hex_by_id('J9').tile.exits).to include(0)
          expect(game.graph_for_entity(hlb).connected_hexes(hlb).keys.map(&:id)).to include('J9')
        end
      end
    end
  end
end
