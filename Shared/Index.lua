BaseClasses = {}
Package.Export("BaseClasses", BaseClasses)

BaseClasses.Initialized = false
BaseClasses.Initializing = false

--- Returns whether the library is currently in the process of initializing.
---@return boolean
function BaseClasses.IsInitializing()
    return BaseClasses.Initializing
end

--- Returns whether the library has finished initializing and is ready to use.
---@return boolean
function BaseClasses.IsInitialized()
    return BaseClasses.Initialized
end

--- Returns the built classes informations table.
---@return table|nil
function BaseClasses.GetClassesInfo()
    if not BaseClasses.IsInitialized() then
        Console.Warn("Tried to use BaseClasses before it was Initialized!")
        return
    end
    return BaseClasses.APIClasses
end

--- Returns a sequential table of the parents of the class named classname.
---@param classname string The class name of a nanos class
---@return table|nil
function BaseClasses.GetClassParentNames(classname)
    if not BaseClasses.IsInitialized() then
        Console.Warn("Tried to use BaseClasses before it was Initialized!")
        return
    end
    if BaseClasses.APIClasses[classname] then
        return BaseClasses.APIClasses[classname].Parents
    end
end

--- Returns a sequential table of the children of the class named classname.
---@param classname string The class name of a nanos class
---@return table|nil
function BaseClasses.GetClassChildrenNames(classname)
    if not BaseClasses.IsInitialized() then
        Console.Warn("Tried to use BaseClasses before it was Initialized!")
        return
    end
    if BaseClasses.APIClasses[classname] then
        return BaseClasses.APIClasses[classname].Children
    end
end

--- Calls a scripting function on all classes that have the class 'classname' as parent, intended to be used with Base* classes.
---@param classname string The class name
---@param func function the function that will receive the class as first argument
---@vararg any The other call arguments
function BaseClasses.CallFunc(classname, func, ...)
    if not BaseClasses.IsInitialized() then
        Console.Warn("Tried to use BaseClasses before it was Initialized!")
        return
    end
    if not BaseClasses.APIClasses[classname] then return Console.Warn("Could not CallFunc to '" .. classname .. "' (not found)") end
    if not BaseClasses.APIClasses[classname].Children then return Console.Warn("Could not CallFunc to '" .. classname .. "' (No Children)") end

    for _, v in ipairs(BaseClasses.APIClasses[classname].Children) do
        if _ENV[v] then
            func(_ENV[v], ...)
        end
    end
end

--- Calls a function on all classes that have the class 'classname' as parent, intended to be used with Base* classes.
---@param classname string The class name
---@param funcname string the function name to call
---@vararg any The call arguments
function BaseClasses.CallFuncName(classname, funcname, ...)
    if not BaseClasses.IsInitialized() then
        Console.Warn("Tried to use BaseClasses before it was Initialized!")
        return
    end
    if not BaseClasses.APIClasses[classname] then return Console.Warn("Could not BaseCall to '" .. classname .. "' (not found)") end
    if not BaseClasses.APIClasses[classname].Children then return Console.Warn("Could not BaseCall to '" .. classname .. "' (No Children)") end

    for _, v in ipairs(BaseClasses.APIClasses[classname].Children) do
        if _ENV[v] then
            if _ENV[v][funcname] then
                _ENV[v][funcname](...)
            end
        end
    end
end

--- Override or set a function on a base class. (Intended for Base* classes)
---@param classname string The class name
---@param name string the function name
---@param func function the function to set
function BaseClasses.Extend(classname, name, func)
    return BaseClasses.CallFunc(classname, function(class)
        class[name] = func
    end)
end


--- Function called when the library is ready.
function BaseClasses.Ready()
    BaseClasses.Initializing = false
    BaseClasses.Initialized = true
    Console.Log("Ready")
    Events.Call("BaseClassesInitialized")
end

--- Function to split strings using a simple separator, supports longer separators.
---@param str string the string to split
---@param sep string|nil the simple separator as string
---@return table
function BaseClasses.SplitString(str, sep)
    local sep, fields = sep or ":", {}
    local sep_len = string.len(sep)
    local c = 0
    local last_i = 1
    for i in string.gmatch(str, "()" .. sep) do
      c = c + 1
      fields[c] = string.sub(str, last_i, i-1)
      last_i = i+sep_len
    end
    fields[c+1] = string.sub(str, last_i)
    return fields
end

--- Function to tell the library to Initialize.
function BaseClasses.Initialize()
    if not APILib.IsInitialized() then
        Events.Subscribe("APILibInitialized", BaseClasses.Initialize)
        APILib.Initialize()
        return
    end
    if BaseClasses.IsInitializing() then return end
    if BaseClasses.IsInitialized() then return end
    Events.Unsubscribe("APILibInitialized", BaseClasses.Initialize)

    BaseClasses.Initializing = true

    local classes_files = APILib.ListAPIFiles("Classes")

    if (not classes_files) or (not next(classes_files)) then
        Console.Error("Could not find API Classes files")
        BaseClasses.Initializing = false
        return
    end

    local total = #classes_files
    local completed = 0

    BaseClasses.APIClasses = {}
    for _, api_path in ipairs(classes_files) do
        local split_slash = BaseClasses.SplitString(api_path, "/")
        local filename = split_slash[#split_slash]
        local classname = string.sub(filename, 1, string.len(filename)-string.len(".json"))

        APILib.ReadAPIFileAsync(api_path, function(data)
            completed = completed + 1

            if data then
                BaseClasses.APIClasses[classname] = {}
                if data.inheritance then
                    local Parents = {}

                    for i, v in ipairs(data.inheritance) do
                        table.insert(Parents, "Base" .. v)
                    end

                    BaseClasses.APIClasses[classname].Parents = Parents
                end
            end

            if completed >= total then

                -- Do reverse job to add Children to all classes
                for class, v in pairs(BaseClasses.APIClasses) do
                    if v.Parents then
                        for _, parent in ipairs(v.Parents) do
                            if BaseClasses.APIClasses[parent] then
                                if not BaseClasses.APIClasses[parent].Children then
                                    BaseClasses.APIClasses[parent].Children = {}
                                end

                                table.insert(BaseClasses.APIClasses[parent].Children, class)
                            end
                        end
                    end
                end

                --print(NanosTable.Dump(BaseClassEvents.APIClasses))

                -- Cleanup because we use it once
                APILib.ClearCache()

                BaseClasses.Ready()
            end
        end)
    end
end