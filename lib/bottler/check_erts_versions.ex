require Logger, as: L
require Bottler.Helpers, as: H

defmodule Bottler.CheckErtsVersions do

  defmodule State do
    defstruct ~w(config local_release remote_cmd server_data ssh_conn remote_erts_version check_results)a
  end

  defmodule Error do
    defstruct ~w(reason state)a
  end

  @moduledoc """
    Code to check erts versions on servers
  """
  def check_erts_versions({:ok, config}) do
    :ssh.start # just in case

    %State{config: config}
    |> add_local_release
    |> add_remote_cmd
    |> perform_erts_checks

    #level = if Enum.all?(remote_releases, &( local_release == &1 |> String.split(" ") |> List.first )), do: :info, else: :error

    #L.log level, "Compiling against Erlang/OTP release #{local_release}. Remote releases are #{Enum.map_join(remote_releases, ", ", &(&1))}."

    #if level == :error, do: raise "Aborted release"
  end

  defp add_local_release(%State{} = state) do
    %State{state | local_release: to_string(:erlang.system_info(:version))}
  end
  defp add_local_release(x), do: x

  defp add_remote_cmd(%State{} = state) do
    remote_cmd = "source ~/.bash_profile && erl -eval 'erlang:display(erlang:system_info(version)), halt().'  -noshell"
    %State{state | remote_cmd: to_charlist(remote_cmd)}
  end
  defp add_remote_cmd(x), do: x

  defp perform_erts_checks(%State{config: config} = state) do
    erts_check_results = config[:servers]
      |> Enum.map(&(%State{state | server_data: &1}))
      |> H.in_tasks(&perform_erts_check/1, to_s: false)

    state
  end
  defp perform_erts_checks(x), do: x

  defp perform_erts_check(%State{} = state) do
    state
    |> add_ssh_conn
    |> add_remote_erts_version
  end

  defp add_ssh_conn(%State{server_data: server_data, config: config} = state) do
    user = to_charlist(config[:remote_user])
    ip = to_charlist(server_data[:ip])

    case SSHEx.connect(ip: ip, user: user) do
      {:ok, ssh_conn} ->
        %State{state | ssh_conn: ssh_conn}

      {:error, reason} ->
        %Error{reason: reason, state: state}
    end
  end
  defp add_ssh_conn(x), do: x

  defp add_remote_erts_version(%State{ssh_conn: ssh_conn, remote_cmd: remote_cmd} = state) do
    remote_erts_version = ssh_conn
      |> SSHEx.cmd!(remote_cmd)
      |> H.chop

    %State{state | remote_erts_version: remote_erts_version}
  end
  defp add_remote_erts_version(x), do: x

end
