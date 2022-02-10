// ----------------------------------------------------------
// This Source Code Form is subject to the terms of the
// Mozilla Public License, v.2.0. If a copy of the MPL
// was not distributed with this file, You can obtain one
// at http://mozilla.org/MPL/2.0/.
// ----------------------------------------------------------
// Codebase: https://github.com/ArKuznetsov/cpdb/
// ----------------------------------------------------------

// Процедура - устанавливает описание команды
//
// Параметры:
//  Команда    - КомандаПриложения     - объект описание команды
//
Процедура ОписаниеКоманды(Команда) Экспорт
	
	Команда.ДобавитьКоманду("script scripts s",
	                        "выполнить произвольные скрипты в СУБД",
	                        Новый КомандаВыполнитьСкрипты());

	Команда.ДобавитьКоманду("backup b",
	                        "создать резервную копию базы данных",
	                        Новый КомандаСоздатьРезервнуюКопию());

	Команда.ДобавитьКоманду("restore r",
	                        "восстановить базу данных из резервной копии",
	                        Новый КомандаВосстановитьИзРезервнойКопии());
	
	Команда.ДобавитьКоманду("compress c",
	                        "выполнить сжатие страниц базы данных",
	                        Новый КомандаВыполнитьКомпрессиюСтраниц());

	Команда.Опция("s sql-srvr", "", "адрес сервера СУБД")
	       .ТСтрока()
	       .Обязательный()
	       .ВОкружении("CPDB_SQL_SRVR");

	Команда.Опция("u sql-user", "", "Пользователь сервера СУБД")
	       .ТСтрока()
	       .Обязательный()
	       .ВОкружении("CPDB_SQL_USER");
	
	Команда.Опция("p sql-pwd", "", "Пароль пользователя сервера СУБД")
	       .ТСтрока()
	       .ВОкружении("CPDB_SQL_PWD");

КонецПроцедуры // ОписаниеКоманды()
