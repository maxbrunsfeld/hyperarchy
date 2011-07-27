module Views
  module NotificationMailer
    class Notification < Erector::Widget
      attr_reader :presenter

      def content
        html do
          body do
            div :style => "font-size: 14px; font-family: 'Helvetica Neue', Arial, 'Liberation Sans', FreeSans, sans-serif;"  do
              presenter.membership_presenters.each do |membership_presenter|
                membership_section(membership_presenter)
              end
              div :style => "margin-top: 20px; width: 550px;" do
                rawtext "To change the frequency of these notifications or unsubscribe entirely, "
                a "visit your account preferences page", :href => account_url, :style => "color: #000094; white-space: nowrap;"
                text "."
              end
            end
          end
        end
      end

      def membership_section(presenter)
        if num_membership_presenters > 1
          h1 "#{presenter.team.name}", :style => "font-size: 22px;"
        end
        h2 presenter.headline
        presenter.meeting_presenters.each do |meeting_presenter|
          meeting_section(meeting_presenter)
        end
      end

      def meeting_section(presenter)
        meeting = presenter.meeting

        color = presenter.meeting_is_new ? "black" : "#888"

        div :style => "background: #eee; border: 1px solid #DDD; margin-bottom: 10px; max-width: 500px; color: #{color};" do
          div :style => "margin: 8px;" do
            a "View Meeting", :href => meeting_url(meeting), :style => "float: right; padding: 5px 15px; background: white; margin-left: 10px; color: #000094;"
            div meeting.body, :style => "padding: 0px; padding-top: 5px;"
            div :style => "clear: both;"
          end

          unless presenter.agenda_item_presenters.empty?
            div :style => "max-height: 400px; overflow-y: auto; padding: 0px 8px; margin-top: 8px;" do
              div :style => "margin-top: 8px;" do
                presenter.agenda_item_presenters.each do |agenda_item_presenter|
                  agenda_item_section(agenda_item_presenter)
                end
              end
            end
          end
        end
      end

      def agenda_item_section(presenter)
        agenda_item = presenter.agenda_item
        color = presenter.agenda_item_is_new ? "black" : "#888"

        div :style => "margin-bottom: 8px; background: white; color: #{color};" do
          div agenda_item.body, :style => "float: left; padding: 8px; margin-bottom: -8px;"
          div raw("&mdash;#{agenda_item.creator.full_name}"), :style => "white-space: nowrap; float: right; font-style: italic; color: #777; padding: 8px;"
          div :style => "clear: both;"

          unless presenter.new_notes.empty?
            div :style => "padding: 8px; padding-top: 0px;" do
              div :style => "padding: 8px; background: white; color: black; border: 2px solid #ddd; font-size: 13px;" do
                div "Notes", :style => "margin-bottom: 16px; font-weight: bold;"
                presenter.new_notes.each do |note|
                  note_section(note)
                end
              end
            end
          end
        end
      end

      def note_section(note)
        div do
          div :style => "color: #777; border-bottom: 1px solid #f0f0f0; margin-bottom: 4px;" do
            div note.creator.full_name, :style => "font-style: italic;"
          end

          div note.body, :style => "margin-bottom: 16px;"
        end
      end

      def num_membership_presenters
        presenter.membership_presenters.length
      end
    end
  end
end