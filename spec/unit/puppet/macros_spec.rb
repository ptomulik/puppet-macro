#! /usr/bin/env ruby -S rspec
require 'spec_helper'
require 'puppet/macros'

describe Puppet::Macros do
  before { described_class.instance_variable_set(:@macros,nil) }

  [
    :valid_name?,
    :validate_name,
    :macro_arities_by_parameters,
    :macro_arities_by_arity,
    :macro_arities,
    :check_macro_arity,
    :default_environment,
    :newmacro,
    :macros,
    :macro,
    :autoloader,
    :load,
    :load_from_file,
    :loadall,
    :get_macro,
    :fix_error_msg,
    :call_macro,
    :call_macro_from_func
  ].each do |method|
    it "should respond to #{method}" do
      described_class.should respond_to method
    end
  end

  # From Validation module
  describe 'valid_name?' do
    [1,nil,{},[],'9','1ad','',':','::','::9','::asd::'].each do |name|
      context "validat_name?(#{name.inspect})" do
        let(:name) { name }
        it { described_class.valid_name?(name).should be_false }
      end
    end
    ['a','_','a1::b2','_::__1'].each do |name|
      context "validate_name?(#{name.inspect})" do
        let(:name) { name }
        it { described_class.valid_name?(name).should be_true }
      end
    end
  end

  describe 'validate_name' do
    [1,nil,{},[],'9','1ad','',':','::','::9','::asd::'].each do |name|
      context "validate_name(#{name.inspect})" do
        let(:name) { name }
        it do
          expect { described_class.validate_name(name) }.to raise_error ArgumentError, "Invalid macro name #{name.inspect}"
        end
      end
    end
    ['a','_','a1::b2','_::__1'].each do |name|
      context "validate_name(#{name.inspect})" do
        let(:name) { name }
        it { expect { described_class.validate_name(name) }.to_not raise_error }
      end
    end
  end

  if Puppet::Util::Package.versioncmp(RUBY_VERSION,'1.9') >= 0
    describe 'macro_arities_by_parameters' do
      context 'macro_arities_by_parameters(lambda{})' do
        let(:macro) { lambda{} }
        it { described_class.macro_arities_by_parameters(macro).should == [0,0] }
      end
      context 'macro_arities_by_parameters(lambda{|x|})' do
        let(:macro) { lambda{|x|} }
        it { described_class.macro_arities_by_parameters(macro).should == [1,1] }
      end
      context 'macro_arities_by_parameters(lambda{|x,y|})' do
        let(:macro) { lambda{|x,y|} }
        it { described_class.macro_arities_by_parameters(macro).should == [2,2] }
      end
      context 'macro_arities_by_parameters(lambda{|*x|})' do
        let(:macro) { lambda{|*x|} }
        it { described_class.macro_arities_by_parameters(macro).should == [0,:inf] }
      end
      context 'macro_arities_by_parameters(lambda{|x,*y|})' do
        let(:macro) { lambda{|x,*y|} }
        it { described_class.macro_arities_by_parameters(macro).should == [1,:inf] }
      end
      context 'macro_arities_by_parameters(lambda{|x,y=nil|})' do
        let(:macro) { Kernel.eval('lambda{|x,y=nil|}')} # must eval, otherwise it would break compilation on 1.8
        it { described_class.macro_arities_by_parameters(macro).should == [1,2] }
      end
      context 'macro_arities_by_parameters(lambda{|x,y=nil,*z|})' do
        let(:macro) { Kernel.eval('lambda{|x,y=nil,*z|}')} # must eval, otherwise it would break compilation on 1.8
        it { described_class.macro_arities_by_parameters(macro).should == [1,:inf] }
      end
      context 'macro_arities_by_parameters(lambda{|x,y=nil,*z,v|})' do
        let(:macro) { Kernel.eval('lambda{|x,y=nil,*z,v|}')} # must eval, otherwise it would break compilation on 1.8
        it { described_class.macro_arities_by_parameters(macro).should == [2,:inf] }
      end
    end
  end

  describe 'macro_arities_by_arity' do
    context 'macro_arities_by_arity(lambda{||})' do
      let(:macro) { lambda{||} }
      it { described_class.macro_arities_by_arity(macro).should == [0,0] }
    end
    context 'macro_arities_by_arity(lambda{|x|})' do
      let(:macro) { lambda{|x|} }
      it { described_class.macro_arities_by_arity(macro).should == [1,1] }
    end
    context 'macro_arities_by_arity(lambda{|x,y|})' do
      let(:macro) { lambda{|x,y|} }
      it { described_class.macro_arities_by_arity(macro).should == [2,2] }
    end
    context 'macro_arities_by_arity(lambda{|*x|})' do
      let(:macro) { lambda{|*x|} }
      it { described_class.macro_arities_by_arity(macro).should == [0,:inf] }
    end
    context 'macro_arities_by_arity(lambda{|x,*y|})' do
      let(:macro) { lambda{|x,*y|} }
      it { described_class.macro_arities_by_arity(macro).should == [1,:inf] }
    end
    if Puppet::Util::Package.versioncmp(RUBY_VERSION,'1.9') >= 0
      # This actually shows how 'arity' fails for default parameters on
      # different ruby versions
      if Puppet::Util::Package.versioncmp(RUBY_VERSION,'2.0') < 0
        context 'macro_arities_by_arity(lambda{|x,y=nil|})' do
          let(:macro) { Kernel.eval('lambda{|x,y=nil|}')} # must eval, otherwise it would break compilation on 1.8
          it { described_class.macro_arities_by_arity(macro).should == [1,1] }
        end
      else
        context 'macro_arities_by_arity(lambda{|x,y=nil|})' do
          let(:macro) { Kernel.eval('lambda{|x,y=nil|}')} # must eval, otherwise it would break compilation on 1.8
          it { described_class.macro_arities_by_arity(macro).should == [1,:inf] }
        end
      end
      context 'macro_arities_by_arity(lambda{|x,*y,z|})' do
        let(:macro) { Kernel.eval('lambda{|x,*y,z|}') } # must eval, otherwise it would break compilation on 1.8
        it { described_class.macro_arities_by_arity(macro).should == [2,:inf] }
      end
    end
  end

  describe 'macro_arities' do
    context 'on objects having "parameters" method' do
      let(:macro) { stub('macro', :parameters => []) }
      before do
        described_class.stubs(:macro_arities_by_parameters).once.with(macro).returns :ok
        described_class.stubs(:macro_arities_by_arity).never
      end
      it("should == macro_arities_by_parameters(macro)") { described_class.macro_arities(macro).should be :ok }
    end
    context 'on objects that do not have "parameters" method' do
      let(:macro) { stub('macro') }
      before do
        described_class.stubs(:macro_arities_by_parameters).never
        described_class.stubs(:macro_arities_by_arity).once.with(macro).returns :ok
      end
      it("should == macro_arities_by_arity(macro)"){ described_class.macro_arities(macro).should be :ok }
    end
  end

  describe 'check_macro_arity' do
    context 'check_macro_arity(lambda{},[])' do
      it { expect { described_class.check_macro_arity(lambda{},[]) }.to_not raise_error }
    end
    context 'check_macro_arity(lambda{||},[])' do
      it { expect { described_class.check_macro_arity(lambda{||},[]) }.to_not raise_error }
    end
    context 'check_macro_arity(lambda{||},[:arg1])' do
      it { expect { described_class.check_macro_arity(lambda{||},[:arg1]) }.to raise_error ArgumentError, "Wrong number of arguments (1 for 0)"}
    end
    context 'check_macro_arity(lambda{|x|},[:arg1])' do
      it { expect { described_class.check_macro_arity(lambda{|x|},[:arg1]) }.to_not raise_error }
    end
    context 'check_macro_arity(lambda{|x|},[])' do
      it { expect { described_class.check_macro_arity(lambda{|x|},[]) }.to raise_error ArgumentError, "Wrong number of arguments (0 for 1)"}
    end
    context 'check_macro_arity(lambda{|x|},[:arg1,:arg2])' do
      it { expect { described_class.check_macro_arity(lambda{|x|},[:arg1,:arg2]) }.to raise_error ArgumentError, "Wrong number of arguments (2 for 1)"}
    end
    context 'check_macro_arity(lambda{|*x|},[])' do
      it { expect { described_class.check_macro_arity(lambda{|*x|},[]) }.to_not raise_error }
    end
    context 'check_macro_arity(lambda{|*x|},[:arg1,:arg2])' do
      it { expect { described_class.check_macro_arity(lambda{|*x|},[:arg1,:arg2]) }.to_not raise_error }
    end
    context 'check_macro_arity(lambda{|x,*y|},[])' do
      it { expect { described_class.check_macro_arity(lambda{|x,*y|},[]) }.to raise_error ArgumentError, "Wrong number of arguments (0 for minimum 1)"}
    end
    context 'check_macro_arity(lambda{|x,*y|},[:arg1])' do
      it { expect { described_class.check_macro_arity(lambda{|x,*y|},[:arg1]) }.to_not raise_error }
    end
    context 'check_macro_arity(lambda{|x,*y|},[:arg1,:arg2])' do
      it { expect { described_class.check_macro_arity(lambda{|x,*y|},[:arg1,:arg2]) }.to_not raise_error }
    end
    if Puppet::Util::Package.versioncmp(RUBY_VERSION,'1.9') >= 0
      context 'check_macro_arity(lambda{|x=nil|},[])' do
        it { expect { described_class.check_macro_arity(Kernel.eval('lambda{|x=nil|}'),[]) }.to_not raise_error }
      end
      context 'check_macro_arity(lambda{|x=nil|},[:arg1])' do
        it { expect { described_class.check_macro_arity(Kernel.eval('lambda{|x=nil|}'),[:arg1]) }.to_not raise_error }
      end
      context 'check_macro_arity(lambda{|x=nil|},[:arg1,:arg2])' do
        it { expect { described_class.check_macro_arity(Kernel.eval('lambda{|x=nil|}'),[:arg1,:arg2]) }.to raise_error ArgumentError, "Wrong number of arguments (2 for maximum 1)"}
      end
    end
  end


  # From DefaultEnvironment module
  describe 'default_environment' do
    let(:klass) { Puppet::Node::Environment }
    if Puppet.respond_to?(:lookup)
      it { described_class.default_environment.should be_a klass }
    else
      begin
        require 'puppet/context'
        it { described_class.default_environment.should be_a klass }
      rescue LoadError
        begin
          require 'puppet/node/environment'
          it { described_class.default_environment.should be_a klass }
        rescue LoadError
          it { described_class.default_environment.should be_nil }
        end
      end
    end
  end

  # From ToLambda module
 

  describe 'newmacro' do
    let(:hash) { Hash.new }
    let(:block) { Proc.new { :yes_its_me } }
    context 'when macro "foo" does not exist' do
      before do
        Puppet.expects(:debug).never
        described_class.expects(:validate_name).once.with("foo")
      end
      context 'newmacro("foo") {}' do
        before do
          described_class.stubs(:default_environment).with().returns :env0
          described_class.stubs(:macro).once.with("foo",:env0,false).returns nil
          described_class.expects(:macros).with(:env0).returns hash
        end
        it 'should assign block macros(:env0)["foo"]' do
          hash["foo"].should be_nil
          described_class.newmacro("foo",&block)
          hash["foo"].call.should be :yes_its_me
        end
      end
      context 'newmacro("foo",{:environment => :env1}) {}' do
        before do
          described_class.stubs(:default_environment).never
          described_class.stubs(:macro).once.with("foo",:env1,false).returns nil
          described_class.expects(:macros).with(:env1).returns hash
        end
        if Puppet::Util::Package.versioncmp(RUBY_VERSION,"1.9") >= 0
          it 'should convert procs to lambdas' do
            described_class.newmacro("foo",{:environment => :env1},&block).lambda?.should be_true
          end
        end
        it 'should assign block macros(:env1)["foo"]' do
          hash["foo"].should be_nil
          described_class.newmacro("foo",{:environment => :env1},&block)
          hash["foo"].call.should be :yes_its_me
        end
      end
    end
    context 'when macro "foo" exists' do
      context 'newmacro("foo") {}' do
        before do
          Puppet.expects(:debug).once.with("overwritting macro foo")
          described_class.stubs(:default_environment).with().returns :env0
          described_class.stubs(:macro).once.with("foo",:env0,false).returns Proc.new{|x|}
          described_class.expects(:macros).with(:env0).returns hash
        end
        it 'should assign block to macros(:env1)["foo"]' do
          hash["foo"].should be_nil
          described_class.newmacro("foo",&block)
          hash["foo"].call.should be :yes_its_me
        end
      end
    end
  end

  describe 'macros' do
    context 'without arguments' do
      before { described_class.stubs(:default_environment).with().returns :env0 }
      it { described_class.macros.should be_instance_of Hash }
      it "should create @macros" do
        described_class.macros
        vars = described_class.instance_variables
        # 1.8 uses Strings, 1.9+ uses Symbols ... so let's convert all to Symbols
        vars = vars.map{|v| v.is_a?(Symbol) ? v : v.intern}
        vars.should include :@macros
      end
      it "should create @macros[:env0] == macros" do
        macros = described_class.macros
        described_class.instance_variable_get(:@macros)[:env0].should be macros
      end
    end
    context 'macros(:env1)' do
      it "should create @macros" do
        described_class.macros(:env1)
        vars = described_class.instance_variables
        # 1.8 uses Strings, 1.9+ uses Symbols ... so let's convert all to Symbols
        vars = vars.map{|v| v.is_a?(Symbol) ? v : v.intern}
        vars.should include :@macros
      end
      it "should create @macros[:env1] == macros(:env1)" do
        macros = described_class.macros(:env1)
        described_class.instance_variable_get(:@macros)[:env1].should be macros
      end
    end
  end

  describe 'macro' do
    before { Puppet::Node::Environment.stubs(:root).with().returns :rootenv }
    context 'macro("foo")' do
      before do
        described_class.stubs(:default_environment).once.with().returns :env0
        described_class.stubs(:load).with("foo",:env0)
      end
      context "when macro 'foo' exists in :env0" do
        it 'should == macros(:env0)["foo"]' do
          described_class.expects(:macros).once.with(:env0).returns({'foo' => 'macro foo'})
          described_class.expects(:macros).never.with(:rootenv)
          described_class.expects(:load).never
          described_class.macro("foo").should == 'macro foo'
        end
      end
      context "when macro 'foo' exists only in root environment" do
        it 'should == macros(:rootenv)["foo"]' do
          described_class.expects(:macros).once.with(:env0).returns({})
          described_class.expects(:macros).once.with(:rootenv).returns({'foo' => 'macro foo'})
          described_class.expects(:load).never
          described_class.macro("foo").should == 'macro foo'
        end
      end
      context "when macro 'foo' does not exists but is loadable" do
        it 'should == macros(:rootenv)["foo"]' do
          described_class.expects(:macros).once.with(:env0).returns({})
          described_class.expects(:macros).once.with(:rootenv).returns({})
          described_class.expects(:load).once.with("foo",:env0).returns('macro foo')
          described_class.macro("foo").should == 'macro foo'
        end
      end
    end
    context 'macro("foo",:env1)' do
      context "when macro 'foo' exists in :env1" do
        it 'should == macros(:env1)["foo"]' do
          described_class.expects(:macros).once.with(:env1).returns({'foo' => 'macro foo'})
          described_class.expects(:macros).never.with(:rootenv)
          described_class.expects(:load).never
          described_class.macro("foo",:env1).should == 'macro foo'
        end
      end
      context "when macro 'foo' exists only in root environment" do
        it 'should == macros(:rootenv)["foo"]' do
          described_class.expects(:macros).once.with(:env1).returns({})
          described_class.expects(:macros).once.with(:rootenv).returns({'foo' => 'macro foo'})
          described_class.expects(:load).never
          described_class.macro("foo",:env1).should == 'macro foo'
        end
      end
      context "when macro 'foo' does not exists but is loadable" do
        it 'should == macros(:rootenv)["foo"]' do
          described_class.expects(:macros).once.with(:env1).returns({})
          described_class.expects(:macros).once.with(:rootenv).returns({})
          described_class.expects(:load).once.with("foo",:env1).returns('macro foo')
          described_class.macro("foo",:env1).should == 'macro foo'
        end
      end
    end
    context 'macro("foo",:env1,false)' do
      context "when macro 'foo' exists in :env1" do
        it 'should == macros(:env1)["foo"]' do
          described_class.expects(:macros).once.with(:env1).returns({'foo' => 'macro foo'})
          described_class.expects(:macros).never.with(:rootenv)
          described_class.expects(:load).never
          described_class.macro("foo",:env1,false).should == 'macro foo'
        end
      end
      context "when macro 'foo' exists only in root environment" do
        it 'should == macros(:rootenv)["foo"]' do
          described_class.expects(:macros).once.with(:env1).returns({})
          described_class.expects(:macros).once.with(:rootenv).returns({'foo' => 'macro foo'})
          described_class.expects(:load).never
          described_class.macro("foo",:env1,false).should == 'macro foo'
        end
      end
      context "when macro 'foo' does not exists" do
        it 'should == macros(:rootenv)["foo"]' do
          described_class.expects(:macros).once.with(:env1).returns({})
          described_class.expects(:macros).once.with(:rootenv).returns({})
          described_class.expects(:load).never
          described_class.macro("foo",:env1,false).should be_nil
        end
      end
    end
  end

  describe 'autoloader' do
    after { described_class.instance_variable_set(:@autoloader, nil) }
    context "when autoloader is not memoized yet" do
      let(:autoloader) { stub('autoloader') }
      before do
        described_class.instance_variable_set(:@autoloader, nil)
        Puppet::Util::Autoload.expects(:new).once.
          with(described_class,'puppet/macros', :wrap => false).returns autoloader
      end
      it { described_class.autoloader.should be autoloader }
      it { described_class.autoloader.methods.map{|m| m.is_a?(Symbol) ? m : m.intern}.should include :loadall }
      it { described_class.autoloader.methods.map{|m| m.is_a?(Symbol) ? m : m.intern}.should include :files_to_load }
    end
    context "when autoloader is already memoized" do
      before { described_class.instance_variable_set(:@autoloader, :memoized) }
      it do
        Puppet::Util::Autoload.expects(:new).never
        described_class.autoloader.should be :memoized
      end
    end
  end

  describe 'load' do
    context 'load("foo::bar")' do
      before { described_class.stubs(:default_environment).once.with().returns :env0 }
      it 'should == load_from_file("foo::bar","foo/bar",:env0)' do
        described_class.expects(:load_from_file).once.
          with("foo::bar","foo/bar",:env0).returns 'macro foo::bar'
        described_class.load("foo::bar").should == 'macro foo::bar'
      end
    end
    context 'load("foo::bar",:env1)' do
      it 'should == load_from_file("foo::bar","foo/bar",:env1)' do
        described_class.expects(:load_from_file).once.
          with("foo::bar","foo/bar",:env1).returns 'macro foo::bar'
        described_class.load("foo::bar",:env1).should == 'macro foo::bar'
      end
    end
  end

  describe 'load_from_file' do
    context 'load_from_file("foo::bar","foo/bar")' do
      let(:autoloader) { stub('autoloader') }
      before do
        described_class.stubs(:default_environment).once.with().returns :env0
        described_class.stubs(:autoloader).with().returns autoloader
      end
      context 'when "foo/bar" exists and defines macro "foo::bar"' do
        before do
          autoloader.stubs(:load).once.with('foo/bar',:env0).returns true
          described_class.stubs(:macros).once.with(:env0).
            returns({'foo::bar' => 'macro foo::bar'})
        end
        it do
          described_class.load_from_file("foo::bar", "foo/bar").
             should == 'macro foo::bar'
        end
      end
      context 'when "foo/bar" exists but does not define "foo::bar" macro' do
        before do
          autoloader.stubs(:load).once.with('foo/bar',:env0).returns true
          autoloader.stubs(:expand).once.with('foo/bar').returns 'xyz/foo/bar'
          described_class.stubs(:macros).once.with(:env0).returns({})
          Puppet::Node::Environment.stubs(:root).once.with().returns :rootenv
          described_class.stubs(:macros).once.with(:rootenv).returns({})
          Puppet.stubs(:debug)
        end
        msg = "#{"xyz/foo/bar".inspect} loaded but it didn't define macro " +
          "#{"foo::bar".inspect}"
        let(:msg) { msg }
        it "should print debug message: #{msg}" do
          Puppet.expects(:debug).once.with(msg)
          expect { described_class.load_from_file("foo::bar", "foo/bar") }.
            to_not raise_error
        end
        it { described_class.load_from_file("foo::bar", "foo/bar").should be_nil }
      end
      context 'when "foo/bar" does not exist' do
        before do
          autoloader.stubs(:load).once.with('foo/bar',:env0).returns false
          autoloader.stubs(:expand).once.with('foo/bar').returns 'xyz/foo/bar'
          Puppet.stubs(:debug)
        end
        msg = "could not autoload #{"xyz/foo/bar".inspect}"
        let(:msg) { msg }
        it "should print debug message: #{msg}" do
          Puppet.expects(:debug).once.with(msg)
          expect { described_class.load_from_file("foo::bar", "foo/bar") }.
            to_not raise_error
        end
        it { described_class.load_from_file("foo::bar", "foo/bar").should be_nil }
      end
    end
  end

  describe "loadall" do
    let(:autoloader) { stub('autoloader', :loadall => :result0) }
    before { described_class.stubs(:autoloader).with().returns autoloader }
    it("should == autoloader.loadall") { described_class.loadall.should == :result0 }
  end

  describe "call_macro" do
    let(:scope) { stub('scope') }
    before { described_class.stubs(:default_environment).with().returns :env0 }
    context 'call_macro(scope,["foo::bar"])' do
      before { described_class.expects(:validate_name).once.with("foo::bar",ArgumentError) }
      context 'when "foo::bar" is a defined macro' do
        let(:macro) { lambda {|| :ok1} }
        before { described_class.stubs(:macro).with("foo::bar",:env0).returns macro }
        it { described_class.call_macro(scope,"foo::bar",[]).should be :ok1 }
      end
      context 'when "foo::bar" is undefined' do
        before { described_class.stubs(:macro).with("foo::bar",:env0).returns nil }
        it { expect { described_class.call_macro(scope,"foo::bar",[]) }.to raise_error Puppet::Error, 'Undefined macro foo::bar' }
      end
    end

    context 'with macro upcase = lambda{|x| x.upcase}' do
      let(:macro) { lambda {|x| x.upcase} }
      before { described_class.stubs(:macro).with("upcase",:env0).returns macro }
      context 'call_macro(scope,"upcase",[])' do
        it { expect { described_class.call_macro(scope,"upcase",[]) }.to raise_error ArgumentError, "Wrong number of arguments (0 for 1)" }
      end
      context 'call_macro(scope,"upcase", ["arg1"])' do
        it { described_class.call_macro(scope,"upcase",["arg1"]).should == "ARG1" }
      end
      context 'call_macro(scope,"upcase",["arg1","arg2"])' do
        it { expect { described_class.call_macro(scope, "upcase",["arg1","arg2"]) }.to raise_error ArgumentError, "Wrong number of arguments (2 for 1)" }
      end
    end

    context 'with macro upcase = lambda {|x,*y| x.upcase}' do
      let(:macro) { lambda {|x,*y| x.upcase} }
      before { described_class.stubs(:macro).with("upcase",:env0).returns macro }
      context 'call_macro(scope,"upcase",[])' do
        it { expect { described_class.call_macro(scope,"upcase",[]) }.to raise_error ArgumentError, "Wrong number of arguments (0 for minimum 1)" }
      end
      [ ["arg1"], ["arg1","arg2"], ["arg1","arg2","arg3"] ].each do |args|
        let(:args) { args }
        context "call_macro(scope,\"upcase\", #{args.inspect})" do
          it { described_class.call_macro(scope,"upcase",args).should == "ARG1" }
        end
      end
    end

    context 'call_macro(scope,"foo-bar",[])' do
      let(:msg) { "Invalid macro name foo-bar" }
      before { described_class.stubs(:validate_name).once.with("foo-bar",ArgumentError).raises ArgumentError, msg }
      it { expect { described_class.call_macro(scope,"foo-bar",[]) }.to raise_error ArgumentError, msg }
    end

    context 'call_macro(scope,"foo-bar",[], {:a_err => Puppet::ParseError}, :env1)' do
      let(:msg) { "Invalid macro name foo-bar" }
      before { described_class.stubs(:validate_name).once.with("foo-bar",Puppet::ParseError).raises Puppet::ParseError, msg }
      it { expect { described_class.call_macro(scope, "foo-bar", [], {:a_err => Puppet::ParseError}, :env1) }.to raise_error Puppet::ParseError, msg }
    end
  end

  describe 'call_macro_from_func' do
    let(:scope) { stub('scope') }
    before { described_class.stubs(:default_environment).with().returns :env0 }
    context "call_macro_from_func(scope,'somefun',[])" do
      it { expect { described_class.call_macro_from_func(scope,'somefun',[]) }.to raise_error Puppet::ParseError, 'somefun(): Wrong number of arguments (0) - missing macro name' }
    end
    context "call_macro_from_func(scope,'somefun',['foo',:arg1,:arg2])" do
      it "should == call_macro(scope,'foo', [:arg1,:arg2], {:a_err => Puppet::ParseError, :l_err => Puppet::ParseError}, default_environment)" do
        described_class.expects(:call_macro).once.with(scope,'foo',[:arg1,:arg2], {:a_err => Puppet::ParseError, :l_err => Puppet::ParseError}, :env0).returns :ok
        described_class.call_macro_from_func(scope,'somefun',['foo',:arg1,:arg2]).should be :ok
      end
    end
    context "call_macro_from_func(scope, 'somefun', ['foo',:arg1,:arg2], 1, :env1)" do
      it "should == call_macro(scope, 'foo',[:arg1,:arg2], {:a_err => Puppet::ParseError, :l_err => Puppet::ParseError}, :env1)" do
        described_class.expects(:call_macro).once.with(scope,'foo',[:arg1,:arg2], {:a_err => Puppet::ParseError, :l_err => Puppet::ParseError}, :env1).returns :ok
        described_class.call_macro_from_func(scope,'somefun',['foo',:arg1,:arg2], 1, :env1).should be :ok
      end
      context "when call_macro(...) raises Puppet::ParseError with message 'blah blah'" do
        before { described_class.expects(:call_macro).once.with(scope,'foo',[:arg1,:arg2], {:a_err => Puppet::ParseError, :l_err => Puppet::ParseError}, :env1).raises Puppet::ParseError, "blah blah"}
        it { expect { described_class.call_macro_from_func(scope,'somefun',['foo',:arg1,:arg2], 1, :env1) }.to raise_error Puppet::ParseError, 'somefun(): blah blah' }
      end
      context "when call_macro(...) raises ArgumentError with message 'Wrong number of arguments (0 for 1)'" do
        before { described_class.expects(:call_macro).once.with(scope,'foo',[:arg1,:arg2], {:a_err => Puppet::ParseError, :l_err => Puppet::ParseError}, :env1).raises Puppet::ParseError, "Wrong number of arguments (0 for 1)"}
        it { expect { described_class.call_macro_from_func(scope,'somefun',['foo',:arg1,:arg2], 1, :env1) }.to raise_error Puppet::ParseError, 'somefun(): Wrong number of arguments (2 for 3)' }
      end
      context "when call_macro(...) raises ArgumentError with message 'Wrong number of arguments (0 for minimum 1)'" do
        before { described_class.expects(:call_macro).once.with(scope,'foo',[:arg1,:arg2], {:a_err => Puppet::ParseError, :l_err => Puppet::ParseError}, :env1).raises Puppet::ParseError, "Wrong number of arguments (0 for minimum 1)"}
        it { expect { described_class.call_macro_from_func(scope,'somefun',['foo',:arg1,:arg2], 1, :env1) }.to raise_error Puppet::ParseError, 'somefun(): Wrong number of arguments (2 for minimum 3)' }
      end
      context "when call_macro(...) raises ArgumentError with message 'Wrong number of arguments (0 for maximum 1)'" do
        before { described_class.expects(:call_macro).once.with(scope,'foo',[:arg1,:arg2], {:a_err => Puppet::ParseError, :l_err => Puppet::ParseError}, :env1).raises Puppet::ParseError, "Wrong number of arguments (0 for maximum 1)"}
        it { expect { described_class.call_macro_from_func(scope,'somefun',['foo',:arg1,:arg2], 1, :env1) }.to raise_error Puppet::ParseError, 'somefun(): Wrong number of arguments (2 for maximum 3)' }
      end
      context "when call_macro(...) raises ArgumentError with message 'blah blah'" do
        before { described_class.expects(:call_macro).once.with(scope,'foo',[:arg1,:arg2], {:a_err => Puppet::ParseError, :l_err => Puppet::ParseError}, :env1).raises ArgumentError, "blah blah"}
        it { expect { described_class.call_macro_from_func(scope,'somefun',['foo',:arg1,:arg2], 1, :env1) }.to raise_error ArgumentError, 'blah blah' }
      end
    end
  end
end

describe Puppet::Parser::Scope do
  it { should respond_to :call_macro }
  it { should respond_to :pp2r }
  let(:subject) { PuppetlabsSpec::PuppetInternals.scope }
  describe 'call_macro' do
    context 'call_macro("foo")' do
      before { Puppet::Macros.stubs(:default_environment).once.with().returns :env0 }
      it 'should == Macros.call_macro(self,"foo",[],{},Macros.default_environment)' do
        Puppet::Macros.expects(:call_macro).once.with(subject,"foo",[],{},:env0).returns :ok
        subject.call_macro("foo")
      end
    end
    context 'call_macro("foo", [])' do
      before { Puppet::Macros.stubs(:default_environment).once.with().returns :env0 }
      it 'should == Macros.call_macro(self,"foo",[],{},Macros.default_environment)' do
        Puppet::Macros.expects(:call_macro).once.with(subject,"foo",[],{},:env0).returns :ok
        subject.call_macro("foo",[])
      end
    end
    context 'call_macro("foo", [],:opts,:env1)' do
      before { Puppet::Macros.stubs(:default_environment).never }
      it 'should == Macros.call_macro(self,"foo",[],:opts,:env1)' do
        Puppet::Macros.expects(:call_macro).once.with(subject,"foo",[],:opts,:env1).returns :ok
        subject.call_macro("foo",[],:opts,:env1)
      end
    end
    describe 'pp2r' do
      context 'pp2r(:foo)' do
        it { subject.pp2r(:foo).should be :foo }
      end
      context 'pp2r("foo")' do
        it { subject.pp2r("foo").should == "foo" }
      end
      context 'pp2r(nil)' do
        it { subject.pp2r(nil).should be_nil }
      end
      context 'pp2r("")' do
        it { subject.pp2r("").should be_nil }
      end
      context 'pp2r(:undef)' do
        it { subject.pp2r(:undef).should be_nil }
      end
    end
    describe 'fr2r' do
      context 'fr2r(:foo)' do
        it { subject.fr2r(:foo).should be :foo }
      end
      context 'fr2r("foo")' do
        it { subject.fr2r("foo").should == "foo" }
      end
      context 'fr2r(nil)' do
        it { subject.fr2r(nil).should be_nil }
      end
      context 'fr2r("")' do
        it { subject.fr2r("").should be_nil }
      end
      context 'fr2r(:undefined)' do
        it { subject.fr2r(:undefined).should be_nil }
      end
    end
  end
end

require 'spec_helper_integration'
# These are actually "integration" tests. It checks, for example, whether the
# Puppet::Macros integrates well with puppet environments or
# Puppet::Util::Autoloader.
describe Puppet::Macros  do
  before { described_class.instance_variable_set(:@macros,nil) }
  describe 'macros() and autoloader' do
    context 'macro("testmodule::foo::a",defaul_environment,false)' do
      it "should not autoload macro" do
        env = described_class.default_environment
        described_class.macro("testmodule::foo::a", env, false).should be_nil
      end
    end
    context 'macro("testmodule::foo::a",defaul_environment,true)' do
      it "should autoload macro from disk" do
        env = described_class.default_environment
        described_class.macro("testmodule::foo::a", env, true).should be_instance_of Proc
      end
    end
    context 'macro("nonexistent::macro")' do
      it { described_class.macro('nonexistent::macro').should be_nil }
    end
    context 'macro("testmodule::nomacro")' do
      it { described_class.macro('nonexistent::macro').should be_nil }
    end
  end
end
