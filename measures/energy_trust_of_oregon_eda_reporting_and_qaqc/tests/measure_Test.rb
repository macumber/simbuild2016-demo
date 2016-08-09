require 'openstudio'

require 'openstudio/ruleset/ShowRunnerOutput'

require "#{File.dirname(__FILE__)}/../measure.rb"

require 'fileutils'

require 'minitest/autorun'

class EnergyTrustOfOregonEDAReportingAndQAQC_Test < MiniTest::Unit::TestCase

  # class level variable
  @@co = OpenStudio::Runmanager::ConfigOptions.new(true)

# commented this out so I can pass in unique models and weather files to different tests
=begin
  def model_in_path
    "#{File.dirname(__FILE__)}/BasicOfficeTest_Salem.osm"
  end

  def epw_path
    # make sure we have a weather data location
    epw = OpenStudio::Path.new(File.dirname(__FILE__)) / OpenStudio::Path.new('USA_TX_Austin-Mueller.Muni.AP.722540_TMY3.epw')
    assert(File.exist?(epw.to_s))

    epw.to_s
  end
=end

  def run_dir(test_name)
    # always generate test output in specially named 'output' directory so result files are not made part of the measure
    "#{File.dirname(__FILE__)}/output/#{test_name}"
  end

  def model_out_path(test_name)
    "#{run_dir(test_name)}/TestOutupt.osm"
  end

  def workspace_path(test_name)
    "#{run_dir(test_name)}/ModelToIdf/in.idf"
  end

  def sql_path(test_name)
    "#{run_dir(test_name)}/ModelToIdf/EnergyPlusPreProcess-0/EnergyPlus-0/eplusout.sql"
  end

  def report_path(test_name)
    "#{run_dir(test_name)}/report.xml"
  end

  # create test files if they do not exist when the test first runs
  def setup_test(test_name, idf_output_requests, model_in_path, epw_path)
    @@co.findTools(false, true, false, true)

    unless File.exist?(run_dir(test_name))
      FileUtils.mkdir_p(run_dir(test_name))
    end
    assert(File.exist?(run_dir(test_name)))

    if File.exist?(report_path(test_name))
      FileUtils.rm(report_path(test_name))
    end

    assert(File.exist?(model_in_path))

    if File.exist?(model_out_path(test_name))
      FileUtils.rm(model_out_path(test_name))
    end

    # convert output requests to OSM for testing, OS App and PAT will add these to the E+ Idf
    workspace = OpenStudio::Workspace.new('Draft'.to_StrictnessLevel, 'EnergyPlus'.to_IddFileType)
    workspace.addObjects(idf_output_requests)
    rt = OpenStudio::EnergyPlus::ReverseTranslator.new
    request_model = rt.translateWorkspace(workspace)

    translator = OpenStudio::OSVersion::VersionTranslator.new
    model = translator.loadModel(model_in_path)
    assert((not model.empty?))
    model = model.get
    model.addObjects(request_model.objects)
    model.save(model_out_path(test_name), true)

    unless File.exist?(sql_path(test_name))
      puts 'Running EnergyPlus'

      wf = OpenStudio::Runmanager::Workflow.new('modeltoidf->energypluspreprocess->energyplus')
      wf.add(@@co.getTools)
      job = wf.create(OpenStudio::Path.new(run_dir(test_name)), OpenStudio::Path.new(model_out_path(test_name)), OpenStudio::Path.new(epw_path))

      rm = OpenStudio::Runmanager::RunManager.new
      rm.enqueue(job, true)
      rm.waitForFinished
    end
  end

  # test pass
  def test_EnergyTrustOfOregonEDAReportingAndQAQC_pass

    # setup test name, model, and epw
    test_name = 'pass'
    model_in_path = "#{File.dirname(__FILE__)}/BasicOfficeTest_Salem.osm"
    epw = OpenStudio::Path.new(File.dirname(__FILE__)) / OpenStudio::Path.new('USA_OR_Salem-McNary.Field.726940_TMY3.epw')

    # create an instance of the measure
    measure = EnergyTrustOfOregonEDAReportingAndQAQC.new

    # create an instance of a runner
    runner = OpenStudio::Ruleset::OSRunner.new
    runner.setLastOpenStudioModelPath(OpenStudio::Path.new(model_in_path))

    # get arguments
    arguments = measure.arguments
    argument_map = OpenStudio::Ruleset.convertOSArgumentVectorToMap(arguments)

    # create hash of argument values
    args_hash = {}

    # get the energyplus output requests, this will be done automatically by OS App and PAT
    idf_output_requests = measure.energyPlusOutputRequests(runner, argument_map)
    assert(idf_output_requests.size > 0)

    # mimic the process of running this measure in OS App or PAT
    setup_test(test_name, idf_output_requests, model_in_path, epw)

    assert(File.exist?(model_out_path(test_name)))
    assert(File.exist?(sql_path(test_name)))
    assert(File.exist?(epw.to_s))

    # set up runner, this will happen automatically when measure is run in PAT or OpenStudio
    runner.setLastOpenStudioModelPath(OpenStudio::Path.new(model_out_path(test_name)))
    runner.setLastEnergyPlusWorkspacePath(OpenStudio::Path.new(workspace_path(test_name)))
    runner.setLastEpwFilePath(epw.to_s)
    runner.setLastEnergyPlusSqlFilePath(OpenStudio::Path.new(sql_path(test_name)))

    # delete the output if it exists
    if File.exist?(report_path(test_name))
      FileUtils.rm(report_path(test_name))
    end
    assert(!File.exist?(report_path(test_name)))

    # temporarily change directory to the run directory and run the measure
    start_dir = Dir.pwd
    begin
      Dir.chdir(run_dir(test_name))

      # run the measure
      measure.run(runner, argument_map)
      result = runner.result
      show_output(result)
      assert_equal('Success', result.value.valueName)
    ensure
      Dir.chdir(start_dir)
    end

    # make sure the report file exists
    assert(File.exist?(report_path(test_name)))

  end

  # test fail_a
  def test_EnergyTrustOfOregonEDAReportingAndQAQC_fail_a

    # setup test name, model, and epw
    test_name = 'fail_a'
    model_in_path = "#{File.dirname(__FILE__)}/BasicOfficeTest_Portland.osm"
    epw = OpenStudio::Path.new(File.dirname(__FILE__)) / OpenStudio::Path.new('USA_OR_Portland.Intl.AP.726980_TMY3.epw')

    # create an instance of the measure
    measure = EnergyTrustOfOregonEDAReportingAndQAQC.new

    # create an instance of a runner
    runner = OpenStudio::Ruleset::OSRunner.new
    runner.setLastOpenStudioModelPath(OpenStudio::Path.new(model_in_path))

    # get arguments
    arguments = measure.arguments
    argument_map = OpenStudio::Ruleset.convertOSArgumentVectorToMap(arguments)

    # create hash of argument values
    args_hash = {}

    # get the energyplus output requests, this will be done automatically by OS App and PAT
    idf_output_requests = measure.energyPlusOutputRequests(runner, argument_map)
    assert(idf_output_requests.size > 0)

    # mimic the process of running this measure in OS App or PAT
    setup_test(test_name, idf_output_requests, model_in_path, epw)

    assert(File.exist?(model_out_path(test_name)))
    assert(File.exist?(sql_path(test_name)))
    assert(File.exist?(epw.to_s))

    # set up runner, this will happen automatically when measure is run in PAT or OpenStudio
    runner.setLastOpenStudioModelPath(OpenStudio::Path.new(model_out_path(test_name)))
    runner.setLastEnergyPlusWorkspacePath(OpenStudio::Path.new(workspace_path(test_name)))
    runner.setLastEpwFilePath(epw.to_s)
    runner.setLastEnergyPlusSqlFilePath(OpenStudio::Path.new(sql_path(test_name)))

    # delete the output if it exists
    if File.exist?(report_path(test_name))
      FileUtils.rm(report_path(test_name))
    end
    assert(!File.exist?(report_path(test_name)))

    # temporarily change directory to the run directory and run the measure
    start_dir = Dir.pwd
    begin
      Dir.chdir(run_dir(test_name))

      # run the measure
      measure.run(runner, argument_map)
      result = runner.result
      show_output(result)
      assert_equal('Success', result.value.valueName)
    ensure
      Dir.chdir(start_dir)
    end

    # make sure the report file exists
    assert(File.exist?(report_path(test_name)))

  end
# test fail_b
  def test_EnergyTrustOfOregonEDAReportingAndQAQC_fail_b

    # setup test name, model, and epw
    test_name = 'fail_b'
    model_in_path = "#{File.dirname(__FILE__)}/BasicOfficeTest.osm"
    epw = OpenStudio::Path.new(File.dirname(__FILE__)) / OpenStudio::Path.new('USA_CO_Golden-NREL.724666_TMY3.epw')

    # create an instance of the measure
    measure = EnergyTrustOfOregonEDAReportingAndQAQC.new

    # create an instance of a runner
    runner = OpenStudio::Ruleset::OSRunner.new
    runner.setLastOpenStudioModelPath(OpenStudio::Path.new(model_in_path))

    # get arguments
    arguments = measure.arguments
    argument_map = OpenStudio::Ruleset.convertOSArgumentVectorToMap(arguments)

    # create hash of argument values
    args_hash = {}

    # get the energyplus output requests, this will be done automatically by OS App and PAT
    idf_output_requests = measure.energyPlusOutputRequests(runner, argument_map)
    assert(idf_output_requests.size == 0) # no airTerminalSingleDuctVAVReheats

    # mimic the process of running this measure in OS App or PAT
    setup_test(test_name, idf_output_requests, model_in_path, epw)

    assert(File.exist?(model_out_path(test_name)))
    assert(File.exist?(sql_path(test_name)))
    assert(File.exist?(epw.to_s))

    # set up runner, this will happen automatically when measure is run in PAT or OpenStudio
    runner.setLastOpenStudioModelPath(OpenStudio::Path.new(model_out_path(test_name)))
    runner.setLastEnergyPlusWorkspacePath(OpenStudio::Path.new(workspace_path(test_name)))
    runner.setLastEpwFilePath(epw.to_s)
    runner.setLastEnergyPlusSqlFilePath(OpenStudio::Path.new(sql_path(test_name)))

    # delete the output if it exists
    if File.exist?(report_path(test_name))
      FileUtils.rm(report_path(test_name))
    end
    assert(!File.exist?(report_path(test_name)))

    # temporarily change directory to the run directory and run the measure
    start_dir = Dir.pwd
    begin
      Dir.chdir(run_dir(test_name))

      # run the measure
      measure.run(runner, argument_map)
      result = runner.result
      show_output(result)
      assert_equal('Success', result.value.valueName)
    ensure
      Dir.chdir(start_dir)
    end

    # make sure the report file exists
    assert(File.exist?(report_path(test_name)))

  end

# test hvac_a
  def test_EnergyTrustOfOregonEDAReportingAndQAQC_hvac_a

    # setup test name, model, and epw
    test_name = 'hvac_a'
    model_in_path = "#{File.dirname(__FILE__)}/School_Hvac_a.osm"
    epw = OpenStudio::Path.new(File.dirname(__FILE__)) / OpenStudio::Path.new('USA_OR_Portland.Intl.AP.726980_TMY3.epw')

    # create an instance of the measure
    measure = EnergyTrustOfOregonEDAReportingAndQAQC.new

    # create an instance of a runner
    runner = OpenStudio::Ruleset::OSRunner.new
    runner.setLastOpenStudioModelPath(OpenStudio::Path.new(model_in_path))

    # get arguments
    arguments = measure.arguments
    argument_map = OpenStudio::Ruleset.convertOSArgumentVectorToMap(arguments)

    # create hash of argument values
    args_hash = {}

    # get the energyplus output requests, this will be done automatically by OS App and PAT
    idf_output_requests = measure.energyPlusOutputRequests(runner, argument_map)
    #assert(idf_output_requests.size > 0)

    # mimic the process of running this measure in OS App or PAT
    setup_test(test_name, idf_output_requests, model_in_path, epw)

    assert(File.exist?(model_out_path(test_name)))
    assert(File.exist?(sql_path(test_name)))
    assert(File.exist?(epw.to_s))

    # set up runner, this will happen automatically when measure is run in PAT or OpenStudio
    runner.setLastOpenStudioModelPath(OpenStudio::Path.new(model_out_path(test_name)))
    runner.setLastEnergyPlusWorkspacePath(OpenStudio::Path.new(workspace_path(test_name)))
    runner.setLastEpwFilePath(epw.to_s)
    runner.setLastEnergyPlusSqlFilePath(OpenStudio::Path.new(sql_path(test_name)))

    # delete the output if it exists
    if File.exist?(report_path(test_name))
      FileUtils.rm(report_path(test_name))
    end
    assert(!File.exist?(report_path(test_name)))

    # temporarily change directory to the run directory and run the measure
    start_dir = Dir.pwd
    begin
      Dir.chdir(run_dir(test_name))

      # run the measure
      measure.run(runner, argument_map)
      result = runner.result
      show_output(result)
      assert_equal('Success', result.value.valueName)
    ensure
      Dir.chdir(start_dir)
    end

    # make sure the report file exists
    assert(File.exist?(report_path(test_name)))

  end

# test 0422_sm_off
  def test_EnergyTrustOfOregonEDAReportingAndQAQC_0422_sm_off

    # setup test name, model, and epw
    test_name = '0422_sm_off'
    model_in_path = "#{File.dirname(__FILE__)}/0422_test_b_sm_off.osm"
    epw = OpenStudio::Path.new(File.dirname(__FILE__)) / OpenStudio::Path.new('USA_OR_Salem-McNary.Field.726940_TMY3.epw')

    # create an instance of the measure
    measure = EnergyTrustOfOregonEDAReportingAndQAQC.new

    # create an instance of a runner
    runner = OpenStudio::Ruleset::OSRunner.new
    runner.setLastOpenStudioModelPath(OpenStudio::Path.new(model_in_path))

    # get arguments
    arguments = measure.arguments
    argument_map = OpenStudio::Ruleset.convertOSArgumentVectorToMap(arguments)

    # create hash of argument values
    args_hash = {}

    # get the energyplus output requests, this will be done automatically by OS App and PAT
    idf_output_requests = measure.energyPlusOutputRequests(runner, argument_map)
    #assert(idf_output_requests.size > 0)

    # mimic the process of running this measure in OS App or PAT
    setup_test(test_name, idf_output_requests, model_in_path, epw)

    assert(File.exist?(model_out_path(test_name)))
    assert(File.exist?(sql_path(test_name)))
    assert(File.exist?(epw.to_s))

    # set up runner, this will happen automatically when measure is run in PAT or OpenStudio
    runner.setLastOpenStudioModelPath(OpenStudio::Path.new(model_out_path(test_name)))
    runner.setLastEnergyPlusWorkspacePath(OpenStudio::Path.new(workspace_path(test_name)))
    runner.setLastEpwFilePath(epw.to_s)
    runner.setLastEnergyPlusSqlFilePath(OpenStudio::Path.new(sql_path(test_name)))

    # delete the output if it exists
    if File.exist?(report_path(test_name))
      FileUtils.rm(report_path(test_name))
    end
    assert(!File.exist?(report_path(test_name)))

    # temporarily change directory to the run directory and run the measure
    start_dir = Dir.pwd
    begin
      Dir.chdir(run_dir(test_name))

      # run the measure
      measure.run(runner, argument_map)
      result = runner.result
      show_output(result)
      assert_equal('Success', result.value.valueName)
    ensure
      Dir.chdir(start_dir)
    end

    # make sure the report file exists
    assert(File.exist?(report_path(test_name)))

  end

end
