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
      before { Puppet::Parser::Macros.stubs(:call_macro_from_func).once.with(scope,:determine,args).returns :ok }
      it "should == Puppet::Parser::Macros.call_macro_from_func(scope,:determine,#{args_str})" do
        scope.function_determine(args).should be :ok
      end
    end
  end
  context "when Puppet::Parser::Macros.call_macro_from_func raises Puppet::ParseError with message 'blah blah'" do
    context "determine(['foo'])" do
      let(:msg) { 'blah blah' }
      it do
        Puppet::Parser::Macros.stubs(:call_macro_from_func).once.with(scope,:determine,['foo']).raises Puppet::ParseError, msg
        expect { scope.function_determine(['foo']) }.to raise_error Puppet::ParseError, msg
      end
    end
  end
end

require 'spec_helper_integration'
# These are actually "integration" tests. They test whether the function
# integerates with macros.
describe "determine function with macros" do
  let(:scope) { PuppetlabsSpec::PuppetInternals.scope }
  let(:function) { Puppet::Parser::Functions.function(:determine) }
  before do
    function
    Puppet::Parser::Macros.instance_variable_set(:@macros,nil)
    Puppet::Parser::Macros.newmacro 'local::a', &Proc.new {|a|
      (not a or a.equal?(:undef) or a.empty?) ? 'default a' : a
    }
    Puppet::Parser::Macros.newmacro 'local::b', &Proc.new {|b,a|
      (not b or b.equal?(:undef) or b.empty?) ? "default b for a=#{a.inspect}" : b
    }
    Puppet::Parser::Macros.newmacro 'local::c', &Proc.new {|b,*rest| }
  end
  after { Puppet::Parser::Macros.instance_variable_set(:@macros,nil) }

  context "determine('local::a')" do
    it { expect { scope.function_determine(['local::a']) }.to raise_error Puppet::ParseError, "determine(): Wrong number of arguments (1 for 2)" }
  end
  context "determine('local::a','foo','bar')" do
    it { expect { scope.function_determine(['local::a','foo','bar']) }.to raise_error Puppet::ParseError, "determine(): Wrong number of arguments (3 for 2)" }
  end
  context "determine('local::a',nil)" do
    it { scope.function_determine(['local::a',nil]).should == 'default a' }
  end
  context "determine('local::a','')" do
    it { scope.function_determine(['local::a','']).should == 'default a' }
  end
  context "determine('local::a',:undef)" do
    it { scope.function_determine(['local::a',:undef]).should == 'default a' }
  end
  context "determine('local::a','custom a')" do
    it { scope.function_determine(['local::a','custom a']).should == 'custom a' }
  end
  context "determine('local::b')" do
    it { expect { scope.function_determine(['local::b']) }.to raise_error Puppet::ParseError, "determine(): Wrong number of arguments (1 for 3)" }
  end
  context "determine('local::b','foo')" do
    it { expect { scope.function_determine(['local::b','foo']) }.to raise_error Puppet::ParseError, "determine(): Wrong number of arguments (2 for 3)" }
  end
  context "determine('local::b','foo','bar','geez')" do
    it { expect { scope.function_determine(['local::b','foo','bar','geez']) }.to raise_error Puppet::ParseError, "determine(): Wrong number of arguments (4 for 3)" }
  end
  context "determine('local::b',nil,nil)" do
    it { scope.function_determine(['local::b',nil,nil]).should == 'default b for a=nil' }
  end
  context "determine('local::b',nil,'custom a')" do
    it { scope.function_determine(['local::b',nil,'custom a']).should == 'default b for a="custom a"' }
  end
  context "determine('local::b','cuatom b','custom a')" do
    it { scope.function_determine(['local::b','custom b', 'custom a']).should == "custom b" }
  end
  context "determine('local::c')" do
    it { expect { scope.function_determine(['local::c']) }.to raise_error Puppet::ParseError, "determine(): Wrong number of arguments (1 for minimum 2)" }
  end
  context "determine('local::c','foo')" do
    it { expect { scope.function_determine(['local::c','foo']) }.to_not raise_error }
  end
  context "determine('local::c','foo','bar')" do
    it { expect { scope.function_determine(['local::c','foo','bar']) }.to_not raise_error }
  end
end
