require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'net/http'

describe "Muscle" do
  
  it "should allow me to setup many calls in threads" do
    start_time =  Time.now.to_f
    m = Muscle.new do |m|
      m.action(:foo) do 
        sleep 1
        :foo
      end
      m.action(:bar) do
        0.5
        :bar
      end
      m.action(:baz) do
        sleep 1
        :baz
      end
    end # Muscle.new
    end_time = Time.now.to_f
    (end_time - start_time).should < 1.2
    
    m[:foo].should == :foo
    m[:bar].should == :bar
    m[:baz].should == :baz
  end
  
  it "should walk through the output of the actions in declared order" do
    m = Muscle.new do |m|
      m.action(:foo) do
        sleep 0.25
        :foo
      end
      m.action(:bar) do
        sleep 0.1
        :bar
      end
      m.action do
        :unamed
      end
    end #{ Muscle
    m.map{|f| f}.should == [:foo, :bar, :unamed]
  end
  
  it "should allow me to set a timeout on a particular action" do
    m = Muscle.new do |m|
      m.action(:foo, :timeout => 0.1) do
        sleep 2
      end
    end
    lambda do 
      m[:foo]
    end.should raise_error(Timeout::Error)
  end
  
  it "should allow me to set a timeout result" do
    m = Muscle.new do |m|
      m.action(:foo, :timeout => 0.1) do
        sleep 2
      end

      m.on_timeout(:foo) do |name|
        "#{name.inspect} Timed Out"
      end 
    end # Muscle
    m[:foo].should == ":foo Timed Out"
  end
  
  it "Should allow me to setup a catch all timeout" do
    m = Muscle.new do |m|
      m.action(:foo, :timeout => 0.1){sleep 2}
      m.action(:bar, :timeout => 0.1){sleep 2}
      m.on_timeout do |name|
        "#{name.inspect} timed out"
      end
    end # Muscle
    m[:foo].should == ":foo timed out"
    m[:bar].should == ":bar timed out"
  end
  
  it "should allow me to setup an on_timeout for many actions" do
    m = Muscle.new do |m|
      m.action(:foo, :timeout => 0.1){sleep 2}
      m.action(:bar, :timeout => 0.1){sleep 2}
      m.action(:baz, :timeout => 0.1){sleep 2}
      m.on_timeout(:foo, :baz){|n| "Special: #{n.inspect} timed out"}
      m.on_timeout{|n| "Plain: #{n.inspect} timed out"}
    end # Muscle
    m[:foo].should == "Special: :foo timed out"
    m[:baz].should == "Special: :baz timed out"
    m[:bar].should == "Plain: :bar timed out"
  end
end
