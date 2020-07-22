defmodule Exsftpd.Server do
  use GenServer
  require Logger

  @moduledoc """
  Documentation for Exsftp.
  """

  ## Client API

  @doc """
  Starts the registry.
  """
  def start_link(opts) do
    case Keyword.fetch(opts, :name) do
      {:ok, name} -> GenServer.start_link(__MODULE__, opts, name: name)
      _ -> GenServer.start_link(__MODULE__, opts)
    end
  end

  @doc """
  Daemon status
  """
  def status(pid) do
    GenServer.call(pid, :status)
  end

  @doc false
  def state(pid) do
    GenServer.call(pid, :state)
  end

  ## Server Callbacks

  defp init_daemon(options) do
    Logger.info("Starting SFTP daemon on #{options[:port]}")

    paths = Exsftpd.path_of_config(options)

    daemon_opts = [
      system_dir: String.to_charlist(paths.system_dir),
      shell: &Exsftpd.dummy_shell/2,
      subsystems: [
        Exsftpd.SftpdChannel.subsystem_spec(
          file_handler:
            Exsftpd.SftpFileHandler.file_handler_spec(
              event_handler: options[:event_handler],
              user_root_dir: paths.user_root_dir
            ),
          cwd: '/'
        )
      ],
      user_dir_fun: paths.user_auth_dir_fun
    ]

    # Optional daemon_opts
    daemon_opts =
      Enum.reduce(options, daemon_opts, fn
        {:authenticate, handler}, daemon_opts ->
          Keyword.put(daemon_opts, :pwdfun, Exsftpd.Authenticator.handler_to_fun(handler))

        _, daemon_opts ->
          daemon_opts
      end)

    :ssh.daemon(options[:port], daemon_opts)
  end

  def init(options) do
    :ok = :ssh.start()

    with {:ok, ref} <- init_daemon(options) do
      {:ok, %{options: options, daemon: ref}}
    end
  end

  def handle_info({:DOWN, _ref, :process, _pid, _reason}, state) do
    {:stop, :ssh_deamon_down, state}
  end

  def handle_info(_msg, state) do
    {:noreply, state}
  end

  def handle_call(:state, _from, state) do
    {:reply, state, state}
  end

  def handle_call(:status, _from, state) do
    {:reply, :ssh.daemon_info(state.daemon), state}
  end

  def terminate(_reason, state) do
    :ssh.stop_daemon(state.daemon)
  end
end
