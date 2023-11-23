defmodule Mixpanel.SupervisorTest do
  use ExUnit.Case

  alias Mixpanel.Config

  test "start_link/0 with no clients configured" do
    assert {:ok, pid} = Mixpanel.Supervisor.start_link()
    assert :ok = DynamicSupervisor.stop(pid)
    refute Process.alive?(pid)
  end

  describe "dynamic children" do
    setup do
      start_supervised!(Mixpanel.Supervisor)
      :ok
    end

    test "start_child/1 starts a client process" do
      assert {:ok, pid} =
               Mixpanel.Supervisor.start_child(
                 Config.client!(__MODULE__.Mixpanel, project_token: "")
               )

      assert Process.alive?(pid)

      assert {:error, {:already_started, ^pid}} =
               Mixpanel.Supervisor.start_child(
                 Config.client!(__MODULE__.Mixpanel, project_token: "")
               )

      assert Process.alive?(pid)
    end

    test "terminate_child/1 kills a client process" do
      Mixpanel.Supervisor.start_child(Config.client!(__MODULE__.Mixpanel.A, project_token: ""))
      Mixpanel.Supervisor.start_child(Config.client!(__MODULE__.Mixpanel.B, project_token: ""))

      assert :ok = Mixpanel.Supervisor.terminate_child(__MODULE__.Mixpanel.A)

      refute Process.whereis(__MODULE__.Mixpanel.A)
      assert Process.whereis(__MODULE__.Mixpanel.B)

      assert :ok = Mixpanel.Supervisor.terminate_child(__MODULE__.Mixpanel.B)

      refute Process.whereis(__MODULE__.Mixpanel.A)
      refute Process.whereis(__MODULE__.Mixpanel.B)
    end
  end
end
