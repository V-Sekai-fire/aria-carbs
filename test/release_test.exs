# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaCarbs.ReleaseTest do
  use ExUnit.Case, async: false

  alias AriaCarbs.TestFixtures.ParamSpaces
  alias AriaCarbs.TestFixtures.CarbsConfig

  @fixtures_path Path.join([__DIR__, "fixtures"])

  setup do
    # Use a test-specific database path to avoid conflicts
    test_db_path = Path.join([System.tmp_dir!(), "aria_carbs_test_#{System.unique_integer([:positive])}.db"])
    
    # Configure Repo to use test database
    Application.put_env(:aria_carbs, AriaCarbs.Repo, database: test_db_path)
    
    # Ensure application is started
    Application.ensure_all_started(:aria_carbs)
    
    # Ensure directory exists
    db_dir = Path.dirname(test_db_path)
    File.mkdir_p!(db_dir)
    
    # Ensure database is clean
    if File.exists?(test_db_path) do
      File.rm(test_db_path)
    end
    
    # Also remove any SQLite journal files
    for ext <- [".db-shm", ".db-wal"] do
      journal_path = test_db_path <> ext
      if File.exists?(journal_path), do: File.rm(journal_path)
    end

    # Run migrations
    AriaCarbs.Release.migrate()

    on_exit(fn ->
      # Clean up database after test
      # Note: We don't stop the Repo here as it's managed by the application supervisor
      # and stopping it would break other tests that might still need it
      if File.exists?(test_db_path) do
        File.rm(test_db_path)
      end
      for ext <- [".db-shm", ".db-wal"] do
        journal_path = test_db_path <> ext
        if File.exists?(journal_path), do: File.rm(journal_path)
      end
    end)

    :ok
  end

  describe "release compatibility" do
    test "can read JSON fixtures" do
      params_path = Path.join(@fixtures_path, "sample_params.json")
      param_spaces_path = Path.join(@fixtures_path, "sample_param_spaces.json")

      assert File.exists?(params_path)
      assert File.exists?(param_spaces_path)

      {:ok, params_json} = File.read(params_path)
      {:ok, param_spaces_json} = File.read(param_spaces_path)

      {:ok, params} = Jason.decode(params_json)
      {:ok, param_spaces} = Jason.decode(param_spaces_json)

      assert is_map(params)
      assert is_list(param_spaces)
      assert length(param_spaces) == 2
    end

    test "can initialize CARBS with fixture data" do
      if AriaCarbs.available?() do
        params_path = Path.join(@fixtures_path, "sample_params.json")
        param_spaces_path = Path.join(@fixtures_path, "sample_param_spaces.json")

        {:ok, params_json} = File.read(params_path)
        {:ok, param_spaces_json} = File.read(param_spaces_path)

        {:ok, params} = Jason.decode(params_json)
        {:ok, param_spaces} = Jason.decode(param_spaces_json)

        assert {:ok, :carbs_initialized} = AriaCarbs.init(params, param_spaces)
      end
    end

    test "can load GP optimization test fixture" do
      gp_test_path = Path.join(@fixtures_path, "gp_optimization_test.json")

      assert File.exists?(gp_test_path)

      {:ok, gp_test_json} = File.read(gp_test_path)
      {:ok, gp_test} = Jason.decode(gp_test_json)

      assert Map.has_key?(gp_test, "test_name")
      assert Map.has_key?(gp_test, "true_values")
      assert Map.has_key?(gp_test, "param_spaces")
      assert Map.has_key?(gp_test, "expected_tolerance")

      assert gp_test["test_name"] == "GP hyperparameter optimization"
      assert is_map(gp_test["true_values"])
      assert is_list(gp_test["param_spaces"])
    end

    test "database migrations work in release context" do
      # Ensure Repo is started
      Application.ensure_all_started(:aria_carbs)
      
      # This simulates what happens in a release
      assert AriaCarbs.Repo.__adapter__() == Ecto.Adapters.SQLite3

      # Verify table exists
      result = AriaCarbs.Repo.query!("SELECT name FROM sqlite_master WHERE type='table' AND name='carbs_instances'")
      assert length(result.rows) == 1
    end

    test "can store and retrieve CARBS instance data" do
      if AriaCarbs.available?() do
        params = CarbsConfig.minimal_config()
        param_spaces = ParamSpaces.minimal_param_space()

        # Initialize CARBS
        assert {:ok, :carbs_initialized} = AriaCarbs.init(params, param_spaces)

        # Get a suggestion
        {:ok, suggestion} = AriaCarbs.suggest()
        assert is_map(suggestion)

        # Observe a result
        output = 0.5
        cost = 10.0
        assert {:ok, :observed} = AriaCarbs.observe(suggestion, output, cost, false)
      end
    end
  end
end

