function set_project {
	# Check if the project is set.
	if [ -z "$PROJECT_PATH" ]; then
		echo "\$PROJECT_PATH isn't set. Leaving.";
		return;
	fi
	# Check if the project is set.
	if [ -z "$PROJECT_NAME" ]; then
		echo "\$PROJECT_NAME isn't set. Leaving.";
		return;
	fi
  #                      bold green       reset     bold white
	PS1="($PROJECT_NAME) \[\e[1;32m\]\u@\h\[\e[0m\]:\[\e[1;34m\]\w\[\e[0m\]\$ "
	cd $PROJECT_PATH;
}
function project_name {
	PROJECT_PATH="/home/$USER/projects/project_name"
	PROJECT_NAME="project_name"
	set_project;
}
