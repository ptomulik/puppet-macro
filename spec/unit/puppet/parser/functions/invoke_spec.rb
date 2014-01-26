#! /usr/bin/env ruby -S rspec
require 'spec_helper'
require 'puppet/parser/macros'
require 'puppet/util/package' # versioncmp

describe "invoke function" do
  let(:scope) { PuppetlabsSpec::PuppetInternals.scope }
  it "should exist" do
    Puppet::Parser::Functions.function("invoke").should == "function_invoke"
  end

  [['foo'],['foo',:arg1],['foo',:arg1,:arg2]].each do |args|
    args_str = "#{args.map{|x| x.intern}.join(', ')}"
    context "invoke(#{args_str})" do
      let(:args_str) { args_str }
      before { Puppet::Parser::Macros.stubs(:call_macro).once.with(scope,args).returns :not_ok }
      it { scope.function_invoke(args).should be_nil }
    end
  end
  context "when Puppet::Parser::Macros.call_macro raises Puppet::ParseError" do
    context "invoke(['foo'])" do
      let(:msg) { 'blah blah' }
      it do
        Puppet::Parser::Macros.stubs(:call_macro).once.with(scope,['foo']).raises Puppet::ParseError, msg
        expect { scope.function_invoke(['foo']) }.to raise_error Puppet::ParseError, "invoke(): #{msg}"
      end
    end
  end
end
