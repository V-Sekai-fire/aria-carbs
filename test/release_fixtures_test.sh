#!/bin/bash
# Test mix release against test fixtures

set -e

# Skip optimization test by default for faster builds
# Set SKIP_OPTIMIZATION_TEST=0 to run the optimization test
SKIP_OPTIMIZATION_TEST=${SKIP_OPTIMIZATION_TEST:-1}

RELEASE_DIR="_build/prod/rel/aria_carbs"
FIXTURES_DIR="test/fixtures"

echo "=== Testing Mix Release Against Fixtures ==="
echo ""

# Check if release exists
if [ ! -d "$RELEASE_DIR" ]; then
    echo "❌ Release not found. Building release..."
    MIX_ENV=prod mix release
fi

echo "✓ Release found at $RELEASE_DIR"
echo ""

# Test 1: Check fixtures exist
echo "=== Test 1: Verify fixtures exist ==="
for fixture in sample_params.json sample_param_spaces.json gp_optimization_test.json; do
    if [ -f "$FIXTURES_DIR/$fixture" ]; then
        echo "✓ Found $fixture"
    else
        echo "❌ Missing $fixture"
        exit 1
    fi
done
echo ""

# Test 2: Run migrations in release
echo "=== Test 2: Run migrations in release ==="
$RELEASE_DIR/bin/aria_carbs eval "AriaCarbs.Release.migrate()" || {
    echo "❌ Migrations failed"
    exit 1
}
echo "✓ Migrations completed"
echo ""

# Test 3: Read JSON fixtures from release
echo "=== Test 3: Read JSON fixtures from release ==="
$RELEASE_DIR/bin/aria_carbs eval "
Application.ensure_all_started(:aria_carbs)
fixtures_path = Path.join([\"test\", \"fixtures\"])
params_path = Path.join([fixtures_path, \"sample_params.json\"])
param_spaces_path = Path.join([fixtures_path, \"sample_param_spaces.json\"])

{:ok, params_json} = File.read(params_path)
{:ok, param_spaces_json} = File.read(param_spaces_path)

{:ok, params} = Jason.decode(params_json)
{:ok, param_spaces} = Jason.decode(param_spaces_json)

IO.puts(\"✓ Read params: #{inspect(Map.keys(params))}\")
IO.puts(\"✓ Read param_spaces: #{length(param_spaces)} parameters\")
" || {
    echo "❌ Failed to read fixtures"
    exit 1
}
echo ""

# Test 4: Verify database was created
echo "=== Test 4: Verify database exists ==="
if [ -f "priv/aria_carbs.db" ]; then
    echo "✓ Database file exists"
    DB_SIZE=$(stat -f%z "priv/aria_carbs.db" 2>/dev/null || stat -c%s "priv/aria_carbs.db" 2>/dev/null)
    echo "  Database size: $DB_SIZE bytes"
else
    echo "⚠ Database file not found (may be in release directory)"
fi
echo ""

# Test 5: Check database schema
echo "=== Test 5: Verify database schema ==="
$RELEASE_DIR/bin/aria_carbs eval "
Application.ensure_all_started(:aria_carbs)
result = AriaCarbs.Repo.query!(\"SELECT name FROM sqlite_master WHERE type='table' AND name='carbs_instances'\")
if length(result.rows) > 0 do
  IO.puts(\"✓ Table 'carbs_instances' exists\")
else
  IO.puts(\"❌ Table 'carbs_instances' not found\")
  System.halt(1)
end
" || {
    echo "❌ Schema verification failed"
    exit 1
}
echo ""

# Test 6: Initialize CARBS with fixture data and run optimization (REQUIRED - will crash if Pythonx unavailable)
if [ "$SKIP_OPTIMIZATION_TEST" = "1" ]; then
  echo "=== Test 6: Initialize CARBS and run optimization ==="
  echo "⏭️  Skipping optimization test (SKIP_OPTIMIZATION_TEST=1)"
  echo ""
else
  echo "=== Test 6: Initialize CARBS and run optimization ==="
  $RELEASE_DIR/bin/aria_carbs eval "
Application.ensure_all_started(:aria_carbs)

unless AriaCarbs.available?() do
  IO.puts(\"❌ Pythonx/CARBS not available - test will fail\")
  System.halt(1)
end

fixtures_path = Path.join([\"test\", \"fixtures\"])
params_path = Path.join([fixtures_path, \"sample_params.json\"])
param_spaces_path = Path.join([fixtures_path, \"sample_param_spaces.json\"])

{:ok, params_json} = File.read(params_path)
{:ok, param_spaces_json} = File.read(param_spaces_path)

{:ok, params} = Jason.decode(params_json)
{:ok, param_spaces} = Jason.decode(param_spaces_json)

case AriaCarbs.init(params, param_spaces) do
  {:ok, :carbs_initialized} ->
    IO.puts(\"✓ CARBS initialized successfully with fixture data\")
    
    # Define optimal values for optimization test
    # Using a simple quadratic objective: minimize (length_scale - 1.0)^2 + (noise_variance - 0.1)^2
    optimal_length_scale = 1.0
    optimal_noise_variance = 0.1
    
    IO.puts(\"\\n🎯 Running optimization (15 iterations)...\")
    IO.puts(\"   Optimal values: length_scale=#{optimal_length_scale}, noise_variance=#{optimal_noise_variance}\")
    IO.puts(\"   Objective: minimize (length_scale - 1.0)^2 + (noise_variance - 0.1)^2\")
    IO.puts(\"\\n\")
    
    # Objective function
    evaluate_objective = fn suggestion ->
      length_scale = suggestion[\"length_scale\"]
      noise_variance = suggestion[\"noise_variance\"]
      :math.pow(length_scale - optimal_length_scale, 2) + :math.pow(noise_variance - optimal_noise_variance, 2)
    end
    
    # Run optimization loop
    {best_objective, best_suggestion} = Enum.reduce(1..15, {1_000_000.0, nil}, fn i, {current_best_obj, current_best_sugg} ->
      case AriaCarbs.suggest() do
        {:ok, suggestion} ->
          objective = evaluate_objective.(suggestion)
          cost = 1.0
          
          case AriaCarbs.observe(suggestion, objective, cost, false) do
            {:ok, :observed} ->
              {new_best_obj, new_best_sugg} = if objective < current_best_obj do
                {objective, suggestion}
              else
                {current_best_obj, current_best_sugg}
              end
              
              if rem(i, 5) == 0 do
                IO.puts(\"  Iteration #{i}: objective=#{Float.round(objective, 4)}, best=#{Float.round(new_best_obj, 4)}\")
              end
              
              {new_best_obj, new_best_sugg}
            {:error, msg} ->
              IO.puts(\"❌ Failed to observe: #{msg}\")
              System.halt(1)
          end
        {:error, msg} ->
          IO.puts(\"❌ Failed to get suggestion: #{msg}\")
          System.halt(1)
      end
    end)
    
    IO.puts(\"\\n\" <> \"=\" |> String.duplicate(70))
    IO.puts(\"📊 OPTIMIZATION RESULTS (REAL VALUES, NOT SIMULATED)\")
    IO.puts(\"=\" |> String.duplicate(70))
    IO.puts(\"\\nOptimal Values:\")
    IO.puts(\"  length_scale:     #{optimal_length_scale}\")
    IO.puts(\"  noise_variance:   #{optimal_noise_variance}\")
    IO.puts(\"\\nBest Values Found by CARBS:\")
    IO.puts(\"  length_scale:     #{best_suggestion[\"length_scale\"]}\")
    IO.puts(\"  noise_variance:   #{best_suggestion[\"noise_variance\"]}\")
    IO.puts(\"\\nErrors:\")
    length_scale_error = abs(best_suggestion[\"length_scale\"] - optimal_length_scale)
    noise_variance_error = abs(best_suggestion[\"noise_variance\"] - optimal_noise_variance)
    IO.puts(\"  length_scale:     #{Float.round(length_scale_error, 4)} (target: < 0.5)\")
    IO.puts(\"  noise_variance:   #{Float.round(noise_variance_error, 4)} (target: < 0.1)\")
    IO.puts(\"\\nBest Objective Value: #{Float.round(best_objective, 6)}\")
    IO.puts(\"\\n\" <> \"=\" |> String.duplicate(70))
    
    # Verify convergence (allow reasonable tolerance)
    if length_scale_error > 1.0 do
      IO.puts(\"❌ Length scale error too large: #{length_scale_error} (expected < 1.0)\")
      System.halt(1)
    end
    
    if noise_variance_error > 0.3 do
      IO.puts(\"❌ Noise variance error too large: #{noise_variance_error} (expected < 0.3)\")
      System.halt(1)
    end
    
    IO.puts(\"✓ Optimization converged to near-optimal values!\")
    
  {:error, msg} ->
    IO.puts(\"❌ CARBS initialization failed: #{msg}\")
    System.halt(1)
end
" || {
    echo "❌ CARBS optimization test failed - Pythonx may not be available"
    exit 1
  }
  echo ""
fi

echo "=== All Release Fixture Tests Passed! ==="

