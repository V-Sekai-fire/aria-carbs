# Aria CARBS

Elixir wrapper for CARBS (Cost-Aware pareto-Region Bayesian Search) using pythonx.

## Overview

This library provides Elixir functions to interact with CARBS, a hyperparameter optimizer that can optimize both regular hyperparameters (like learning rate) and cost-related hyperparameters (like the number of epochs over data).

CARBS is installed from the [fire/carbs](https://github.com/fire/carbs) repository via pythonx's uv dependency management.

## Installation

Add `aria_carbs` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:aria_carbs, git: "https://github.com/V-Sekai-fire/aria-carbs.git"}
  ]
end
```

## Configuration

The library automatically configures pythonx to install CARBS from git. No additional configuration is needed.

## Usage

```elixir
# Initialize CARBS with parameters and parameter spaces
params = %{
  "better_direction_sign" => -1,
  "is_wandb_logging_enabled" => false,
  "resample_frequency" => 0,
  "num_random_samples" => 3,
  "initial_search_radius" => 0.3
}

param_spaces = [
  %{
    "name" => "Alpha",
    "space_type" => "LogSpace",
    "min" => 0.01,
    "max" => 0.1,
    "search_center" => 0.02
  },
  %{
    "name" => "ScaleFact",
    "space_type" => "LinearSpace",
    "min" => 0.5,
    "max" => 2.0,
    "scale" => 0.5,
    "search_center" => 1.0
  }
]

{:ok, _} = AriaCarbs.init(params, param_spaces)

# Get a suggestion
{:ok, suggestion} = AriaCarbs.suggest()
# suggestion = %{"Alpha" => 0.025, "ScaleFact" => 1.2}

# Test the suggestion and observe the result
output = run_test(suggestion)
cost = 120.5  # runtime in seconds
{:ok, _} = AriaCarbs.observe(suggestion, output, cost)
```

## Parameter Space Types

- **LinearSpace**: For linear parameters. Requires a `scale` parameter.
- **LogSpace**: For log-distributed parameters (like learning rates). Good for cost-related variables.
- **LogitSpace**: For parameters between 0 and 1.

## Dependencies

- **pythonx**: Elixir Python interop library
- **jason**: JSON encoding/decoding
- **CARBS**: Installed from fire/carbs via pythonx (includes torch, pyro-ppl, etc.)

## License

MIT
