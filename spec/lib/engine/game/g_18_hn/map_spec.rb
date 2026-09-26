# frozen_string_literal: true

require 'spec_helper'
require_relative 'spec_helpers'

module Engine
  module Game
    module G18HN
      describe Game do
        include G18HNSpecHelpers

        let(:game) { build_game }
        let(:regions) { described_class::NATIONAL_REGION_HEXES }
        let(:region_entries) { regions.values.flatten }
        let(:frame_regions) { { 'plum' => 'KAS', 'yellow' => 'WAL', 'lightgreen' => 'NAS', 'white' => 'DAR' } }

        context 'regions' do
          it 'assigns every hex on the map to exactly one region' do
            expect(game.hexes.size).to eq(94)
            expect(region_entries.size).to eq(94)
            expect(region_entries.sort).to eq(game.hexes.map(&:name).sort)
          end

          it 'never lists a hex in two regions' do
            expect(region_entries.tally.select { |_, count| count > 1 }).to be_empty
          end

          it 'frames each hex in the colour of its region' do
            mismatched = game.hexes.select { |hex| hex.tile.frame }.reject do |hex|
              regions[frame_regions[hex.tile.frame.color]]&.include?(hex.name)
            end

            expect(mismatched.map { |hex| [hex.name, hex.tile.frame.color] }).to be_empty
          end

          it 'puts unframed and red hexes into ALL' do
            open_hexes = game.hexes.select { |hex| !hex.tile.frame || hex.tile.color == :red }.map(&:name)

            expect(open_hexes - regions['ALL']).to be_empty
          end

          it 'puts every home hex into the region the corporation may operate in' do
            misplaced = game.corporations.reject do |corporation|
              regions[described_class::CORPORATIONS_OPERATING_RIGHTS[corporation.id]].include?(corporation.coordinates)
            end

            expect(misplaced.map(&:id)).to be_empty
          end
        end

        context 'transit bonus' do
          it 'matches the printed legend row by row' do
            legend = game.map_legend('black')

            expect(legend[1].map { |cell| cell[:text] }).to eq(%w[Ausland S N O W])

            body = legend.drop(2)
            expect(body.size).to eq(described_class::TRANSIT_REGIONS.size)

            body.each do |row|
              region, direction = row.first[:text].split
              data = described_class::TRANSIT_REGIONS[region]

              expect(data).not_to be_nil, "#{region} is missing from TRANSIT_REGIONS"
              expect(data[:dir]).to eq(direction.to_sym), region
              expect(%i[S N O W].map { |key| data[key] })
                .to eq(row.drop(1).map { |cell| cell[:text].delete('+').to_i }), region
            end
          end

          it 'pays the same for both directions of travel' do
            pairs = described_class::TRANSIT_REGIONS.keys.combination(2).to_a
            expect(pairs.size).to eq(28)

            pairs.each do |a, b|
              expect(game.transit_bonus(a, b)).to eq(game.transit_bonus(b, a)), "#{a} / #{b}"
            end
          end

          it 'pays the corrected values for the three neighbouring pairs' do
            expect(game.transit_bonus('Ostwestfalen', 'Südwestfalen')).to eq(30)
            expect(game.transit_bonus('Ostwestfalen', 'Rheinland')).to eq(70)
            expect(game.transit_bonus('Südwestfalen', 'Thüringen')).to eq(50)
          end
        end

        context 'labels and tiles' do
          it 'has a tile for every label used on the map' do
            map_labels = game.hexes.filter_map { |hex| hex.tile.label&.to_s }.uniq
            tile_labels = game.tiles.filter_map { |tile| tile.label&.to_s }.uniq

            expect(map_labels.sort).to eq(%w[F/E F/W Hom KGD MZ])
            expect(map_labels - tile_labels).to be_empty
          end

          it 'upgrades the western Frankfurt tile only along its own label' do
            tile = ->(name) { game.tiles.find { |t| t.name == name } }

            expect(game.upgrades_to?(tile['921'], tile['923'])).to be(true)
            expect(game.upgrades_to?(tile['921'], tile['924'])).to be(false)
          end

          it 'only lets the privates lay tiles that exist' do
            laid = game.companies.flat_map { |company| company.all_abilities.select { |a| a.type == :tile_lay } }
              .flat_map(&:tiles).uniq

            expect(laid).not_to be_empty
            expect(laid - described_class::TILES.keys).to be_empty
          end
        end

        context 'tiles' do
          # the colours a hex of the given colour can still be upgraded to
          let(:later_colors) { { white: %i[yellow green brown], yellow: %i[green brown], green: %i[brown] } }

          it 'resolves every id in TILES to a tile in the game' do
            expect(described_class::TILES.size).to eq(63)

            missing = described_class::TILES.keys.reject { |id| game.tiles.any? { |tile| tile.name == id } }
            expect(missing).to be_empty
          end

          it 'builds the preprinted tile of every map hex' do
            expect(described_class::HEXES.values.flat_map(&:keys).flatten.size).to eq(94)

            described_class::HEXES.each do |color, definitions|
              definitions.each do |coordinates, code|
                coordinates.each do |coordinate|
                  hex = game.hex_by_id(coordinate)

                  expect(hex).not_to be_nil, coordinate
                  expect(hex.tile.color).to eq(color), coordinate
                  expect { Engine::Tile.from_code(coordinate, color, code) }.not_to raise_error
                end
              end
            end
          end

          it 'leaves no white, yellow or green hex without a legal upgrade' do
            # E15: the labels T and O on the Taunus and Odenwald hexes made these dead ends
            open_hexes = game.hexes.select { |hex| later_colors.key?(hex.tile.color) }
            expect(open_hexes.size).to eq(78)

            dead_ends = open_hexes.reject { |hex| game.tiles.any? { |tile| game.upgrades_to?(hex.tile, tile) } }
            expect(dead_ends.map(&:name)).to be_empty
          end

          it 'stocks every map label in the colours that still follow its hex' do
            expected = {
              'KGD' => { yellow: 4, green: 4, brown: 3 },
              'MZ' => { yellow: 1, green: 1, brown: 1 },
              'F/W' => { yellow: 1, green: 1, brown: 1 },
              'F/E' => { yellow: 1, green: 1, brown: 1 },
              'Hom' => { brown: 1 },
            }

            game.hexes.each do |hex|
              label = hex.tile.label&.to_s
              next unless label

              counts = game.tiles.select { |tile| tile.label&.to_s == label }
                .group_by(&:color).transform_values(&:size)

              expect(counts.keys.sort).to eq(later_colors[hex.tile.color].sort), label
              expect(counts).to eq(expected[label]), label
            end
          end

          it 'holds the measured number of tiles per colour' do
            expect(game.tiles.group_by(&:color).transform_values(&:size)).to eq(yellow: 68, green: 49, brown: 38)
          end
        end
      end
    end
  end
end
