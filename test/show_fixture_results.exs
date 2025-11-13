#!/usr/bin/env elixir

# Script to demonstrate fixture testing results
# Run with: elixir test/show_fixture_results.exs

Mix.install([
  {:jason, "~> 1.4"}
])

# Load fixtures
fixtures_path = Path.join([__DIR__, "fixtures"])
params_path = Path.join([fixtures_path, "sample_params.json"])
param_spaces_path = Path.join([fixtures_path, "sample_param_spaces.json"])
gp_test_path = Path.join([fixtures_path, "gp_optimization_test.json"])

IO.puts("=" |> String.duplicate(70))
IO.puts("CARBS Fixture Test Results - Illustration")
IO.puts("=" |> String.duplicate(70))
IO.puts("")

# Show fixture 1: Sample Parameters
IO.puts("📋 Fixture 1: Sample CARBS Parameters")
IO.puts("-" |> String.duplicate(70))
{:ok, params_json} = File.read(params_path)
{:ok, params} = Jason.decode(params_json)
IO.inspect(params, pretty: true, limit: :infinity)
IO.puts("")

# Show fixture 2: Parameter Spaces
IO.puts("📋 Fixture 2: Parameter Spaces")
IO.puts("-" |> String.duplicate(70))
{:ok, param_spaces_json} = File.read(param_spaces_path)
{:ok, param_spaces} = Jason.decode(param_spaces_json)
IO.inspect(param_spaces, pretty: true, limit: :infinity)
IO.puts("")

# Show fixture 3: GP Optimization Test
IO.puts("📋 Fixture 3: GP Optimization Test Configuration")
IO.puts("-" |> String.duplicate(70))
{:ok, gp_test_json} = File.read(gp_test_path)
{:ok, gp_test} = Jason.decode(gp_test_json)
IO.puts("Test Name: #{gp_test["test_name"]}")
IO.puts("")
IO.puts("True Values (Ground Truth):")
IO.inspect(gp_test["true_values"], pretty: true)
IO.puts("")
IO.puts("Expected Tolerance:")
IO.inspect(gp_test["expected_tolerance"], pretty: true)
IO.puts("")

# Show what the test expects
IO.puts("=" |> String.duplicate(70))
IO.puts("Expected Test Results:")
IO.puts("=" |> String.duplicate(70))
IO.puts("")
IO.puts("When CARBS optimizes with these fixtures, it should find:")
IO.puts("  • length_scale: ~#{gp_test["true_values"]["length_scale"]} (±#{gp_test["expected_tolerance"]["length_scale"] * 100}%)")
IO.puts("  • noise_variance: ~#{gp_test["true_values"]["noise_variance"]} (±#{gp_test["expected_tolerance"]["noise_variance"] * 100}%)")
IO.puts("  • signal_variance: ~#{gp_test["true_values"]["signal_variance"]} (±#{gp_test["expected_tolerance"]["signal_variance"] * 100}%)")
IO.puts("")
IO.puts("The test verifies that CARBS can recover these known optimal")
IO.puts("hyperparameters from synthetic GP data.")
IO.puts("")

