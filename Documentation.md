# TweenVs Documentation
________________________________

```lua
:from(target, property = nil)
```
Gets the initial value to tween, `target` can be an entity handle or a numeric value  
if `target` is an entity handle then `property` has to be specified, this dictates what entity property to tween  
valid properties:  
```lua
TweenVS.EntProps
{
    "pos"     -- entity position
    "ang"     -- entity angles
}
```
________________________________

```lua
:to(value, duration = 1)
```
Sets the end value of the tween.  
`value` will set the value the tween will interpolate to, this has to match the value type used in `:from()`   
`duration` will set the time in seconds in which the tween will go from the initial value to the end value     
________________________________

```lua
:toLocal(value, duration = 1, localLoop = false)
```
The same as `:to()` but takes `value` as relative to the entity  
`localLoop` will make it so that if the tween is looping, the end value is re-evaluated at the start of each new loop relative to the entity.  
________________________________

```lua
:start()
```
Starts the tween.
________________________________

```lua
:stop()
```
Stops the tween, this will stop the tween from being updated in any way.
________________________________

```lua
:pause(time = nil)
```
Pauses the tween, if `time` in seconds is provided this will act as a delay.
________________________________

```lua
:unpause()
```
Unpauses the tween.  
________________________________

```lua
:loop(loopCount = nil)
```
Loops the tween, the tween will `start()` itself after it finishes tweening  
if `loopCount = -1` the tween will loop forever  
________________________________

```lua
:bounce(val = true)
```
If `val` is set to true it will make the tween go backwards, from the end value to the initial value, on each loop  
if `val` is set to false it will disable bouncing  
requires `loop()` to be at least `1`
________________________________

```lua
:chain(tween)
```
Runs the provided tween when the current tween finishes  
`tween` needs to be another `Tween()` class  
________________________________

```lua
:on(type, func)
```
Will add a callback function `func` to be run based on the `type`  
the functions needs to have the form `function(output)` where `output` is the output value of the tween that will be passed to the function  
`type` dictates when the callback is ran, valid types are:  
```lua
TweenVS.Callbacks
{
    "update"        -- runs the callback function each time the tween updates
    "finish"        -- runs the callback function when the tween finishes
    "start"         -- runs the callback function only on the first start of the tween
    "everyStart"    -- runs the callback function on every other subsequent start, ex: when the tween is looping
    "stop"          -- runs the callback function when the tween stops
}
```
________________________________

```lua
:easing(easingFunction = nil)
```
Sets the easing type of the interpolation, the library includes an extensive collection of easing functions, see: `TweenVS.EasingFunctions`  
you can also define a custom easing function of the form `function(t)` that returns `t` 
________________________________

```lua
:invert(val = true)
```
if `val` is set to `true` it will invert the tween, however it does this by inverting the `t` progress value itself not the start and end values  
if `val` is set to `false` it will disable the inversion  
