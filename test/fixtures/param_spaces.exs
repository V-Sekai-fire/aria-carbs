# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaCarbs.TestFixtures.ParamSpaces do
  @moduledoc """
  Test fixtures for CARBS parameter spaces.

  Provides common parameter space configurations for testing.
  """

  @doc """
  Returns a simple LinearSpace parameter space for testing.
  """
  def linear_space_example do
    [
      %{
        "name" => "learning_rate",
        "space_type" => "LinearSpace",
        "min" => 0.001,
        "max" => 0.1,
        "scale" => 0.01,
        "search_center" => 0.01
      }
    ]
  end

  @doc """
  Returns a LogSpace parameter space for testing (common for learning rates).
  """
  def log_space_example do
    [
      %{
        "name" => "learning_rate",
        "space_type" => "LogSpace",
        "min" => 0.0001,
        "max" => 0.1,
        "scale" => 1.0,
        "search_center" => 0.01
      }
    ]
  end

  @doc """
  Returns a LogitSpace parameter space for testing (for values between 0 and 1).
  """
  def logit_space_example do
    [
      %{
        "name" => "momentum",
        "space_type" => "LogitSpace",
        "search_center" => 0.9
      }
    ]
  end

  @doc """
  Returns QuadWild parameter spaces (Alpha, ScaleFact, SharpAngle).
  This matches the parameter spaces used in mesh_topology.
  """
  def quadwild_param_spaces do
    [
      %{
        "name" => "Alpha",
        "space_type" => "LogSpace",
        "min" => 0.01,
        "max" => 0.1,
        "scale" => 1.0,
        "search_center" => 0.02
      },
      %{
        "name" => "ScaleFact",
        "space_type" => "LinearSpace",
        "min" => 0.5,
        "max" => 2.0,
        "scale" => 0.5,
        "search_center" => 1.0
      },
      %{
        "name" => "SharpAngle",
        "space_type" => "LinearSpace",
        "min" => 15.0,
        "max" => 60.0,
        "scale" => 15.0,
        "search_center" => 30.0
      }
    ]
  end

  @doc """
  Returns a multi-parameter space with different space types.
  """
  def multi_param_space do
    [
      %{
        "name" => "learning_rate",
        "space_type" => "LogSpace",
        "min" => 0.0001,
        "max" => 0.1,
        "scale" => 1.0,
        "search_center" => 0.01
      },
      %{
        "name" => "batch_size",
        "space_type" => "LinearSpace",
        "min" => 16,
        "max" => 128,
        "scale" => 16,
        "is_integer" => true,
        "search_center" => 32
      },
      %{
        "name" => "momentum",
        "space_type" => "LogitSpace",
        "search_center" => 0.9
      }
    ]
  end

  @doc """
  Returns an integer parameter space (for epochs, batch size, etc.).
  """
  def integer_param_space do
    [
      %{
        "name" => "epochs",
        "space_type" => "LogSpace",
        "min" => 2,
        "max" => 512,
        "scale" => 1.0,
        "is_integer" => true,
        "search_center" => 10
      }
    ]
  end

  @doc """
  Returns a minimal parameter space for quick tests.
  """
  def minimal_param_space do
    [
      %{
        "name" => "x",
        "space_type" => "LinearSpace",
        "min" => 0.0,
        "max" => 1.0,
        "scale" => 0.1,
        "search_center" => 0.5
      }
    ]
  end
end
