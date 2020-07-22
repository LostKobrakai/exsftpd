defmodule Exsftpd.SftpFileHandler do
  def file_handler_spec(options) do
    {__MODULE__, options}
  end

  defp user_path(path, state) do
    Path.join(state[:root_path], path)
  end

  defp on_event({event_name, meta}, state) do
    args = [{event_name, state[:user], meta}]

    case state[:event_handler] do
      {module, fun} -> apply(module, fun, args)
      fun when is_function(fun, 1) -> apply(fun, args)
      nil -> nil
    end
  end

  defp after_event(param, state, result) do
    on_event(param, state)
    result
  end

  defp get_file_info(io_device) do
    case :file.pid2name(io_device) do
      {:ok, filename} -> {io_device, filename}
      _ -> {io_device}
    end
  end

  @file_functions [
    :delete,
    :del_dir,
    :list_dir,
    :make_dir,
    :read_link,
    :read_link_info,
    :read_file_info
  ]
  defp module_for_operation(operation) do
    case operation do
      operation when operation in [:is_dir] -> :filelib
      operation when operation in @file_functions -> :file
    end
  end

  # run operation on `:file` or `:filelib` module with the given path
  defp simple_file_operation_on_path(operation, path, state) do
    full_path = user_path(path, state)
    return = {apply(module_for_operation(operation), operation, [full_path]), state}
    after_event({operation, path}, state, return)
  end

  def delete(path, state) do
    simple_file_operation_on_path(:delete, path, state)
  end

  def make_dir(path, state) do
    simple_file_operation_on_path(:make_dir, path, state)
  end

  def list_dir(path, state) do
    simple_file_operation_on_path(:list_dir, path, state)
  end

  def is_dir(path, state) do
    simple_file_operation_on_path(:is_dir, path, state)
  end

  def del_dir(path, state) do
    simple_file_operation_on_path(:del_dir, path, state)
  end

  def read_link(path, state) do
    simple_file_operation_on_path(:read_link, path, state)
  end

  def read_link_info(path, state) do
    simple_file_operation_on_path(:read_link_info, path, state)
  end

  def read_file_info(path, state) do
    simple_file_operation_on_path(:read_file_info, path, state)
  end

  def get_cwd(state) do
    task = {:cwd, []}
    result = {:file.get_cwd(), state}
    after_event(task, state, result)
  end

  def make_symlink(path2, path, state) do
    task = {:make_symlink, {path2, path}}
    result = {:file.make_symlink(user_path(path2, state), user_path(path, state)), state}
    after_event(task, state, result)
  end

  def open(path, flags, state) do
    case :file.open(user_path(path, state), flags) do
      {:ok, pid} ->
        on_event({:open, {get_file_info(pid), path, flags}}, state)
        {{:ok, pid}, state}

      other ->
        {other, state}
    end
  end

  def close(io_device, state) do
    task = {:close, get_file_info(io_device)}
    result = {:file.close(io_device), state}
    after_event(task, state, result)
  end

  def position(io_device, offs, state) do
    task = {:position, {io_device, offs}}
    result = {:file.position(io_device, offs), state}
    after_event(task, state, result)
  end

  def read(io_device, len, state) do
    task = {:read, get_file_info(io_device)}
    result = {:file.read(io_device, len), state}
    after_event(task, state, result)
  end

  def rename(path, path2, state) do
    task = {:rename, {path, path2}}
    result = {:file.rename(user_path(path, state), user_path(path2, state)), state}
    after_event(task, state, result)
  end

  def write(io_device, data, state) do
    task = {:write, get_file_info(io_device)}
    result = {:file.write(io_device, data), state}
    after_event(task, state, result)
  end

  def write_file_info(path, info, state) do
    task = {:write_file_info, {path, info}}
    result = {:file.write_file_info(user_path(path, state), info), state}
    after_event(task, state, result)
  end
end
