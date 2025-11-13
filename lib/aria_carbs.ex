# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaCarbs do
  @moduledoc """
  Elixir wrapper for CARBS (Cost-Aware pareto-Region Bayesian Search).

  This module provides Elixir functions to interact with CARBS through pythonx.
  CARBS is a hyperparameter optimizer that can optimize both regular hyperparameters
  and cost-related hyperparameters.
  """

  require Logger
  alias Pythonx

  @doc """
  Check if CARBS is available via pythonx.
  """
  @spec available?() :: boolean()
  def available? do
    case ensure_pythonx() do
      :ok -> true
      _ -> false
    end
  end

  @doc """
  Initialize a CARBS optimizer with the given parameters and parameter spaces.

  ## Parameters

  - `params`: A map with CARBS configuration parameters (see CARBSParams)
  - `param_spaces`: A list of parameter space definitions

  ## Examples

      params = %{
        "better_direction_sign" => -1,
        "is_wandb_logging_enabled" => false,
        "resample_frequency" => 0,
        "num_random_samples" => 3,
        "initial_search_radius" => 0.3
      }

      param_spaces = [
        %{"name" => "Alpha", "space_type" => "LogSpace", "min" => 0.01, "max" => 0.1, "search_center" => 0.02},
        %{"name" => "ScaleFact", "space_type" => "LinearSpace", "min" => 0.5, "max" => 2.0, "scale" => 0.5, "search_center" => 1.0}
      ]

      {:ok, carbs_instance} = AriaCarbs.init(params, param_spaces)
  """
  @spec init(map(), list()) :: {:ok, reference()} | {:error, String.t()}
  def init(params, param_spaces) when is_map(params) and is_list(param_spaces) do
    case ensure_pythonx() do
      :ok ->
        do_init(params, param_spaces)

      :not_available ->
        {:error, "Pythonx not available"}
    end
  end

  defp do_init(params, param_spaces) do
    params_json = Jason.encode!(params)
    param_spaces_json = Jason.encode!(param_spaces)

    code = """
    import sys
    import json

    try:
        from carbs.carbs import CARBS
        from carbs.utils import CARBSParams, Param, LinearSpace, LogSpace, LogitSpace

        # Parse parameters
        params_dict = json.loads('#{String.replace(params_json, "'", "\\'")}')
        param_spaces_list = json.loads('#{String.replace(param_spaces_json, "'", "\\'")}')

        # Convert param_spaces to CARBS Param objects
        param_objects = []
        for ps in param_spaces_list:
            name = ps['name']
            space_type = ps.get('space_type', 'LinearSpace')
            search_center = ps.get('search_center', 0.0)

            if space_type == 'LogSpace':
                space = LogSpace(
                    min=ps.get('min'),
                    max=ps.get('max'),
                    scale=ps.get('scale', 1.0),
                    is_integer=ps.get('is_integer', False),
                    rounding_factor=ps.get('rounding_factor')
                )
            elif space_type == 'LogitSpace':
                space = LogitSpace()
            else:  # LinearSpace
                space = LinearSpace(
                    min=ps.get('min'),
                    max=ps.get('max'),
                    scale=ps.get('scale', 1.0),
                    is_integer=ps.get('is_integer', False),
                    rounding_factor=ps.get('rounding_factor')
                )

            param_objects.append(Param(name=name, space=space, search_center=search_center))

        # Create CARBSParams
        carbs_params = CARBSParams(
            better_direction_sign=params_dict.get('better_direction_sign', -1),
            is_wandb_logging_enabled=params_dict.get('is_wandb_logging_enabled', False),
            resample_frequency=params_dict.get('resample_frequency', 5),
            num_random_samples=params_dict.get('num_random_samples', 4),
            initial_search_radius=params_dict.get('initial_search_radius', 0.3),
            max_suggestion_cost=params_dict.get('max_suggestion_cost'),
            min_pareto_cost_fraction=params_dict.get('min_pareto_cost_fraction', 0.2),
            is_saved_on_every_observation=params_dict.get('is_saved_on_every_observation', True)
        )

        # Initialize CARBS
        carbs = CARBS(carbs_params, param_objects)

        # Return success indicator
        json.dumps({'status': 'ok', 'message': 'CARBS initialized successfully'})
    except ImportError as e:
        json.dumps({'status': 'error', 'message': f'Failed to import CARBS: {str(e)}'})
    except Exception as e:
        json.dumps({'status': 'error', 'message': f'Failed to initialize CARBS: {str(e)}'})
    """

    case Pythonx.eval(code, %{}) do
      {result, _globals} ->
        case Pythonx.decode(result) do
          json_str when is_binary(json_str) ->
            case Jason.decode(json_str) do
              {:ok, %{"status" => "ok"}} ->
                {:ok, :carbs_initialized}

              {:ok, %{"status" => "error", "message" => msg}} ->
                {:error, msg}

              _ ->
                {:error, "Unexpected response from CARBS initialization"}
            end

          _ ->
            {:error, "Failed to decode CARBS initialization result"}
        end

      error ->
        {:error, "Failed to initialize CARBS: #{inspect(error)}"}
    end
  rescue
    e -> {:error, Exception.message(e)}
  end

  @doc """
  Get a suggestion from CARBS.

  This should be called after initialization. The suggestion contains
  parameter values to test.
  """
  @spec suggest() :: {:ok, map()} | {:error, String.t()}
  def suggest do
    case ensure_pythonx() do
      :ok ->
        do_suggest()

      :not_available ->
        {:error, "Pythonx not available"}
    end
  end

  defp do_suggest do
    code = """
    import json

    try:
        # Get suggestion from CARBS
        # Note: This assumes CARBS instance is stored in globals
        # In a full implementation, we'd need to manage CARBS instances
        suggestion_output = carbs.suggest()
        suggestion = suggestion_output.suggestion

        json.dumps({'status': 'ok', 'suggestion': suggestion})
    except NameError:
        json.dumps({'status': 'error', 'message': 'CARBS not initialized. Call init/2 first.'})
    except Exception as e:
        json.dumps({'status': 'error', 'message': f'Failed to get suggestion: {str(e)}'})
    """

    case Pythonx.eval(code, %{}) do
      {result, _globals} ->
        case Pythonx.decode(result) do
          json_str when is_binary(json_str) ->
            case Jason.decode(json_str) do
              {:ok, %{"status" => "ok", "suggestion" => suggestion}} ->
                {:ok, suggestion}

              {:ok, %{"status" => "error", "message" => msg}} ->
                {:error, msg}

              _ ->
                {:error, "Unexpected response from CARBS suggest"}
            end

          _ ->
            {:error, "Failed to decode CARBS suggestion result"}
        end

      error ->
        {:error, "Failed to get CARBS suggestion: #{inspect(error)}"}
    end
  rescue
    e -> {:error, Exception.message(e)}
  end

  @doc """
  Observe a result from testing a CARBS suggestion.

  ## Parameters

  - `input`: The parameter values that were tested (from suggest/0)
  - `output`: The result/score from testing those parameters
  - `cost`: The cost (e.g., runtime in seconds) of the test
  - `is_failure`: Whether the test failed (default: false)
  """
  @spec observe(map(), float(), float(), boolean()) :: {:ok, :observed} | {:error, String.t()}
  def observe(input, output, cost, is_failure \\ false)
      when is_map(input) and is_float(output) and is_float(cost) and is_boolean(is_failure) do
    case ensure_pythonx() do
      :ok ->
        do_observe(input, output, cost, is_failure)

      :not_available ->
        {:error, "Pythonx not available"}
    end
  end

  defp do_observe(input, output, cost, is_failure) do
    input_json = Jason.encode!(input)

    code = """
    import json
    from carbs.utils import ObservationInParam

    try:
        input_dict = json.loads('#{String.replace(input_json, "'", "\\'")}')
        output_val = #{output}
        cost_val = #{cost}
        is_failure_val = #{is_failure}

        # Create observation
        observation = ObservationInParam(
            input=input_dict,
            output=output_val,
            cost=cost_val,
            is_failure=is_failure_val
        )

        # Observe the result
        carbs.observe(observation)

        json.dumps({'status': 'ok', 'message': 'Observation recorded'})
    except NameError:
        json.dumps({'status': 'error', 'message': 'CARBS not initialized. Call init/2 first.'})
    except Exception as e:
        json.dumps({'status': 'error', 'message': f'Failed to observe: {str(e)}'})
    """

    case Pythonx.eval(code, %{}) do
      {result, _globals} ->
        case Pythonx.decode(result) do
          json_str when is_binary(json_str) ->
            case Jason.decode(json_str) do
              {:ok, %{"status" => "ok"}} ->
                {:ok, :observed}

              {:ok, %{"status" => "error", "message" => msg}} ->
                {:error, msg}

              _ ->
                {:error, "Unexpected response from CARBS observe"}
            end

          _ ->
            {:error, "Failed to decode CARBS observe result"}
        end

      error ->
        {:error, "Failed to observe CARBS result: #{inspect(error)}"}
    end
  rescue
    e -> {:error, Exception.message(e)}
  end

  defp ensure_pythonx do
    if Code.ensure_loaded?(Pythonx) do
      :ok
    else
      Logger.warning("Pythonx not available")
      :not_available
    end
  end
end

