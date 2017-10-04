package ise2import;

import org.apache.commons.cli.Options;
import org.apache.commons.cli.BasicParser;
import org.apache.commons.cli.CommandLine;
import org.apache.commons.cli.ParseException;
import org.apache.commons.cli.HelpFormatter;
import java.io.IOException;
import java.io.File;
import java.io.FileOutputStream;
import java.io.PrintStream;
import ca.nines.ise.log.Log;
import ca.nines.ise.schema.Schema;
import ca.nines.ise.dom.DOM;
import ca.nines.ise.dom.DOMBuilder;
import ca.nines.ise.dom.DOM.DOMStatus;
import ca.nines.ise.validator.DOMValidator;
import ca.nines.ise.validator.DescendantCountValidator;
import ca.nines.ise.validator.ForeignValidator;
import ca.nines.ise.validator.HungWordValidator;
import ca.nines.ise.validator.NestingValidator;
import ca.nines.ise.validator.SectionCoverageValidator;
import ca.nines.ise.validator.SpanLineValidator;
import ca.nines.ise.validator.SplitLineValidator;
import ca.nines.ise.validator.TagBalanceValidator;
import ca.nines.ise.validator.UniqueIdValidator;
import ca.nines.ise.validator.semantic.OrnamentValidator;
import ca.nines.ise.validator.semantic.RuleValidator;
import ca.nines.ise.transformer.DeprecatedTransformer;
import ca.nines.ise.writer.ExpandedSGMLWriter;

public class ValidateAndExpand {
	private static final Log log = Log.getInstance();

	public static void main(String[] args) {
		// parse options / filenames
		Options opts = new Options();
		opts.addOption("o", "output-dir", true, "Output directory");
		BasicParser parser = new BasicParser();
		CommandLine cmd;
		try {
			cmd = parser.parse(opts, args);
			File outputDir;
			if (cmd.hasOption("o")) {
				outputDir = new File(cmd.getOptionValue("o")).getAbsoluteFile();
			} else {
				outputDir = new File("out").getAbsoluteFile();
			}
			System.out.println("Running isetools on input IML");
			if (!run(outputDir, cmd.getArgs())) {
				System.err.println("One or more input files are invalid IML; check the output folder for error logs.");
				System.exit(1);
			}
		}
		catch (ParseException e) {
			System.err.println("Invalid or missing arguments.");
			new HelpFormatter().printHelp(
				"java ValidateAndExpand [options] <file> [<file>...]",
				opts
			);
			System.exit(2);
		}
		catch (IOException e) {
			System.err.println("IO Error: "+e.getMessage());
			System.exit(3);
		}
		catch (Exception e) {
			System.err.println("XML error: "+e.getMessage());
			System.exit(4);
		}
	}

	private static boolean run(File outputDir, String[] inputs) throws Exception {
		boolean goodIml = true; // keep track of whether any bad IML was encountered
		outputDir.mkdirs();
		Log log = Log.getInstance();
		Schema sch = Schema.defaultSchema();
		// process each file in turn (can't parallelize, since Log is shared)
		for (String file : inputs) {
			File imlFile = new File(file);
			File outFile = new File(outputDir, imlFile.getName());
			File logFile = new File(
				outputDir,
				imlFile.getName().replaceAll("\\.txt$", "-errors.log")
			);
			// if the output already exists and is newer, don't regenerate!
			if (outFile.lastModified() >= imlFile.lastModified()) {
				System.out.println(".. skipping "+imlFile.getName()+" (up to date)");
				continue;
			}
			// otherwise...
			System.out.println(".. processing "+imlFile.getName());
			DOM dom = new DOMBuilder(imlFile).build();
			if (dom.getStatus() == DOMStatus.ERROR) {
				goodIml = false;
				printLog(logFile);
			} else {
				// validate
				try {
                	(new DOMValidator()).validate(dom, sch);
	                (new DescendantCountValidator()).validate(dom);
	                (new ForeignValidator()).validate(dom);
	                (new HungWordValidator()).validate(dom);
	                (new NestingValidator(sch)).validate(dom);
	                (new SectionCoverageValidator()).validate(dom);
	                (new SpanLineValidator(sch)).validate(dom);
	                (new SplitLineValidator()).validate(dom);
	                (new TagBalanceValidator(sch)).validate(dom);
	                (new UniqueIdValidator()).validate(dom);
					(new OrnamentValidator()).validateDOM(dom);
					(new RuleValidator()).validateDOM(dom);
                } catch (Exception e) {
                	// absorbed by the log
                }
				if (log.count() > 1) {
					// FIXME: probably don't care about many warnings
					goodIml = false;
					printLog(logFile);
				} else {
					dom = (new DeprecatedTransformer()).transform(dom);
					PrintStream out = new PrintStream(
						new FileOutputStream(outFile),
						true,
						"UTF-8"
					);
					out.print("<root><![CDATA[");
					ExpandedSGMLWriter writer = new ExpandedSGMLWriter(out);
					writer.render(dom);
					out.println("]]></root>");
				}
			}
		}
		return goodIml;
	}

	private static void printLog(File to) throws IOException {
		PrintStream out = new PrintStream(
			new FileOutputStream(to),
			true,
			"UTF-8"
		);
		out.println(log);
		log.clear();
	}
}
