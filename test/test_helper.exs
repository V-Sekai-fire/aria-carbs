# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

# Load test fixtures
Code.require_file("test/fixtures/param_spaces.exs")
Code.require_file("test/fixtures/carbs_config.exs")

# Start pythonx application if available
if Code.ensure_loaded?(Pythonx) do
  Application.ensure_all_started(:pythonx)
end

ExUnit.start()

