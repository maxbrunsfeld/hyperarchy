require 'spec_helper'

describe BackdoorController do
  describe "#create" do
    it "merges the given field_values into a plan generated by the blueprint for the model being created" do
      expect {
        post :create, :relation => "users", :field_values => { :first_name => "Joe" }
        response.should be_success
      }.to change(User, :count).by(1)

      user = User.find(response_json['id'])

      user.first_name.should == "Joe"
      user.last_name.should_not be_blank
      response_json.should == user.wire_representation
    end
  end

  describe "#clear_tables" do
    it "clears all tables in the database" do
      User.make
      User.should_not be_empty
      post :clear_tables
      response.should be_success
      User.should be_empty
    end
  end
end
