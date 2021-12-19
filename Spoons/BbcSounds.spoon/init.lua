--- === BBC Sounds ===
---
--- Implementation of https://github.com/moomerman/Sounds in Hammerspoon.

local obj = {}
obj.__index = obj


obj.name = "BBC Sounds"
obj.version = "0.1"
obj.author = "Markus Birth <markus@birth-online.de>"

function obj:init()
    self.webView = hs.webview.new({x=0, y=0, w=900, h=716})
    self.eventTap = nil
    self.log = hs.logger.new(self.name, "verbose")
end

function obj:start()
    self.log.v('Start')
    self.webView:allowNewWindows(false)
    self.webView:navigationCallback(self.webViewMods)
    -- self.webView:magnification(1)
    self.webView:url("https://www.bbc.co.uk/sounds/play/live:bbc_radio_one_dance")
    local iconImage = hs.image.imageFromPath("Spoons/BbcSounds.spoon/icon_16.png")
    self.mbIcon = hs.menubar.new()
    self.mbIcon:setIcon(iconImage)
    self.mbIcon:setClickCallback(self.showHide)
    local mbPos = self.mbIcon:frame()
    local newPos = hs.geometry.point(mbPos.y, mbPos.x)
    self.webView:topLeft(newPos)
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

function obj.webViewMods(action, webView, navID, error)
    if action == "didFinishNavigation" then
        obj.hideHeader()
    end
end

function obj.hideHeader()
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
        obj.webView:show(0.3)
        obj.webView:bringToFront(true)
    end
end

function obj:stop()
    self.eventTap:stop()
    self.webView:delete()
    self.mbIcon:delete()
end


return obj
