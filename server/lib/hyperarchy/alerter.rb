module Hyperarchy
  class Alerter
    def send_alerts(period)
      period = period.to_s

      User.each do |user|
        send_alerts_for_user(user, period)
      end
    end

    def send_alerts_for_user(user, period)
      alert_presenter = AlertPresenter.new(user, period)
      return if alert_presenter.sections.empty?
      Mailer.send(
        :to => user.email_address,
        :subject => alert_presenter.subject,
        :alert_presenter => alert_presenter
      )
    end

    class AlertPresenter
      attr_reader :user, :period, :sections

      def initialize(user, period)
        @user = user
        @period = period
        @sections = memberships.map do |membership|
          MembershipSection.new(membership, period) if membership.wants_alerts?(period)
        end.compact
      end

      def memberships
        user.memberships.
          join_to(Organization).
          order_by(:social).
          project(Membership)
      end

      def subject
        items = []
        items.push("questions") if new_elections?
        items.push("answers") if new_candidates?
        "New #{items.join(" and ")} on Hyperarchy"
      end

      def new_elections?
        sections.any? {|section| !section.elections_section.nil? }
      end

      def new_candidates?
        sections.any? {|section| !section.candidates_section.nil? }
      end

      class MembershipSection
        attr_reader :membership, :period, :candidates_section, :elections_section

        def initialize(membership, period)
          @membership = membership
          @period = period

          if membership.wants_candidate_alerts?(period)
            @candidates_section = CandidatesSection.new(membership, period)
          end

          if membership.wants_election_alerts?(period)
            @elections_section = ElectionsSection.new(membership, period)
          end
        end
      end

      class CandidatesSection
        attr_reader :membership, :period, :candidate_groups_by_election_id

        def initialize(membership, period)
          @membership = membership
          @period = period
          @candidate_groups_by_election_id = Hash.new do |h,election_id|
            h[election_id] = CandidateGroup.new(Election.find(election_id))
          end

          new_candidates.each do |candidate|
            candidate_groups_by_election_id[candidate.election_id].add_candidate(candidate)
          end
        end

        def new_candidates
          membership.new_candidates_in_period(period)
        end

        def candidate_groups
          candidate_groups_by_election_id.values
        end
      end

      class CandidateGroup
        attr_reader :election, :candidates

        def initialize(election)
          @election = election
          @candidates = []
        end

        def add_candidate(candidate)
          candidates.push(candidate)
        end
      end

      class ElectionsSection
        attr_reader :membership, :period, :elections

        def initialize(membership, period)
          @membership = membership
          @period = period
          @elections = membership.new_elections_in_period(period).all
        end
      end
    end
  end
end