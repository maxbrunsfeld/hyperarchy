class QuestionNote < Prequel::Record
  column :id, :integer
  column :body, :string
  column :question_id, :integer
  column :creator_id, :integer
  column :created_at, :datetime
  column :updated_at, :datetime

  belongs_to :question
  belongs_to :creator, :class_name => 'User'
  delegate :team, :to => :question

  def before_create
    self.creator = current_user
  end

  def team_ids
    question ? question.team_ids : []
  end

  def can_create?
    team.current_user_can_create_items?
  end

  def can_update_or_destroy?
    current_user.admin? || creator_id == current_user.id || question.team.has_owner?(current_user)
  end

  alias can_update? can_update_or_destroy?
  alias can_destroy? can_update_or_destroy?

  def create_whitelist
    [:body, :question_id]
  end

  def update_whitelist
    [:body]
  end

  def extra_records_for_create_events
    [creator]
  end
end