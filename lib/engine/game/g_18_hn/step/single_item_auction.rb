# frozen_string_literal: true

require_relative '../../../step/base'
require_relative '../../../step/passable_auction'

module Engine
  module Game
    module G18HN
      module Step
        # ch. 6: the privates are auctioned one after another in a fixed order
        class SingleItemAuction < Engine::Step::Base
          include Engine::Step::PassableAuction
          ACTIONS = %w[bid pass].freeze

          attr_reader :companies

          def actions(entity)
            return [] if @companies.empty?

            entity == current_entity ? ACTIONS : []
          end

          def description
            'Bid on Companies'
          end

          def available
            @companies
          end

          def active_auction
            yield @auctioning, @bids[@auctioning]
          end

          # ch. 6: the opener rotates with the position in the start packet, whoever won before
          def initial_auction_entities
            entities.rotate(@game.initial_auction_companies.index(@auctioning))
          end

          def active_entities
            winning_bid = highest_bid(@auctioning)
            return [@active_bidders.first] unless winning_bid

            [@active_bidders[(@active_bidders.index(winning_bid.entity) + 1) % @active_bidders.size]]
          end

          # ch. 6: whoever passes is out for this private, the opener too
          def process_pass(action)
            pass_auction(action.entity)
            resolve_bids
          end

          def process_bid(action)
            raise GameError, "#{action.company.name} is not up for auction" unless action.company == @auctioning

            add_bid(action)
          end

          def min_increment
            @game.class::MIN_BID_INCREMENT
          end

          def setup
            setup_auction
            @companies = @game.initial_auction_companies.reject(&:owner)

            auction_entity_log(@companies.first) unless @companies.empty?
          end

          def auction_entity_log(entity)
            @game.log << "#{entity.name} is up for auction, minimum bid is #{@game.format_currency(min_bid(entity))}"
            auction_entity(entity)
          end

          def min_bid(company)
            return unless company
            return company.min_bid if @bids[company].empty?

            highest_bid(company).price + min_increment
          end

          def may_purchase?(_company)
            false
          end

          def max_bid(player, _company)
            player.cash
          end

          private

          def add_bid(bid)
            @log << "#{bid.entity.name} bids #{@game.format_currency(bid.price)} for #{bid.company.name}"
            super
            resolve_bids
          end

          def win_bid(winner, company)
            return no_bids(company) unless winner

            player = winner.entity
            price = winner.price
            company.owner = player
            player.companies << company
            player.spend(price, @game.bank) if price.positive?
            @companies.delete(company)
            @log << "#{player.name} wins the auction for #{company.name} with a bid of #{@game.format_currency(price)}"
            # the concession right of the private comes with it
            @game.after_buy_company(player, company, price)
          end

          def no_bids(company)
            # ch. 6: an unwanted Homburger Bahn gets 5 cheaper each time until the opener must take it for 0
            return unless company == @game.company_by_id('HB')

            company.discount += 5
            @log << "Nobody bids on #{company.name}, minimum bid drops to #{@game.format_currency(company.min_bid)}"
          end

          def post_win_bid(winner, company)
            # avoid recursion while the game is still being set up
            return if @game.players.empty?
            return restart_auction(company) unless winner

            @companies.empty? ? pass! : auction_entity_log(@companies.first)
          end

          def restart_auction(company)
            # TODO: 7.3 short operating round before the restart (rulebook ch. 6)
            auction_entity_log(company)
            return unless company.min_bid.zero?

            add_bid(Engine::Action::Bid.new(@active_bidders.first, company: company, price: 0))
          end
        end
      end
    end
  end
end
