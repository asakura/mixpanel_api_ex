defmodule MixpanelTest.SupervisorTest do
  use ExUnit.Case

  test "start_link/1 with no clients configured" do
    assert {:ok, pid} = Mixpanel.Supervisor.start_link([])
    Process.exit(pid, :shutdown)
    assert Process.alive?(pid) == false
  end
end
