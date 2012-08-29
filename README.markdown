
Dependence
frozen_time)
==========

What?
-----

This is a lightweight dependency injection layer for ruby. Of
course, in ruby we have the ability to say things like
`Time.should_receive(:now).and_return(some_time)` but that doesn't mean we should not be cogniscent of the level coupling we are gliding over when introducing such difficult to test links between classes.

Dependency What?
----------------

I've always seen dependency injection in ruby best described as a way
to identify and isolate dependencies. Take the following for example

    class StockBroker < Person

      def sell_shares symbol
        ShareEvent.new(
          :broker => self,
          :symbol => symbol,
          :effective => Time.now
        ).publish
      end

    end

    broker = StockBroker.new 
    broker.sell_shares "APPL"


And in the test, we must now mock out Time to reliably test the
effective date.

    describe StockBroker do
      before do
        @broker = described_class.new
      end

      describe "selling shares" do
        it "sets the effective date on share events" do
          frozen_time = Time.now
          Time.should_receive(:now).and_return(frozen_time)
          event = @broker.sell_shares        
          event.effective.should == frozen_time
        end
      end
    end


Of course, if this were the only problem (that being Time can be
difficult to be test), then we would be fine as there are plenty of
gems out there for testing time. One non-gem based solution is to use
dependency injection to pass the provider of the time to the

==========

What?
-----

This is a lightweight dependency injection layer for ruby. Of
course, in ruby we have the ability to say things like
`Time.should_receive(:now).and_return(some_time)` but that doesn't mean we should not be cogniscent of the level coupling we are gliding over when introducing such difficult to test links between classes.

Dependency What?
----------------

I've always seen dependency injection in ruby best described as a way
to identify and isolate dependencies. Take the following for example

    class StockBroker < Person

      def sell_shares symbol
        ShareEvent.new(
          :broker => self,
          :symbol => symbol,
          :effective => Time.now
        ).publish
      end

    end

    broker = StockBroker.new 
    broker.sell_shares "APPL"


And in the test, we must now mock out Time to reliably test the
effective date.

    describe StockBroker do
      before do
        @broker = described_class.new
      end

      describe "selling shares" do
        it "sets the effective date on share events" do
          frozen_time = Time.now
          Time.should_receive(:now).and_return(frozen_time)
          event = @broker.sell_shares        
          event.effective.should == frozen_time
        end
      end
    end


Of course, if this were the only problem (that being Time can be
difficult to be test), then we would be fine as there are plenty of
gems out there for testing time. One non-gem based solution is to use
dependency injection to pass the provider of the time to the
methods or classes that require it. 

    class StockBroker < Person

      def sell_shares symbol, time_provider = Time
        ShareEvent.new(
          :broker => self,
          :symbol => symbol,
          :effective => time_provider.now
        ).publish
      end

    end

    describe StockBroker do
      before do
        @broker = described_class.new
      end

      describe "selling shares" do
        it "sets the effective date on share events" do
          frozen_time = Time.now
          event = @broker.sell_shares "MSFT", stub(:now => frozen_time)
          event.effective.should == frozen_time
        end
      end
    end

This is really cool. However, I've been working with
objection and guice in the Objective-C and Java worlds, and over time,
the way that tests had to be written in these static languages has began
to appeal to me. The limits of the language force you to isolate
dependencies, there is often no quick and simply way to mock class-level functionality.

What does Dependence do?
------------------------

    class StockBroker < Person
      requires :now, :as => Time      # <==== explicitly declared dependencies 
      def sell_shares symbol, time_prov
        ShareEvent.new(
          :broker => self,
          :symbol => symbol,
          :effective => now
        ).publish
      end
    end


    describe StockBroker do
      before do
        @broker = described_class.new
      end

      describe "selling shares" do
        it "sets the effective date on share events" do
          frozen_time = Time.now
          described_class.dependencies[:now] = stub(:now =>frozen_time) # <===== that can be replaced with stubs/mocks 
          
          
          event = @broker.sell_shares "MSFT"
          event.effective.should == frozen_time
        end
      end
    end

It also…
---------
* can define dependencies with proc `require :logger, :as => -> { Application::Logger.instance }`
* can define dependencies with an instance of a class `require :warn, :as => Logger.new`
* is very flexible about redefining dependencies (mix and match) `SomeClass.dependencies[:warn] = -> { TotallyCrazyRemoteLoggerFactory }`



But that's not even that cool! 
--------------------------

Yes, but it has room to grow. On the roadmap is

 * Dependency configuration hooks
 * Manifesting an entire dependency graph with a single call
 * Instance level dependency overrides
 * Scoped dependency modification
 
Also, it was quite a bit of fun to code. Hopefully it could be something cooler one-day!

Contributing!
-------------

 1. Fork
 2. Tests
 3. Pull Request
 4. Yeah

