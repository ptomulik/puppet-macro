#! /usr/bin/env ruby -S rspec
require 'spec_helper'
require 'puppet/parser/macros'
require 'puppet/util/package' # versioncmp

describe "determine function" do
  let(:scope) { PuppetlabsSpec::PuppetInternals.scope }
  it "should exist" do
    Puppet::Parser::Functions.function("determine").should == "function_determine"
  end

  [['foo'],['foo',:arg1],['foo',:arg1,:arg2]].each do |args|
    args_str = "#{args.map{|x| x.intern}.join(', ')}"
    context "determine(#{args_str})" do
      let(:args_str) { args_str }
      it "should == Puppet::Parser::Macros.call_macro_from_function(:determine,#{args_str})" do
        Puppet::Parser::Macros.stubs(:call_macro).once.with(scope,args).returns :ok
        scope.function_determine(args).should be :ok
      end
    end
  end
end
