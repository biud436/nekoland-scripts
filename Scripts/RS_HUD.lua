-- =========================================
-- # Name : RS_HUD
-- # Author : biud436
-- # Script Calls (Client only) : 
-- 
-- In the script, You can change x and y coordinates, as follows.
--  HUD.setX(n)
--  HUD.setY(n)
-- 
-- This function allows you to change the 'visible' property of HUD.
--  HUD.setVisible(true)
--  HUD.setVisible(false)
--  HUD.toggleVisible()
--
-- # Version Log
-- 2019.04.20 (v1.0.0) - First Release.
-- 2019.04.21 (v1.0.1) - 공격키 및 패드가 클릭되지 않는 현상 수정.
-- 2019.04.22 (v1.0.2) - 버프 아이콘이 가려지지 않게 스케일 조정
-- 2019.05.20 (v1.0.3) - 최대 레벨 관련 버그 수정
-- 2020.03.08 (v1.0.4) : 
-- - Fixed the bug that is not working in Nekoland v2.45 or more.
-- - Removed buff icon.
-- =========================================

-- 스케일 조정을 위한 Rect 생성
function ScaleRECT(x, y, width, height, scaleX, scaleY)
    
    local self = Rect(x, y, width, height)
    
    local scaleX = scaleX
    local scaleY = scaleY
    
    self.x = x * scaleX
    self.y = y * scaleY
    self.width = width * scaleX
    self.height = height * scaleY
    
    return self
    
end

-- 텍스트 그림자를 위한 Rect 생성
function ShadowRECT(rect)
    
    local self = Rect(rect.x + 1, rect.y + 1, rect.width, rect.height)
    
    return self
    
end

-- 테두리 설정
function OutlineText(text, rect)
    
    local body = Text("", rect)
    local self = {}
    
    table.insert(self, body)
    
    local frontColor = Color(255, 255, 100, 255)
    local outlineColor = Color(10, 10, 10, 200)
    
    for i=-1, 1 do
        for j=-1, 1 do
            local text = Text(text, Rect(rect.x + i, rect.y + j, rect.width, rect.height))
            text.color = outlineColor
            table.insert(self, text)
            body.AddChild(text)
        end
    end
    
    local frontText = Text(text, rect)
    frontText.color = frontColor
    table.insert(self, frontText)
    body.AddChild(frontText)
    
    return self
    
end

-- HUD 관리 객체
local function HUDLayerImpl(scaleX, scaleY)
    
    local self = {}
    
    -- 프레임 업데이트 주기
    self.REFRESH_TIME = 15
    
    -- 스케일
    self.scaleX = scaleX
    self.scaleY = scaleY
    
    -- ON/OFF 
    self.visible = true
    
    -- RECT 생성
    local RECT = {
        BACKGROUND = ScaleRECT(0, 0, 300, 52, self.scaleX, self.scaleY),
        HP = ScaleRECT(148, 5, 120, 20, self.scaleX, self.scaleY),
        MP = ScaleRECT(148, 29, 120, 20, self.scaleX, self.scaleY),
        EXP = ScaleRECT(72, 48, 195, 4, self.scaleX, self.scaleY),
        HP_TEXT = ScaleRECT(148, 5, 120, 20, self.scaleX, self.scaleY),
        MP_TEXT = ScaleRECT(148, 29, 120, 20, self.scaleX, self.scaleY),
        EXP_TEXT = ScaleRECT(72, 45, 195, 12, self.scaleX, self.scaleY),
        LEVEL_TEXT = ScaleRECT(92, 25, 32, 20, self.scaleX, self.scaleY),
        NAME_TEXT = ScaleRECT(18, 0, 100, 32, self.scaleX, self.scaleY)
    }
    
    -- 폰트 크기 설정
    local fontScale = math.min(self.scaleX, self.scaleY)
    local fontSize = 10 * fontScale
    local levelFontSize = 16 * fontScale
    local nameFontSize = 16 *  fontScale
    
    -- 최대 값 테스트 상수
    local MAX_VALUE = 2147483647
    
    -- 검은색
    local blackColor = Color(0, 0, 0, 255)
    
    -- 위치 변수
    self.POSITION = {
        X = 0,
        Y = 0
    }
    
    -- 자식 객체 테이블
    self.children = {}
    
    -- 생성
    function self.create()
        
        Client.ShowTopUI(false) -- 메인 패널 숨김 처리
        
        self.prepareLayer()     -- 패널 준비
        self.prepareImage()     -- 이미지 생성
        self.prepareText()      -- 텍스트 생성
        self.refresh()          -- 갱신
    end
    
    -- 패널 준비
    function self.prepareLayer()
        self.hud = Panel();   
        self.hud.showOnTop = true
        self.hud.x = self.POSITION.X
        self.hud.y = self.POSITION.Y    
        self.hud.width = RECT.BACKGROUND.width
        self.hud.height = RECT.BACKGROUND.height
    end
    
    -- 이미지 생성
    function self.prepareImage()
        self.background = Image("Pictures/hud_window_empty.png", RECT.BACKGROUND)
        
        -- Get the app version.
        local version = tonumber(Client.appVersion)
        if version >= 2.45 then
            self.background.imageType = 3 -- it must set 3 if the game will be going to work.
        end
        
        self.hp = Image("Pictures/hp.png", RECT.HP)
        self.mp = Image("Pictures/mp.png", RECT.MP)
        self.exp = Image("Pictures/exr.png", RECT.EXP)
    end
    
    -- 텍스트 생성
    function self.prepareText()
        self.hpTextShadow = Text("", ShadowRECT(RECT.HP_TEXT))
        self.hpText = Text("", RECT.HP_TEXT)
        self.mpTextShadow = Text("", ShadowRECT(RECT.MP_TEXT))
        self.mpText = Text("", RECT.MP_TEXT)
        self.expTextShadow = Text("", ShadowRECT(RECT.EXP_TEXT))
        self.expText = Text("", RECT.EXP_TEXT)
        self.levelTextShadow = Text("", ShadowRECT(RECT.LEVEL_TEXT))
        self.levelText = Text("", RECT.LEVEL_TEXT)
        self.nameText = OutlineText("", RECT.NAME_TEXT)
    end
    
    -- 화면에 이미지 및 텍스트 표시
    function self.refresh()
        
        for k, child in pairs(self.children) do
            if child then 
                self.hud.RemoveChild(child)
            end
        end 
        
        self.children = {
            self.background,
            self.hp,
            self.mp,
            self.exp,
            self.hpTextShadow,
            self.hpText,
            self.mpTextShadow,
            self.mpText,
            self.expTextShadow,
            self.expText,
            self.levelTextShadow,
            self.levelText,
            self.nameText[1]
        }
        
        for k, child in pairs(self.children) do
            child.showOnTop = false
            self.hud.AddChild(child)
        end       
        
    end
    
    -- 텍스트 및 텍스트 그림자 묘화
    function self.makeText(objectName, size, text)
        local shadow = self[objectName.."Shadow"]
        local body = self[objectName]
        self.drawShadow(shadow, size, text)
        self.drawText(body, size, text)
    end
    
    function self.makeOutlineText(_object, size, text)
        for i=2, #_object do
            if _object[i] ~= nil then
                _object[i].text = text
                _object[i].textSize = size
                _object[i].textAlign = 4
            end 
        end
    end
    
    -- 텍스트 묘화
    function self.drawText(_object, size, text)
        _object.textSize = size
        _object.text = text
        _object.textAlign = 4
        _object.pivotY = 0
    end
    
    -- 텍스트 그림자 묘화
    function self.drawShadow(_object, size, text)
        _object.textSize = size
        _object.text = text
        _object.textAlign = 4
        _object.pivotY = 0
        _object.color = blackColor
    end
    
    -- 위치 업데이트
    function self.updatePosition()
        self.hud.x = self.POSITION.X
        self.hud.y = self.POSITION.Y
    end
    
    -- 세 자릿수마다 글자 자르기
    -- Refer to @link : https://stackoverflow.com/a/10992898
    function self.format_int(number)
        
        local i, j, minus, int, fraction = tostring(number):find('([-]?)(%d+)([.]?%d*)')
        
        -- reverse the int-string and append a comma to all blocks of 3 digits
        int = int:reverse():gsub("(%d%d%d)", "%1,")
        
        -- reverse the int-string back remove an optional comma and put the 
        -- optional minus and fractional part back
        return minus .. int:reverse():gsub("^,", "") .. fraction
    end    
    
    -- 텍스트 포맷
    function self.format(current, max)
        local s = string.format("%s / %s", self.format_int(current), self.format_int(max))
        return s
    end
    
    -- https://stackoverflow.com/a/25449599	
    function self.split(str, sep)
        local result = {}
        local regex = ("([^%s]+)"):format(sep)
        for each in str:gmatch(regex) do
            table.insert(result, each)
        end
        return result
    end
    
    -- 프레임 업데이트
    function self.update()
        
        self.hud.visible = self.visible
        
        local player = Client.myPlayerUnit
        
        -- 플레이어가 없는 경우
        if not player then
            return
        end
        
        local hp = player.hp
        local mhp = player.maxHP
        local mp = player.mp
        local mmp = player.maxMP
        local exp = player.exp
        local mexp = player.maxEXP
        local level = player.level
        local name = player.name
        
        local hpRate = (hp / mhp) * RECT.HP.width
        local mpRate = (mp / mmp) * RECT.MP.width
        local expRate = 0.0
        
        local is_max_level = (mexp == 0)
        
        if is_max_level then
            expRate = RECT.EXP.width
        else
            expRate = (exp / mexp) * RECT.EXP.width
        end
        
        self.hp.rect = Rect(RECT.HP.x, RECT.HP.y, hpRate,  RECT.HP.height)
        self.mp.rect = Rect(RECT.MP.x, RECT.MP.y, mpRate, RECT.MP.height)
        self.exp.rect = Rect(RECT.EXP.x, RECT.EXP.y, expRate, RECT.EXP.height)
        
        self.makeText("hpText", fontSize, self.format(hp, mhp))
        self.makeText("mpText", fontSize, self.format(mp, mmp))
        
        if is_max_level then
            self.makeText("expText", fontSize, "------- / -------")            
        else
            self.makeText("expText", fontSize, self.format(exp, mexp))
        end
        
        self.makeText("levelText", levelFontSize, string.format("%d", level))        
        self.makeOutlineText(self.nameText, nameFontSize, name)
        
        self.updatePosition()
        
    end
    
    function self.start()
        Client.onTick.Add(self.update, self.REFRESH_TIME)
    end
    
    self.create()
    
    return self
    
end

-- 인자 값은 스케일X, 스케일Y
-- 채팅창에 가려지므로 스케일 조정이 필요하였음.
HUDLayer = HUDLayerImpl(0.8, 0.8)
HUDLayer.start()

-- Client Functions...
HUD = {}

-- HUD Y 좌표 설정
HUD.setX = function (n)
    HUDLayer.POSITION.X = n
end

-- HUD X 좌표 설정
HUD.setY = function (n)
    HUDLayer.POSITION.Y = n
end

-- HUD ON/OFF 설정
HUD.setVisible = function(value)
    HUDLayer.visible = value
end

-- HUD ON/OFF 토글
HUD.toggleVisible = function()
    HUDLayer.visible = not HUDLayer.visible
end