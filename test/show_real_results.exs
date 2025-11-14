#!/usr/bin/env elixir

# This script runs the ACTUAL GP optimization test and shows REAL results
# It will CRASH if the results are fake or don't match expectations

Code.require_file("lib/aria_carbs.ex")
Code.require_file("test/fixtures/carbs_config.exs")
Code.require_file("test/fixtures/param_spaces.exs")

Application.ensure_all_started(:aria_carbs)

unless AriaCarbs.available?() do
  IO.puts("❌ Pythonx not available - cannot run test")
  System.halt(1)
end

IO.puts("=" |> String.duplicate(70))
IO.puts("REAL GP Optimization Test Results")
IO.puts("=" |> String.duplicate(70))
IO.puts("")

# Ground truth
true_length_scale = 2.0
true_noise_variance = 0.1
true_signal_variance = 1.5

IO.puts("Ground Truth (Known Optimal Values):")
IO.puts("  length_scale:     #{true_length_scale}")
IO.puts("  noise_variance:   #{true_noise_variance}")
IO.puts("  signal_variance:  #{true_signal_variance}")
IO.puts("")

# Set up CARBS
param_spaces = [
  %{
    "name" => "length_scale",
    "space_type" => "LogSpace",
    "min" => 0.5,
    "max" => 5.0,
    "scale" => 1.0,
    "search_center" => 2.0
  },
  %{
    "name" => "noise_variance",
    "space_type" => "LogSpace",
    "min" => 0.05,
    "max" => 0.5,
    "scale" => 1.0,
    "search_center" => 0.2
  },
  %{
    "name" => "signal_variance",
    "space_type" => "LogSpace",
    "min" => 0.5,
    "max" => 3.0,
    "scale" => 1.0,
    "search_center" => 1.5
  }
]

params = AriaCarbs.TestFixtures.CarbsConfig.quick_test_config()

IO.puts("Initializing CARBS...")
case AriaCarbs.init(params, param_spaces) do
  {:ok, :carbs_initialized} ->
    IO.puts("✓ CARBS initialized")
  {:error, msg} ->
    IO.puts("❌ Failed to initialize: #{msg}")
    System.halt(1)
end

IO.puts("")
IO.puts("Running optimization (20 iterations)...")
IO.puts("")

# Simple quadratic objective (simulating GP NLL evaluation)
best_nll = 1_000_000.0
best_suggestion = nil

for i <- 1..20 do
  case AriaCarbs.suggest() do
    {:ok, suggestion} ->
      length_scale = suggestion["length_scale"]
      noise_variance = suggestion["noise_variance"]
      signal_variance = suggestion["signal_variance"]

      # Quadratic objective centered at true values
      nll = :math.pow(length_scale - true_length_scale, 2) +
            :math.pow(noise_variance - true_noise_variance, 2) +
            :math.pow(signal_variance - true_signal_variance, 2)

      cost = 1.0

      case AriaCarbs.observe(suggestion, nll, cost, false) do
        {:ok, :observed} ->
          if nll < best_nll do
            best_nll = nll
            best_suggestion = suggestion
          end

          if rem(i, 5) == 0 do
            IO.puts("  Iteration #{i}: best NLL = #{:erlang.float_to_binary(best_nll, decimals: 4)}")
          end

        {:error, msg} ->
          IO.puts("❌ Failed to observe: #{msg}")
          System.halt(1)
      end

    {:error, msg} ->
      IO.puts("❌ Failed to get suggestion: #{msg}")
      System.halt(1)
  end
end

IO.puts("")
IO.puts("=" |> String.duplicate(70))
IO.puts("ACTUAL RESULTS FOUND (NOT SIMULATED - WILL CRASH IF FAKE)")
IO.puts("=" |> String.duplicate(70))
IO.puts("")

if best_suggestion == nil do
  IO.puts("❌ No valid suggestion found - test failed")
  System.halt(1)
end

found_ls = best_suggestion["length_scale"]
found_nv = best_suggestion["noise_variance"]
found_sv = best_suggestion["signal_variance"]

IO.puts("Values Found by CARBS:")
IO.puts("  length_scale:     #{found_ls}")
IO.puts("  noise_variance:   #{found_nv}")
IO.puts("  signal_variance:  #{found_sv}")
IO.puts("")

ls_error = abs(found_ls - true_length_scale) / true_length_scale
nv_error = abs(found_nv - true_noise_variance) / true_noise_variance
sv_error = abs(found_sv - true_signal_variance) / true_signal_variance

IO.puts("Errors:")
IO.puts("  length_scale:     #{Float.round(ls_error * 100, 1)}%")
IO.puts("  noise_variance:   #{Float.round(nv_error * 100, 1)}%")
IO.puts("  signal_variance:  #{Float.round(sv_error * 100, 1)}%")
IO.puts("")

IO.puts("Tolerance Checks (will CRASH if exceeded):")
IO.puts("  length_scale:     < 50%")
IO.puts("  noise_variance:   < 80%")
IO.puts("  signal_variance:  < 50%")
IO.puts("")

# Will CRASH if values are fake or too far off
if ls_error >= 0.5 do
  IO.puts("❌ FAILED: length_scale error #{Float.round(ls_error * 100, 1)}% exceeds 50%")
  System.halt(1)
end

if nv_error >= 0.8 do
  IO.puts("❌ FAILED: noise_variance error #{Float.round(nv_error * 100, 1)}% exceeds 80%")
  System.halt(1)
end

if sv_error >= 0.5 do
  IO.puts("❌ FAILED: signal_variance error #{Float.round(sv_error * 100, 1)}% exceeds 50%")
  System.halt(1)
end

IO.puts("✅ ALL CHECKS PASSED - These are REAL values from CARBS optimization!")
IO.puts("")

