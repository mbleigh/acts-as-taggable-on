require File.dirname(__FILE__) + '/../spec_helper'

describe "Tagger" do
  before(:each) do
    @user = User.new
  end
  
  it { @user.should respond_to(:owned_taggings) }
  it { @user.should respond_to(:owned_tags) }
  it { @user.should respond_to(:is_tagger?)}
  it { @user.should respond_to(:tag) }
end