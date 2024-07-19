module TaskTracker

export generate_gantt

using Dates
using Kroki

mutable struct Task
  name::String
  complete::Bool
  subtasks::Vector{Task}
  level::Int
  start_date::Union{Date,Nothing}
  duration::Int
  completion::Float64
end

function calculate_completion!(task::Task)
  if isempty(task.subtasks)
    task.completion = task.complete ? 1.0 : 0.0
  else
    for subtask in task.subtasks
      calculate_completion!(subtask)
    end
    task.completion = sum(subtask.completion for subtask in task.subtasks) / length(task.subtasks)
  end
  return task.completion
end

function parse_markdown(filename)
  tasks = Task[]
  task_stack = Task[]

  function process_task(line, level)
    is_complete = startswith(strip(line), "- [x]")
    task_name = strip(strip(line)[6:end])

    # Check for start date and duration
    start_date = nothing
    duration = 5  # Default duration
    if contains(task_name, "|")
      parts = split(task_name, "|")
      task_name = strip(parts[1])
      if length(parts) > 1
        start_date = Date(strip(parts[2]), "yyyy-mm-dd")
      end
      if length(parts) > 2
        duration = parse(Int, strip(parts[3]))
      end
    end

    new_task = Task(task_name, is_complete, Task[], level, start_date, duration, is_complete ? 1.0 : 0.0)

    if level == 0
      push!(tasks, new_task)
    else
      push!(task_stack[end].subtasks, new_task)
    end

    return new_task
  end

  open(filename, "r") do file
    for line in eachline(file)
      if startswith(strip(line), "- [ ]") || startswith(strip(line), "- [x]")
        level = count(c -> c == ' ', line[1:findfirst(c -> c != ' ', line)-1]) ÷ 2

        new_task = process_task(line, level)

        push!(task_stack, new_task)
      end
    end
  end

  for task in tasks
    task.completion = calculate_completion!(task)
  end

  return tasks
end

function generate_plantuml(tasks)
  plantuml = """
  @startgantt
  printscale daily
  project starts 2024-07-01
  saturday are closed
  sunday are closed

  """

  for (index, task) in enumerate(tasks)
    start_date = isnothing(task.start_date) ? "2024-07-01" : Dates.format(task.start_date, "yyyy-mm-dd")
    plantuml *= "[$index] as [$(task.name)] starts $start_date and lasts $(task.duration) days\n"
    plantuml *= "[$index] is $(round(Int, task.completion * 100))% complete\n"
  end

  plantuml *= "@endgantt"
  return plantuml
end

function generate_gantt(todo_file="todo.md"; output_file="gannt.png")
  tasks = parse_markdown(todo_file)
  plantuml = generate_plantuml(tasks)
  diagram_format = splitext(output_file)[2][2:end]
  diagram = Kroki.Diagram(:PlantUML, plantuml)
  rendered = render(diagram, diagram_format)
  write(output_file, rendered)
end

end # module TaskTracker
