defmodule Todo.ProcessRegistry do
  use GenServer
  import Kernel, except: [send: 2]

  def start_link do
      IO.puts "Starting process registry"
      GenServer.start_link(__MODULE__, nil, name: :process_registry)
  end

  def register_name(key, pid) do
      GenServer.call(:process_registry, {:register_name, key, pid})
  end

  def whereis_name(key) do
    case :ets.lookup(:ets_process_registry, key) do
      [{^key, value}] -> value
      _ -> :undefined
    end
  end

  def unregister_name(key) do
      GenServer.call(:process_registry, {:unregister_name, key})
  end

  def send(key, message) do
    case whereis_name(key) do
      :undefined -> {:badarg, {key, message}}
      pid ->
        Kernel.send(pid, message)
        pid
    end
  end

  def init(_) do
    :ets.new(:ets_process_registry, [:set, :named_table, :protected])
    {:ok, nil}
  end

  def handle_call({:register_name, key, pid}, _sender, state) do
    case whereis_name(key) do
      :undefined ->
        Process.monitor(pid)
        :ets.insert(:ets_process_registry, {key, pid})
        {:reply, :yes, state}

      _ -> {:reply, :no, state}
      end
  end

  def handle_call({:unregister_name, key}, _, state) do
    :ets.delete(:ets_process_registry, key)
    {:reply, key, state}
  end

  def handle_info({:DOWN, _, :process, pid, _}, state) do
    :ets.match_delete(:ets_process_registry, {:_, pid})
    {:noreply, state}
  end
end
