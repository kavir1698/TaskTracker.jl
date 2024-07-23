# TaskTracker

TaskTracker.jl is a Julia package that helps you track and visualize your tasks from a todo file. It parses a markdown file, calculates the completion percentage of each task, and generates a Gantt chart using PlantUML.

## Features

- Parse markdown files to extract tasks and subtasks
- Calculate completion percentage of each task
- Generate Gantt charts using PlantUML
- Support for custom project start date
- Support for multiple todo files in a directory
- Export Gantt charts in various formats (pdf, png, svg, xml, plain)

## Usage

### Installation

Install the package by typing `]add https://github.com/kavir1698/TaskTracker.jl` in Julia.

### Creating a Todo file

Create a todo file in markdown format (e.g., `todo.md`) with the following syntax:

- Tasks start with `- [ ] ` or `- [x] ` for incomplete or complete tasks, respectively.
- Tasks can have subtasks through indentation.
- Tasks can have a start date and duration in days specified in the format `Task name | yyyy-mm-dd | duration`.
- Alternatively, tasks can start after another task has been completed using the format `Task name | after Task2 | duration`.
- You can specify a custom project start date at the top of the file using the format `#project start date: yyyy-mm-dd`.

### Generating a Gantt chart

- Run `julia -e 'using TaskTracker; generate_gantt("todo.md"; output_file="gantt.svg")'` in the terminal, replacing `todo.md` with your todo file name if necessary.
- A Gantt chart will be generated as `gantt.svg` in the same directory.

### Generating a Combined Gantt Chart

- If you have multiple todo files in a directory, you can generate a combined Gantt chart for all of them by running `julia -e 'using TaskTracker; generate_gantt_for_dir("path/to/directory"; output_file="combined_gantt.png")'` in the terminal, replacing `path/to/directory` with your directory path if necessary.
- The combined Gantt chart will be generated as `combined_gantt.png` in the same directory.


## Example Todo File

See `example/todo.md` for an example todo file.

## Export Formats

You can export Gantt charts in the following formats:

- `pdf`
- `png`
- `svg`
- `xml`
- `plain` (for text)

Note: Combined charts can only be exported in `png` format.
