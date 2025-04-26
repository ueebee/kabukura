defmodule Kabukura.Jobs.TestJob do
  use Oban.Worker, queue: :daily_quotes
  import Ecto.Query

  @impl Oban.Worker
  def perform(_job) do
    IO.puts("Test job executed at #{DateTime.utc_now()}")
    :ok
  end

  def create_job do
    new(%{}) |> Oban.insert()
  end

  def list_jobs do
    Oban.Job
    |> where([j], j.worker == "Kabukura.Jobs.TestJob")
    |> Kabukura.Repo.all()
  end
end
