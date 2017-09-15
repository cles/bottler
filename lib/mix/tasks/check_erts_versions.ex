require Bottler.Helpers, as: H
alias Bottler, as: B

defmodule Mix.Tasks.Bottler.CheckErtsVersions do

  @moduledoc """
    Check erts versions on the remote servers. Usage: `mix bottler.check_erts_versions`
    Build a release file. Use like `mix bottler.release`.

    `prod` environment is used by default. Use like
    `MIX_ENV=other_env mix bottler.check_erts_versions` to force it to `other_env`.
  """

  use Mix.Task

  def run(_args) do
    H.set_prod_environment
    c = H.read_and_validate_config
      |> H.validate_branch
      |> H.inline_resolve_servers

    B.check_erts_versions {:ok, c}
    :ok
  end

end

