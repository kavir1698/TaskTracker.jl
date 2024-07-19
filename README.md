TaskTracker
===========

TaskTracker.jl is a Julia package that helps you track and visualize your tasks from a todo file. It parses a markdown file, calculates the completion percentage of each task, and generates a Gantt chart using PlantUML.

Usage
-----

To use TaskTracker, follow these steps:

1. Install the package.
2. Create a todo file in markdown format (e.g., `todo.md`) with the following syntax:
   - Tasks start with `- [ ]` or `- [x]` for incomplete or complete tasks, respectively.
   - Tasks can have subtasks indented with two spaces.
   - Tasks can have a start date and duration in days specified in the format `Task name | yyyy-mm-dd | duration`.
3. Run `julia -e 'using TaskTracker; TaskTracker.generate_gantt("todo.md"; output_file="gannt.png")'` in the terminal, replacing `todo.md` with your todo file name if necessary.
4. A Gantt chart will be generated as `gantt.png` in the same directory.

Example Todo File
----------------

See `src/todo.md` for an example todo file.
