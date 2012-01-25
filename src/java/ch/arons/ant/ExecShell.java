package ch.arons.ant;

import org.apache.tools.ant.BuildException;
import org.apache.tools.ant.Task;
/**
 * Ant extension task 
 *
 */
public class ExecShell extends Task {
	
	private String shellcommand;
	
	public void setShellcommand(String shellcommand) {
		this.shellcommand = shellcommand;
	}
	public String getShellcommand() {
		return shellcommand;
	}
	
	// The method executing the task
	public void execute() throws BuildException {
		if (shellcommand == null) throw new BuildException("no shell command");
		Shell.execute(shellcommand);
	}
}
