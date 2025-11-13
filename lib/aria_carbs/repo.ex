# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaCarbs.Repo do
  use Ecto.Repo,
    otp_app: :aria_carbs,
    adapter: Ecto.Adapters.SQLite3
end

