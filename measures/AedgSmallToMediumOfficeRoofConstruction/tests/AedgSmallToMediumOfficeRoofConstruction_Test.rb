require 'openstudio'

require 'openstudio/ruleset/ShowRunnerOutput'

require "#{File.dirname(__FILE__)}/../measure.rb"

require 'minitest/autorun'

class AedgSmallToMediumOfficeRoofConstruction_Test < MiniTest::Test

  
  def test_AedgSmallToMediumOfficeRoofConstruction
     
    # create an instance of the measure
    measure = AedgSmallToMediumOfficeRoofConstruction.new
    
    # create an instance of a runner
    runner = OpenStudio::Ruleset::OSRunner.new
    
    # load the test model
    translator = OpenStudio::OSVersion::VersionTranslator.new
    path = OpenStudio::Path.new(File.dirname(__FILE__) + "/0206_SimpleSchool_b_123_dev.osm")
    model = translator.loadModel(path)
    assert((not model.empty?))
    model = model.get
    
    # get arguments and test that they are what we are expecting
    arguments = measure.arguments(model)
    assert_equal(2, arguments.size)
    assert_equal("material_cost_insulation_increase_ip", arguments[0].name)
    assert_equal("material_cost_sri_increase_ip", arguments[1].name)

    # set argument values to good values and run the measure on model with spaces
    argument_map = OpenStudio::Ruleset::OSArgumentMap.new
    material_cost_insulation_increase_ip = arguments[0].clone
    assert(material_cost_insulation_increase_ip.setValue(5.0))
    argument_map["material_cost_insulation_increase_ip"] = material_cost_insulation_increase_ip
    material_cost_sri_increase_ip = arguments[1].clone
    assert(material_cost_sri_increase_ip.setValue(1.0))
    argument_map["material_cost_sri_increase_ip"] = material_cost_sri_increase_ip
    measure.run(model, runner, argument_map)
    result = runner.result
    show_output(result)
    #assert(result.value.valueName == "Success")
    #assert(result.warnings.size == 0)
    #assert(result.info.size == 0)
    
  end  

end
