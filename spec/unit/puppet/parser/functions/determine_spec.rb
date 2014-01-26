#! /usr/bin/env ruby -S rspec
require 'spec_helper'
require 'puppet/parser/macros'
require 'puppet/util/package' # versioncmp

describe "determine function" do
  let(:scope) { PuppetlabsSpec::PuppetInternals.scope }
  let(:function) { Puppet::Parser::Functions.function(:determine) }
  before { function }
  it("should exist"){ function.should == "function_determine" }
  it("should be an :rvalue") { Puppet::Parser::Functions.rvalue?(:determine).should be_true }

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
  context "when Puppet::Parser::Macros.call_macro raises Puppet::ParseError" do
    context "determine(['foo'])" do
      let(:msg) { 'blah blah' }
      it do
        Puppet::Parser::Macros.stubs(:call_macro).once.with(scope,['foo']).raises Puppet::ParseError, msg
        expect { scope.function_determine(['foo']) }.to raise_error Puppet::ParseError, "determine(): #{msg}"
      end
    end
  end
end
