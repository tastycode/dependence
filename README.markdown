Dependence
==========

What?
-----

Dependence is a lightweight dependency injection gem for ruby. Of
course, in ruby we have the ability to say things like
`Time.should_receive(:now).and_return(some_time)` but that doesn't mean we should not be cogniscent of the level of coupling we are gliding over when introducing such difficult to test links between classes.

Dependency What?
----------------

Dependency Injection has a formal definition. 

> Dependency injection is a software design pattern that allows a choice of 
> component to be made at run-time rather than compile time. This can be used, 
> for example, as a simple way to load plugins dynamically or to choose mock objects 
> in test environments vs. real objects in production environments. This software 
> design pattern injects the dependent element (object or value etc) to the destination 
> automatically by knowing the requirement of the destination. There is another pattern 
> called Dependency Lookup, which is a regular process and reverse process to Dependency injection.

Dependency injection in the ruby world has normally been limited to injection of dependency providers (e.g. the `Time` class) into a method or as an instance varible. 
Complex frameworks as seen in many other languages are not as necessary given ruby's dynamic nature. 
Methods are candidates for dependency injection when they refer to another class or external data structure that
is not directly related to the single responsibility of the method. Take the following for example. 

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


Because we reference `Time` in the method, this creates a dependency to the `Time` class. So to make the test
for this method determininstic, we might mock out `Time` to ensure that the results are repeatable between test runs.

    describe StockBroker do
      before do
        @broker = described_class.new
      end

      describe "selling shares" do
        it "sets the effective date on share events" do
          frozen_time = Time.now
          Time.should_receive(:now).and_return(frozen_time)  # polluting Time.now forever
          event = @broker.sell_shares        
          event.effective.should == frozen_time
        end
      end
    end


Of course, if this were the only problem (that being Time can be
difficult to be test), then we would be fine as there are plenty of
gems (e.g. timecop) out there for testing time. However, time is only a common
situation which begs for a more general solution to external dependencies. File, network access,
and logging are also common candidates for isolating and separating the link between our methods
and the things they require to fulfill their responsibility. 

The following is an example of how dependency is usually implemented in ruby. 

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
Additionally, with many of these frameworks. There is no need to alter the method signature, and
there is also explicit declaration of the dependencies between classes.

What dependence offers. 
------------------------

    class StockBroker < Person
      requires :now, :as => Time      # <==== explicitly declared dependencies 
      def sell_shares symbol
        ShareEvent.new(
          :broker => self,
          :symbol => symbol,
          :effective => now # <==== instance methods are automatically generated and linked to dependency providers
        ).publish
      end
    end

Notice how we do not have to modify the method definition, and we didn't have to add
any instance variables or methods to the class to wire up the dependency to its source.
Testing with this is still a little less elegant than I would like it to be, but it would go as 
follows. 

    describe StockBroker do
      before do
        @broker = described_class.new
      end

      describe "selling shares" do
        it "sets the effective date on share events" do
          frozen_time = Time.now
          
          # inject a fake dependency provider which provides the method :now
          
          described_class.dependencies[:now] = stub(:now =>frozen_time) 
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

License
-----------

Dependence is licensed under the MIT license

* [www.opensource.org/licenses/MIT](www.opensource.org/licenses/MIT)
