defmodule MixpanelTest.SupervisorTest do
  use ExUnit.Case

  test "start_link/1 with no clients configured" do
    assert {:ok, pid} = Mixpanel.Supervisor.start_link([])
    Supervisor.stop(pid)
    assert Process.alive?(pid) == false
  end
end
