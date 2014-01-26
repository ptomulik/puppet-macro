#! /usr/bin/env ruby -S rspec
require 'spec_helper'
require 'puppet/parser/macros'
require 'puppet/util/package' # versioncmp

describe "invoke function" do
  let(:scope) { PuppetlabsSpec::PuppetInternals.scope }
  let(:function) { Puppet::Parser::Functions.function(:invoke) }
  before { function }
  it("should exist") { function.should == "function_invoke" }
  it("should be a :statement") { Puppet::Parser::Functions.rvalue?(:invoke).should be_false }

  [['foo'],['foo',:arg1],['foo',:arg1,:arg2]].each do |args|
    args_str = "#{args.map{|x| x.intern}.join(', ')}"
    context "invoke(#{args_str})" do
      let(:args_str) { args_str }
      before { Puppet::Parser::Macros.stubs(:call_macro).once.with(scope,args).returns :ok }
      it "should == Puppet::Parser::Macros.call_macro(scope,#{args_str})" do
        scope.function_invoke(args).should be :ok
      end
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

require 'spec_helper_integration'
# These are actually "integration" tests. They test whether the function
# integerates with macros.
describe "invoke function with macros" do
  let(:scope) { PuppetlabsSpec::PuppetInternals.scope }
  let(:function) { Puppet::Parser::Functions.function(:invoke) }
  before do
    function
    Puppet::Parser::Macros.instance_variable_set(:@macros,nil)
    Puppet::Parser::Macros.newmacro 'local::a', &lambda {|a|
      (not a or a.equal?(:undef) or a.empty?) ? 'default a' : a
    }
    Puppet::Parser::Macros.newmacro 'local::b', &lambda {|b,a|
      (not b or b.equal?(:undef) or b.empty?) ? "default b for a=#{a.inspect}" : b
    }
    Puppet::Parser::Macros.newmacro 'local::c', &lambda {|b,*rest| }
  end
  after { Puppet::Parser::Macros.instance_variable_set(:@macros,nil) }

  context "invoke('local::a')" do
    it { expect { scope.function_invoke(['local::a']) }.to raise_error Puppet::ParseError, "invoke(): Wrong number of arguments (1 for 2)" }
  end
  context "invoke('local::a','foo','bar')" do
    it { expect { scope.function_invoke(['local::a','foo','bar']) }.to raise_error Puppet::ParseError, "invoke(): Wrong number of arguments (3 for 2)" }
  end
  context "invoke('local::a',nil)" do
    it { scope.function_invoke(['local::a',nil]).should == 'default a' }
  end
  context "invoke('local::a','')" do
    it { scope.function_invoke(['local::a','']).should == 'default a' }
  end
  context "invoke('local::a',:undef)" do
    it { scope.function_invoke(['local::a',:undef]).should == 'default a' }
  end
  context "invoke('local::a','custom a')" do
    it { scope.function_invoke(['local::a','custom a']).should == 'custom a' }
  end
  context "invoke('local::b')" do
    it { expect { scope.function_invoke(['local::b']) }.to raise_error Puppet::ParseError, "invoke(): Wrong number of arguments (1 for 3)" }
  end
  context "invoke('local::b','foo')" do
    it { expect { scope.function_invoke(['local::b','foo']) }.to raise_error Puppet::ParseError, "invoke(): Wrong number of arguments (2 for 3)" }
  end
  context "invoke('local::b','foo','bar','geez')" do
    it { expect { scope.function_invoke(['local::b','foo','bar','geez']) }.to raise_error Puppet::ParseError, "invoke(): Wrong number of arguments (4 for 3)" }
  end
  context "invoke('local::b',nil,nil)" do
    it { scope.function_invoke(['local::b',nil,nil]).should == 'default b for a=nil' }
  end
  context "invoke('local::b',nil,'custom a')" do
    it { scope.function_invoke(['local::b',nil,'custom a']).should == 'default b for a="custom a"' }
  end
  context "invoke('local::b','cuatom b','custom a')" do
    it { scope.function_invoke(['local::b','custom b', 'custom a']).should == "custom b" }
  end
  context "invoke('local::c')" do
    it { expect { scope.function_invoke(['local::c']) }.to raise_error Puppet::ParseError, "invoke(): Wrong number of arguments (1 for minimum 2)" }
  end
  context "invoke('local::c','foo')" do
    it { expect { scope.function_invoke(['local::c','foo']) }.to_not raise_error }
  end
  context "invoke('local::c','foo','bar')" do
    it { expect { scope.function_invoke(['local::c','foo','bar']) }.to_not raise_error }
  end
end
