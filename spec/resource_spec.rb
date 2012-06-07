require 'spec_helper'

module TestTotangoAdapter
  extend Totango::Adapters::Base

  register_adapter :test_totango_adapter
  hook_method :hook_method
  action_finder :action_name
end

class ResourceClient
  def self.hook_method(method)
    true
  end

  def action_name
    :a
  end

  include TestTotangoAdapter
end

describe Totango::Resource do
  context 'when tracking multiple activities for a single action' do
    let(:proc1) { proc { 1 == 2 } } # proc that returns false
    let(:proc2) { proc { 1 == 1 } } # proc that returns true

    subject { ResourceClient.sp_trackers.detect { |t| t.action.to_s == "a" } }

    before do
      ResourceClient.track :a, :activity => "Activity1", :if => proc1
      ResourceClient.track :a, :activity => "Activity2", :if => proc2
    end

    describe 'tracker' do
      it 'should have a conditions hash' do
        subject.opts[:conditions].keys.should =~ ["Activity1", "Activity2"]
      end
    end

    describe '#sp_run' do
      let(:rc) { ResourceClient.new }

      it 'should set the activity corresponding to proc that returns true' do
        Totango.should_receive(:track) { true }
        rc.send(:sp_run)
        subject.opts[:activity].should == "Activity2"
      end
    end
  end
end
