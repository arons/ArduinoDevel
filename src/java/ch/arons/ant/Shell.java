package ch.arons.ant;

import java.io.BufferedReader;

public class Shell {

	/**
	 * 
	 * @param shellCommang command to execute
	 */
	public static void execute(String shellCommang) {
		if (shellCommang == null)
			throw new RuntimeException("no shell command");

		//shellcommand = shellcommand.replace("\\","/") ;
		System.out.println(shellCommang);

		BufferedReader input = null;
		BufferedReader error = null;
		try {
			Runtime rt = Runtime.getRuntime();

			Process pr = rt.exec(shellCommang);

			// any error message?
			StreamGobbler errorGobbler = new StreamGobbler( pr.getErrorStream(), "ERROR");

			// any output?
			StreamGobbler outputGobbler = new StreamGobbler( pr.getInputStream(), "OUTPUT");

			// kick them off
			errorGobbler.start();
			outputGobbler.start();

			int exitVal = pr.waitFor();
			if (exitVal != 0) {
				throw new RuntimeException("Exited with error code " + exitVal);
			}

		} catch (Exception e) {
			System.err.println(e.toString());
			throw new RuntimeException(e.getMessage(), e);
		} finally {
			if (input != null)
				try { input.close(); } catch (Exception e) { }
			if (error != null)
				try { error.close(); } catch (Exception e) { }
		}
	}

}
