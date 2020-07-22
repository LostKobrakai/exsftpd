defmodule Exsftpd do
  @doc """
  Dummy shell implementation

  Prints a short message confirming a connection to user and then closes.
  """
  @spec dummy_shell(charlist(), {:inet.ip_address(), :inet.port_number()}) :: pid()
  def dummy_shell(user, {ip, _port}) do
    spawn(fn ->
      remote_ip = ip |> Tuple.to_list() |> Enum.join(".")
      IO.puts("Hello, #{user} from #{remote_ip}")
      IO.puts("No shell available for you here")
    end)
  end

  @doc false
  @spec path_of_config(keyword()) :: %{
          system_dir: Path.t(),
          user_auth_dir_fun: (any -> Path.t()),
          user_root_dir: Path.t()
        }
  def path_of_config(options) do
    %{
      system_dir: system_dir(options),
      user_root_dir: user_root_dir(options),
      user_auth_dir_fun: user_auth_dir(options)
    }
  end

  defp system_dir(env) do
    unless is_binary(env[:system_dir]) do
      raise "Invalid or missing system_dir"
    end

    env[:system_dir]
  end

  defp user_root_dir(env) do
    unless env[:user_root_dir] do
      raise "Invalid or missing user_root_dir"
    end

    env[:user_root_dir]
  end

  defp user_auth_dir(env) do
    unless env[:user_auth_dir] do
      raise "Invalid or missing user_auth_dir"
    end

    unless env[:user_root_dir] do
      raise "Invalid or missing user_root_dir"
    end

    fn user ->
      dir_or_fun = env[:user_auth_dir] || env[:user_root_dir]

      if is_function(dir_or_fun) do
        dir_or_fun.(user)
      else
        "#{dir_or_fun}/#{user}/.ssh"
      end
    end
  end
end
