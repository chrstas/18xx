# frozen_string_literal: true

require 'spec_helper'

module Engine
  module Game
    module G18Cuba
      describe Game do
        let(:players) { %w[a b c] }
        let(:game) { Engine::Game::G18Cuba::Game.new(players) }
        let(:minor) { game.corporations.find { |c| c.type == :minor } }

        describe '#extra_revenue' do
          it 'adds the bonus of every machine when the minor runs a train' do
            game.add_machine(minor, :yellow)
            game.add_machine(minor, :green)

            expect(game.extra_revenue(minor, [double])).to eq(30)
          end

          it 'adds nothing when the minor runs no train' do
            game.add_machine(minor, :brown)

            expect(game.extra_revenue(minor, [])).to eq(0)
          end
        end
      end
    end
  end
end
