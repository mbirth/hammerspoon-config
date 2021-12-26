--- === BBC Sounds ===
---
--- Implementation of https://github.com/moomerman/Sounds in Hammerspoon.

local obj = {}
obj.__index = obj


obj.name = "BBC Sounds"
obj.version = "0.1"
obj.author = "Markus Birth <markus@birth-online.de>"

function obj:init()
    -- prepare variable for menubar item/icon
    self.mbIcon = nil
    -- prepare variable for media key handler, but don't assign just yet
    self.eventTap = nil
    -- prepare logger
    self.log = hs.logger.new(self.name, "verbose")
end

function obj:start()
    self.log.v('Start')
    -- create global webview to keep it running/playing the whole time
    self.webView = hs.webview.new()
    self.webView:allowNewWindows(false)
    self.webView:windowCallback(self.webViewHide)
    self.webView:navigationCallback(self.webViewMods)
    self.webView:url("https://www.bbc.co.uk/sounds/play/live:bbc_radio_one_dance")
    -- self.webView:magnification(1)

    -- load menubar icon and prepare menubar item
    local iconImage = hs.image.imageFromPath("Spoons/BbcSounds.spoon/icon_16.png")
    self.mbIcon = hs.menubar.new()
    self.mbIcon:setIcon(iconImage)
    self.mbIcon:setClickCallback(self.showHide)

    -- create eventtap for handling media keys
    self.eventTap = hs.eventtap.new({hs.eventtap.event.types.systemDefined}, self.handleMediaKey)
    self.eventTap:start()
    self.log.v('Startup complete.')
    return self
end

function obj.handleMediaKey(event)
    local delete = false
    
    local data = event:systemKey()
    
    if data["down"] == false or data["repeat"] == true then
        obj.log.v("Key event: " .. data["key"])
        if data["key"] == "PLAY" then
            -- Handled automatically by WebView
            -- obj.togglePlay()
            delete = true
        elseif data["key"] == "NEXT" then
            obj.goLive()
            delete = true
        elseif data["key"] == "PREVIOUS" then
            obj.goStart()
            delete = true
        end
    end
    
    return delete, nil
end

function obj.webViewHide(action, webview, state)
    obj.log.v("webViewHide: " .. action)
    if action == "focusChange" and not state then
        obj.webView:hide(0.3)
    end
end

function obj.webViewMods(action, webView, navID, error)
    if action == "didFinishNavigation" then
        obj.hideHeader()
    end
end

function obj.hideHeader()
    -- Hide top navbar on BBC page
    obj.webView:evaluateJavaScript("document.getElementById(\"orb-banner\").style.display = \"none\"")
end

function obj.togglePlay()
    obj.webView:evaluateJavaScript("document.getElementById(\"smphtml5iframesmp-wrapper\").contentWindow.document.getElementById(\"p_audioui_playpause\").click()")
end

function obj.goLive()
    obj.webView:evaluateJavaScript("document.getElementById(\"smphtml5iframesmp-wrapper\").contentWindow.document.getElementById(\"p_audioui_toLiveButton\").click()")
end

function obj.goStart()
    obj.webView:evaluateJavaScript("document.getElementById(\"smphtml5iframesmp-wrapper\").contentWindow.document.getElementById(\"p_audioui_backToStartButton\").click()")
end

function obj.showHide(modifierKeys)
    if obj.webView:isVisible() then
        obj.webView:hide(0.3)
    else
        -- get position of menubar item and move webview there, then show it
        local mbPos = obj.mbIcon:frame()
        mbPos.w = 900
        mbPos.h = 716
        -- check if out of bounds
        local desktopFrame = hs.window.desktop():frame()
        if mbPos.x + mbPos.w > desktopFrame.w then
            obj.log.w("webView width larger than desktop. Adjusting position.")
            mbPos.x = desktopFrame.w - mbPos.w
        end
        if mbPos.y + mbPos.h > desktopFrame.h then
            obj.log.w("webView height larger than desktop. Adjusting position.")
            mbPos.y = desktopFrame.h - mbPos.h
        end
        obj.webView:frame(mbPos)
        obj.webView:show(0.3)
        obj.webView:bringToFront()
    end
end

function obj:stop()
    self.eventTap:stop()
    self.webView:delete()
    self.mbIcon:delete()
end


return obj
