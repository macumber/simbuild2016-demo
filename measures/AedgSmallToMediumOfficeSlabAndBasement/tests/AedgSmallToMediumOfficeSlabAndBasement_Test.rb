require 'openstudio'

require 'openstudio/ruleset/ShowRunnerOutput'

require "#{File.dirname(__FILE__)}/../measure.rb"

require 'minitest/autorun'

class AedgSmallToMediumOfficeSlabAndBasement_Test < MiniTest::Test

  def test_AedgSmallToMediumOfficeSlabAndBasement_withBasementModel

    # create an instance of the measure
    measure = AedgSmallToMediumOfficeSlabAndBasement.new

    # create an instance of a runner
    runner = OpenStudio::Ruleset::OSRunner.new
    runner.setLastEpwFilePath(OpenStudio::Path.new("#{File.dirname(__FILE__)}/USA_IL_Chicago-OHare.Intl.AP.725300_TMY3.epw"))

    # load the test model
    translator = OpenStudio::OSVersion::VersionTranslator.new
    path = OpenStudio::Path.new(File.dirname(__FILE__) + "/CorePerim_Basement.osm")
    model = translator.loadModel(path)
    assert((not model.empty?))
    model = model.get

    # forward translate OpenStudio Model to EnergyPlus Workspace
    ft = OpenStudio::EnergyPlus::ForwardTranslator.new
    workspace = ft.translateModel(model)

    # get arguments and test that they are what we are expecting
    arguments = measure.arguments(workspace)
    #assert_equal(0, arguments.size)

    # set argument values to good values and run the measure on the workspace
    argument_map = OpenStudio::Ruleset::OSArgumentMap.new

    count = -1

    target = arguments[count += 1].clone
    assert(target.setValue("ASHRAE 90.1 2004"))
    argument_map["target"] = target

    slabOrBasement = arguments[count += 1].clone
    assert(slabOrBasement.setValue("Basement (choose this if you have below grade walls)"))
    argument_map["slabOrBasement"] = slabOrBasement

    heatedSlab = arguments[count += 1].clone
    assert(heatedSlab.setValue(false))
    argument_map["heatedSlab"] = heatedSlab

    climateZone = arguments[count += 1].clone
    assert(climateZone.setValue("8"))
    argument_map["climateZone"] = climateZone

    apRatio = arguments[count += 1].clone
    assert(apRatio.setValue(32.5))
    argument_map["apRatio"] = apRatio

    costTotalSlabBasementInsulation = arguments[count += 1].clone
    assert(costTotalSlabBasementInsulation.setValue(0.0))
    argument_map["costTotalSlabBasementInsulation"] = costTotalSlabBasementInsulation

    measure.run(workspace, runner, argument_map)
    result = runner.result
    show_output(result)
    assert(result.value.valueName == "Success")
    #assert(result.warnings.size == 0)
    #assert(result.info.size == 0)

    # save the model in an output directory
    output_dir = File.expand_path('output', File.dirname(__FILE__))
    FileUtils.mkdir output_dir unless Dir.exist? output_dir
    workspace.save("#{output_dir}/test_1.idf", true)
  end

  def test_AedgSmallToMediumOfficeSlabAndBasement_withSlabModel

    # create an instance of the measure
    measure = AedgSmallToMediumOfficeSlabAndBasement.new

    # create an instance of a runner
    runner = OpenStudio::Ruleset::OSRunner.new
    runner.setLastEpwFilePath(OpenStudio::Path.new("#{File.dirname(__FILE__)}/USA_IL_Chicago-OHare.Intl.AP.725300_TMY3.epw"))

    # load the test model
    translator = OpenStudio::OSVersion::VersionTranslator.new
    path = OpenStudio::Path.new(File.dirname(__FILE__) + "/CorePerim_NoBasement.osm")
    model = translator.loadModel(path)
    assert((not model.empty?))
    model = model.get

    # forward translate OpenStudio Model to EnergyPlus Workspace
    ft = OpenStudio::EnergyPlus::ForwardTranslator.new
    workspace = ft.translateModel(model)

    # get arguments and test that they are what we are expecting
    arguments = measure.arguments(workspace)
    #assert_equal(0, arguments.size)

    # set argument values to good values and run the measure on the workspace
    argument_map = OpenStudio::Ruleset::OSArgumentMap.new

    count = -1

    target = arguments[count += 1].clone
    assert(target.setValue("AEDG Small To Medium Office - Target"))
    argument_map["target"] = target

    slabOrBasement = arguments[count += 1].clone
    assert(slabOrBasement.setValue("Slab"))
    argument_map["slabOrBasement"] = slabOrBasement

    heatedSlab = arguments[count += 1].clone
    assert(heatedSlab.setValue(true))
    argument_map["heatedSlab"] = heatedSlab

    climateZone = arguments[count += 1].clone
    assert(climateZone.setValue("8"))
    argument_map["climateZone"] = climateZone

    apRatio = arguments[count += 1].clone
    assert(apRatio.setValue(32.5))
    argument_map["apRatio"] = apRatio

    costTotalSlabBasementInsulation = arguments[count += 1].clone
    assert(costTotalSlabBasementInsulation.setValue(0.0))
    argument_map["costTotalSlabBasementInsulation"] = costTotalSlabBasementInsulation

    measure.run(workspace, runner, argument_map)
    result = runner.result
    show_output(result)
    assert(result.value.valueName == "Success")
    #assert(result.warnings.size == 0)
    #assert(result.info.size == 0)

    # save the model in an output directory
    output_dir = File.expand_path('output', File.dirname(__FILE__))
    FileUtils.mkdir output_dir unless Dir.exist? output_dir
    workspace.save("#{output_dir}/test_2.idf", true)

  end

end