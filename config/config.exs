import Config

# Pythonx configuration for uv-based Python dependency management
# This initializes Pythonx with the pyproject.toml configuration at compile time
# CARBS is installed from fire/carbs git repository
config :pythonx, :uv_init,
  pyproject_toml: """
  [project]
  name = "aria-carbs"
  version = "0.1.0"
  requires-python = ">=3.9"
  dependencies = [
      # CARBS from git (includes all its dependencies: torch, pyro-ppl, etc.)
      "carbs @ git+https://github.com/fire/carbs.git",
  ]
  """

# Ecto configuration for SQLite database
config :aria_carbs,
  ecto_repos: [AriaCarbs.Repo]

config :aria_carbs, AriaCarbs.Repo,
  database: Path.expand("../priv/aria_carbs.db", __DIR__),
  pool_size: 1,
  show_sensitive_data_on_connection_error: true

