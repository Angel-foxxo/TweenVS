--Inspired by the GDC talk "Math for Game Programmers: Fast and Funky 1D Nonlinear Transformations" -- https://www.youtube.com/watch?v=mr5xkf6zSzk&ab_channel=GDC

local TweenVS = {
    _VERSION        =   "1.0.2",
    _NAME           =   "TweenVS",
    _DESCRIPTION    =   "VScript Tweening library for the Source2 game engine",
    _LINK           =   "github.com/Angel-foxxo/TweenVS",
    _COPYRIGHT      =   [[
        * Copyright (C) 2023 Angel - All Rights Reserved
        * You may use, distribute and modify this code under the
        * terms of the MIT license.
        *
        * You should have received a copy of the LICENSE file with
        * this file. If not, please write to: angelcazacu8@gmail.com or visit : github.com/Angel-foxxo/TweenVS
    ]]
}

TweenVS.Tweens = {}

if TweenVS.ROUND_START_EVENT ~= nil then

    StopListeningToGameEvent(TweenVS.ROUND_START_EVENT)
    TweenVS.ROUND_START_EVENT = nil
end

--------------------
--  Main Tween Class
--------------------
TweenVS.Tween = {}

local TweenMetatable = {
    __call = function(self, ...)
        return self:new(...)
    end,
}
setmetatable(TweenVS.Tween, TweenMetatable)

function TweenVS.Tween:new()

    local NewTween = {

        _target = nil,
        _type = nil,
        _initVal = nil,
        _endVal = nil,
        _initTime = nil,
        _duration = nil,
        _running = false,
        _timeElapsed = 0,
        _resultVal = nil,
        _callbackUpdateList = {},
        _callbackFinishList = {},
        _callbackStartList = {},
        _callbackEveryStartList = {},
        _callbackStopList = {},
        _nextTween = nil,
        _looping = nil,
        _loopCount = nil,
        _runCount = 0,
        _paused = false,
        _pausedTime = nil,
        _delay = nil,
        _delayTime = nil,
        _easingFunction = nil,
        _property = nil,
        _localVal = nil,
        _localLoop = nil,
        _inverted = false,
        _bounce = false,
        _justStarted = true
    }

    setmetatable(NewTween, self)
    self.__index = self

    return NewTween
end

TweenVS.Tween.__type = "Tween"

function TweenVS.Tween:__tostring()

    return string.format("Tween [StartVal: %s | EndVal: %s | ResultVal: %s]", self._initVal, self._endVal, self._resultVal)
end

--get the target to interpolate, the target can be either an entity or a basic type
function TweenVS.Tween:from(target, property)
    property = property or nil

    --set what property we are modifying
    if property == TweenVS.EntProps.pos then

        self._type = TweenVS.EntProps.pos
    elseif property == TweenVS.EntProps.ang then

        self._type = TweenVS.EntProps.ang
    elseif property == TweenVS.EntProps.scale then

        self._type = TweenVS.EntProps.scale
    elseif property == TweenVS.EntProps.color then

        self._type = TweenVS.EntProps.color
    end

    --is it an entity?
    if TweenVS.instanceof(target, "CBaseEntity") then

        if property == nil then
            error("TweenVS: from() target is an entity but no entity propery is specified!", 2)
        end

        --check if propery is valid
        if TweenVS.EntProps[property] == nil then
            error("TweenVS: from() target is an entity but the entity property is invalid!", 2)
        end

        --set the property
        if self._type == TweenVS.EntProps.pos then
            self._initVal = target:GetOrigin()
        elseif self._type == TweenVS.EntProps.ang then
            self._initVal = target:EyeAngles()
        elseif self._type == TweenVS.EntProps.scale then
            self._initVal = target:GetAbsScale()
        elseif self._type == TweenVS.EntProps.color then
            self._initVal = target:GetRenderColor()
        end

        self._target = target
        self._property = property

    --not an entity, perhaps a type?
    elseif TweenVS.ValTypes[TweenVS.type(target)] ~= nil then

        self._initVal = target
        self._target = target

    --NEITHER!! WHAT ARE YOU TRYING TO DO!?
    else
        error("TweenVS: from() target is invalid!", 2)
    end

    return self
end

--target value of the tween, has to match with the initial value type
function TweenVS.Tween:to(value, duration)
    duration = duration or 1

    if self._initVal == nil then
        error("TweenVS: start value doesn't exist! did you run from() first?", 2)
    end

    if TweenVS.type(value) ~= TweenVS.type(self._initVal) then
        error("TweenVS: start value type doesn't match end value type!", 2)
    end

    if TweenVS.type(duration) ~= TweenVS.ValTypes.number then
        error("TweenVS: tween duration is invalid!", 2)
    end

    self._endVal = value
    self._duration = duration

    return self
end

--only for entities, makes the tween local to the entity
function TweenVS.Tween:toLocal(value, duration, localLoop)
    duration = duration or 1
    localLoop = localLoop or false

    if self._initVal == nil then

        error("TweenVS: start value doesn't exist! did you run from() first?", 2)
    end

    if not TweenVS.instanceof(self._target, "CBaseEntity") then

        error("TweenVS: toLocal is only meant for entities!", 2)
    end

    self._localVal = value
    self._localLoop = localLoop
    self:to(self._initVal+value, duration)

    return self
end

--start tweening
function TweenVS.Tween:start()

    if self._localLoop then

        self:from(self._target, self._property)
        self:toLocal(self._localVal, self._duration, self._localLoop)

    end

    self._initTime = Time()
    self._timeElapsed = 0
    self._running = true

    if TweenVS.FindInArray(TweenVS.Tweens, self) == nil then

        self._runCount = 0
        self._justStarted = true
        table.insert(TweenVS.Tweens, self)

    end

    return self
end

--stops tweening, will actually remove it from the Tweens array
function TweenVS.Tween:stop()

    table.remove(TweenVS.Tweens, TweenVS.FindInArray(TweenVS.Tweens, self))
    self:handleCallback(self._callbackStopList, "TweenVS: on(stop) is attempting to call something that isn't a function!")

    return self
end

--add a callback function
function TweenVS.Tween:on(type, func)

    if not TweenVS.FindInArray(TweenVS.Callbacks, type) then

        error("TweenVS: on() was passed an invalid callback type!", 2)
    end

    TweenVS.Switch(type, {

        ["update"] = function()
            table.insert(self._callbackUpdateList, func)
        end,

        ["finish"] = function()
            table.insert(self._callbackFinishList, func)
        end,

        ["start"] = function()
            table.insert(self._callbackStartList, func)
        end,

        ["everyStart"] = function()
            table.insert(self._callbackEveryStartList, func)
        end,

        ["stop"] = function()
            table.insert(self._callbackStopList, func)
        end,

    })

    return self
end

--pauses the tweening, passing a number in seconds makes it act as a delay
--otherwise it pauses forever
function TweenVS.Tween:pause(time)
    time = time or nil

    if self._paused == true then

        return self
    end
    self._pausedTime = Time()
    self._running = false
    self._paused = true

    if time ~= nil then

        if TweenVS.type(time) ~= "number" then

            error("TweenVS: delay() has an invalid parameter!", 2)
        end
        self._delay = time
        self._delayTime = Time()
    end

    return self
end

--unpauses a tween, does nothing if its not paused
function TweenVS.Tween:unpause()

    if not self._initTime then

        return self
    end
    if self._paused ~= true then

        return self
    end
    if self._delay ~= nil then

        return self
    end

    local resumeTime = Time()
    self._initTime = resumeTime - (self._pausedTime -self._initTime)
    self._running = true
    self._paused = false
    return self
end

--loops the tween, loopCount of -1 is infinite looping
function TweenVS.Tween:loop(loopCount)
    loopCount = loopCount or -1

    if TweenVS.type(loopCount) ~= "number" and loopCount ~= nil then

        error("TweenVS: loop() has an invalid parameter!", 2)
    end

    self._looping = true
    self._loopCount = loopCount

    if loopCount == 0 then

        self._looping = false
        self._loopCount = 0
    end
    if loopCount < 0 then

        self._looping = true
        self._loopCount = nil
    end
    return self
end

--makes the tween reverse direction at the end of each loop
--each start of the tween in a single direction counts as a single bounce, for example
--to play a tween once forward, and once back, set the loop() function to 1
function TweenVS.Tween:bounce(val)
    val = val or true

    if TweenVS.type(val) ~= "boolean" then

        error("TweenVS: bounce() has an invalid parameter!", 2)
    end
    self._bounce = val

    return self
end

--runs the provided tween when the current tween finishes
function TweenVS.Tween:chain(tween)
    tween = tween or nil

    if tween == nil then

        error("TweenVS: chain() is missing a value!", 2)
    end
    if TweenVS.type(tween) ~= "Tween" then

        error("TweenVS: chain() was pass an invalid value!", 2)
    end
    self._nextTween = tween
    return self
end

--sets the easing function, leave black for linear interpolation
--you can either use a function from TweenVS.EasingFunctions or
--pass a custom function, the function needs to take one parameter (t)
--and return the modified t parameter
function TweenVS.Tween:easing(easingFunction)
    easingFunction = easingFunction or nil

    if easingFunction ~= null and TweenVS.type(easingFunction) ~= "function" then

        error("TweenVS: easing() has an invalid parameter!", 2)
    end
    self._easingFunction = easingFunction

    return self
end

--inverts the tween, this does not modify the self._initVal and self._endVal variables like bounce()
--but is instead done by inverting the t value used to interpolate
function TweenVS.Tween:invert(val)
    val = val or true

    if TweenVS.type(val) ~= "boolean" then

        error("TweenVS: invert() has an invalid parameter!", 2)
    end
    self._inverted = val

    return self
end

--read more in the function, this shit does too much stuff to write it all here
function TweenVS.Tween:update()

    if self._delay ~= nil then

        if Time() - self._delayTime < self._delay then
            return
        else

            self._delay = nil
            self:unpause()

        end
    end

    if not self._running then
        return
    end

    self._timeElapsed = Time() - self._initTime

    --horrible hack to fix the tween not starting from the initial value on loops due to execution order
    if self._justLooped then

        self._timeElapsed = 0
        self._justLooped = false
    end

    if self._timeElapsed < self._duration then

        local t = self._timeElapsed/self._duration

        if self._easingFunction == nil then

            t = t
        else

            t = self._easingFunction(t)
        end

        if self._inverted then

            t = (t * -1) + 1
        end

        if TweenVS.type(self._initVal) == "QAngle" then

            --builting slerp, thank god
            self._resultVal = QSlerp(self._initVal, self._endVal, t)
        else

            self._resultVal = TweenVS.Lerp(self._initVal, self._endVal, t)
        end

        if self._justStarted then

            self:handleCallback(self._callbackEveryStartList, "TweenVS: on(everyStart) is attempting to call something that isn't a function!")
        end
    else

        self._resultVal = self._endVal
        self._runCount = self._runCount + 1
        self._running = false

        self:handleCallback(self._callbackFinishList, "TweenVS: on(update) is attempting to call something that isn't a function!")

        if self._looping then

            if self._loopCount == nil or self._runCount <= self._loopCount then

                if self._bounce then

                    local tempInitVal = self._initVal
                    local tempEndVal = self._endVal
                    self._initVal = tempEndVal
                    self._endVal = tempInitVal
                end
                self._justLooped = true
                self:start()
            end
        end
    end
    --its an entity!
    if TweenVS.instanceof(self._target, "CBaseEntity") then

        --set entity property based on the type
        if self._type == TweenVS.EntProps.pos then

            self._target:SetOrigin(self._resultVal)
        elseif self._type == TweenVS.EntProps.ang then

            self._target:SetAngles(self._resultVal.x, self._resultVal.y, self._resultVal.z)
        elseif self._type == TweenVS.EntProps.scale then

            self._target:SetAbsScale(self._resultVal)
        elseif self._type == TweenVS.EntProps.color then

            self._target:SetRenderColor(self._resultVal.x, self._resultVal.y, self._resultVal.z)
        end
    --not an entity, perhaps a type?
    elseif TweenVS.FindInArray(TweenVS.ValTypes, TweenVS.type(self._target)) then

        self._target = self._resultVal
    end

    self:handleCallback(self._callbackUpdateList, "TweenVS: on(start) is attempting to call something that isn't a function!")

    if self._runCount == 0 and self._justStarted then

        self:handleCallback(self._callbackStartList, "TweenVS: on(start) is attempting to call something that isn't a function!")
    end

    --twin chaining is executed here because otherwise we wouldnt get the final start position
    if self._nextTween ~= nil and self._timeElapsed >= self._duration then

        if self._nextTween._property ~= nil then
            
            self._nextTween:from(self._nextTween._target, self._nextTween._property)

            if self._nextTween._localVal ~= nil then
                self._nextTween:toLocal(self._nextTween._localVal, self._nextTween._duration, self._nextTween._localLoop)
            end
        end
        self._nextTween:start()
        if self._nextTween._paused then

            self._nextTween._paused = false
            self._nextTween:pause(self._nextTween._delay)
        end
    end

    self._justStarted = false
end

--handles callbacks
function TweenVS.Tween:handleCallback(callbackList, errorString)

    for _, callback in ipairs(callbackList) do
        if TweenVS.type(callback) ~= "function" then

            error(errorString, 2)
        end
        callback(self._resultVal)
    end
end

--------------------
--  Easing Functions
--  taken from https://easings.net/
--------------------
TweenVS.EaseInSine = function(t)
    return 1.0 - math.cos((t * math.pi) / 2.0)
end

TweenVS.EaseOutSine = function(t)
    return math.sin((t * math.pi) / 2)
end

TweenVS.EaseInOutSine = function(t)
    return -(math.cos(math.pi * t) - 1.0) / 2.0
end

TweenVS.EaseInCubic = function(t)
    return t * t * t
end

TweenVS.EaseOutCubic = function(t)
    return 1.0 - math.pow(1.0 - t, 3.0)
end

TweenVS.EaseInOutCubic = function(t)
    return t < 0.5 and (4.0 * t * t * t) or (1 - math.pow(-2.0 * t + 2.0, 3.0) / 2.0)
end

TweenVS.EaseInQuint = function(t)
    return t * t * t * t * t
end

TweenVS.EaseOutQuint = function(t)
    return 1.0 - math.pow(1.0 - t, 5.0)
end

TweenVS.EaseInOutQuint = function(t)
    return t < 0.5 and (16.0 * t * t * t * t * t) or (1.0 - math.pow(-2.0 * t + 2.0, 5.0) / 2.0)
end

TweenVS.EaseInCircle = function(t)
    return 1.0 - math.sqrt(1.0 - math.pow(t, 2.0))
end

TweenVS.EaseOutCircle = function(t)
    return math.sqrt(1.0 - math.pow(t - 1.0, 2.0))
end

TweenVS.EaseInOutCircle = function(t)
    return t < 0.5 and ((1.0 - math.sqrt(1.0 - math.pow(2.0 * t, 2.0))) / 2.0) or ((math.sqrt(1.0 - math.pow(-2.0 * t + 2.0, 2.0)) + 1.0) / 2.0)
end

TweenVS.EaseInElastic = function(t)
    local c4 = (2.0 * math.pi) / 3.0

    if t == 0 then
        return 0
    elseif t == 1.0 then
        return 1.0
    else
        return -math.pow(2.0, 10.0 * t - 10.0) * math.sin((t * 10.0 - 10.75) * c4)
    end
end

TweenVS.EaseOutElastic = function(t)
    local c4 = (2.0 * math.pi) / 3.0

    if t == 0 then
        return 0
    elseif t == 1.0 then
        return 1.0
    else
        return math.pow(2.0, -10.0 * t) * math.sin((t * 10.0 - 0.75) * c4) + 1.0
    end
end

TweenVS.EaseInOutElastic = function(t)
    local c5 = (2.0 * math.pi) / 4.5

    if t == 0 then
        return 0
    elseif t == 1 then
        return 1
    elseif t < 0.5 then
        return -(math.pow(2.0, 20.0 * t - 10.0) * math.sin((20.0 * t - 11.125) * c5)) / 2.0
    else
        return (math.pow(2.0, -20.0 * t + 10.0) * math.sin((20.0 * t - 11.125) * c5)) / 2.0 + 1.0
    end
end

TweenVS.EaseInQuad = function(t)
    return t * t
end

TweenVS.EaseOutQuad = function(t)
    return 1.0 - (1.0 - t) * (1.0 - t)
end

TweenVS.EaseInOutQuad = function(t)
    return t < 0.5 and (2.0 * t * t) or (1.0 - math.pow(-2.0 * t + 2.0, 2.0) / 2.0)
end

TweenVS.EaseInQuart = function(t)
    return t * t * t * t
end

TweenVS.EaseOutQuart = function(t)
    return 1.0 - math.pow(1.0 - t, 4.0)
end

TweenVS.EaseInOutQuart = function(t)
    return t < 0.5 and (8.0 * t * t * t * t) or (1.0 - math.pow(-2.0 * t + 2.0, 4.0) / 2.0)
end

TweenVS.EaseInExpo = function(t)
    return t == 0 and 0 or math.pow(2.0, 10.0 * t - 10.0)
end

TweenVS.EaseOutExpo = function(t)
    return t == 1.0 and 1.0 or 1.0 - math.pow(2.0, -10.0 * t)
end

TweenVS.EaseInOutExpo = function(t)
    if t == 0 then
        return 0
    elseif t == 1.0 then
        return 1.0
    elseif t < 0.5 then
        return math.pow(2.0, 20.0 * t - 10.0) / 2.0
    else
        return (2.0 - math.pow(2.0, -20.0 * t + 10.0)) / 2.0
    end
end

TweenVS.EaseInBack = function(t)
    local c1 = 1.70158
    local c3 = c1 + 1

    return c3 * t * t * t - c1 * t * t
end

TweenVS.EaseOutBack = function(t)
    local c1 = 1.70158
    local c3 = c1 + 1

    return 1.0 + c3 * math.pow(t - 1.0, 3.0) + c1 * math.pow(t - 1.0, 2.0)
end

TweenVS.EaseInOutBack = function(t)
    local c1 = 1.70158
    local c2 = c1 * 1.525

    return t < 0.5 and (math.pow(2.0 * t, 2.0) * ((c2 + 1.0) * 2.0 * t - c2)) / 2.0 or (math.pow(2.0 * t - 2.0, 2.0) * ((c2 + 1.0) * (t * 2.0 - 2.0) + c2) + 2.0) / 2.0
end

TweenVS.EaseInBounce = function(t)
    return 1 - TweenVS.EaseOutBounce(1 - t)
end

TweenVS.EaseOutBounce = function(t)
    local n1 = 7.5625
    local d1 = 2.75

    if t < 1.0 / d1 then
        return n1 * t * t
    elseif t < 2.0 / d1 then
        t = t - 1.5 / d1
        return n1 * t * t + 0.75
    elseif t < 2.5 / d1 then
        t = t - 2.25 / d1
        return n1 * t * t + 0.9375
    else
        t = t - 2.625 / d1
        return n1 * t * t + 0.984375
    end
end


TweenVS.EaseInOutBounce = function(t)
    return t < 0.5 and (1.0 - TweenVS.EaseOutBounce(1.0 - 2.0 * t)) / 2.0 or (1.0 + TweenVS.EaseOutBounce(2.0 * t - 1.0)) / 2.0
end

TweenVS.EasingFunctions =
{
    TweenVS.EaseInSine,
    TweenVS.EaseOutSine,
    TweenVS.EaseInOutSine,
    TweenVS.EaseInCubic,
    TweenVS.EaseOutCubic,
    TweenVS.EaseInOutCubic,
    TweenVS.EaseInQuint,
    TweenVS.EaseOutQuint,
    TweenVS.EaseInOutQuint,
    TweenVS.EaseInCircle,
    TweenVS.EaseOutCircle,
    TweenVS.EaseInOutCircle,
    TweenVS.EaseInElastic,
    TweenVS.EaseOutElastic,
    TweenVS.EaseInOutElastic,
    TweenVS.EaseInQuad,
    TweenVS.EaseOutQuad,
    TweenVS.EaseInQuart,
    TweenVS.EaseOutQuart,
    TweenVS.EaseInOutQuart,
    TweenVS.EaseInExpo,
    TweenVS.EaseOutExpo,
    TweenVS.EaseInOutExpo,
    TweenVS.EaseInBack,
    TweenVS.EaseOutBack,
    TweenVS.EaseInOutBack,
    TweenVS.EaseInBounce,
    TweenVS.EaseOutBounce,
    TweenVS.EaseInOutBounce
}

--------------------
--  Util functions
--------------------
--Overrides the Tweens array with an empty one
function TweenVS.PurgeTweens()

    TweenVS.Tweens = {}
end

--Squirrel style switch statement
function TweenVS.Switch(param, case_table)
    local case = case_table[param]
    if case then return case() end
    local def = case_table['default']
    return def and def() or nil
end


function TweenVS.Lerp(a, b, t)
    return (a * (1.0 - t)) + (b * t);
end

function TweenVS.FindInArray(array, target)
    for i, value in ipairs(array) do
        if value == target then
            return i
        end
    end

    return nil
end

--Horrible hack to get type() to acknowledge my class and other classes like Vector and Qangle, I miss squirrel
function TweenVS.type(obj)
    local otype = type(obj)
    if otype == "table" and getmetatable(obj) == TweenVS.Tween then
        return TweenVS.Tween.__type
    end
    if otype == "userdata" and getmetatable(obj) == debug.getregistry()["Vector"] then
        return "Vector"
    end
    if otype == "userdata" and getmetatable(obj) == debug.getregistry()["QAngle"] then
        return "QAngle"
    end
    return otype
end

--Less Horrible hack to get instanceof functionality from squirrel back, how can people still say lua is better
function TweenVS.instanceof(obj, classname)
    local classname = debug.getregistry()[tostring(classname)]
    if classname == nil then
        error("instanceof() invalid classname", 2)
    end

    local mt2 = getmetatable(obj)
    while mt2 ~= nil do
        if mt2 == classname then
            return true
        end
        mt2 = getmetatable(mt2.__index)
    end

    return false
end


--------------------
--  Tween Value Types
--------------------
TweenVS.ValTypes =
{
    number = "number",
    Vector = "Vector",
    QAngle = "QAngle"
}

--------------------
--  Entity Properties
--------------------
TweenVS.EntProps =
{
    pos = "pos",
    ang = "ang",
    scale = "scale",
    color = "color"
}

--------------------
--  Tween Callback Function Types
--------------------
TweenVS.Callbacks =
{
    "update",
    "finish",
    "start",
    "everyStart",
    "stop"
}

--------------------
--  Tween Update Function
--------------------
function TweenVS.UpdateTweens()

    for _, Tween in ipairs(TweenVS.Tweens) do

        if Tween._initVal == nil then

            error("TweenVS: Updating Tween without a start value!", 2);
        end

        if Tween._endVal == nil then

            error("TweenVS: Updating Tween without an end value!", 2);
        end

        Tween:update()
    end

    return FrameTime()
end

Entities:FindByClassname(nil, "worldent"):SetContextThink("TWEENVS_THINK", TweenVS.UpdateTweens, FrameTime())

--------------------
--  Round Start Function
--------------------
function TweenVS.OnRoundStart()
    --this is needed to reset the code if the round restarts, so tweens from the last round dont exist into the next round
    TweenVS.PurgeTweens()
end

TweenVS.ROUND_START_EVENT = ListenToGameEvent("round_start", TweenVS.OnRoundStart, nil)

print("TweenVS: Succesfully loaded, version " .. TweenVS._VERSION)
return TweenVS
