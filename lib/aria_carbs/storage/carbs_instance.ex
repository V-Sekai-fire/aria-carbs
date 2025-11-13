# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaCarbs.Storage.CarbsInstance do
  use Ecto.Schema

  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "carbs_instances" do
    field :instance_key, :string
    field :params_json, :string
    field :param_spaces_json, :string
    field :python_globals_json, :string
    field :created_at, :utc_datetime_usec
    field :updated_at, :utc_datetime_usec
  end

  def changeset(carbs_instance, attrs) do
    carbs_instance
    |> cast(attrs, [:instance_key, :params_json, :param_spaces_json, :python_globals_json])
    |> validate_required([:instance_key, :params_json, :param_spaces_json])
    |> unique_constraint(:instance_key)
  end
end

