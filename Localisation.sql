--------------------------------------------------------------------------------------------------------------------------
-- LocalisedText
--------------------------------------------------------------------------------------------------------------------------
INSERT OR REPLACE INTO LocalizedText
		(Tag, 									Language,	Text)
VALUES
-- English US ------------------------------------------------------------------------------------------------------------
		("LOC_FF16_NOTIFICATION_LOG_TITLE",  	"en_US",	"NOTIFICATION LOG"),
		("LOC_FF16_LOGSIZE_OPTION", 	 		"en_US",	"Log Size:"),
		("LOC_FF16_MAXLOGSIZE_OPTION", 	 		"en_US",	"Maximum Size:"),
		("LOC_FF16_LOGSIZE_AUTO",  				"en_US",	"Auto"),
		("LOC_FF16_CLEARLOG_OPTION",	  		"en_US",	"Empty Log Between Turns"),
		("LOC_FF16_LOG_OPTIONS_TITLE",			"en_US",	"Notification Log Preferences"),
		("LOC_FF16_NOTIFICATION_LOG_TOOLTIP",	"en_US",	"Preferences"),
		("LOC_FF16_LOG_ENTRY_SINGLE",			"en_US",	"new gossip entry. Right click to empty the log."),
		("LOC_FF16_LOG_ENTRY_MULTIPLE",			"en_US",	"new gossip entries. Right click to empty the log."),

-- Japanese JP ------------------------------------------------------------------------------------------------------------

		("LOC_FF16_NOTIFICATION_LOG_TITLE",  	"ja_JP",	"通知ログ"),
		("LOC_FF16_LOGSIZE_OPTION", 	 		"ja_JP",	"ログのサイズ:"),
		("LOC_FF16_MAXLOGSIZE_OPTION", 	 		"ja_JP",	"最大サイズ:"),
		("LOC_FF16_LOGSIZE_AUTO",  				"ja_JP",	"自動"),
		("LOC_FF16_CLEARLOG_OPTION",	  		"ja_JP",	"ターン間の空のログ"),
		("LOC_FF16_LOG_OPTIONS_TITLE",			"ja_JP",	"通知ログの設定"),
		("LOC_FF16_NOTIFICATION_LOG_TOOLTIP",	"ja_JP",	"設定"),
		("LOC_FF16_LOG_ENTRY_SINGLE",			"ja_JP",	"件の新着情報"),
		("LOC_FF16_LOG_ENTRY_MULTIPLE",			"ja_JP",	"件の新着情報");