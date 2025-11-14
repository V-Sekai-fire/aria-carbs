# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaCarbs.Repo.Migrations.CreateCarbsInstances do
  use Ecto.Migration

  def change do
    create table(:carbs_instances, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :instance_key, :string, null: false
      add :params_json, :text, null: false
      add :param_spaces_json, :text, null: false
      add :python_globals_json, :text
      add :created_at, :utc_datetime_usec, null: false
      add :updated_at, :utc_datetime_usec, null: false
    end

    create unique_index(:carbs_instances, [:instance_key])
  end
end

