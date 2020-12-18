目录备份脚本
使用RSYNC增量备份。

支持设置备份数量。
支持备份日志。
支持自动清理。
支持排除列表文件。

备份错误时,日志后面自动添加"_ERROR"结尾。


命令行参数:
  BackupDirectory.CMD [配置[.cfg]]
  
  无参数时: 使用命令名.cfg为参数。
	        比如: 将命令脚本改名为 XXX.cmd ，
	              此时默认参数为XXX.cfg

Global.rules为全局规则文件
Run.CMD为执行全部任务，并记录日志。
