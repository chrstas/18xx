# frozen_string_literal: true

require 'spec_helper'
require_relative 'spec_helpers'

module Engine
  module Game
    module G18HN
      describe Game do
        include G18HNSpecHelpers

        let(:game) { build_game }

        context 'concessions' do
          it 'covers the four home regions and leaves Frankfurt without one' do
            home_regions = described_class::CORPORATIONS_OPERATING_RIGHTS.values.uniq

            expect(described_class::CONCESSION_REGIONS.values.uniq.sort).to eq(home_regions.sort)
            expect(described_class::CONCESSION_REGIONS).not_to have_key('FC')
            expect(described_class::CONCESSIONS).to include('FC')
          end

          it 'backs every concession with an unbuyable company' do
            described_class::CONCESSIONS.each do |id|
              company = game.company_by_id(id)

              expect(company).not_to be_nil, "#{id} has no company"
              expect(company.all_abilities.map(&:type)).to include(:no_buy), id
            end
          end

          it 'hands each concession to exactly one private' do
            acquired = game.companies.flat_map do |company|
              company.all_abilities.select { |a| a.type == :acquire_company }.map(&:company)
            end

            expect(acquired.sort).to eq(described_class::CONCESSIONS.sort)
          end
        end

        context 'corporations' do
          it 'needs 50 percent to float' do
            expect(game.corporations.size).to eq(10)
            expect(game.corporations.map(&:percent_to_float)).to all(eq(50))
          end

          it 'reserves a single share for the four exchangeable corporations' do
            reserved = game.corporations.to_h { |corporation| [corporation.id, corporation.reserved_shares.sum(&:percent)] }

            expect(reserved.select { |_, percent| percent.positive? }).to eq('SB' => 10, 'WEG' => 10, 'FHB' => 10, 'WLB' => 10)
            expect(reserved.reject { |_, percent| percent.positive? }.keys).to eq(%w[MNB HLB VB LTB MWB FWN])
          end
        end
      end
    end
  end
end
