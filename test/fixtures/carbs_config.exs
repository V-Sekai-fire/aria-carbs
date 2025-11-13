# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaCarbs.TestFixtures.CarbsConfig do
  @moduledoc """
  Test fixtures for CARBS configuration parameters.

  Provides common CARBS configuration setups for testing.
  """

  @doc """
  Returns a minimal CARBS configuration for testing.
  """
  def minimal_config do
    %{
      "better_direction_sign" => -1,
      "is_wandb_logging_enabled" => false,
      "resample_frequency" => 0,
      "num_random_samples" => 3,
      "initial_search_radius" => 0.3
    }
  end

  @doc """
  Returns a default CARBS configuration.
  """
  def default_config do
    %{
      "better_direction_sign" => -1,
      "is_wandb_logging_enabled" => false,
      "resample_frequency" => 5,
      "num_random_samples" => 4,
      "initial_search_radius" => 0.3,
      "min_pareto_cost_fraction" => 0.2,
      "is_saved_on_every_observation" => true
    }
  end

  @doc """
  Returns a CARBS configuration optimized for quick testing (fewer samples).
  """
  def quick_test_config do
    %{
      "better_direction_sign" => -1,
      "is_wandb_logging_enabled" => false,
      "resample_frequency" => 0,
      "num_random_samples" => 2,
      "initial_search_radius" => 0.3
    }
  end

  @doc """
  Returns a CARBS configuration with cost constraints.
  """
  def cost_constrained_config do
    %{
      "better_direction_sign" => -1,
      "is_wandb_logging_enabled" => false,
      "resample_frequency" => 5,
      "num_random_samples" => 4,
      "initial_search_radius" => 0.3,
      "max_suggestion_cost" => 1000.0,
      "min_pareto_cost_fraction" => 0.2,
      "is_saved_on_every_observation" => true
    }
  end

  @doc """
  Returns a CARBS configuration for maximizing (better_direction_sign = 1).
  """
  def maximize_config do
    %{
      "better_direction_sign" => 1,
      "is_wandb_logging_enabled" => false,
      "resample_frequency" => 5,
      "num_random_samples" => 4,
      "initial_search_radius" => 0.3
    }
  end
end
