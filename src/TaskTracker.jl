module TaskTracker

export generate_gantt, generate_gantt_for_dir

using Dates
using Kroki
using Images

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
  title = ""

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
        date_str = strip(parts[2])
        if startswith(date_str, "after ")
          # Handle "after Task" syntax
          referenced_task_name = strip(date_str[6:end])
          referenced_task_index = findfirst(t -> !isnothing(t) && t.name == referenced_task_name, tasks)
          if !isnothing(referenced_task_index)
            referenced_task = tasks[referenced_task_index]
            start_date = referenced_task.start_date + Day(referenced_task.duration)
          end
        else
          start_date = Date(date_str, "yyyy-mm-dd")
        end
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
      if startswith(strip(line), "# ")
        title = strip(line)[3:end]
      elseif startswith(strip(line), "- [ ]") || startswith(strip(line), "- [x]")
        level = count(c -> c == ' ', line[1:findfirst(c -> c != ' ', line)-1]) ÷ 2

        while length(task_stack) > level
          calculate_completion!(task_stack[end])  # Update the completion of the parent task
          pop!(task_stack)
        end

        new_task = process_task(line, level)

        push!(task_stack, new_task)
      end
    end
  end

  for task in tasks
    task.completion = calculate_completion!(task)
  end

  return title, tasks
end

function generate_plantuml(title, tasks)
  # Find the earliest start date among the tasks
  start_dates = [task.start_date for task in tasks if !isnothing(task.start_date) && typeof(task.start_date) != String]
  project_start_date = isempty(start_dates) ? Dates.today() : Dates.format(minimum(start_dates), "yyyy-mm-dd")

  plantuml = """
  @startgantt
  title $title
  printscale daily
  project starts $project_start_date
  saturday are closed
  sunday are closed

  <style>
  ganttDiagram {
    task {
      BackGroundColor #66CC66
    }
  }
  </style>

  """

  for task in tasks
    plantuml *= "[$(task.name)] as [$(task.name)] lasts $(task.duration) days\n"
    plantuml *= "[$(task.name)] is $(round(Int, task.completion * 100))% complete\n"
    if !isnothing(task.start_date) && typeof(task.start_date) == String && startswith(task.start_date, "after ")
      referenced_task_name = strip(task.start_date)[6:end]
      plantuml *= "[$(task.name)] starts at [$(referenced_task_name)]'s end\n"
    else
      start_date = isnothing(task.start_date) ? project_start_date : Dates.format(task.start_date, "yyyy-mm-dd")
      plantuml *= "[$(task.name)] starts $start_date\n"
    end
  end

  plantuml *= "@endgantt"
  return plantuml
end

"""
    generate_gantt(todo_file="todo.md"; output_file="gantt.png")

Generate a Gantt chart for the task list in the specified markdown file.

# Arguments
- `todo_file::String`: The markdown file containing the task list. Each task should have a name, start date, duration, and completion percentage. Default is "todo.md".
- `output_file::String`: The name of the output file. The file will be saved in the format specified by the file extension. Default is "gantt.png".

# Returns
Nothing. The function saves the Gantt chart to the output file.

# Example
```julia
generate_gantt("path/to/todo.md", output_file="gantt.png")
```
"""
function generate_gantt(todo_file="todo.md"; output_file="gannt.png")
  title, tasks = parse_markdown(todo_file)
  plantuml = generate_plantuml(title, tasks)
  diagram_format = splitext(output_file)[2][2:end]
  diagram = Kroki.Diagram(:PlantUML, plantuml)
  rendered = render(diagram, diagram_format)
  write(output_file, rendered)
end

"""
    generate_gantt_for_dir(directory::String; output_file::String="gantt.png")

Generate a Gantt chart for each markdown file in the specified directory and combine them into a single PNG image.

# Arguments
- `directory::String`: The directory to search for markdown files. Each markdown file should contain a task list that can be converted into a Gantt chart.
- `output_file::String`: The name of the output file. The file will be saved in PNG format. Default is "gantt.png".

# Returns
Nothing. The function saves the combined Gantt chart to the output file.

# Throws
`ArgumentError` if the output file format is not PNG.

# Example
```julia
generate_gantt_for_dir("path/to/directory", output_file="combined_gantt.png")
```
"""
function generate_gantt_for_dir(directory::String; output_file::String="gantt.png")
  diagram_format = splitext(output_file)[2][2:end]
  diagram_format == "png" || throw(ArgumentError("Only png format is supported"))
  md_files = filter(f -> endswith(f, ".md"), readdir(directory))
  temp_dir = mktempdir()

  try
    images = []
    for md_file in md_files
      title, tasks = parse_markdown(joinpath(directory, md_file))
      plantuml = generate_plantuml(title, tasks)
      temp_file = joinpath(temp_dir, md_file * ".png")
      diagram = Kroki.Diagram(:PlantUML, plantuml)
      rendered = render(diagram, "png")
      write(temp_file, rendered)
      push!(images, load(temp_file))
    end

    combined_image = vcat(images...)
    save(output_file, combined_image)
  finally
    rm(temp_dir, force=true, recursive=true)
  end
end

end # module TaskTracker
