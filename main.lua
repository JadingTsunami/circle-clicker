-- Copyright (C) 2015 
-- 
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
-- 
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
-- 
-- You should have received a copy of the GNU General Public License
-- along with this program.  If not, see <http://www.gnu.org/licenses/>

DEBUG=1

streak=0

-- Obtainables
score=0
life=0
energy=0
water=0
luck=0
friends=0
respect=0

text=""
text2=""

message=""

-- table of circles
circles = {}

-- Size of puzzle matrix
MATRIXSIZE=10

-- outer_radius of each circle (start at 0, filled in during load())
outer_radius=0
inner_radius=0
segments=50

-- called when game starts
-- load assets, graphics, sounds, etc.
function love.load(arg)
    math.randomseed( os.time() )

    message=""
    streak=0
    score=0
    life=100
    energy=0
    water=0
    luck=0
    friends=0
    respect=5

    text=""
    text2=""

    width, height = love.window.getDimensions()
    -- outer_radius must be smaller of width or height
    outer_radius = math.min(width,height)/(2*MATRIXSIZE)
    inner_radius = outer_radius * 0.95
    love.graphics.setNewFont(20)
    generate_new_matrix()
end

-- called each frame
function love.update(dt)
    if love.keyboard.isDown('escape') then
        love.event.push('quit')
    end
end

function round(n)
    return math.floor(n+0.5)
end

function round(n,places)
    local multiplier = 10^(places or 0)
    return math.floor(n * multiplier + 0.5) / multiplier
end

function love.mousepressed(x, y, button)
    if button == 'l' then
        text = x .. ", " .. y
        text2 = is_inside_circle(x,y)
        if text2=="INSIDE" then
            whichone = math.floor(x/60) + (math.floor(y/60)*MATRIXSIZE) + 1
            text2 = text2 .. " "..whichone

            -- adjust score
            local red = circles[whichone].r
            local green = circles[whichone].g
            local blue = circles[whichone].b
            local flicker = circles[whichone].flicker
            local fader = circles[whichone].fader

            -- skip "deleted" circles
            if( red == 0 and green == 0 and blue == 0 and flicker == false and fader == false ) then return end

            -- "delete" clicked circle
            circles[whichone].r=0
            circles[whichone].g=0
            circles[whichone].b=0
            circles[whichone].flicker=false
            circles[whichone].fader=false

            if( (red > green) and (green > blue) ) then
                generate_new_matrix()
                return
            end

            score = score + red
            if( fader ) then
                message="got one"
                score = score + streak*red -- increase score
            else
                message="r " .. red .. "\ng " .. green .. "\nb " .. blue .. "\nfade " .. tostring(fader) .. "\nflicker " .. tostring(flicker)
            end

            life = math.floor( life - (100/red) )
            if blue > green then
                water = water + blue
            else
                water = water - green
            end

            luck = luck^(math.ceil(red*blue*green))

            score=round(score)
            life=round(life)
            energy=round(energy)
            water=round(water)
            luck=round(luck)
            friends=round(friends)
            respect=round(respect)

            -- FIXME uncomment generate_new_matrix()
        end
    end
end

function print_sidebar()

    love.graphics.setColor(255,255,255)

    print_offset = 0
    if( DEBUG ) then
        love.graphics.print(text,600,print_offset)
        print_offset = print_offset + 25
        love.graphics.print(text2,600,print_offset)
        print_offset = print_offset + 25
        -- fake newline between last print and next line
        print_offset = print_offset + 25
    end


    love.graphics.print("Score: " .. score,600,print_offset)
    print_offset = print_offset + 25
    love.graphics.print("Life: " .. life,600,print_offset)
    print_offset = print_offset + 25
    love.graphics.print("Energy: " .. energy,600,print_offset)
    print_offset = print_offset + 25
    love.graphics.print("Water: " .. water,600,print_offset)
    print_offset = print_offset + 25
    love.graphics.print("Luck: " .. luck,600,print_offset)
    print_offset = print_offset + 25
    love.graphics.print("Friends: " .. friends,600,print_offset)
    print_offset = print_offset + 25
    love.graphics.print("Respect: " .. respect,600,print_offset)
    print_offset = print_offset + 25

    if( message ) then
        print_offset = print_offset + 25
        love.graphics.print(message,600,print_offset)
    end
end

-- called each frame
function love.draw()
    print_sidebar()

    -- draw each circle
    love.graphics.setColor(255,255,255)
    for i, c in ipairs(circles) do
        if c.flicker then
            c.r = c.r - 0.1
            c.g = c.g - 0.1
            c.b = c.b - 0.1
        end
        if c.fader then
            c.r = c.r - 1
            c.g = c.g - 1
            c.b = c.b - 1
            if (c.r < 0) or (c.g < 0) or (c.b < 0) then
                c.fader = false
                c.r = math.max(0,c.r)
                c.g = math.max(0,c.g)
                c.b = math.max(0,c.b)
            end
        end
        love.graphics.setColor(c.r,c.g,c.b)
        love.graphics.circle("fill",outer_radius*(2*c.x+1),outer_radius*(2*c.y+1),inner_radius,segments)

        love.graphics.setColor(255,0,0)
        -- love.graphics.print(i-1,outer_radius*(2*c.x+1)-10,outer_radius*(2*c.y+1)-10)
    end
end

function generate_new_matrix()
    circles = {}
    for i=0,MATRIXSIZE-1 do
        for j=0,MATRIXSIZE-1 do
            flickerer = false
            fade = false
            if math.random(100) < 25 then
                flickerer = true
            end
            if math.random(100) < 2 then
                fade = true
                flickerer = false -- flicker/fader are mutually exclusive
            end
            new_circle = { x=j, y=i, r=math.random(255), g=math.random(255), b=math.random(255), flicker=flickerer, fader=fade }
            table.insert(circles,new_circle)
        end
    end
end

function is_inside_circle(targx,targy)

    -- outer edge of the playing area
    if targx > 600 then return "OUTSIDE" end

    -- reduce to 0th circle case
    targx = targx % (outer_radius*2)
    targy = targy % (outer_radius*2)

    -- apply distance formula to circle centered at r
    distance = math.sqrt( (targx-outer_radius)^2 + (targy-outer_radius)^2 )
    if distance < outer_radius then
        return "INSIDE"
    else
        return "OUTSIDE"
    end
end
