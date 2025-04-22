--------------------------------------------------------------------------------------------------------------------------
-- Default Preferences for Notification Log
--------------------------------------------------------------------------------------------------------------------------

INSERT OR REPLACE INTO GlobalParameters 
  VALUES  	("FF16_DEFAULT_LOGSIZE", 	0), -- Default starting log size on game load. 			Values = 0-8 | 0 = Auto Mode 
			("FF16_DEFAULT_MAXLOGSIZE", 8), -- Default maximum log size when using Auto mode. 	Values = 1-8
			("FF16_DEFAULT_EMPTYLOG", 	1);	-- Empty the log on next turn? 						Values = 0-1 | 0=No, 1=Yes