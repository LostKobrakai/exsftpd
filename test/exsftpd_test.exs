defmodule ExsftpdTest do
  use ExUnit.Case, async: true
  doctest Exsftpd

  setup do
    env = Application.get_env(:exsftpd, Exsftpd.Server)
    root_dir = env[:user_auth_dir]
    :file.make_dir(root_dir)
    server = start_supervised!({Exsftpd.Server, env})
    %{server: server}
  end

  test "lifecycle", %{server: server} do
    assert {:ok, _} = Exsftpd.Server.status(server)
  end
end
