defmodule Kabukura.DataSources.JQuants.Workers.Common.JobLogger do
  @moduledoc """
  Standardized logging functionality for JQuants workers.
  Provides consistent log formatting and log levels for all worker operations.
  """

  require Logger

  @doc """
  Logs the start of a job execution.

  ## Parameters
    - `worker_module`: The worker module name
    - `job_id`: The Oban job ID
    - `args`: The job arguments
  """
  def log_job_start(worker_module, job_id, args) do
    Logger.info("Starting #{worker_module} job execution", %{
      job_id: job_id,
      worker: worker_module,
      args: args,
      timestamp: DateTime.utc_now()
    })
  end

  @doc """
  Logs the successful completion of a job.

  ## Parameters
    - `worker_module`: The worker module name
    - `job_id`: The Oban job ID
    - `result`: The job execution result
  """
  def log_job_success(worker_module, job_id, result) do
    Logger.info("Successfully completed #{worker_module} job", %{
      job_id: job_id,
      worker: worker_module,
      result: result,
      timestamp: DateTime.utc_now()
    })
  end

  @doc """
  Logs a job execution error.

  ## Parameters
    - `worker_module`: The worker module name
    - `job_id`: The Oban job ID
    - `error`: The error that occurred
    - `attempt`: Current attempt number
    - `max_attempts`: Maximum number of attempts
  """
  def log_job_error(worker_module, job_id, error, attempt, max_attempts) do
    Logger.error("Error in #{worker_module} job execution", %{
      job_id: job_id,
      worker: worker_module,
      error: error,
      attempt: attempt,
      max_attempts: max_attempts,
      timestamp: DateTime.utc_now()
    })
  end

  @doc """
  Logs the scheduling of a new job.

  ## Parameters
    - `worker_module`: The worker module name
    - `cron_expression`: The cron expression used for scheduling
    - `opts`: The scheduling options
  """
  def log_job_scheduled(worker_module, cron_expression, opts) do
    Logger.info("Scheduled new #{worker_module} job", %{
      worker: worker_module,
      cron_expression: cron_expression,
      opts: opts,
      timestamp: DateTime.utc_now()
    })
  end

  @doc """
  Logs the scheduling failure of a job.

  ## Parameters
    - `worker_module`: The worker module name
    - `cron_expression`: The cron expression that failed
    - `error`: The error that occurred
  """
  def log_scheduling_error(worker_module, cron_expression, error) do
    Logger.error("Failed to schedule #{worker_module} job", %{
      worker: worker_module,
      cron_expression: cron_expression,
      error: error,
      timestamp: DateTime.utc_now()
    })
  end

  @doc """
  Logs debug information about job parameters.

  ## Parameters
    - `worker_module`: The worker module name
    - `message`: The debug message
    - `data`: The debug data
  """
  def log_debug(worker_module, message, data) do
    Logger.debug("#{worker_module}: #{message}", %{
      worker: worker_module,
      data: data,
      timestamp: DateTime.utc_now()
    })
  end
end
