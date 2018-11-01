defmodule Exsftpd.Supervisor do
  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, :ok)
  end

  def init(:ok) do
    children = [
      worker(Exsftpd.Server, [Exsftpd.Server, Application.get_env(:exsftpd, Exsftpd.Server)])
    ]
    supervise(children, strategy: :one_for_one)

  end

end