require 'spec_helper'
describe Dependence do
  describe "when simply extending another class" do
    it "provides a class's dependencies" do
      klass = Class.new do
        include Dependence
      end
      klass.dependencies.must_be_empty
    end
  end
  describe "when adding a dependency to another class" do
    describe "with a class" do
      let(:important_class) do
        Class.new do
          def self.now
            Time.now
          end
        end
      end

      describe "basic dependency proxying" do
        before do
          ImportantTime = important_class
          @klass = tested_class do
            requires :now, :as => ImportantTime
          end
        end

        it "exposes the dependency through the class dependency list" do
          @klass.dependencies.keys.must_include :now
        end

        it "delegates methods to the dependency" do
          important_class.expects(:now).returns :foo # the very problem we are building this to avoid
          @klass.new.now.must_equal :foo
        end
      end
    end
    describe "with the current instance" do
      describe "dependencies on the current instance" do
        subject do
          ImportantClass = Class.new do
            def important behavior
              "original #{behavior}"
            end
          end

          tested_class(ImportantClass) do
            requires :important, :as => :instance
          end
        end

        it "exposes basic delegation" do
          subject.new.important("things").must_equal "original things"
        end

        it "does not interfere with methods of the same name on the current instance" do
          skip "not sure if this is going too far"
          klass = tested_class(ImportantClass) do
            requires :important, :as => :instance
            def important(thing)
              "#{thing} is intact"
            end
          end
          klass.new.important("function").must_equal "function is intact"
        end
      end
    end

    describe "with a proc providing the dependency" do
        subject do
          class FakeKernel
            def self.rest
              raise "should not be called"
            end
          end
          tested_class do
            requires :rest, :as => lambda {
              FakeKernel
            }
          end
        end

        it "will not bypass the dangerous method by default" do
          -> {
            subject.new.rest
          }.must_raise RuntimeError, "should not be called"
        end

        it "however, the dangerous dependency can easily be mocked" do
          fake_rester = mock
          fake_rester.expects(:rest).returns(:refreshment)
          subject.dependencies[:rest] = fake_rester
          subject.new.rest.must_equal :refreshment 
        end
    end

    describe "with an object that responds to the dependency" do
        subject do
          original_dependency = Class.new do
            def obscure_method 
              raise "do not call"
            end
          end.new
          @odd_dependency = Object.new
          class << @odd_dependency 
            def obscure_method odd_arg
              "obscure result #{odd_arg}"
            end
          end
          tested_class do
            requires :obscure_method, :as => original_dependency
          end
        end

        it "normally proxies" do
          -> { 
            subject.new.obscure_method 
          }.must_raise RuntimeError, "do not call"
        end

        it "can be overidden" do
          subject.dependencies[:obscure_method] = @odd_dependency
          subject.new.obscure_method(666).must_equal "obscure result 666"
        end
    end

    describe "when doing things the wrong way" do
      it "crys on #requires if no block is passed, and no :as is defined" do
        -> {
          tested_class do
            requires :foo
          end
        }.must_raise Dependence::Error
      end

      it "complains if the dependency resolver breaks down" do
        klass = tested_class do
          requires :func, :as => -> { stub(:func => :result) }
        end 
        -> { 
          klass.dependencies[:func] = Object.new
          klass.new.func
        }.must_raise Dependence::Error
      end

      it "complains if the proxying goes wrong due to argument counts" do
        test_dep = Object.new
        class << test_dep
          def buy_stocks sym, price
            "buying #{sym} at price #{price}"
          end
        end
        klass = tested_class do 
          requires :buy_stocks, :as => -> {
            test_dep
          }
        end
        test_dep2 = Object.new
        class << test_dep2
          def buy_stocks sym
            "buying undeterminate amounts of shares of #{sym}"
          end
        end
        klass.dependencies[:buy_stocks] = test_dep2
        -> { klass.new.buy_stocks }.must_raise Dependence::Error
      end
    end
  end
end

def tested_class *args, &block
  klass = Class.new(*args) {
    include Dependence
  }.tap { |klass| klass.instance_eval &block}
end
