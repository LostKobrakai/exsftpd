defmodule Exsftpd.Authenticator do
  def accept_all(_user, _password, _opts) do
    true
  end

  @doc false
  def handler_to_fun(handler) do
    fn username, password, peer_address, state ->
      args = [username, password, [peer_address: peer_address]]

      accepted =
        case handler do
          {module, fun} -> apply(module, fun, args)
          fun -> apply(fun, args)
        end

      {accepted, state}
    end
  end
end
