#!/usr/bin/env ruby

require File.dirname(__FILE__) + '/../../spec_helper'

require 'facter/util/solaris'

describe Facter::Util::Solaris do
    it "should have a method for returning zones" do
        Facter::Util::Solaris.should respond_to(:zones)
    end

    it "should return a zonename and state for global zone" do
        zone_output_file = File.dirname(__FILE__) + '/../data/solaris_zones_single'
        zone_output = File.new(zone_output_file).read()
        Facter::Util::Solaris.expects(:get_zone_output).returns(zone_output)
        Facter::Util::Solaris.zones().should == [["global", "running"]]
    end

end
