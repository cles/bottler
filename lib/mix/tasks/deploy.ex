require Bottler.Helpers, as: H
alias Bottler, as: B

defmodule Mix.Tasks.Deploy do

  @moduledoc """
    Build a release file, ship it to remote servers, install it, and restart
    the app. No hot code swap for now.

    Use like `mix deploy`.

    `prod` environment is used by default. Use like
    `MIX_ENV=other_env mix deploy` to force it to `other_env`.
  """

  use Mix.Task

  def run(args) do
    {switches, _} = H.parse_args!(args)

    H.set_prod_environment

    c = H.read_and_validate_config
      |> H.validate_branch
      |> H.inline_resolve_servers(switches)

    {:ok, c}
    |> B.release
    |> B.publish
    |> B.ship
    |> B.install
    |> B.restart
    |> B.green_flag
  end

end
