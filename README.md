# nanos-base-classes
#### Shared
#### LuaLS annotations included

## Example
```lua
Events.Subscribe("BaseClassesInitialized", function()
    BaseClasses.CallFuncName("BaseEntity", "Subscribe", "Spawn", function(ent)
        print("Entity Spawned:", ent)
    end)

    BaseClasses.CallFuncName("BaseEntity", "Subscribe", "Destroy", function(ent)
        print("Entity Destroyed:", ent)
    end)

    BaseClasses.CallFunc("BaseEntity", function(self)
        print("BaseEntity child class:", self)
    end)

    BaseClasses.Extend("BaseEntity", "PrintValue", function(self, value)
        print("PrintValue", self, value)
    end)

    local my_prop = Prop(Vector(), Rotator(), "nanos-world::SM_Cube")
    local stack_o_bot = CharacterSimple(Vector(100, 0, 100), Rotator(0, 0, 0), "nanos-world::SK_StackOBot", "nanos-world::ABP_StackOBot")

    my_prop:PrintValue(1)
    stack_o_bot:PrintValue(2)
end)

Package.Subscribe("Load", function()
    BaseClasses.Initialize()
end)
```

## Dependencies
* [api-lib](https://github.com/vugi99/nanos-api-lib)

## Functions
```lua
BaseClasses.IsInitializing()
BaseClasses.IsInitialized()

BaseClasses.GetClassParentNames(classname)
BaseClasses.GetClassChildrenNames(classname)

BaseClasses.CallFunc(classname, func, ...)
BaseClasses.CallFuncName(classname, funcname, ...)
BaseClasses.Extend(classname, name, func)

BaseClasses.SplitString(str, sep)

BaseClasses.Initialize()

-- Internal
BaseClasses.Ready()
```

## Events
```lua
Events.Subscribe("BaseClassesInitialized", function() end)
```