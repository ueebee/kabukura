# lib/kabukura/jobs/hello_job.ex
defmodule Kabukura.Jobs.HelloJob do
  use Oban.Worker

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"name" => name}}) do
    IO.puts("Hello, #{name}!")
    :ok
  end
end
