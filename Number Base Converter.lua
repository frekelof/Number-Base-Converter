-- Changelog --
-- 2019-10-26: First version considered done.
-- 2019-11-13: Added CAS check and warning if program running on a non CAS calculator.
--             Improved how active I/O box is set. Focus remains in active box during resize in comp view. On prgm launch and switch between calc and comp view, focus is set in dec I/O box.
--             Added copy/cut/paste text functionality.

-- Minimum requirements: TI Nspire CX CAS (color resulution 318x212)
platform.apilevel = '2.4'
local appversion = "191113" -- Made by: Fredrik Ekelöf, fredrik.ekelof@gmail.com

-- App layout configuration
local lines = 4 -- Total lines program contains. Lines are evenly split horizonatally.
local padding = 8 -- Empty space (in relative px) between borders and working area

-- Font size configuration. Availible sizes are 7,9,10,11,12,16,24.
local fnthdgset = 12 -- Heading font size
local fntbodyset = 11 -- Label and body text font size

-- Colors
local bgcolor = 0xCFE2F3 -- Background, light blue
local brdcoloract = 0x2478CF -- Active box border, blue
local brdcolorinact = 0xEBEBEB -- Inactive box border, grey
local errorcolor = 0xF02600 -- Error text, dark red

-- Variabels for internal use
local isCAS = nil -- Used for CAS check. Variabel is set in on.resize() function.
local fnthdg,fntbody = fnthdgset,fntbodyset -- Font size variabels used by functions
local lblhdg = "Number Base Converter" -- Program heading
local ioidtable = {} -- Initial empty table for storing I/O editor boxes unique ID:s

-- Screen properties
local scr = platform.window -- Shortcut
local scrwh,scrht = scr:width(),scr:height() -- Stores screen dimensions

function on.construction()

    -- Sets background colour
    scr:setBackgroundColor(bgcolor)

    -- Activates copy/cut/paste functionality
    toolpalette.enableCopy(true)
    toolpalette.enableCut(true)
    toolpalette.enablePaste(true)

    -- Defines editor boxes variabels, var = iobox(ID,"label text",number base,line number)
    iobin = iobox(1,"Bin: ",2,1)
    iooct = iobox(2,"Oct: ",8,2)
    iodec = iobox(3,"Dec: ",10,3)
    iohex = iobox(4,"Hex: ",16,4)

end

function on.resize()

    -- Fetches and stores new screen dimensions when window resizes
    scrwh,scrht = scr:width(),scr:height()

    -- Checks if program running on a CAS calculator
    isCAS = not not math.evalStr("?")

    -- Adjusts font size to screen size.
    if scrwh >= 318 then
        fnthdg = fnthdgset*scrwh/318
        fntbody = fntbodyset*scrwh/318
    else --Sets minimum font to 7
        fnthdg = 7
        fntbody = 7
    end

    -- Prints editor boxes to above defined variabels
    iobin:ioeditor()
    iooct:ioeditor()
    iodec:ioeditor()
    iohex:ioeditor()

    -- Makes border remain blue in active box
    local setfocus = 1 -- Used to set focus in dec I/O box
    for i = 1,4 do -- Tracks which input box has focus
        if ioidtable[i]:hasFocus() == true then
            ioidtable[i]:setBorderColor(brdcoloract)
            setfocus = 0
        end
    end
    if setfocus == 1 then -- Makes dec I/O box active at launch and if no other input boxes focus
        ioidtable[3]:setFocus()
        ioidtable[3]:setBorderColor(brdcoloract)
    end

end

function on.paint(gc)

    -- Prints labels to above defined editor boxes
    iobin:lblpaint(gc)
    iooct:lblpaint(gc)
    iodec:lblpaint(gc)
    iohex:lblpaint(gc)

    -- Prints app version at bottom of page
    gc:setFont("sansserif","r",7)
    gc:setColorRGB(0x000000)
    gc:drawString("Version: "..appversion,0,scrht,"bottom")

    -- Prints heading
    gc:setFont("sansserif","b",fnthdg) -- Heading font
    gc:setColorRGB(0x000000)
    local hdgwh,hdght = gc:getStringWidth(lblhdg),gc:getStringHeight(lblhdg) -- Fetches heading dimensions
    if scrht/scrwh < 0.65 or scrht/scrwh > 0.69 or scrht < 212 or scrwh < 318 then -- Prints warning for incorrect screen split
        gc:setColorRGB(errorcolor)
        gc:drawString("Screen ratio not supported!",0,0,"top")
    elseif isCAS == false then -- Prints warning if calculator is not CAS
        gc:setColorRGB(errorcolor)
        gc:drawString("Calculator not supported!",0,0,"top")    
    else
        gc:drawString(lblhdg,scrwh/2-hdgwh/2,0,"top") -- Prints heading
    end
    gc:setPen("thin", "dotted")
    gc:drawLine(0,hdght,scrwh,hdght) -- Draws line below heading

end

-- Checks heading string size outside of paint function
function gethdgsize(str,gc)

    gc:setFont("sansserif","b",fnthdg)
    local strwh,strht = gc:getStringWidth(str),gc:getStringHeight(str)
    return strwh,strht

end

-- Checks body string size outside of paint function
function getbodysize(str,gc)

    gc:setFont("sansserif","b",fntbody)
    local strwh,strht = gc:getStringWidth(str),gc:getStringHeight(str)
    return strwh,strht

end

iobox = class()

function iobox:init(id,lbl,base,line) -- (ID,"label text",number base,line number)

    self.id = id
    self.lbl = lbl
    self.base = base
    self.line = line
    self.boxid = D2Editor.newRichText() -- Generates iobox
    ioidtable[id] = self.boxid -- Stores iobox unique ID

end

function iobox:lblpaint(gc)

    -- Fetches string sizes of heading and labels
    local lblwh,lblht = platform.withGC(getbodysize,self.lbl)
    local hdgwh,hdght = platform.withGC(gethdgsize,lblhdg)

    local scrht = scrht-hdght -- Removes heading from line equations

    -- Properties for labels
    gc:setFont("sansserif","b",fntbody)
    gc:setColorRGB(0x000000)
    gc:drawString(self.lbl,padding*scrwh/318,hdght+padding*scrwh/318+scrht*(self.line-1)/lines,"top")

end

function iobox:ioeditor()

    function converter()

        local boxexp = self.boxid:getExpression() -- Fetsches I/O boxes input data
        local srcisplit,srcichk,srcitbl = 0,0,{} -- Variabels for organizing  integer part
        local srcfsplit,srcfchk,srcftbl = 0,0,{} -- Variabels for organizing source number fraction part
        local numdec,inumdec,fnumdec = 0,0,0 -- Variabels for organizing intermediate decimal number
        local trgtint2,trgtint8,trgtint10,trgtint16 = 0,0,0,0 -- Target numbers integers
        local trgtfrc2,trgtfrc8,trgtfrc10,trgtfrc16 = 0,0,0,0 -- Target numbers fractions
        local trgtnumbin,trgtnumoct,trgtnumdec,trgtnumhex = "","","","" -- Final results to be displayd
        
        -- Clears all I/O boxes when active I/O box is empty 
        if boxexp == nil then
            for i = 1,4 do
                ioidtable[i]:setText("")
            end
        end
        
        if boxexp ~= nil then

            -- Removes - minus and (-) negative sign from string
            boxexp = boxexp:gsub(string.uchar(8722),"")
            boxexp = boxexp:gsub("-","")

            -- Part 1, collect, organize and split source number
            srcisplit = math.eval("isplit(\""..boxexp.."\")") -- Interger part of source number
            srcichk = tonumber(srcisplit,self.base) -- Verifies if integer is a valid (base n) number
            srcfsplit = math.eval("fsplit(\""..boxexp.."\")") -- Fraction part of source number
            srcfchk = tonumber(srcfsplit,self.base) -- Verifies if fraction is a valid (base n) number
            if type(srcichk) == "number" then -- Generates a digit table of source integer
                srcitbl = math.eval("itblsplit(\""..srcisplit.."\")")
            else
                scritbl = {0}
            end
            if type(srcfchk) == "number" then -- Generates a digit table of source fraction
                srcftbl = math.eval("ftblsplit(\""..srcfsplit.."\")")
            else
                srcftbl = {0}
            end

            -- Part 2, convert source number to a decimal number
            if type(srcichk) == "number" and type(srcfchk) == "number" then
                var.store("srcitbl",srcitbl) -- Stores tables to be used by TI math engine
                var.store("srcftbl",srcftbl)
                numdec = math.eval("basetodec(srcitbl,srcftbl,"..self.base..")") -- Decimal number
                inumdec = math.eval("isplit(\""..numdec.."\")") -- Decimal integer part of number
                fnumdec = math.eval("fsplit(\""..numdec.."\")") -- Decimal fraction part of number
            end

            -- Part 3, convert decimal number to target numbers
            if type(numdec) == "number" and type(inumdec) == "string" then
                trgtint2 = math.evalStr("idectoibase(\""..inumdec.."\",2)") -- Target bin integer
                trgtfrc2 = math.evalStr("fdectofbase("..numdec..",2)") -- Target bin fraction
                trgtint8 = math.evalStr("idectoibase(\""..inumdec.."\",8)") -- Target oct integer
                trgtfrc8 = math.evalStr("fdectofbase("..numdec..",8)") -- Target oct fraction
                trgtint10 = math.evalStr("idectoibase(\""..inumdec.."\",10)") -- Target dec integer
                trgtfrc10 = math.evalStr("fdectofbase("..numdec..",10)") -- Target dec fraction
                trgtint16 = math.evalStr("idectoibase(\""..inumdec.."\",16)") -- Target hex integer
                trgtfrc16 = math.evalStr("fdectofbase("..numdec..",16)") -- Target hex fraction
            end

            -- Part 4, Convert target numbers to strings
            if numdec-math.floor(numdec) > 0 then -- Final result contains fractions
                trgtnumbin = string.gsub(trgtint2,"\"","").."."..string.gsub(trgtfrc2,"\"","")
                trgtnumoct = string.gsub(trgtint8,"\"","").."."..string.gsub(trgtfrc8,"\"","")
                trgtnumdec = string.gsub(trgtint10,"\"","").."."..string.gsub(trgtfrc10,"\"","")
                trgtnumhex = string.gsub(trgtint16,"\"","").."."..string.gsub(trgtfrc16,"\"","")
            elseif numdec ~= 0 then -- Final result is enteger only
                trgtnumbin = string.gsub(trgtint2,"\"","")
                trgtnumoct = string.gsub(trgtint8,"\"","")
                trgtnumdec = string.gsub(trgtint10,"\"","")
                trgtnumhex = string.gsub(trgtint16,"\"","")
            else -- Something is wrong
                trgtnumbin = "0"
                trgtnumoct = "0"
                trgtnumdec = "0"
                trgtnumhex = "0"
            end

            -- Part 5, Diplays final results
            if ioidtable[1]:hasFocus() then -- Bin input
                ioidtable[2]:setExpression(trgtnumoct) -- Oct output
                ioidtable[3]:setExpression(trgtnumdec) -- Dec output
                ioidtable[4]:setExpression(trgtnumhex) -- Hex output
            end
            if ioidtable[2]:hasFocus() then -- Oct input
                ioidtable[1]:setExpression(trgtnumbin) -- Bin output
                ioidtable[3]:setExpression(trgtnumdec) -- Dec output
                ioidtable[4]:setExpression(trgtnumhex) -- Hex output
            end
            if ioidtable[3]:hasFocus() then -- Dec input
                ioidtable[1]:setExpression(trgtnumbin) -- Bin output
                ioidtable[2]:setExpression(trgtnumoct) -- Oct output
                ioidtable[4]:setExpression(trgtnumhex) -- Hex output
            end
            if ioidtable[4]:hasFocus() then -- Hex input
                ioidtable[1]:setExpression(trgtnumbin) -- Bin output
                ioidtable[2]:setExpression(trgtnumoct) -- Oct output
                ioidtable[3]:setExpression(trgtnumdec) -- Dec output
            end
        end
    end

    -- Fetches string sizes of heading and labels
    local lblwh,lblht = platform.withGC(getbodysize,"Hex: ") -- "Hex: " used instead of self.lbl as reference as it the longest string
    local hdgwh,hdght = platform.withGC(gethdgsize,lblhdg)

    local scrht = scrht-hdght -- Removes heading from line equations

    -- Properties for input boxes
    self.boxid:setMainFont("sansserif","r",fntbody)
    self.boxid:move(padding*scrwh/318+lblwh,hdght+padding*scrwh/318+(scrht*(self.line-1))/lines)
    self.boxid:resize(scrwh-lblwh-2*padding*scrwh/318,(27+2*(fntbody-10))) -- Height formula concluded from different screen size tests
    self.boxid:setBorder(1) -- Border = 1 px
    self.boxid:setBorderColor(brdcolorinact) -- Default border color (grey)
    self.boxid:setColorable(false) -- Disables manual colors
    self.boxid:setWordWrapWidth(-1) -- Disables word wrap
    self.boxid:setReadOnly(false)
    self.boxid:setDisable2DinRT(true) -- Disables mathprint
    self.boxid:setTextChangeListener(converter) -- Checks function converter() during writing
    self.boxid:registerFilter { -- Keyboard/mouse actions, Start
        tabKey = function() -- Moves curser to next input box
            if self.id >= 1 and self.id <= 3 then
                self.boxid:setBorderColor(brdcolorinact)
                ioidtable[self.id+1]:setBorderColor(brdcoloract)
                ioidtable[self.id+1]:setFocus()
                return true
            else
                self.boxid:setBorderColor(brdcolorinact)
                ioidtable[1]:setBorderColor(brdcoloract)
                ioidtable[1]:setFocus()
                return true
            end
        end,
        backtabKey = function() -- Moves curser to previous input box
            if self.id >= 2 and self.id <= 4 then
                self.boxid:setBorderColor(brdcolorinact)
                ioidtable[self.id-1]:setBorderColor(brdcoloract)
                ioidtable[self.id-1]:setFocus()
                return true
            else
                self.boxid:setBorderColor(brdcolorinact)
                ioidtable[4]:setBorderColor(brdcoloract)
                ioidtable[4]:setFocus()
                return true
            end
        end,
        arrowDown = function() -- Moves curser to next input box
            if self.id >= 1 and self.id <= 3 then
                self.boxid:setBorderColor(brdcolorinact)
                ioidtable[self.id+1]:setBorderColor(brdcoloract)
                ioidtable[self.id+1]:setFocus()
                return true
            else
                self.boxid:setBorderColor(brdcolorinact)
                ioidtable[1]:setBorderColor(brdcoloract)
                ioidtable[1]:setFocus()
                return true
            end
        end,
        arrowUp = function() -- Moves curser to previous input box
            if self.id >= 2 and self.id <= 4 then
                self.boxid:setBorderColor(brdcolorinact)
                ioidtable[self.id-1]:setBorderColor(brdcoloract)
                ioidtable[self.id-1]:setFocus()
                return true
            else
                self.boxid:setBorderColor(brdcolorinact)
                ioidtable[4]:setBorderColor(brdcoloract)
                ioidtable[4]:setFocus()
                return true
            end
        end,
        escapeKey = function() -- Clears all values when Esc pressed
            reset() -- Command is sent to reset function
            return true
        end,
        enterKey = function() -- Moves curser to next input box
            if self.id >= 1 and self.id <= 3 then
                self.boxid:setBorderColor(brdcolorinact)
                ioidtable[self.id+1]:setBorderColor(brdcoloract)
                ioidtable[self.id+1]:setFocus()
                return true
            else
                self.boxid:setBorderColor(brdcolorinact)
                ioidtable[1]:setBorderColor(brdcoloract)
                ioidtable[1]:setFocus()
                return true
            end
        end,
        returnKey = function() -- Moves curser to next input box
            if self.id >= 1 and self.id <= 3 then
                self.boxid:setBorderColor(brdcolorinact)
                ioidtable[self.id+1]:setBorderColor(brdcoloract)
                ioidtable[self.id+1]:setFocus()
                return true
            else
                self.boxid:setBorderColor(brdcolorinact)
                ioidtable[1]:setBorderColor(brdcoloract)
                ioidtable[1]:setFocus()
                return true
            end
        end,
        mouseDown = function() -- Moves curser to clicked input box
            if ioidtable[self.id]:hasFocus() == false then
                for i = 1,4 do -- Makes all I/O box borders grey
                    ioidtable[i]:setBorderColor(brdcolorinact)
                end
                ioidtable[self.id]:setBorderColor(brdcoloract) -- Makes active I/O box blue
            end
            return false -- Must be false, otherwise not possible to select text with mouse
        end
    } -- Keyboard/mouse actions, End

end

-- Empties all I/O boxes
function reset()

    for i = 1,4 do
        ioidtable[i]:setText("")
    end

end