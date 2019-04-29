require "/scripts/util.lua"

function init()
	quest.setCompletionText("RPG Growth正在关闭这个任务. 请不要担心它已经完成了.")
	quest.setFailureText("RPG Growth正在关闭这个任务. 请不要担心它已经失败了.")
	quest.fail()
end

function update(dt)
	
end
