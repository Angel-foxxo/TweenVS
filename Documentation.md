# TweenVS Documentation
________________________________

### Tween Class Functions
Note that all the following functions are members of the ``Tween()`` classs and should be called on an instance of the ``Tween()`` class.

[`TweenVS:from(target, property = nil)`](#from)  
[`TweenVS:to(value, duration = 1)`](#to)    
[`TweenVS:toLocal(value, duration = 1, localLoop = false)`](#toLocal)  
[`TweenVS:start()`](#start)  
[`TweenVS:end()`](#end)  
[`TweenVS:pause(time = nil)`](#pause)  
[`TweenVS:unpause()`](#unpause)  
[`TweenVS:loop(loopCount = nil)`](#loop)  
[`TweenVS:bounce(val = true)`](#bounce)  
[`TweenVS:on(type, func)`](#on)  
[`TweenVS:chain(tween)`](#chain)  
[`TweenVS:easing(easingFunction = nil)`](#easing)  
[`TweenVS:invert(val = true)`](#invert)  
________________________________     
#### from
```lua
from(target, property = nil)
```
Set the initial value to tween from.
##### Parameters:
``target``  Can be an entity handle or a numeric value. If an entity handle is passed, then ``property`` must be specified.  
``property``    Which of the entity's keyvalues should be tweened. Only necessary if ``target`` is an entity.  

Available keyvalues to tween are:

```lua
"pos",          -- entity origin
"ang",          -- entity angles
"mass",         -- entity mass
"scale",        -- entity scale
"color",        -- entity rendercolor
"alpha",        -- entity alpha
"health",       -- entity health
"velocity",     -- entity velocity
"angVelocity"   -- entity angular velocity
```
________________________________
#### to
```lua
to(value, duration = 1)
```
Set the end value to tween towards.
##### Parameters:
``value`` The final value of the tween. The library will interpolate from the value specified in ``from()`` to this value. Must match the data type used in ``from()`` !  
``duration`` The amount of time the tween will last, in seconds. A value of ``1``, with a from value of ``0`` and a ``to()`` value of ``1``, will interpolate from ``0`` to ``1`` in ``1`` second.   
________________________________
#### toLocal
```lua
toLocal(value, duration = 1, localLoop = false)
```
Behaves the same as ``to()`` but tweened keyvalues are relative to the entity's current keyvalue.
##### Parameters:
``value`` The final value of the tween. The library will interpolate from the value specified in ``from()`` to this value. Must match the data type used in ``from()`` !   
``duration`` The amount of time the tween will last, in seconds. A value of ``1``, with a from value of ``0`` and a ``to()`` value of ``1``, will interpolate from ``0`` to ``1`` in ``1`` second.  
``localLoop`` A boolean ``true`` or ``false`` flag that specifies whether to use the entity's local keyvalues at the start of each loop. ``false`` means the local ``from()`` value is only calculated at the start of the tween.  
##### Example:

```lua
--makes the entity tween 50 units up from its current position over 1 second.
local myEntity = GetListenServerHost()
TweenVS.Tween()
:from(myEntity, "pos")
:toLocal(Vector(0.0, 0.0, 50.0), 1)
:start()

--the entity's local origin is reevaluated after each loop, making the entity continually move 50 units higher each second.
local myEntity = GetListenServerHost()
TweenVS.Tween()
:from(myEntity, "pos")
:toLocal(Vector(0.0, 0.0, 50.0), 1, true)
:start()

``` 
________________________________
#### start
```lua
start()
```
Starts the tween.
________________________________
#### stop
```lua
stop()
```
Stops the tween and removes it from the tween table.
________________________________
#### pause
```lua
pause(time = nil)
```
Pauses the tween.
##### Parameters:
``time`` If specified, determines how long the tween should pause for, in seconds. Default is ``nil`` (infinite).
________________________________
#### unpause
```lua
unpause()
```
Unpauses the tween.  
________________________________
#### loop
```lua
loop(loopCount = nil)
```
Loops the tween.
##### Parameters:
``loopCount`` Specifies how many times the tween should loop. A value of ``-1`` will make the tween loop indefinitely.
________________________________
#### bounce
```lua
bounce(val = true)
```
Creates a bouncing tween effect. Requires ``loopCount`` in ``loop()`` to be greater than 0.
##### Parameters:
``val`` A boolean value - ``true`` makes the tween bounce backwards, from the ``to()`` value to the ``from()`` value on each loop. ``false`` Disables bouncing.
________________________________
#### on
```lua
on(type, func)
```
Add a custom callback function to the tween. Functions can have one optional argument that passes in the value of the current tween.
##### Parameters:
``type`` The type of callback to use. Available callbacks are:
```lua
"update"        -- runs the callback function each time the tween updates
"finish"        -- runs the callback function when the tween finishes
"start"         -- runs the callback function only on the first start of the tween
"everyStart"    -- runs the callback function on every other subsequent start, ie when the tween is looping
"stop"          -- runs the callback function when the tween stops
```
``func`` The custom function to run when the callback is called
 ##### Example:
 ```lua
  -- Create a tween that tweens from 1 to 5 in 0.5 seconds and prints out "Done!" when its finished
myTween = TweenVS.Tween()
:from(1)
:to(5, 0.5)
:on("finish", function()
    print("Done!")
end)
:start()

-- The above code can also be written in this way
function PrintDone()
    print("Done!")
end

myTween = TweenVS.Tween()
:from(1)
:to(5, 0.5)
:on("finish", PrintDone)
:start()
 ```
________________________________
#### chain
```lua
chain(tween)
```
Allows you to chain multiple tweens together to create complex tweening effects.
##### Parameters:
``tween`` The tween to run after the current one. Must be another instance of the ``Tween()`` class. 
 ##### Example:
 ```lua
 -- Create a tween that tweens from 1 to 5 in 0.5 seconds and prints out the value on each update
 -- do not start it yet
myTweenOne = TweenVS.Tween()
:from(1)
:to(5, 0.5)
:on("update", function(val)
    print("Tweened value is: " .. tostring(val))    --print out the tweened value
end)

-- Create a tween called "myTweenTwo" that moves an entity to world position (64, 64, 0) 
-- and chain `myTweenOne` to the end of `myTweenTwo`, then begin tweening
local myEntity = GetListenServerHost()
myTweenTwo = TweenVS.Tween()
:from(myEntity, "pos")
:to(Vector(64, 64, 0), 5)
:chain(myTweenOne)
:start()
 ```
________________________________
#### easing
```lua
easing(easingFunction = nil)
```
Set the interpolation type. A custom interpolation function can also be passed in, the function argument must take in at least one value and then return it. (this value would be the current ``t`` value of the interpolation).
##### Parameters:
``easingFunction`` The type of interpolation to use. Available easing functions are:
```lua
TweenVS.EaseInSine
TweenVS.EaseOutSine
TweenVS.EaseInOutSine
TweenVS.EaseInCubic
TweenVS.EaseOutCubic
TweenVS.EaseInOutCubic
TweenVS.EaseInQuint
TweenVS.EaseOutQuint
TweenVS.EaseInOutQuint
TweenVS.EaseInCircle
TweenVS.EaseOutCircle
TweenVS.EaseInOutCircle
TweenVS.EaseInElastic
TweenVS.EaseOutElastic
TweenVS.EaseInOutElastic
TweenVS.EaseInQuad
TweenVS.EaseOutQuad
TweenVS.EaseInQuart
TweenVS.EaseOutQuart
TweenVS.EaseInOutQuart
TweenVS.EaseInExpo
TweenVS.EaseOutExpo
TweenVS.EaseInOutExpo
TweenVS.EaseInBack
TweenVS.EaseOutBack
TweenVS.EaseInOutBack
TweenVS.EaseInBounce
TweenVS.EaseOutBounce
TweenVS.EaseInOutBounce
```
The website https://easings.net/ has a collection of graphs and animations illustrating the various easing functions.
 ##### Example:
 ```lua
 -- Create a tween that tweens from 1 to 5 in 0.5 seconds, using a Cubic formula, then begin tweening
myTween = TweenVS.Tween()
:from(1)
:to(5, 0.5)
:easing(TweenVS.EaseInCubic)
:on("update", function(val)
    print("Tweened value is: " .. tostring(val))    --print out the tweened value
end)
:start()


-- Custom functions can also be passed in, for example:
function EaseInRidiculous(t)
    return t * t * t * t * t * t * t * t * t
end

myTween = TweenVS.Tween()
:from(1)
:to(5, 0.5)
:easing(EaseInRidiculous)
:on("update", function(val)
    print("Tweened value is: " .. tostring(val))    --print out the tweened value
end)
:start()

-- The previous code could also be written as
myTween = TweenVS.Tween()
:from(1)
:to(5, 0.5)
:easing(function (t)
    return t * t * t * t * t * t * t * t * t
end)
:on("update", function(val)
    print("Tweened value is: " .. tostring(val))    --print out the tweened value
end)
:start()
 ```
________________________________
#### invert
```lua
invert(val = true)
```
Invert the current ``t`` value of the interpolation.
##### Parameters:
``val`` A boolean value specifying whether to invert the tween. ``true`` Enables inversion, ``false`` disables inversion.
________________________________
## TweenVS General Functions
The following functions are part of the TweenVS table
________________________________
[`TweenVS:PurgeTweens()`](#from)  
[`TweenVS:type(obj)`](#from)
________________________________
#### PurgeTweens
```lua
PurgeTweens()
```
Wipes the current tween table, destroying all created tweens.
________________________________
#### type
```lua
type(obj)
```
Custom type() function, returns the data type of `obj` including the Tween(), Vector() and QAngle() classes, which the normal type() function misses.
________________________________