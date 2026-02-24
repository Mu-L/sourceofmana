extends ServiceBase

# Discord bot instance
var bot : DiscordBot			= null

# Configuration
var botToken : String			= ""
var channelID : String			= ""
var enabled : bool				= false

# State
var isBotReady : bool			= false

# Overrides
func _post_launch():
	isInitialized = true

func Destroy():
	if bot:
		bot.queue_free()
		bot = null

func _ready():
	# Initial copy of the cfg file
	var userConfigPath : String = Path.Local + "discord" + Path.ConfExt
	if not FileSystem.FileExists(userConfigPath):
		var defaultConfigPath : String = Path.ConfRsc + "discord" + Path.ConfExt
		if FileSystem.FileExists(defaultConfigPath):
			FileSystem.CopyFile(defaultConfigPath, userConfigPath)
			Util.PrintLog("Discord", "Copied default discord.cfg to user directory")

	enabled = Conf.GetBool("Default", "Discord-Enabled", Conf.Type.DISCORD)
	botToken = Conf.GetString("Default", "Discord-Token", Conf.Type.DISCORD)
	channelID = Conf.GetString("Default", "Discord-ChannelID", Conf.Type.DISCORD)

	if not enabled:
		Util.PrintInfo("Discord", "Discord bot disabled")
		return
	elif botToken.is_empty() or channelID.is_empty():
		Util.PrintInfo("Discord", "Discord bot not configured")
		return

	bot = DiscordBot.new()
	bot.name = "DiscordBot"
	bot.TOKEN = botToken
	bot.VERBOSE = OS.is_debug_build()

	bot.bot_ready.connect(_on_bot_ready)
	bot.message_create.connect(_on_message_create)

	add_child(bot)
	bot.login()

	Util.PrintLog("Discord", "Discord bot initializing...")

# Signals
func _on_bot_ready(_bot : DiscordBot):
	if _bot != bot:
		return

	isBotReady = true
	Util.PrintLog("Discord", "Discord bot ready! Connected as %s" % bot.user.username)

func _on_message_create(_bot : DiscordBot, message : Message, _channel : Dictionary):
	if not isBotReady or _bot != bot or message.author.id == bot.user.id or message.channel_id != channelID or message.content.is_empty():
		return

	Network.NotifyGlobal("ChatGlobal", [message.author.username, message.content])

# Utils
func SendToDiscord(playerName : String, messageText : String):
	if not isBotReady:
		return

	var formattedText : String = "**%s**: %s" % [playerName, messageText]
	bot.send(channelID, formattedText)

func SaveConfig():
	Conf.SetValue("Default", "Discord-Enabled", Conf.Type.DISCORD, enabled)
	Conf.SetValue("Default", "Discord-Token", Conf.Type.DISCORD, botToken)
	Conf.SetValue("Default", "Discord-ChannelID", Conf.Type.DISCORD, channelID)
	Conf.SaveType("discord", Conf.Type.DISCORD)
