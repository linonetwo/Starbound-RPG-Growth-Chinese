require "/scripts/util.lua"
require "/scripts/vec2.lua"
require "/scripts/rect.lua"
require "/scripts/poly.lua"
require "/scripts/drawingutil.lua"
-- engine callbacks
function init()
  --View:init()
  
  self.clickEvents = {}
  self.state = FSM:new()
  self.state:set(splashScreenState)
  self.system = celestial.currentSystem()
  self.pane = pane
  player.addCurrency("skillbookopen", 1)
  --initiating level and xp
  self.xp = player.currency("experienceorb")
  self.level = player.currency("currentlevel")
  self.mastery = player.currency("masterypoint")
  --Mastery Conversion: 10000 Experience = 1 Mastery!!
  --initiating stats
  updateStats()
  self.classTo = 0
  self.class = player.currency("classtype")
    --[[
    0: No Class
    1: Knight
    2: Wizard
    3: Ninja
    4: Soldier
    5: Rogue
    6: Explorer
    ]]
  self.specTo = 0
  self.spec = player.currency("spectype")
    --[[
    ]]
  self.profTo = 0
  self.profession = player.currency("proftype")
    --[[
    ]]
  self.affinityTo = 0
  self.affinity = player.currency("affinitytype")
  --[[
    0: No Affinity
    1: Flame
    2: Venom
    3: Frost
    4: Shock
    5: Infernal
    6: Toxic
    7: Cryo 
    8: Arc
    ]]
    self.quests = {"ivrpgaegisquest", "ivrpgnovaquest", "ivrpgaetherquest", "ivrpgversaquest", "ivrpgsiphonquest", "ivrpgspiraquest"}
    self.classWeaponText = {
      "庇护者是一把可以当盾牌使用的双手大剑. 使用完美格挡触可以发无畏战士的职业能力. 生灵庇护者完美格挡可以恢复生命值.",
      "新星是一根可以切换法术元素的法杖. 可以在新星,火焰,电弧和寒冰之间循环切换. 新星可以削弱敌人. 奥义超新星会使击杀的敌人爆炸.", 
      "虚灵镖是一枚必定导致出血的暗器. 猩红虚灵镖可以穿透墙壁自动追踪敌人. 追踪能力和持续时间与敏捷成正比.", 
      "DGN战斗步枪有两种射击模式. 使用狙击和霰射进行持续射击可以增加伤害. MKIII的子弹每反弹一次都会增加伤害.", 
      "虹吸爪的终结技可以造成巨大伤害. 终结技:撕裂者可以恢复饱食度并使目标出血. 孢子可以恢复自身生命值并使目标中毒. 电弧可以回复能量并使目标触电.", 
      "RPT钻机原型是一个强劲的挖掘工具,速度快,无限用. RPT开拓者钻头可以吸取物品. 在使用RPT探索者钻头时按下shift会直接破坏方块不掉落,但会在破坏方块时回复能量."
    }
    --initiating possible Level Change (thus, level currency should not be used in another script!!!)
    self.challengeText = {
      {
        {"击败500个4级或更高级别的敌人.", 500},
        {"击败350个5级或更高级别的敌人.", 350},
        {"击败火凤凰.", 1},
        {"击败埃尔丘斯而不受伤害.", 1}
      },
      {
        {"击败400个6级或更高级别的敌人.", 400},
        {"击败骨龙.", 1},
        {"获得并使用5个升级模块.", 5}
      },
      {
        {"击败400个遗迹级别或更高级别的敌人.", 400},
        {"击败2个遗迹守护者.", 2},
        {"击败毁灭之心.", 1},
        {"毫发无损的击败毁灭之心.", 1},
        {"-------------------------------------------------------. <- Period is max length!"}
      }
    }

    self.hardcoreWeaponText = {
      "当前可以装备所有类型的武器.",
      "无畏战士职业武器:^green;\n双手近战武器\n单手近战武器 ^reset;^red;\n(不包括拳击武器&鞭子)\n\n无畏战士无法双持武器.",
      "奥术法师职业武器:^green;\n棍棒\n法杖\n匕首 ^red;(仅副手)^reset;\n^green;能源之眼, 邪恶之眼, 磁电魔球.\n\n奥术法师可以双持武器.^reset;",
      "边缘刺客职业武器:^green;\n单手近战武器\n拳击武器&鞭\n弩&武士刀\n\n边缘刺客可以双持武器.^reset;",
      "太空陆战队职业武器:^green;\n双手远程武器.\n单手远程武器.\n\n^reset;^red;太空陆战队无法双持武器.\n太空陆战队无法使用魔杖.\n太空陆战队无法使用能源之眼.^reset;",
      "不法之徒职业武器:^green;\n单手近战武器.\n单手远程武器.\n拳击武器&鞭\n\n不法之徒可以双持武器.\n^reset;^red;不法之徒无法使用魔杖.^reset;",
      "星际探险家职业武器:^green;\n任何类型的武器\n\n星际探险家可以双持武器.^reset;"
    }

    self.textData = root.assetJson("/ivrpgtext.config")
    updateLevel()
end

function dismissed()
  player.consumeCurrency("skillbookopen", player.currency("skillbookopen"))
end

function update(dt)
  --if not world.sendEntityMessage(player.id(), "holdingSkillBook"):result() then
  if player.currency("skillbookopen") == 2 then
    self.pane.dismiss()
  end

  if player.currency("experienceorb") ~= self.xp then
    updateLevel()
    if widget.getChecked("bookTabs.2") then
      local checked = widget.getChecked("classlayout.techicon1") and 1 or (widget.getChecked("classlayout.techicon2") and 2 or (widget.getChecked("classlayout.techicon3") and 3 or (widget.getChecked("classlayout.techicon4") and 4 or 0))) 
      if checked ~= 0 then unlockTechVisible(("techicon" .. tostring(checked)), 2^(checked+1)) end
      updateClassWeapon()
    elseif widget.getChecked("bookTabs.3") then
      removeLayouts()
      changeToAffinities()
    elseif widget.getChecked("bookTabs.5") then
      changeToSpecialization()
    elseif widget.getChecked("bookTabs.6") then
      changeToProfession()
    elseif widget.getChecked("bookTabs.7") then
      changeToMastery()
    end
  end

  if player.currency("classtype") ~= self.class then
    self.class = player.currency("classtype")
    if widget.getChecked("bookTabs.2") then
      changeToClasses()
    elseif widget.getChecked("bookTabs.0") then
      changeToOverview()
    end
  end

  if player.currency("affinitytype") ~= self.affinity then
    self.affinity = player.currency("affinitytype")
    if widget.getChecked("bookTabs.3") then
      changeToAffinities()
    elseif widget.getChecked("bookTabs.0") then
      changeToOverview()
    end
  end

  if player.currency("masterypoint") ~= self.mastery then
    self.mastery = player.currency("masterypoint")
    if widget.getChecked("bookTabs.7") then
      changeToMastery()
    end
  end

  if status.statPositive("ivrpgmasteryunlocked") and widget.getChecked("bookTabs.7") then
    updateChallenges()
  end

  if widget.getChecked("bookTabs.8") then
    updateUpgradeTab()
  end

  updateStats()
  if widget.getChecked("bookTabs.4") then
    updateInfo()
  end
  --checkStatPoints()

  self.state:update(dt)
end

function updateBookTab()
  removeLayouts()
  if widget.getChecked("bookTabs.0") then
    changeToOverview()
  elseif widget.getChecked("bookTabs.1") then
    changeToStats()
  elseif widget.getChecked("bookTabs.2") then
    changeToClasses()
  elseif widget.getChecked("bookTabs.3") then
    changeToAffinities()
  elseif widget.getChecked("bookTabs.4") then
    changeToInfo()
  elseif widget.getChecked("bookTabs.5") then
    changeToSpecialization()
  elseif widget.getChecked("bookTabs.6") then
    changeToProfession()
  elseif widget.getChecked("bookTabs.7") then
    changeToMastery()
  elseif widget.getChecked("bookTabs.8") then
    changeToUpgrades()
  end
end

function updateLevel()
  self.xp = player.currency("experienceorb")
  if self.xp < 100 then
    player.addCurrency("experienceorb", 100)
  end
  self.level = player.currency("currentlevel")
  self.newLevel = math.floor(math.sqrt(self.xp/100))
  self.newLevel = self.newLevel >= 50 and 50 or self.newLevel
  if self.newLevel > self.level then
    addStatPoints(self.newLevel, self.level)
  elseif self.newLevel < self.level then
    player.consumeCurrency("currentlevel", self.level - self.newLevel)
  end
  self.level = player.currency("currentlevel")
  widget.setText("statslayout.statpointsleft", player.currency("statpoint"))
  updateStats()
  self.toNext = 2*self.level*100+100
  updateOverview(self.toNext)
  updateBottomBar(self.toNext)
end

function startingStats()
  player.addCurrency("strengthpoint",1)
  player.addCurrency("dexteritypoint",1)
  player.addCurrency("intelligencepoint",1)
  player.addCurrency("agilitypoint",1)
  player.addCurrency("endurancepoint",1)
  player.addCurrency("vitalitypoint",1)
  player.addCurrency("vigorpoint",1)
end

function addStatPoints(newLevel, oldLevel)
  player.addCurrency("currentlevel", newLevel - oldLevel)
  while newLevel > oldLevel do
    if oldLevel > 48 then
      player.addCurrency("statpoint", 4)
    elseif oldLevel > 38 then
      player.addCurrency("statpoint", 3)
    elseif oldLevel > 18 then
      player.addCurrency("statpoint", 2)
    elseif oldLevel > 0 then
      player.addCurrency("statpoint", 1)
    else
      startingStats()
    end
    oldLevel = oldLevel + 1
  end
end

function updateBottomBar(toNext)
  widget.setText("levelLabel", "等级 " .. tostring(self.level))
  if self.level == 50 then
    widget.setText("xpLabel","最高等级!")
    widget.setProgress("experiencebar",1)
  else
    widget.setText("xpLabel",tostring(math.floor((self.xp-self.level^2*100))) .. "/" .. tostring(toNext))
    widget.setProgress("experiencebar",(self.xp-self.level^2*100)/toNext)
  end
end

function updateOverview(toNext)
  widget.setText("overviewlayout.levellabel","等级 " .. tostring(self.level))
  if self.level == 50 then
    widget.setText("overviewlayout.xptglabel","下一级所需经验: N/A.")
    widget.setText("overviewlayout.xptotallabel","总经验: " .. tostring(self.xp))
  else
    widget.setText("overviewlayout.xptglabel","下一级所需经验: " .. tostring(toNext - (math.floor(self.xp-self.level^2*100))))
    widget.setText("overviewlayout.xptotallabel","总经验: " .. tostring(self.xp))
  end
  widget.setText("overviewlayout.statpointsremaining","可用属性点: " .. tostring(player.currency("statpoint")))

  if player.currency("classtype") == 0 then
    widget.setText("overviewlayout.classtitle","未选择职业")
    widget.setImage("overviewlayout.classicon","/objects/class/noclass.png")
    widget.setText("overviewlayout.hardcoretext","没有负面影响")
  elseif player.currency("classtype") == 1 then
    widget.setText("overviewlayout.classtitle","无畏战士")
    widget.setImage("overviewlayout.classicon","/objects/class/knight.png")
    widget.setText("overviewlayout.hardcoretext","-10% 速度\n-30% 跳跃高度\n-25% 最大能量")
  elseif player.currency("classtype") == 2 then
    widget.setText("overviewlayout.classtitle","奥术法师")
    widget.setImage("overviewlayout.classicon","/objects/class/wizard.png")
    widget.setText("overviewlayout.hardcoretext","-20% 速度\n-20% 跳跃高度\n-20% 物理抗性")
  elseif player.currency("classtype") == 3 then
    widget.setText("overviewlayout.classtitle","边缘刺客")
    widget.setImage("overviewlayout.classicon","/objects/class/ninja.png")
    widget.setText("overviewlayout.hardcoretext","-50% 最大生命值")
  elseif player.currency("classtype") == 4 then
    widget.setText("overviewlayout.classtitle","太空陆战队")
    widget.setImage("overviewlayout.classicon","/objects/class/soldier.png")
    widget.setText("overviewlayout.hardcoretext","-10% 跳跃高度\n-20% 状态抗性")
  elseif player.currency("classtype") == 5 then
    widget.setText("overviewlayout.classtitle","不法之徒")
    widget.setImage("overviewlayout.classicon","/objects/class/rogue.png")
    widget.setText("overviewlayout.hardcoretext","+20% 饱食度消耗\n-20% 最大生命值")
  elseif player.currency("classtype") == 6 then
    widget.setText("overviewlayout.classtitle","星际探险家")
    widget.setImage("overviewlayout.classicon","/objects/class/explorer.png")
    widget.setText("overviewlayout.hardcoretext","-25% 能量加成")
  end

  local affinity = player.currency("affinitytype")
  if affinity == 0 then
    widget.setText("overviewlayout.affinitytitle","无亲和力")
    widget.setImage("overviewlayout.affinityicon","/objects/class/noclass.png")
  elseif affinity == 1 then
    widget.setText("overviewlayout.affinitytitle","火焰")
    widget.setImage("overviewlayout.affinityicon","/objects/affinity/flame.png")
  elseif affinity == 2 then
    widget.setText("overviewlayout.affinitytitle","毒液")
    widget.setImage("overviewlayout.affinityicon","/objects/affinity/venom.png")
  elseif affinity == 3 then
    widget.setText("overviewlayout.affinitytitle","寒冰")
    widget.setImage("overviewlayout.affinityicon","/objects/affinity/frost.png")
  elseif affinity == 4 then
    widget.setText("overviewlayout.affinitytitle","冲击")
    widget.setImage("overviewlayout.affinityicon","/objects/affinity/shock.png")
  elseif affinity == 5 then
    widget.setText("overviewlayout.affinitytitle","地狱")
    widget.setImage("overviewlayout.affinityicon","/objects/affinity/flame.png")
  elseif affinity == 6 then
    widget.setText("overviewlayout.affinitytitle","中毒")
    widget.setImage("overviewlayout.affinityicon","/objects/affinity/venom.png")
  elseif affinity == 7 then
    widget.setText("overviewlayout.affinitytitle","低温")
    widget.setImage("overviewlayout.affinityicon","/objects/affinity/frost.png")
  elseif affinity == 8 then
    widget.setText("overviewlayout.affinitytitle"," 电弧")
    widget.setImage("overviewlayout.affinityicon","/objects/affinity/shock.png")
  end

  if status.statPositive("ivrpghardcore") then
    widget.setText("overviewlayout.hardcoretoggletext", "启用")
    widget.setVisible("overviewlayout.hardcoretext", true)
    widget.setVisible("overviewlayout.hardcoreweapontext", true)
  else
    widget.setText("overviewlayout.hardcoretoggletext", "关闭")
    widget.setVisible("overviewlayout.hardcoretext", false)
    widget.setVisible("overviewlayout.hardcoreweapontext", false)
  end

end

function updateClassTab()
  if player.currency("classtype") == 0 then
    widget.setText("classlayout.classtitle","未选择职业")
    widget.setImage("classlayout.classicon","/objects/class/noclass.png")
    widget.setImage("classlayout.effecticon","/objects/class/noclassicon.png")
    widget.setImage("classlayout.effecticon2","/objects/class/noclassicon.png")
  elseif player.currency("classtype") == 1 then
    widget.setText("classlayout.classtitle","无畏战士")
    widget.setFontColor("classlayout.classtitle","blue")
    widget.setImage("classlayout.classicon","/objects/class/knight.png")
    widget.setText("classlayout.weapontext","剑盾搭配时伤害+20%.使用双手剑时+20%伤害.")
    widget.setText("classlayout.passivetext","+20% 击退抗性.")
    widget.setFontColor("classlayout.effecttext","blue")
    widget.setText("classlayout.effecttext","完美格挡会获得20%伤害加成.")
    widget.setImage("classlayout.effecticon","/scripts/knightblock/knightblock.png")
    widget.setImage("classlayout.effecticon2","/scripts/knightblock/knightblock.png")
    widget.setImage("classlayout.classweaponicon","/interface/RPGskillbook/weapons/knight.png")
    widget.setText("classlayout.statscalingtext","^green;主要属性:^reset;\n力量\n^blue;次要属性:^reset;\n耐力\n体质")
  elseif player.currency("classtype") == 2 then
    widget.setText("classlayout.classtitle","奥术法师")
    widget.setFontColor("classlayout.classtitle","magenta")
    widget.setImage("classlayout.classicon","/objects/class/wizard.png")
    widget.setFontColor("classlayout.effecttext","magenta")
    widget.setText("classlayout.weapontext","没有装备任何其他武器的情况下使用魔杖时+10%额外伤害. +10%法杖伤害.")
    widget.setText("classlayout.passivetext","对目标造成伤害时有6%几率会触发冻僵,燃烧或触电效果. 可叠加.")
    widget.setText("classlayout.effecttext","使用法杖时,火毒冰元素抗性+10%.")
    widget.setImage("classlayout.effecticon","/scripts/wizardaffinity/wizardaffinity.png")
    widget.setImage("classlayout.effecticon2","/scripts/wizardaffinity/wizardaffinity.png")
    widget.setImage("classlayout.classweaponicon","/interface/RPGskillbook/weapons/wizard.png")
    widget.setText("classlayout.statscalingtext","^green;主要属性:^reset;\n智力\n^magenta;次要属性:^reset;\n精力")
  elseif player.currency("classtype") == 3 then
    widget.setText("classlayout.classtitle","边缘刺客")
    widget.setImage("classlayout.classicon","/objects/class/ninja.png")
    widget.setFontColor("classlayout.classtitle","red")
    widget.setFontColor("classlayout.effecttext","red")
    widget.setText("classlayout.weapontext","短式冷兵器或空手搭配任何类型的飞刀使用时,飞镖+20%伤害.")
    widget.setText("classlayout.passivetext","+10%移动速度和跳跃高度. -10%掉落伤害.")
    widget.setText("classlayout.effecttext","身在夜间或地下时,+10%出血几率和0.4秒的出血时间.")
    widget.setImage("classlayout.effecticon","/scripts/ninjacrit/ninjacrit.png")
    widget.setImage("classlayout.effecticon2","/scripts/ninjacrit/ninjacrit.png")
    widget.setImage("classlayout.classweaponicon","/interface/RPGskillbook/weapons/ninja.png")
    widget.setText("classlayout.statscalingtext","^green;主要属性:^reset;\n灵巧\n^magenta;次要属性:^reset;\n敏捷")
  elseif player.currency("classtype") == 4 then
    widget.setText("classlayout.classtitle","太空陆战队")
    widget.setFontColor("classlayout.classtitle","orange")
    widget.setFontColor("classlayout.effecttext","orange")
    widget.setImage("classlayout.classicon","/objects/class/soldier.png")
    widget.setText("classlayout.weapontext","单手枪械搭配手雷使用时+20%的伤害. 狙击步枪,突击步枪和霰弹枪+10%伤害.")
    widget.setText("classlayout.passivetext","+10%几率击晕怪物.眩晕的长度取决于所造成的伤害.")
    widget.setText("classlayout.effecttext","能量充足时+10%伤害.\n当能量下降到75%以下时失去此增益.")
    widget.setImage("classlayout.effecticon","/scripts/soldierdiscipline/soldierdiscipline.png")
    widget.setImage("classlayout.effecticon2","/scripts/soldierdiscipline/soldierdiscipline.png")
    widget.setImage("classlayout.classweaponicon","/interface/RPGskillbook/weapons/soldier.png")
    widget.setText("classlayout.statscalingtext","^blue;主要属性:^reset;\n活力\n^magenta;次要属性:^reset;\n灵巧\n^gray;其次属性:^reset;\n精力\n耐力")
  elseif player.currency("classtype") == 5 then
    widget.setText("classlayout.classtitle","不法之徒")
    widget.setFontColor("classlayout.classtitle","green")
    widget.setFontColor("classlayout.effecttext","green")
    widget.setImage("classlayout.classicon","/objects/class/rogue.png")
    widget.setText("classlayout.weapontext","双手持单手武器时+20%伤害.")
    widget.setText("classlayout.passivetext","攻击有20%几率使目标中毒.")
    widget.setText("classlayout.effecttext","饥饿度保持在50%以上时,+20%毒抗性.")
    widget.setImage("classlayout.effecticon","/scripts/roguepoison/roguepoison.png")
    widget.setImage("classlayout.effecticon2","/scripts/roguepoison/roguepoison.png")
    widget.setImage("classlayout.classweaponicon","/interface/RPGskillbook/weapons/rogue.png")
    widget.setText("classlayout.statscalingtext","^blue;主要属性:^reset;\n灵巧\n^magenta;次要属性:^reset;\n精力\n敏捷")
  elseif player.currency("classtype") == 6 then
    widget.setText("classlayout.classtitle","星际探险家")
    widget.setImage("classlayout.classicon","/objects/class/explorer.png")
    widget.setFontColor("classlayout.classtitle","yellow")
    widget.setFontColor("classlayout.effecttext","yellow")
    widget.setText("classlayout.weapontext","同时使用抓钩,绳索,采矿工具,可投掷光源,或手电筒时,+10%伤害和所有抗性.")
    widget.setText("classlayout.passivetext","+10%物理抗性.")
    widget.setText("classlayout.effecttext","生命值高于50%时,提供明亮的黄色照明.")
    widget.setImage("classlayout.effecticon","/scripts/explorerglow/explorerglow.png")
    widget.setImage("classlayout.effecticon2","/scripts/explorerglow/explorerglow.png")
    widget.setImage("classlayout.classweaponicon","/interface/RPGskillbook/weapons/explorer.png")
    widget.setText("classlayout.statscalingtext","^blue;主要属性:^reset;\n精力\n^magenta;次要属性:^reset;\n敏捷\n^gray;其次属性:^reset;\n精力\n耐力")
  end

  if status.statPositive("ivrpgclassability") then
    widget.setText("classlayout.classabilitytoggletext", "关闭")
  else
    widget.setText("classlayout.classabilitytoggletext", "开启")
  end

  updateClassWeapon()
  updateTechImages()
end


function removeLayouts()
  widget.setVisible("overviewlayout",false)
  widget.setVisible("statslayout",false)
  widget.setVisible("classeslayout",false)
  widget.setVisible("classlayout",false)
  widget.setVisible("affinitieslayout",false)
  widget.setVisible("affinitylayout",false)
  widget.setVisible("affinitylockedlayout",false)
  widget.setVisible("infolayout",false)
  widget.setVisible("masterylayout",false)
  widget.setVisible("masterylockedlayout",false)
  widget.setVisible("professionlayout",false)
  widget.setVisible("professionslayout",false)
  widget.setVisible("professionlockedlayout",false)
  widget.setVisible("specializationlayout",false)
  widget.setVisible("specializationlockedlayout",false)
  widget.setVisible("upgradelayout", false)
end

function changeToOverview()
    widget.setText("tabLabel", "概述")
    widget.setVisible("overviewlayout", true)
    updateOverview(2*self.level*100+100)
end

function changeToStats()
    updateStats()
    widget.setText("tabLabel", "属性")
    widget.setVisible("statslayout", true)
end

function changeToClasses()
    widget.setText("tabLabel", "职业")
    if player.currency("classtype") == 0 then
      widget.setVisible("classlayout", false)
      checkClassDescription("default")
      widget.setVisible("classeslayout", true)
      updateTechText("default")
      return
    else
      widget.setVisible("classeslayout", false)
      updateClassTab()
      widget.setVisible("classlayout", true)
    end
end

function changeToAffinities()
    widget.setText("tabLabel", "亲和力")
    if player.currency("affinitytype") == 0 then
      widget.setVisible("affinitylayout", false)
      checkAffinityDescription("default")
      if self.level >= 25 then
        widget.setVisible("affinitieslayout", true)
      else
        widget.setVisible("affinitylockedlayout", true)
      end
      return
    else
      widget.setVisible("affinitieslayout", false)
      updateAffinityTab()
      widget.setVisible("affinitylayout", true)
    end
end

function changeToInfo()
    widget.setText("tabLabel", "信息选项卡")
    widget.setVisible("infolayout", true)
    updateInfo()
end

function changeToSpecialization()
    widget.setText("tabLabel", "专业选项卡")
    if self.level < 40 then
      widget.setVisible("specializationlayout", false)
      widget.setVisible("specializationlockedlayout", true)
    else
      updateSpecializationTab()
      widget.setVisible("specializationlockedlayout", false)
      widget.setVisible("specializationlayout", true)
    end
end

function changeToProfession()
    widget.setText("tabLabel", "职业选项卡")
    if self.level < 10 then
      widget.setVisible("professionlayout", false)
      widget.setVisible("professionlockedlayout", true)
    else
      widget.setVisible("professionlockedlayout", false)
      if player.currency("proftype") == 0 then
        widget.setVisible("professionlayout", false)
        widget.setVisible("professionslayout", true)
      else
        updateProfessionTab()
        widget.setVisible("professionslayout", false)
        widget.setVisible("professionlayout", true)
      end
    end
end

function changeToMastery()
    widget.setText("tabLabel", "专精")
    if self.level < 50 and not status.statPositive("ivrpgmasteryunlocked") then
      widget.setVisible("masterylayout", false)
      widget.setVisible("masterylockedlayout", true)
    else
      updateMasteryTab()
      widget.setVisible("masterylockedlayout", false)
      widget.setVisible("masterylayout", true)
      if not status.statPositive("ivrpgmasteryunlocked") then
        status.setPersistentEffects("ivrpgmasteryunlocked", {
          {stat = "ivrpgmasteryunlocked", amount = 1}
        })
      end
    end
end

function changeToUpgrades()
  widget.setText("tabLabel", "升级")
  widget.setVisible("upgradelayout", true)
  updateUpgradeTab()
end

function updateProfessionTab()
end

function updateSpecializationTab()
end

function updateUpgradeTab()

  local effectName = "nil"

  if status.statPositive("ivrpguctech") then
    effectName = status.getPersistentEffects("ivrpguctech")[2].stat
    widget.setText("upgradelayout.techname", self.textData.upgrades.tech[effectName].title)
    widget.setText("upgradelayout.techtext", self.textData.upgrades.tech[effectName].description)
    widget.setButtonEnabled("upgradelayout.tech", true)
  else
    widget.setText("upgradelayout.techname", "无")
    widget.setText("upgradelayout.techtext", "-")
    widget.setButtonEnabled("upgradelayout.tech", false)
  end

  if status.statPositive("ivrpgucweapon") then
    effectName = status.getPersistentEffects("ivrpgucweapon")[2].stat
    widget.setText("upgradelayout.weaponname", self.textData.upgrades.weapon[effectName].title)
    widget.setText("upgradelayout.weapontext", self.textData.upgrades.weapon[effectName].description)
    widget.setButtonEnabled("upgradelayout.weapon", true)
  else
    widget.setText("upgradelayout.weaponname", "无")
    widget.setText("upgradelayout.weapontext", "-")
    widget.setButtonEnabled("upgradelayout.weapon", false)
  end

  if status.statPositive("ivrpgucaffinity") then
    effectName = status.getPersistentEffects("ivrpgucaffinity")[2].stat
    widget.setText("upgradelayout.affinityname", self.textData.upgrades.affinity[effectName].title)
    widget.setText("upgradelayout.affinitytext", self.textData.upgrades.affinity[effectName].description)
    widget.setButtonEnabled("upgradelayout.affinity", true)
  else
    widget.setText("upgradelayout.affinityname", "无")
    widget.setText("upgradelayout.affinitytext", "-")
    widget.setButtonEnabled("upgradelayout.affinity", false)
  end

  if status.statPositive("ivrpgucgeneral") then
    effectName = status.getPersistentEffects("ivrpgucgeneral")[2].stat
    widget.setText("upgradelayout.generalname", self.textData.upgrades.general[effectName].title)
    widget.setText("upgradelayout.generaltext", self.textData.upgrades.general[effectName].description)
    widget.setButtonEnabled("upgradelayout.general", true)
  else
    widget.setText("upgradelayout.generalname", "无")
    widget.setText("upgradelayout.generaltext", "-")
    widget.setButtonEnabled("upgradelayout.general", false)
  end
end

function updateMasteryTab()
  widget.setText("masterylayout.masterypoints", self.mastery)
  widget.setText("masterylayout.xpover", math.max(0, self.xp - 250000))

  if self.mastery < 3 or self.xp < 250000 then
    widget.setButtonEnabled("masterylayout.prestigebutton", false)
  else
    widget.setButtonEnabled("masterylayout.prestigebutton", true)
  end

  if self.mastery < 5 then
    widget.setButtonEnabled("masterylayout.shopbutton", false)
  else
    widget.setButtonEnabled("masterylayout.shopbutton", true)
  end

  if self.mastery == 100 or self.xp < 260000 then
    widget.setButtonEnabled("masterylayout.refinebutton", false)
  else
    widget.setButtonEnabled("masterylayout.refinebutton", true)
  end

  updateChallenges()
end

function updateInfo()
  self.classType = player.currency("classtype")
  --Yea, yea, this should be in its own file that all lua files can import, but I'm lazy, ya' hear?
  self.strengthBonus = self.classType == 1 and 1.15 or 1
  self.agilityBonus = self.classType == 3 and 1.1 or (self.classType == 5 and 1.1 or (self.classType == 6 and 1.1 or 1))
  self.vitalityBonus = self.classType == 4 and 1.05 or (self.classType == 1 and 1.1 or (self.classType == 6 and 1.15 or 1))
  self.vigorBonus = self.classType == 4 and 1.15 or (self.classType == 2 and 1.1 or (self.classType == 5 and 1.1 or (self.classType == 6 and 1.05 or 1)))
  self.intelligenceBonus = self.classType == 2 and 1.2 or 1
  self.enduranceBonus = self.classType == 1 and 1.1 or (self.classType == 4 and 1.05 or (self.classType == 6 and 1.05 or 1))
  self.dexterityBonus = self.classType == 3 and 1.2 or (self.classType == 5 and 1.15 or (self.classType == 4 and 1.1 or 1))

  widget.setText("infolayout.displaystats", 
    "数值\n" ..
    "^red;" .. math.floor(100*(1 + self.vitality^self.vitalityBonus*.05))/100 .. "^reset;" .. "\n" ..
    "^green;" .. math.floor(100*(1 + self.vigor^self.vigorBonus*.05))/100 .. "\n" ..
    math.floor(status.stat("energyRegenPercentageRate")*100+.5)/100 .. "\n" ..
    math.floor(status.stat("energyRegenBlockTime")*100+.5)/100 .. "^reset;" .. "\n" ..
    "^orange;" .. getStatPercent(status.stat("foodDelta")) .. "^reset;" ..
    "^gray;" .. getStatPercent(status.stat("grit")) ..
    getStatMultiplier(status.stat("fallDamageMultiplier")) ..
    math.floor((1 + self.strength^self.strengthBonus*.05)*100+.5)/100 .. "^reset;" .. "\n" ..
    "^red;" .. (math.floor(self.dexterity^self.dexterityBonus*100+.5)/200 + status.stat("ninjaBleed")) .. "%\n" ..
    (math.floor(self.dexterity^self.dexterityBonus*100+.5)/100 + status.stat("ninjaBleed"))/50 .. "^reset;" .. "\n" ..
    "\n\n百分比\n" ..
    "^gray;" .. getStatPercent(status.stat("physicalResistance")) .. "^reset;" ..
    "^magenta;" .. getStatPercent(status.stat("poisonResistance")) .. "^reset;" ..
    "^blue;" .. getStatPercent(status.stat("iceResistance")) .. "^reset;" .. 
    "^red;" .. getStatPercent(status.stat("fireResistance")) .."^reset;" .. 
    "^yellow;" .. getStatPercent(status.stat("electricResistance")) .. "^reset;" ..
    "^green;" .. getStatPercent(status.stat("radioactiveResistance")) .. "^reset;" ..
    "^gray;" .. getStatPercent(status.stat("shadowResistance")) .. "^reset;" ..
    "^magenta;" .. getStatPercent(status.stat("cosmicResistance")) .. "^reset;")

  widget.setText("infolayout.displaystatsFU", 
    "免疫\n" ..
    "^red;" .. getStatImmunity(status.stat("fireStatusImmunity")) ..
    getStatImmunity(status.stat("lavaImmunity")) ..
    getStatImmunityNoLine(status.stat("biomeheatImmunity")) .. " [" .. getStatImmunityNoLine(status.stat("ffextremeheatImmunity")) .. "]\n" .. "^reset;" ..
    "^blue;" .. getStatImmunity(status.stat("iceStatusImmunity")) ..
    getStatImmunityNoLine(status.stat("biomecoldImmunity")) .. " [" .. getStatImmunityNoLine(status.stat("ffextremecoldImmunity")) .. "]\n" .. 
    getStatImmunity(status.stat("breathProtection")) .. "^reset;" ..
    "^green;" .. getStatImmunity(status.stat("poisonStatusImmunity")) ..
    getStatImmunityNoLine(status.stat("biomeradiationImmunity")) .. " [" .. getStatImmunityNoLine(status.stat("ffextremeradiationImmunity")) .. "]\n" .. "^reset;" ..
    "^yellow;" .. getStatImmunity(status.stat("electricStatusImmunity")) .. "^reset;" ..
    "^gray;" .. getStatImmunity(status.stat("invulnerable")))

  widget.setText("infolayout.displayWeapons", self.hardcoreWeaponText[self.classType+1] .. "\n\n^green;所有职业都可以使用\n破碎英雄之剑!\n所有职业都可以使用猎弓.^reset;")
  if status.statPositive("ivrpghardcore") then
    widget.setVisible("infolayout.displayWeapons", true)
  else
    widget.setVisible("infolayout.displayWeapons", false)
  end

  --[["^gray;" .. getStatPercent(status.stat("physicalResistance")) .. "^reset;" ..
    "^magenta;" .. (status.statPositive("poisonStatusImmunity") and "Immune!\n" or getStatPercent(status.stat("poisonResistance"))) .. "^reset;" ..
    "^blue;" .. (status.statPositive("iceStatusImmunity") and "Immune!\n" or getStatPercent(status.stat("iceResistance"))) .. "^reset;" .. 
    "^red;" .. (status.statPositive("fireStatusImmunity") and "Immune!\n" or getStatPercent(status.stat("fireResistance"))) .."^reset;" .. 
    "^yellow;" .. (status.statPositive("electricStatusImmunity") and "Immune!\n" or getStatPercent(status.stat("electricResistance"))) .. "^reset;" ..
    getStatMultiplier(status.stat("fallDamageMultiplier")) ..]]

end

function unlockTech()
  local classType = player.currency("classtype")
  local checked = widget.getChecked("classlayout.techicon1") and 1 or (widget.getChecked("classlayout.techicon2") and 2 or (widget.getChecked("classlayout.techicon3") and 3 or 4))
  local tech = getTechEnableName(classType, checked)
  player.makeTechAvailable(tech)
  player.enableTech(tech)
  unlockTechVisible(("techicon" .. tostring(checked)), 2^(checked+1))
end

function getTechEnableName(classType, checked)
  if classType == 1 then
    return checked == 1 and "knightbash" or (checked == 2 and "knightslam" or (checked == 3 and "knightarmorsphere" or "knightcharge!"))
  elseif classType == 2 then
    return checked == 1 and "wizardgravitysphere" or (checked == 2 and "wizardhover" or (checked == 3 and "wizardtranslocate" or "wizardmagicshield"))
  elseif classType == 3 then
    return checked == 1 and "ninjaflashjump" or (checked == 2 and "ninjavanishsphere" or (checked == 3 and "ninjaassassinate" or "ninjawallcling"))
  elseif classType == 4 then
    return checked == 1 and "soldiermre" or (checked == 2 and "soldiermarksman" or (checked == 3 and "soldierenergypack" or "soldiertanksphere"))
  elseif classType == 5 then
    return checked == 1 and "roguedeadlystance" or (checked == 2 and "roguetoxicsphere" or (checked == 3 and "rogueescape" or "roguetoxicaura"))
  elseif classType == 6 then
    return checked == 1 and "explorerglide" or (checked == 2 and "explorerenhancedmovement" or (checked == 3 and "explorerdrillsphere" or "explorerenhancedjump"))
  end
end

function hasValue(table, value)
  for index, val in ipairs(table) do
    if value == val then return true end
  end
  return false
end

function unlockTechVisible(tech, amount)
  local check = player.currency("experienceorb") >= amount^2*100
  if check then
    local classType = player.currency("classtype")
    local techName = getTechEnableName(classType, tonumber(string.sub(tech,9,9)))
    if hasValue(player.availableTechs(), techName) then
      widget.setButtonEnabled("classlayout.unlockbutton", false)
      widget.setVisible("classlayout.unlockedtext", true)
    else
      widget.setButtonEnabled("classlayout.unlockbutton", true)
    end
    widget.setVisible("classlayout.reqlvl", false)
  else
    widget.setButtonEnabled("classlayout.unlockbutton", false)
    widget.setVisible("classlayout.reqlvl", true)
    widget.setText("classlayout.reqlvl", "需要等级: " .. math.floor(amount))
  end
  widget.setVisible("classlayout.unlockbutton", true)
end

function updateTechText(name)
  uncheckTechButtons(name)
  if not widget.getChecked("classlayout.techicon1") and not widget.getChecked("classlayout.techicon2") and not widget.getChecked("classlayout.techicon3") and not widget.getChecked("classlayout.techicon4") then
    widget.setText("classlayout.techtext", "选择一个技能来查看或解锁.")
    widget.setVisible("classlayout.techname", false)
    widget.setVisible("classlayout.techtype", false)
    widget.setVisible("classlayout.reqlvl", false)
    widget.setVisible("classlayout.unlockbutton", false)
    widget.setVisible("classlayout.unlockedtext", false)
    return
  else
    widget.setVisible("classlayout.techname", true)
    widget.setVisible("classlayout.techtype", true)
  end
  if name == "techicon1" then
    widget.setText("classlayout.techtext", getTechText(1))
    widget.setText("classlayout.techname", getTechName(1))
    widget.setText("classlayout.techtype", getTechType(1) .. " 科技")
    unlockTechVisible(name, 4)
  elseif name == "techicon2" then
    widget.setText("classlayout.techtext",  getTechText(2))
    widget.setText("classlayout.techname", getTechName(2))
    widget.setText("classlayout.techtype", getTechType(2) .. " 科技")
    unlockTechVisible(name, 8)
  elseif name == "techicon3" then
    widget.setText("classlayout.techtext",  getTechText(3))
    widget.setText("classlayout.techname", getTechName(3))
    widget.setText("classlayout.techtype", getTechType(3) .. " 科技")
    unlockTechVisible(name, 16)
  elseif name == "techicon4" then
    widget.setText("classlayout.techtext",  getTechText(4))
    widget.setText("classlayout.techname", getTechName(4))
    widget.setText("classlayout.techtype", getTechType(4) .. " 科技")
    unlockTechVisible(name, 32)
  end
end

function getTechText(num)
  local classType = player.currency("classtype")
  if classType == 1 then
    return num == 1 and "冲刺猛撞,敌人受到伤害和击退. 举起盾牌时伤害翻倍. 伤害与力量和冲刺速度成正比. 能量消耗随着敏捷的提高而下降."
    or (num == 2 and "升级到二级跳,按[G](设置中绑定[G])向下猛击. 着陆后不会造成坠落伤害,并造成小型爆炸,伤害敌人. 伤害与力量和高度有关."
      or (num == 3 and "无畏重力球,免疫击退并对敌人造成接触伤害. 变形时增加防御." 
        or "进攻性升级. 虽然伤害仍然一样,但敌人被击中时会吓尿. 伤害与力量和冲刺速度成正比. 能量消耗随着敏捷的提高而下降."))
  elseif classType == 2 then
    return num == 1 and "反重力球,同时缓慢恢复生命值,并降低重力的影响. 另外,按住左键单击可创建一个力场,将敌人推开,消耗能量." 
    or (num == 2 and "在空中按[空格]悬浮并往光标处移动. 光标越远,移动的速度越快. 消耗能量. 悬浮速度与敏捷成正比." 
      or (num == 3 and "按[G](设置中绑定[G])传送到光标处(如果可能). 有短暂的冷却时间. 能量消耗取决于距离和敏捷. 在任务期间(和你的星舰),传送仅限于视野!!" 
        or "按[F]祭出奥术护盾,保护你和附近的盟友. 消耗能量,能量不足时自动关闭."))
  elseif classType == 3 then
    return num == 1 and "在半空中按[空格]向前突进. 在突进后有短暂的无敌时间. 只要你精力充沛,你就无法受到伤害. 你可以在半空中进行两次突进." 
    or (num == 2 and "按[F]变身为一个无敌的重力球. 开启时迅速消耗能量. 当你耗尽能量或主动[F]关闭时时,隐匿结束. 与其他重力球不同,隐匿重力球的速度和普通的一样." 
    or (num == 3 and "按下[G](设置中绑定[G])隐匿身形暗中观察. 2秒后,您会出现在光标处(如果可能). 如果手持武器,就会在你出现的地方施展X斩. 在冷却期间,失去20%的物理抗性. 能量消耗取决于距离和敏捷." 
    or "在跳跃时靠着墙壁可以抓取墙壁,并刷新跳跃. 按[S]向下滑动. 在抓取或滑动时按[空格]跳跃离开墙壁."))
  elseif classType == 4 then
    return num == 1 and "按[F]吃一个MRE(军粮),补充少许饥饿度和所有能量. 90秒冷却时间. 虽然冷却时间很长,但会慢慢恢复生命值,移动速度稍微降低." 
    or (num == 2 and "按下[G](设置中绑定[G]),远程武器获得额外的伤害加成,并降低能量回复延迟时间,但速度和抗性降低. 您可以主动按[G]结束效果并使冷却时间会缩短." 
      or (num == 3 and "升级至二级跳,按[空格]以您选择的方向冲刺. 你可以轻松改变你的运动轨迹. 持续时间与敏捷成正比. 你可以在空中冲刺两次." 
        or "按下[F]切换到武装重力球. 左键单击消耗能量发射飞弹. 按住右键开启防御力场.\n由SushiSquid制作！"))
  elseif classType == 5 then
    return num == 1 and "按下[G](设置中绑定[G])来开启力场,大幅增加物理和毒抗性,并获得击退免疫. 开启时消耗能量,能量不足自动关闭." 
    or (num == 2 and "按下[F]转换成免疫毒的重力球. 转换后单击左键,射出一圈毒云(伤害与敏捷挂钩). 按住右键,消耗饥饿度转化为生命值和能量." 
      or (num == 3 and "升级到双重跳,按[空格]按照您选择的方向猛冲,留下一团烟雾,使敌人一脸懵逼. 迷失方向的敌人会降低速度并减少伤害. 默认为向后猛冲." 
        or "按下[G](设置中绑定[G])开启大范围的毒素领域,使敌人的毒素抗性大幅降低. 这些敌人会受到更多毒素和流血伤害. 开启时消耗能量,能量不足自动关闭."))
  elseif classType == 6 then
    return num == 1 and "升级到二级跳,按住[W]滑翔,慢慢的坠落. 滑翔时可以使用二级跳. 滑翔的能量消耗随着敏捷提高而降低." 
    or (num == 2 and "按[G](设置中绑定[G])在增强能量猛冲和增强疾跑之间切换. 增强能量猛冲比能量猛冲更远,冷却时间更短. 与疾跑相比,增强疾跑速度更快,耗能更低." 
      or (num == 3 and "按[H](设置中绑定[H])转换可以跳跃的高速重力球. 按下[F]消耗能量以令人难以置信的速度往下挖掘." 
        or "升级到增强滑翔. 再获得三次空中跳跃和蹬墙跳. 空中跳跃有效率为85%.  你的蹬墙跳比正常的蹬墙跳稍微长一些,而且下落速度也较慢.  滑翔的能量消耗随着敏捷提高而降低."))
  end
end

function getTechName(num)
  local classType = player.currency("classtype")
  if classType == 1 then
    widget.setFontColor("classlayout.techname", "blue")
    return num == 1 and "野蛮冲撞" or (num == 2 and "撼地" or (num == 3 and "无畏重力球" or "战争冲撞!"))
  elseif classType == 2 then
    widget.setFontColor("classlayout.techname", "magenta")
    return num == 1 and "重力球" or (num == 2 and "徘徊" or (num == 3 and "闪烁" or "奥术护盾"))
  elseif classType == 3 then
    widget.setFontColor("classlayout.techname", "red")
    return num == 1 and "暗影突进" or (num == 2 and "隐匿重力球" or (num == 3 and "暗影步" or "虎爪"))
  elseif classType == 4 then
    widget.setFontColor("classlayout.techname", "orange")
    return num == 1 and "MRE" or (num == 2 and "神射手" or (num == 3 and "活力" or "坦克重力球"))
  elseif classType == 5 then
    widget.setFontColor("classlayout.techname", "green")
    return num == 1 and "致命力场" or (num == 2 and "剧毒重力球" or (num == 3 and "战术撤退!" or "毒素灵气"))
  elseif classType == 6 then
    widget.setFontColor("classlayout.techname", "yellow")
    return num == 1 and "滑翔" or (num == 2 and "运动增强" or (num == 3 and "挖掘重力球" or "铁人运动"))
  end
end

function getTechType(num)
  local classType = player.currency("classtype")
  if classType == 1 then
    return num == 1 and "身体" or (num == 2 and "腿部" or (num == 3 and "头部" or "身体"))
  elseif classType == 2 then
    return num == 1 and "头部" or (num == 2 and "腿部" or (num == 3 and "身体" or "头部"))
  elseif classType == 3 then
    return num == 1 and "腿部" or (num == 2 and "头部" or (num == 3 and "身体" or "腿部"))
  elseif classType == 4 then
    return num == 1 and "头部" or (num == 2 and "身体" or (num == 3 and "腿部" or "头部"))
  elseif classType == 5 then
    return num == 1 and "身体" or (num == 2 and "头部" or (num == 3 and "腿部" or "身体"))
  elseif classType == 6 then
    return num == 1 and "腿部" or (num == 2 and "身体" or (num == 3 and "头部" or "腿部"))
  end
end

function uncheckTechButtons(name)
  widget.setVisible("classlayout.reqlvl", false)
  widget.setVisible("classlayout.unlockbutton", false)
  widget.setVisible("classlayout.unlockedtext", false)
  if name ~= "techicon1" then widget.setChecked("classlayout.techicon1", false) end
  if name ~= "techicon2" then widget.setChecked("classlayout.techicon2", false) end
  if name ~= "techicon3" then widget.setChecked("classlayout.techicon3", false) end
  if name ~= "techicon4" then widget.setChecked("classlayout.techicon4", false) end
end

function updateTechImages()
  local classType = player.currency("classtype")
  local className = ""
  if classType == 1 then
    className = "knight"
  elseif classType == 2 then
    className = "wizard"
  elseif classType == 3 then
    className = "ninja"
  elseif classType == 4 then
    className = "soldier"
  elseif classType == 5 then
    className = "rogue"
  elseif classType == 6 then
    className = "explorer"
  end
  widget.setButtonImages("classlayout.techicon1", {
    base = "/interface/RPGskillbook/techbuttons/" .. className .. "1.png",
    hover = "/interface/RPGskillbook/techbuttons/" .. className .. "1hover.png",
    pressed = "/interface/RPGskillbook/techbuttons/" .. className .. "1pressed.png",
    disabled = "/interface/RPGskillbook/techbuttons/techbuttonbackground.png"
  })
  widget.setButtonCheckedImages("classlayout.techicon1", {
    base = "/interface/RPGskillbook/techbuttons/" .. className .. "1pressed.png",
    hover = "/interface/RPGskillbook/techbuttons/" .. className .. "1hover.png"
  })
  widget.setButtonImages("classlayout.techicon2", {
    base = "/interface/RPGskillbook/techbuttons/" .. className .. "2.png",
    hover = "/interface/RPGskillbook/techbuttons/" .. className .. "2hover.png",
    pressed = "/interface/RPGskillbook/techbuttons/" .. className .. "2pressed.png",
    disabled = "/interface/RPGskillbook/techbuttons/techbuttonbackground.png"
  })
  widget.setButtonCheckedImages("classlayout.techicon2", {
    base = "/interface/RPGskillbook/techbuttons/" .. className .. "2pressed.png",
    hover = "/interface/RPGskillbook/techbuttons/" .. className .. "2hover.png"
  })
  widget.setButtonImages("classlayout.techicon3", {
    base = "/interface/RPGskillbook/techbuttons/" .. className .. "3.png",
    hover = "/interface/RPGskillbook/techbuttons/" .. className .. "3hover.png",
    pressed = "/interface/RPGskillbook/techbuttons/" .. className .. "3pressed.png",
    disabled = "/interface/RPGskillbook/techbuttons/techbuttonbackground.png"
  })
  widget.setButtonCheckedImages("classlayout.techicon3", {
    base = "/interface/RPGskillbook/techbuttons/" .. className .. "3pressed.png",
    hover = "/interface/RPGskillbook/techbuttons/" .. className .. "3hover.png"
  })
  widget.setButtonImages("classlayout.techicon4", {
    base = "/interface/RPGskillbook/techbuttons/" .. className .. "4.png",
    hover = "/interface/RPGskillbook/techbuttons/" .. className .. "4hover.png",
    pressed = "/interface/RPGskillbook/techbuttons/" .. className .. "4pressed.png",
    disabled = "/interface/RPGskillbook/techbuttons/techbuttonbackground.png"
  })
  widget.setButtonCheckedImages("classlayout.techicon4", {
    base = "/interface/RPGskillbook/techbuttons/" .. className .. "4pressed.png",
    hover = "/interface/RPGskillbook/techbuttons/" .. className .. "4hover.png"
  })
end

function getStatPercent(stat)
  stat = math.floor(stat*10000+.50)/100
  return stat >= 100 and "Immune!\n" or (stat < 0 and stat .. "%\n" or (stat == 0 and "0%\n" or "+" .. stat .. "%\n"))
end

function getStatMultiplier(stat)
  stat = math.floor(stat*100+.5)/100
  return stat <= 0 and "0\n" or (stat .. "\n")
end

function getStatImmunity(stat)
  return tostring(stat >= 1):gsub("^%l",string.upper) .. "\n"
end

function getStatImmunityNoLine(stat)
  return tostring(stat >= 1):gsub("^%l",string.upper)
end

function raiseStat(name)
  player.consumeCurrency("statpoint", 1)
  name = string.gsub(name,"raise","") .. "point"
  player.addCurrency(name, 1)
  updateStats()
end

function checkStatPoints()
  if player.currency("statpoint") == 0 then
    enableStatButtons(false)
  elseif player.currency("statpoint") ~= 0 then
    enableStatButtons(true)
  end
end

function checkStatDescription(name)
  name = string.gsub(name,"icon","")
  uncheckStatIcons(name)
  if (widget.getChecked("statslayout."..name.."icon")) then
    changeStatDescription(name)
  else
    changeStatDescription("default")
  end
end

function checkClassDescription(name)
  name = string.gsub(name,"icon","")
  uncheckClassIcons(name)
  if (widget.getChecked("classeslayout."..name.."icon")) then
    changeClassDescription(name)
    widget.setButtonEnabled("classeslayout.selectclass", true)
  else
    changeClassDescription("default")
    widget.setButtonEnabled("classeslayout.selectclass", false)
  end
end

--[[function startingStats()
  player.addCurrency("strengthpoint",1)
  player.addCurrency("dexteritypoint",1)
  player.addCurrency("intelligencepoint",1)
  player.addCurrency("agilitypoint",1)
  player.addCurrency("endurancepoint",1)
  player.addCurrency("vitalitypoint",1)
  player.addCurrency("vigorpoint",1)
end]]

function updateStats()
  self.strength = player.currency("strengthpoint")
  widget.setText("statslayout.strengthamount",self.strength)
  self.agility = player.currency("agilitypoint")
  widget.setText("statslayout.agilityamount",self.agility)
  self.vitality = player.currency("vitalitypoint")
  widget.setText("statslayout.vitalityamount",self.vitality)
  self.vigor = player.currency("vigorpoint")
  widget.setText("statslayout.vigoramount",self.vigor)
  self.intelligence = player.currency("intelligencepoint")
  widget.setText("statslayout.intelligenceamount",self.intelligence)
  self.endurance = player.currency("endurancepoint")
  widget.setText("statslayout.enduranceamount",self.endurance)
  self.dexterity = player.currency("dexteritypoint")
  widget.setText("statslayout.dexterityamount",self.dexterity)
  widget.setText("statslayout.statpointsleft",player.currency("statpoint"))
  widget.setText("statslayout.totalstatsamount", addStats())
  checkStatPoints()
end

function addStats()
  return self.strength+self.agility+self.vitality+self.vigor+self.intelligence+self.endurance+self.dexterity
end

function uncheckStatIcons(name)
  if name ~= "strength" then widget.setChecked("statslayout.strengthicon", false) end
  if name ~= "agility" then widget.setChecked("statslayout.agilityicon", false) end
  if name ~= "vitality" then widget.setChecked("statslayout.vitalityicon", false) end
  if name ~= "vigor" then widget.setChecked("statslayout.vigoricon", false) end
  if name ~= "intelligence" then widget.setChecked("statslayout.intelligenceicon", false) end
  if name ~= "endurance" then widget.setChecked("statslayout.enduranceicon", false) end
  if name ~= "dexterity" then widget.setChecked("statslayout.dexterityicon", false) end
end

function uncheckClassIcons(name)
  if name ~= "knight" then
    widget.setChecked("classeslayout.knighticon", false)
    widget.setFontColor("classeslayout.knighttitle", "white")
  end
  if name ~= "wizard" then
    widget.setChecked("classeslayout.wizardicon", false)
    widget.setFontColor("classeslayout.wizardtitle", "white")
  end
  if name ~= "ninja" then
    widget.setChecked("classeslayout.ninjaicon", false)
    widget.setFontColor("classeslayout.ninjatitle", "white")
  end
  if name ~= "soldier" then
    widget.setChecked("classeslayout.soldiericon", false)
    widget.setFontColor("classeslayout.soldiertitle", "white")
  end
  if name ~= "rogue" then
    widget.setChecked("classeslayout.rogueicon", false)
    widget.setFontColor("classeslayout.roguetitle", "white")
  end
  if name ~= "explorer" then
    widget.setChecked("classeslayout.explorericon", false)
    widget.setFontColor("classeslayout.explorertitle", "white")
  end
end

function changeStatDescription(name)
  if name == "strength" then widget.setText("statslayout.statdescription", "大幅提高盾牌耐久.\n显著增加双手近战伤害.\n稍微增加物理抗性.") end
  if name == "agility" then widget.setText("statslayout.statdescription", "显著提高移动速度.\n增加跳跃高度.\n降低掉落伤害.") end
  if name == "vitality" then widget.setText("statslayout.statdescription", "显著提高最大生命值.\n降低饥饿度消耗率.") end
  if name == "vigor" then widget.setText("statslayout.statdescription", "显著提高最大能量.\n大幅提高能量回复速度.") end
  if name == "intelligence" then widget.setText("statslayout.statdescription", "大幅提高能量回复速度.\n大幅增加棍棒伤害.\n降低能量回复延迟.\n稍微增加法杖伤害.") end
  if name == "endurance" then widget.setText("statslayout.statdescription", "增加击退抵抗.\n增加物理抗性.\n稍微增加所有元素抗性.") end
  if name == "dexterity" then widget.setText("statslayout.statdescription", "增加枪械和弓箭伤害.\n增加出血几率和出血持续时间.\n稍微增加单手武器伤害.\n略微减少掉落伤害.") end
  if name == "default" then widget.setText("statslayout.statdescription", "点击属性图标查看加成.") end
end

function changeClassDescription(name)
  if name == "knight" then
    widget.setText("classeslayout.classdescription", "无畏战士:近战坦克. 双手近战武器是绝佳的选择,但剑盾搭配仍然很棒. 无畏战士的技能多以防守为主,尽管也有攻击手段. 无畏战士可以通过完美格挡进行治疗,并非常的耐打.") 
    widget.setFontColor("classeslayout.knighttitle", "blue")
    self.classTo = 1
  end
  if name == "wizard" then
    widget.setText("classeslayout.classdescription", "奥术法师:远程. 但使用棍棒和法杖效果更好. 奥术法师的技能大多是以实用性和位移为主. 奥术法师可以在击中敌人时造成随机的元素伤害状态(火,冰,电),并在手持魔杖或棍棒时提高元素抗性.") 
    widget.setFontColor("classeslayout.wizardtitle", "magenta")
    self.classTo = 2
  end
  if name == "ninja" then
    widget.setText("classeslayout.classdescription", "边缘刺客:混合范围,灵活高输出. 首要武器是飞镖,不过单手(非远程)武器仍然很棒. 边缘刺客的技能主要是突袭和逃脱. 边缘刺客非常灵活,并可轻易地避免摔伤.") 
    widget.setFontColor("classeslayout.ninjatitle", "red")
    self.classTo = 3
  end
  if name == "soldier" then
    widget.setText("classeslayout.classdescription", "太空陆战队:远程坦克. 首选双手远程武器,但仍然可以很好地使用单手远程武器. 太空陆战队的技能主要是提高实用性和防御能力. 太空陆战队可以在高能量水平时造成更多伤害,并且可以在击中敌人时有几率使其眩晕.") 
    widget.setFontColor("classeslayout.soldiertitle", "orange")
    self.classTo = 4
  end
  if name == "rogue" then
    widget.setText("classeslayout.classdescription", "不法之徒:混合输出. 首选单手武器. 不法之徒的技能大多可以提高攻击能力,但也会增加物理,毒性和反击能力. 盗不法之徒可以随机对敌人施放毒气,并且在高饱食度时增加毒素抗性.") 
    widget.setFontColor("classeslayout.roguetitle", "green")
    self.classTo = 5
  end
  if name == "explorer" then
    widget.setText("classeslayout.classdescription", "星际探险家:为探险而生. 擅长使用工具,例如鹤嘴镐,手电筒或物质枪. 探险家的技能主要是改善运动和采矿. 当生命值高于一半时,探险者会发光,稍微增加物理抗性.") 
    widget.setFontColor("classeslayout.explorertitle", "yellow")
    self.classTo = 6
  end
  if name == "default" then
    widget.setText("classeslayout.classdescription", "点击一个职业的图标来查看该职业的简介.")
    uncheckClassIcons("default")
    self.classTo = 0
  end
end

function enableStatButtons(enable)
  if player.currency("classtype") == 0 then
    enable = false
    widget.setVisible("statslayout.statprevention",true)
  else
    widget.setVisible("statslayout.statprevention",false)
  end
  widget.setButtonEnabled("statslayout.raisestrength", self.strength ~= 50 and enable)
  widget.setButtonEnabled("statslayout.raisedexterity", self.dexterity ~= 50 and enable)
  widget.setButtonEnabled("statslayout.raiseendurance", self.endurance ~= 50 and enable)
  widget.setButtonEnabled("statslayout.raiseintelligence", self.intelligence ~= 50 and enable)
  widget.setButtonEnabled("statslayout.raisevigor", self.vigor ~= 50 and enable)
  widget.setButtonEnabled("statslayout.raisevitality", self.vitality ~= 50 and enable)
  widget.setButtonEnabled("statslayout.raiseagility", self.agility ~= 50 and enable)
end

function chooseClass()
  player.addCurrency("classtype", self.classTo)
  self.class = self.classTo
  addClassStats()
  changeToClasses()
end

function addClassStats()
  if player.currency("classtype") == 1 then
      --Knight
    player.addCurrency("strengthpoint", 5)
    player.addCurrency("endurancepoint", 4)
    player.addCurrency("vitalitypoint", 3)
    player.addCurrency("vigorpoint", 1)
  elseif player.currency("classtype") == 2 then
    --Wizard
    player.addCurrency("intelligencepoint", 7)
    player.addCurrency("vigorpoint", 6)
  elseif player.currency("classtype") == 3 then
    --Ninja
    player.addCurrency("agilitypoint", 5)
    player.addCurrency("dexteritypoint", 6)
    player.addCurrency("intelligencepoint", 2)
  elseif player.currency("classtype") == 4 then
    --Soldier
    player.addCurrency("vigorpoint", 5)
    player.addCurrency("endurancepoint", 2)
    player.addCurrency("dexteritypoint", 4)
    player.addCurrency("vitalitypoint", 2)
  elseif player.currency("classtype") == 5 then
    --Rogue
    player.addCurrency("agilitypoint", 3)
    player.addCurrency("endurancepoint", 3)
    player.addCurrency("dexteritypoint", 4)
    player.addCurrency("vigorpoint", 3)
  elseif player.currency("classtype") == 6 then
    --Explorer
    player.addCurrency("agilitypoint", 4)
    player.addCurrency("endurancepoint", 2)
    player.addCurrency("vigorpoint", 3)
    player.addCurrency("vitalitypoint", 4)
  end
  updateStats()
  uncheckClassIcons("default")
  changeClassDescription("default")
end

--deprecated, don't use
function consumeClassStats()
  if player.currency("classtype") == 1 then
      --Knight
    player.consumeCurrency("strengthpoint", 5)
    player.consumeCurrency("endurancepoint", 4)
    player.consumeCurrency("vitalitypoint", 3)
    player.consumeCurrency("vigorpoint", 1)
  elseif player.currency("classtype") == 2 then
    --Wizard
    player.consumeCurrency("intelligencepoint", 7)
    player.consumeCurrency("vigorpoint", 6)
  elseif player.currency("classtype") == 3 then
    --Ninja
    player.consumeCurrency("agilitypoint", 5)
    player.consumeCurrency("dexteritypoint", 6)
    player.consumeCurrency("intelligencepoint", 2)
  elseif player.currency("classtype") == 4 then
    --Soldier
    player.consumeCurrency("vitalitypoint", 5)
    player.consumeCurrency("endurancepoint", 2)
    player.consumeCurrency("dexteritypoint", 4)
    player.consumeCurrency("strengthpoint", 2)
  elseif player.currency("classtype") == 5 then
    --Rogue
    player.consumeCurrency("agilitypoint", 3)
    player.consumeCurrency("endurancepoint", 3)
    player.consumeCurrency("dexteritypoint", 4)
    player.consumeCurrency("vigorpoint", 3)
  elseif player.currency("classtype") == 6 then
    --Explorer
    player.consumeCurrency("agilitypoint", 4)
    player.consumeCurrency("endurancepoint", 2)
    player.consumeCurrency("vitalitypoint", 3)
    player.consumeCurrency("vigorpoint", 4)
  end
  updateStats()
end
--

function areYouSure(name)
  name = string.gsub(name,"resetbutton","")
  name2 = ""
  if name == "" then name2 = "overviewlayout"
  elseif name == "cl" then name2 = "classlayout" end
  --sb.logInfo(name.."test"..name2)
  widget.setVisible(name2..".resetbutton"..name, false)
  widget.setVisible(name2..".yesbutton", true)
  widget.setVisible(name2..".nobutton"..name, true)
  widget.setVisible(name2..".areyousure", true)
  --widget.setVisible(name2..".hardcoretext", false)
end

function notSure(name)
  name = string.gsub(name,"nobutton","")
  name2 = ""
  if name == "" then name2 = "overviewlayout"
  elseif name == "cl" then name2 = "classlayout" end
  widget.setVisible(name2..".resetbutton"..name, true)
  widget.setVisible(name2..".yesbutton", false)
  widget.setVisible(name2..".nobutton"..name, false)
  widget.setVisible(name2..".areyousure", false)
  --updateOverview(2*self.level*100+100)
end

--deprecated, don't use
function resetClass()
  notSure("nobuttoncl")
  consumeClassStats()
  player.consumeCurrency("classtype",player.currency("classtype"))
  changeToClasses()
end
--

function resetSkillBook()
  notSure("nobutton")
  consumeAllRPGCurrency()
  consumeMasteryCurrency()
  removeTechs()
end

function removeTechs()
  if self.class == 3 then
    player.makeTechUnavailable("ninjaassassinate")
    player.makeTechUnavailable("ninjaflashjump")
    player.makeTechUnavailable("ninjawallcling")
    player.makeTechUnavailable("ninjavanishsphere")
  elseif self.class == 2 then
    player.makeTechUnavailable("wizardmagicshield")
    player.makeTechUnavailable("wizardgravitysphere")
    player.makeTechUnavailable("wizardtranslocate")
    player.makeTechUnavailable("wizardhover")
  elseif self.class == 1 then
    player.makeTechUnavailable("knightslam")
    player.makeTechUnavailable("knightbash")
    player.makeTechUnavailable("knightcharge!")
    player.makeTechUnavailable("knightarmorsphere")
  elseif self.class == 5 then
    player.makeTechUnavailable("roguetoxicaura")
    player.makeTechUnavailable("roguetoxicsphere")
    player.makeTechUnavailable("roguedeadlystance")
    player.makeTechUnavailable("rogueescape")
    --Deprecated
    player.makeTechUnavailable("roguepoisondash")
    player.makeTechUnavailable("roguecloudjump")
    player.makeTechUnavailable("roguetoxiccapsule")
  elseif self.class == 4 then
    player.makeTechUnavailable("soldiertanksphere")
    player.makeTechUnavailable("soldierenergypack")
    player.makeTechUnavailable("soldiermarksman")
    player.makeTechUnavailable("soldiermre")
    --Deprecated
    player.makeTechUnavailable("soldiermissilestrike")
  elseif self.class == 6 then
    player.makeTechUnavailable("explorerenhancedjump")
    player.makeTechUnavailable("explorerenhancedmovement")
    player.makeTechUnavailable("explorerdrillsphere")
    player.makeTechUnavailable("explorerglide")
    --Deprecated
    player.makeTechUnavailable("explorerdrill")
  end
end

function updateClassWeapon()
  if self.class == 0 then return end
  if player.hasCompletedQuest(self.quests[self.class]) then
    widget.setText("classlayout.classweapontext", self.classWeaponText[self.class])
    widget.setVisible("classlayout.weaponreqlvl", false)
    widget.setVisible("classlayout.unlockquestbutton", false)
    widget.setVisible("classlayout.classweapontext", true)
  elseif self.level < 12 then
    widget.setFontColor("classlayout.weaponreqlvl", "red")
    widget.setText("classlayout.weaponreqlvl", "所需级别: 15")
    widget.setVisible("classlayout.weaponreqlvl", true)
    widget.setVisible("classlayout.unlockquestbutton", false)
    widget.setVisible("classlayout.classweapontext", false)
  elseif player.hasQuest(self.quests[self.class]) then
    widget.setText("classlayout.classweapontext", "完成任务以获取更多信息.")
    widget.setVisible("classlayout.classweapontext", true)
    widget.setVisible("classlayout.weaponreqlvl", false)
    widget.setVisible("classlayout.unlockquestbutton", false)
  else
    widget.setVisible("classlayout.unlockquestbutton", true)
    widget.setVisible("classlayout.weaponreqlvl", false)
    widget.setVisible("classlayout.classweapontext", false)
  end
end

function unlockQuest()
  player.startQuest(self.quests[self.class])
  widget.setVisible("classlayout.unlockquestbutton", false)
  widget.setText("classlayout.classweapontext", "完成任务以获取更多信息.")
  widget.setVisible("classlayout.classweapontext", true)
end

function chooseAffinity()
  player.addCurrency("affinitytype", self.affinityTo)
  self.affinity = self.affinityTo
  addAffinityStats()
  changeToAffinities()
end

function upgradeAffinity()
  player.addCurrency("affinitytype", 4)
  self.affinity = self.affinity + 4
  addAffinityStats()
  changeToAffinities()
end

function checkAffinityDescription(name)
  name = string.gsub(name,"icon","")
  uncheckAffinityIcons(name)
  if (widget.getChecked("affinitieslayout."..name.."icon")) then
    changeAffinityDescription(name)
    widget.setButtonEnabled("affinitieslayout.selectaffinity", true)
  else
    changeAffinityDescription("default")
    widget.setButtonEnabled("affinitieslayout.selectaffinity", false)
  end
end

function uncheckAffinityIcons(name)
  if name ~= "fire" then
    widget.setChecked("affinitieslayout.fireicon", false)
    widget.setFontColor("affinitieslayout.firetitle", "white")
  end
  if name ~= "ice" then
    widget.setChecked("affinitieslayout.iceicon", false)
    widget.setFontColor("affinitieslayout.icetitle", "white")
  end
  if name ~= "electric" then
    widget.setChecked("affinitieslayout.electricicon", false)
    widget.setFontColor("affinitieslayout.electrictitle", "white")
  end
  if name ~= "poison" then
    widget.setChecked("affinitieslayout.poisonicon", false)
    widget.setFontColor("affinitieslayout.poisontitle", "white")
  end
end

function changeAffinityDescription(name)
  if name == "fire" then
    widget.setText("affinitieslayout.affinitydescription", "火焰, 强大的亲和力. 这种亲和力授予你火焰免疫和抗性, 以及中等的活力属性增强. 升级时提供更好的免疫和更大的属性增强. 不过要小心, 因为选择这种亲和力会在被水淹没时削弱你, 并降低毒抗性.") 
    widget.setFontColor("affinitieslayout.firetitle", "red")
    self.affinityTo = 1
  end
  if name == "poison" then
    widget.setText("affinitieslayout.affinitydescription", "毒, 精明的亲和力. 这种亲和力授予你毒免疫和抗性, 以及小量活力, 灵巧, 和敏捷属性增强. 升级时提供更好的免疫和更大的敏捷属性增强. 不过要小心, 因为选择这种亲和力会降低您的最大生命值并降低电击抗性.") 
    widget.setFontColor("affinitieslayout.poisontitle", "green")
    self.affinityTo = 2
  end
  if name == "ice" then
    widget.setText("affinitieslayout.affinitydescription", "寒冰, 保护性的亲和力. 这种亲和力授予你冰免疫和抗性, 以及中等的体质属性增强. 升级时提供更好的免疫和大型耐力属性增强. 不过要小心, 因为选择这种亲和力可以降低你的移动速度和跳跃高度, 并降低火焰抗性.") 
    widget.setFontColor("affinitieslayout.icetitle", "blue")
    self.affinityTo = 3
  end
  if name == "electric" then
    widget.setText("affinitieslayout.affinitydescription", "电击, 感知亲和力. 这种亲和力授予你电击免疫和抗性, 以及中等的敏捷属性增强. 升级时提供更好的免疫和大型智力属性增强. 不过要小心, 因为选择这种亲和力会在被水淹没时削弱你, 并且使你变得对寒冰无能为力.") 
    widget.setFontColor("affinitieslayout.electrictitle", "yellow")
    self.affinityTo = 4
  end
  if name == "default" then
    widget.setText("affinitieslayout.affinitydescription", "点击一个亲和力图标查看亲和力的描述.")
    uncheckAffinityIcons("default")
    self.affinityTo = 0
  end
end

function updateAffinityTab()
  local affinity = player.currency("affinitytype")
  if affinity == 0 then
    widget.setText("affinitylayout.affinitytitle","无")
    widget.setImage("affinitylayout.affinityicon","/objects/class/noclass.png")
  elseif affinity == 1 then
    widget.setText("affinitylayout.affinitytitle","火焰")
    widget.setFontColor("affinitylayout.affinitytitle","red")
    widget.setImage("affinitylayout.affinityicon","/objects/affinity/flame.png")

    widget.setText("affinitylayout.passivetext","+10%几率造成伤害时烧焦敌人. 点燃的敌人-25%伤害")
    widget.setText("affinitylayout.statscalingtext","+3活力")

    widget.setText("affinitylayout.immunitytext", "燃烧\n高温")
    widget.setText("affinitylayout.weaknesstext", "-25%毒抗性\n在水中时最大能量-30%\n在水中时-1 HP/s")
    widget.setText("affinitylayout.upgradetext", "+20%几率烤焦敌人\n+5力量\n增加免疫:\n火焰伤害\n岩浆\n极端高温")
  elseif affinity == 2 then
    widget.setText("affinitylayout.affinitytitle","毒")
    widget.setFontColor("affinitylayout.affinitytitle","green")
    widget.setImage("affinitylayout.affinityicon","/objects/affinity/venom.png")

    widget.setText("affinitylayout.passivetext","+10%对敌人投毒造成中毒伤害. 中毒的敌人-25%最大生命值并持续造成中毒伤害.")
    widget.setText("affinitylayout.statscalingtext","+1活力\n+1灵巧\n+1敏捷")

    widget.setText("affinitylayout.immunitytext", "中毒\n焦油\n辐射")
    widget.setText("affinitylayout.weaknesstext", "-25%电击抗性\n-15%生命值")
    widget.setText("affinitylayout.upgradetext", "+20%几率投毒伤害敌人\n+5 灵巧\n增加免疫:\n毒性伤害\n极端辐射\n原体")
  elseif affinity == 3 then
    widget.setText("affinitylayout.affinitytitle","寒冰")
    widget.setFontColor("affinitylayout.affinitytitle","blue")
    widget.setImage("affinitylayout.affinityicon","/objects/affinity/frost.png")

    widget.setText("affinitylayout.passivetext","+10%几率在造成伤害时削弱敌人. 被削弱的敌人-25%抗性并在被击杀时造成冰爆. 这冰爆会造成寒冰伤害和冰霜减速敌人.")
    widget.setText("affinitylayout.statscalingtext","+3 活力")

    widget.setText("affinitylayout.immunitytext", "冰冻\n潮湿\n低温")
    widget.setText("affinitylayout.weaknesstext", "-25%火焰抗性\n-15%移动速度\n-15%跳跃高度")
    widget.setText("affinitylayout.upgradetext", "+20%使敌人脆化\n+5耐力\n增加免疫:\n寒冰伤害\n缺氧\n极度低温")
  elseif affinity == 4 then
    widget.setText("affinitylayout.affinitytitle","电击")
    widget.setFontColor("affinitylayout.affinitytitle","yellow")
    widget.setImage("affinitylayout.affinityicon","/objects/affinity/shock.png")

    widget.setText("affinitylayout.passivetext","+10%几率在造成伤害时超负荷敌人. 超负荷的敌人-25%速度并使附近的敌人触电.")
    widget.setText("affinitylayout.statscalingtext","+3敏捷")

    widget.setText("affinitylayout.immunitytext", "减速\n电击伤害")
    widget.setText("affinitylayout.weaknesstext", "-25%寒冰抗性\n在水中时-30%最大生命值\n在水中时-1 E/s")
    widget.setText("affinitylayout.upgradetext", "+20%超负荷敌人的机会\n+5智力\n增加免疫:\n电击伤害\n辐射\n暗影")
  elseif affinity == 5 then
    widget.setText("affinitylayout.affinitytitle","地狱火")
    widget.setFontColor("affinitylayout.affinitytitle","red")
    widget.setImage("affinitylayout.affinityicon","/objects/affinity/flame.png")

    widget.setText("affinitylayout.passivetext","+30%几率造成伤害时烧焦敌人. 点燃的敌人-25%伤害.")
    widget.setText("affinitylayout.statscalingtext","+3活力\n+5力量")

    widget.setText("affinitylayout.immunitytext", "火焰伤害\n岩浆\n极端高温 (FU)")
    widget.setText("affinitylayout.weaknesstext", "-25%毒抗性\n在水中时-30%最大能量\n在水中时-1 HP/s")
    widget.setText("affinitylayout.upgradetext", "全面升级!")
  elseif affinity == 6 then
    widget.setText("affinitylayout.affinitytitle","老毒物")
    widget.setFontColor("affinitylayout.affinitytitle","green")
    widget.setImage("affinitylayout.affinityicon","/objects/affinity/venom.png")

    widget.setText("affinitylayout.passivetext","+30%对敌人投毒造成中毒伤害. 中毒的敌人-25%最大生命值并持续造成中毒伤害.")
    widget.setText("affinitylayout.statscalingtext","+1活力\n+1敏捷\n+6灵巧")

    widget.setText("affinitylayout.immunitytext", "毒性伤害\n焦油\n极端辐射(FU)\n原体(FU)")
    widget.setText("affinitylayout.weaknesstext", "-25%电击抗性\n-15%最大生命值")
    widget.setText("affinitylayout.upgradetext", "全面升级!")
  elseif affinity == 7 then
    widget.setText("affinitylayout.affinitytitle","深寒")
    widget.setFontColor("affinitylayout.affinitytitle","blue")
    widget.setImage("affinitylayout.affinityicon","/objects/affinity/frost.png")

    widget.setText("affinitylayout.passivetext","+30%几率在造成伤害时削弱敌人. 被削弱的敌人-25%抗性并在被击杀时造成冰爆. 这冰爆会造成寒冰伤害和冰霜减速敌人.\n^blue;当你的生命值低于三分之一时, 附近的敌人会被击退并减速.")
    widget.setText("affinitylayout.statscalingtext","+3体质\n+5耐力")

    widget.setText("affinitylayout.immunitytext", "寒冰伤害\n潮湿\n缺氧\n极度低温(FU)")
    widget.setText("affinitylayout.weaknesstext", "-25%火焰抗性\n-15%移动速度\n-15%跳跃高度")
    widget.setText("affinitylayout.upgradetext", "全面升级!")
  elseif affinity == 8 then
    widget.setText("affinitylayout.affinitytitle","弧光")
    widget.setFontColor("affinitylayout.affinitytitle","yellow")
    widget.setImage("affinitylayout.affinityicon","/objects/affinity/shock.png")

    widget.setText("affinitylayout.passivetext","+30%几率在造成伤害时超负荷敌人. 超负荷的敌人-25%速度并使附近的敌人触电.\n^yellow;消耗所有能量后, 释放一次电弧爆炸造成大规模破坏并导致过载.")
    widget.setText("affinitylayout.statscalingtext","+3敏捷\n+5智力")

    widget.setText("affinitylayout.immunitytext", "电击伤害\n减速\n辐射\n阴影 (FU)")
    widget.setText("affinitylayout.weaknesstext", "-25%寒冰抗性\n在水中时-30%最大生命值\n在水中时-1 E/s")
    widget.setText("affinitylayout.upgradetext", "全面升级!")
  end

  if affinity > 4 then
    widget.setVisible("affinitylayout.effecttext", false)
  elseif affinity > 0 then
    widget.setVisible("affinitylayout.effecttext", true)
  end

  if status.statPositive("ivrpgaesthetics") then
    widget.setText("affinitylayout.aestheticstoggletext", "启用")
  else
    widget.setText("affinitylayout.aestheticstoggletext", "关闭")
  end
end

function addAffinityStats()
  if player.currency("affinitytype") == 1 then
      --Flame
    addAffintyStatsHelper("vigorpoint", 3)
  elseif player.currency("affinitytype") == 2 then
    --Venom
    addAffintyStatsHelper("vigorpoint", 1)
    addAffintyStatsHelper("dexteritypoint", 1)
    addAffintyStatsHelper("agilitypoint", 1)
  elseif player.currency("affinitytype") == 3 then
    --Frost
    addAffintyStatsHelper("vitalitypoint", 3)
  elseif player.currency("affinitytype") == 4 then
    --Shock
    addAffintyStatsHelper("agilitypoint", 3)
  end
  updateStats()
  uncheckAffinityIcons("default")
  changeAffinityDescription("default")
end

function addAffintyStatsHelper(statName, amount)
  local current = 50 - player.currency(statName)
  if current < amount then
    --Adds Stat Points if Bonus Stat is near maxed!
    player.addCurrency("statpoint", amount - current)
  end
  player.addCurrency(statName, amount)
end

--Deprecated
function consumeAffinityStats()
  --[[if player.currency("affinitytype") == 1 then
      --Flame
    player.consumeCurrency("vigorpoint", 3)
  elseif player.currency("classtype") == 2 then
    --Venom
    player.consumeCurrency("vigorpoint", 1)
    player.consumeCurrency("vitalitypoint", 1)
    player.consumeCurrency("agilitypoint", 1)
  elseif player.currency("classtype") == 3 then
    --Frost
    player.consumeCurrency("vitalitypoint", 3)
  elseif player.currency("classtype") == 4 then
    --Shock
    player.consumeCurrency("agilitypoint", 3)
  elseif player.currency("cla sstype") == 5 then
    --Infernal
    player.consumeCurrency("strengthpoint", 5)
  elseif player.currency("classtype") == 6 then
    --Toxic
    player.consumeCurrency("dexteritypoint", 5)
  elseif player.currency("classtype") == 7 then
    --Cryo
    player.consumeCurrency("endurancepoint", 5)
  elseif player.currency("classtype") == 8 then
    --Arc
    player.consumeCurrency("intelligencepoint", 5)
  end
  updateStats()]]
end

function toggleAesthetics()
  if status.statPositive("ivrpgaesthetics") then
    status.clearPersistentEffects("ivrpgAesthetics")
  else
    status.setPersistentEffects("ivrpgAesthetics",
    {
      {stat = "ivrpgaesthetics", amount = 1}
    })
  end
  updateAffinityTab()
end

function toggleHardcore()
  if status.statPositive("ivrpghardcore") then
    status.clearPersistentEffects("ivrpgHardcore")
  else
    status.setPersistentEffects("ivrpgHardcore",
    {
      {stat = "ivrpghardcore", amount = 1}
    })
  end
  updateOverview(2*self.level*100+100)
end

function toggleClassAbility()
  if status.statPositive("ivrpgclassability") then
    status.clearPersistentEffects("ivrpgClassAbility")
  else
    status.setPersistentEffects("ivrpgClassAbility",
    {
      {stat = "ivrpgclassability", amount = 1}
    })
  end
  updateClassTab()
end

function consumeAllRPGCurrency()
  player.consumeCurrency("experienceorb", self.xp - 100)
  player.consumeCurrency("currentlevel", self.level - 1)
  player.consumeCurrency("statpoint", player.currency("statpoint"))
  player.consumeCurrency("strengthpoint",player.currency("strengthpoint"))
  player.consumeCurrency("agilitypoint",player.currency("agilitypoint"))
  player.consumeCurrency("vitalitypoint",player.currency("vitalitypoint"))
  player.consumeCurrency("vigorpoint",player.currency("vigorpoint"))
  player.consumeCurrency("intelligencepoint",player.currency("intelligencepoint"))
  player.consumeCurrency("endurancepoint",player.currency("endurancepoint"))
  player.consumeCurrency("dexteritypoint",player.currency("dexteritypoint"))
  player.consumeCurrency("classtype",player.currency("classtype"))
  player.consumeCurrency("affinitytype",player.currency("affinitytype"))
  player.consumeCurrency("proftype",player.currency("proftype"))
  player.consumeCurrency("spectype",player.currency("spectype"))
  startingStats()
  updateStats()
end

function prestige()
  player.consumeCurrency("masterypoint", 3)
  consumeAllRPGCurrency()
  removeDeprecatedTechs()
end

function purchaseShop()
  player.consumeCurrency("masterypoint", 5)
  player.giveItem("ivrpgmasteryshop")
end

function refine()
  local xp = self.xp - 250000
  local mastery = math.floor(xp/10000)
  player.addCurrency("masterypoint", mastery)
  player.consumeCurrency("experienceorb", 10000*mastery)
end

function updateChallenges()
  if not status.statPositive("ivrpgchallenge1") then
    status.setPersistentEffects("ivrpgchallenge1", {
    -- 1. Defeat 150 Level 4 or higher enemies.
    -- 2. Defeat 100 Level 6 or higher enemies.
    -- 3. Defeat 1 Boss Monster.
    -- 4. Defeat the Erchius Horror without taking damage.
      {stat = "ivrpgchallenge1", amount = math.random(1,3)}
    })
  end
  if not status.statPositive("ivrpgchallenge2") then
    -- 1. Defeat 300 Level 6 or higher enemies.
    -- 2. Defeat 3 Boss Monsters.
    status.setPersistentEffects("ivrpgchallenge2", {
      {stat = "ivrpgchallenge2", amount = math.random(1,2)}
    })
  end
  if not status.statPositive("ivrpgchallenge3") then
    -- 1. Defeat 300 Vault enemies.
    -- 2. Defeat 3 Vault Guardians.
    -- 3. Defeat 5 Boss Monsters.
    -- 4. Deafeat the Heart of Ruin without taking damage.
    status.setPersistentEffects("ivrpgchallenge3", {
      {stat = "ivrpgchallenge3", amount = math.random(1,3)}
    })
  end
  updateChallengesText()
end

function updateChallengesText()
  local challenge1 = status.stat("ivrpgchallenge1")
  local challenge2 = status.stat("ivrpgchallenge2")
  local challenge3 = status.stat("ivrpgchallenge3")

  widget.setText("masterylayout.challenge1", self.challengeText[1][challenge1][1])
  widget.setText("masterylayout.challenge2", self.challengeText[2][challenge2][1])
  widget.setText("masterylayout.challenge3", self.challengeText[3][challenge3][1])

  local prog1 = math.floor(status.stat("ivrpgchallenge1progress"))
  local prog2 = math.floor(status.stat("ivrpgchallenge2progress"))
  local prog3 = math.floor(status.stat("ivrpgchallenge3progress"))

  local maxprog1 = self.challengeText[1][challenge1][2]
  local maxprog2 = self.challengeText[2][challenge2][2]
  local maxprog3 = self.challengeText[3][challenge3][2]

  widget.setText("masterylayout.challenge1progress", (prog1 > maxprog1 and maxprog1 or prog1) .. " / " .. maxprog1)
  widget.setText("masterylayout.challenge2progress", (prog2 > maxprog2 and maxprog2 or prog2) .. " / " .. maxprog2)
  widget.setText("masterylayout.challenge3progress", (prog3 > maxprog3 and maxprog3 or prog3) .. " / " .. maxprog3)

  if prog1 >= maxprog1 then
    widget.setFontColor("masterylayout.challenge1progress", "green")
    widget.setButtonEnabled("masterylayout.challenge1button", true)
  else
    widget.setFontColor("masterylayout.challenge1progress", "red")
    widget.setButtonEnabled("masterylayout.challenge1button", false)
  end

  if prog2 >= maxprog2 then
    widget.setFontColor("masterylayout.challenge2progress", "green")
    widget.setButtonEnabled("masterylayout.challenge2button", true)
  else
    widget.setFontColor("masterylayout.challenge2progress", "red")
    widget.setButtonEnabled("masterylayout.challenge2button", false)
  end

  if prog3 >= maxprog3 then
    widget.setFontColor("masterylayout.challenge3progress", "green")
    widget.setButtonEnabled("masterylayout.challenge3button", true)
  else
    widget.setFontColor("masterylayout.challenge3progress", "red")
    widget.setButtonEnabled("masterylayout.challenge3button", false)
  end

end

function challengeRewards(name)
  local rand = math.random(1,10)
  if name == "challenge1button" then
    status.clearPersistentEffects("ivrpgchallenge1")
    status.clearPersistentEffects("ivrpgchallenge1progress")
    if rand < 4 then
      player.giveItem({"experienceorb", math.random(1000,2000)})
    elseif rand < 7 then
      player.giveItem({"money", math.random(500,1000)})
      player.giveItem({"experienceorb", math.random(250,500)})
    elseif rand < 9 then
      player.giveItem({"liquidfuel", 500})
      player.giveItem({"experienceorb", math.random(250,500)})
    else
      player.giveItem({"rewardbag", 5})
      player.giveItem({"experienceorb", math.random(250,500)})
    end
  elseif name == "challenge2button" then
    status.clearPersistentEffects("ivrpgchallenge2")
    status.clearPersistentEffects("ivrpgchallenge2progress")
    if rand < 4 then
      player.giveItem({"experienceorb", math.random(2500,5000)})
    elseif rand < 7 then
      player.giveItem({"money", math.random(1500,2500)})
      player.giveItem({"experienceorb", math.random(500,750)})
    elseif rand < 8 then
      player.giveItem({"masterypoint", 1})
    else
      player.giveItem({"ultimatejuice", math.random(5,10)})
      player.giveItem({"experienceorb", math.random(500,750)})
    end
  elseif name == "challenge3button" then
    status.clearPersistentEffects("ivrpgchallenge3")
    status.clearPersistentEffects("ivrpgchallenge3progress")
    if rand < 5 then
      player.giveItem({"essence", math.random(500,750)})
    elseif rand < 7 then
      player.giveItem({"masterypoint", 1})
    elseif rand < 10 then
      player.giveItem({"essence", math.random(100,250)})
      player.giveItem({"diamond", math.random(7,12)})
    else
      player.giveItem({"vaultkey", 1})
    end
  end
end

function consumeMasteryCurrency()
  player.consumeCurrency("masterypoint",player.currency("masterypoint"))
  status.clearPersistentEffects("ivrpgmasteryunlocked")
  status.clearPersistentEffects("ivrpgchallenge1")
  status.clearPersistentEffects("ivrpgchallenge2")
  status.clearPersistentEffects("ivrpgchallenge3")
  status.clearPersistentEffects("ivrpgchallenge1progress")
  status.clearPersistentEffects("ivrpgchallenge2progress")
  status.clearPersistentEffects("ivrpgchallenge3progress")
end

function removeDeprecatedTechs()
  player.makeTechUnavailable("roguecloudjump")
  player.makeTechUnavailable("roguetoxiccapsule")
  player.makeTechUnavailable("roguepoisondash")
  player.makeTechUnavailable("soldiermissilestrike")
  player.makeTechUnavailable("explorerdrill")
end

function unequipUpgrade(name)
  name = "ivrpguc" .. name
  local effects = status.getPersistentEffects(name)
  local uc = effects[2].stat or "masterypoint"
  player.giveItem(uc)
  status.setPersistentEffects(name, {
    {stat = name, amount = 0}
  })
end