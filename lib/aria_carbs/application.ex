# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaCarbs.Application do
  @moduledoc false
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      AriaCarbs.Repo
    ]

    opts = [strategy: :one_for_one, name: AriaCarbs.Supervisor]
    Supervisor.start_link(children, opts)
  end
end

