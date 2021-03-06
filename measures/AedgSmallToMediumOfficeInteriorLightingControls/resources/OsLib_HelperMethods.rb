module OsLib_HelperMethods

  # populate choice argument from model objects
  def OsLib_HelperMethods.populateChoiceArgFromModelObjects(model,modelObject_args_hash, includeBuilding = nil)

    # populate choice argument for constructions that are applied to surfaces in the model
    modelObject_handles = OpenStudio::StringVector.new
    modelObject_display_names = OpenStudio::StringVector.new

    # looping through sorted hash of constructions
    modelObject_args_hash.sort.map do |key,value|
      modelObject_handles << value.handle.to_s
      modelObject_display_names << key
    end

    if not includeBuilding == nil
      #add building to string vector with space type
      building = model.getBuilding
      modelObject_handles << building.handle.to_s
      modelObject_display_names << includeBuilding
    end

    result = {"modelObject_handles" => modelObject_handles, "modelObject_display_names" => modelObject_display_names}
    return result

  end #end of OsLib_HelperMethods.populateChoiceArgFromModelObjects

  # check choice argument made from model objects
  def OsLib_HelperMethods.checkChoiceArgFromModelObjects(object, variableName,to_ObjectType, runner)

    apply_to_building = false
    modelObject = nil
    if object.empty?
      handle = runner.getStringArgumentValue(variableName,user_arguments)
      if handle.empty?
        runner.registerError("No #{variableName} was chosen.")
      else
        runner.registerError("The selected #{variableName} with handle '#{handle}' was not found in the model. It may have been removed by another measure.")
      end
      return false
    else
      if not eval("object.get.#{to_ObjectType}").empty?
        modelObject = eval("object.get.#{to_ObjectType}").get
      elsif not object.get.to_Building.empty?
        apply_to_building = true
      else
        runner.registerError("Script Error - argument not showing up as #{variableName}.")
        return false
      end
    end  #end of if construction.empty?

    result = {"modelObject" => modelObject, "apply_to_building" => apply_to_building}

  end #end of OsLib_HelperMethods.checkChoiceArgFromModelObjects

  # check value of double arguments
  def OsLib_HelperMethods.checkDoubleArguments(runner, min, max, argumentHash)

    #error flag
    error = false

    argumentHash.each do |display, argument|
      if not min == nil
        if argument < min
          runner.registerError("Please enter value between #{min} and #{max} for #{display}.") # add in argument display name
          error = true
        end
      end
      if not max == nil
        if argument > max
          runner.registerError("Please enter value between #{min} and #{max} for #{display}.") # add in argument display name
          error = true
        end
      end
    end # end of argumentArray.each do

    # check for any errors
    if error
      return false
    else
      return true
    end

  end #end of OsLib_HelperMethods.checkDoubleArguments

  # populate choice argument from model objects. areaType should be string like "floorArea" or "exteriorArea"
  def OsLib_HelperMethods.getAreaOfSpacesInArray(model,spaceArray,areaType = "floorArea")

    # find selected floor spaces, make array and get floor area.
    totalArea = 0
    spaceAreaHash = {}
    spaceArray.each do |space|
      spaceArea = eval("space.#{areaType}*space.multiplier")
      spaceAreaHash[space] = spaceArea
      totalArea += spaceArea
    end

    result = {"totalArea" => totalArea,"spaceAreaHash" => spaceAreaHash}
    return result

  end #end of getAreaOfSpacesInArray

  # runs conversion and neat string, and returns value with units in string, optionally before or after the value
  def OsLib_HelperMethods.neatConvertWithUnitDisplay(double,fromString,toString,digits,unitBefore = false,unitAfter = true, space = true, parentheses = true)

    # convert units
    doubleConverted = OpenStudio::convert(double,fromString,toString)
    if not doubleConverted.nil?
      doubleConverted = doubleConverted.get
    else
      puts "Couldn't convert values, check string choices passed in. From: #{fromString}, To: #{toString}"
    end

    # get neat version of converted
    neatConverted = OpenStudio::toNeatString(doubleConverted,digits,true)

    # add prefix
    if unitBefore
      if space == true and parentheses == true
        prefix = "(#{toString}) "
      elsif space == true and parentheses == false
        prefix = "(#{toString})"
      elsif space == false and parentheses == true
        prefix = "#{toString} "
      else
        prefix = "#{toString}"
      end
    else
      prefix = ""
    end

    # add suffix
    if unitAfter
      if space == true and parentheses == true
        suffix = " (#{toString})"
      elsif space == true and parentheses == false
        suffix = "(#{toString})"
      elsif space == false and parentheses == true
        suffix = " #{toString}"
      else
        suffix = "#{toString}"
      end
    else
      suffix = ""
    end

    finalString = "#{prefix}#{neatConverted}#{suffix}"

    result = finalString
    return result

  end #end of getAreaOfSpacesInArray

  #helper that loops through lifecycle costs getting total costs under "Construction" and add to counter if occurs during year 0
  def OsLib_HelperMethods.getTotalCostForObjects(objectArray, category = "Construction", onlyYearFromStartZero = true)
    counter = 0
    objectArray.each do |object|
      object_LCCs = object.lifeCycleCosts
      object_LCCs.each do |object_LCC|
        if object_LCC.category == category
          if onlyYearFromStartZero == false or object_LCC.yearsFromStart == 0
            counter += object_LCC.totalCost
          end
        end
      end
    end

    return counter
    return result

  end #end of def get_total_costs_for_objects(objects)


  #helper that loops through lifecycle costs getting total costs under "Construction" and add to counter if occurs during year 0
  def OsLib_HelperMethods.getSpaceTypeStandardsInformation(spaceTypeArray)

    # hash of space types
    spaceTypeStandardsInfoHash = {}

    spaceTypeArray.each do |spaceType|
      # get standards building
      if not spaceType.standardsBuildingType.empty?
        standardsBuilding = spaceType.standardsBuildingType.get
      else
        standardsBuilding = nil
      end

      # get standards space type
      if not spaceType.standardsSpaceType.empty?
        standardsSpaceType = spaceType.standardsSpaceType.get
      else
        standardsSpaceType = nil
      end

      # populate hash
      spaceTypeStandardsInfoHash[spaceType] = [standardsBuilding,standardsSpaceType]

    end # end of spaceTypeArray each do

    return spaceTypeStandardsInfoHash
    return result

  end #end of def get_total_costs_for_objects(objects)


  # OpenStudio has built in toNeatString method
  # OpenStudio::toNeatString(double,2,true)# double,decimals, show commas

  # OpenStudio has built in helper for unit conversion. That can be done using OpenStudio::convert() as shown below.
  # OpenStudio::convert(double,"from unit string","to unit string").get

end