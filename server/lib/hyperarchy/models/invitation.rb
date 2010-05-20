class Invitation < Monarch::Model::Record
  column :guid, :string
  column :sent_to_address, :string
  column :redeemed, :boolean
  column :inviter_id, :key
  column :invitee_id, :key

  belongs_to :inviter, :class_name => "User"
  belongs_to :invitee, :class_name => "User"

  def before_create
    self.guid = Guid.new.to_s
  end

  def after_create
    Pony.mail(
      :via => :smtp,
      :smtp => SMTP_OPTIONS,
      :to => sent_to_address,
      :from => "admin@hyperarchy.com",
      :subject => "#{inviter.full_name} has invited you to join Hyperarchy",
      :body => invite_email_body
    )
  end
  
  def redeem(user_attributes)
    raise "Already redeemed" if redeemed?
    user = User.create!(user_attributes)
    self.invitee = user
    self.redeemed = true
    save
    user
  end

  protected
  def invite_email_body
    %{Visit hyperarchy.com/signup?invitation_code=#{guid} to sign up.}
  end
end