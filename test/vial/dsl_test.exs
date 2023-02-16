defmodule Vial.DSLTest do
  use ExUnit.Case

  describe ".create_file/1" do
    test "creates a function called create_file_1/2" do
      defmodule CreateFile do
        use Vial.DSL

        create_file "hello.txt", "Hi there"
      end

      assert function_exported?(CreateFile, :create_file_0, 1)
    end
  end
end
