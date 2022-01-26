// ----------------------------------------------------------
// This Source Code Form is subject to the terms of the
// Mozilla Public License, v.2.0. If a copy of the MPL
// was not distributed with this file, You can obtain one
// at http://mozilla.org/MPL/2.0/.
// ----------------------------------------------------------
// Codebase: https://github.com/ArKuznetsov/cpdb/
// ----------------------------------------------------------

Перем Лог;       // - Объект      - объект записи лога приложения

#Область СлужебныйПрограммныйИнтерфейс

// Процедура - устанавливает описание команды
//
// Параметры:
//  Команда    - КомандаПриложения     - объект описание команды
//
Процедура ОписаниеКоманды(Команда) Экспорт
	
	Команда.Опция("d sql-db", "", "имя базы для резервного копирования")
	       .ТСтрока()
	       .Обязательный()
	       .ВОкружении("CPDB_SQL_DATABASE");
	
	Команда.Опция("p bak-path", "", "путь к файлу резервной копии")
	       .ТСтрока()
	       .Обязательный()
	       .ВОкружении("CPDB_SQL_BACKUP_PATH");
	
	Команда.Опция("c create-db", Ложь, "создать базу в случае отсутствия")
	       .Флаговый()
	       .ВОкружении("CPDB_SQL_RESTORE_CREATE_DB");
	
	Команда.Опция("o db-owner", "", "имя владельца базы после восстановления")
	       .ТСтрока()
	       .ВОкружении("CPDB_SQL_RESTORE_DB_OWNER");
	
	Команда.Опция("cd compress-db", Ложь, "включить компрессию страниц таблиц и индексов после восстановления")
	       .Флаговый()
	       .ВОкружении("CPDB_SQL_RESTORE_COMPRESS_DB");
	
	Команда.Опция("sd shrink-db", Ложь, "сжать файлы данных после восстановления")
	       .Флаговый()
	       .ВОкружении("CPDB_SQL_RESTORE_SHRINK_DB");
	
	Команда.Опция("sl shrink-log", Ложь, "сжать файлы журнала транзакций после восстановления")
	       .Флаговый()
	       .ВОкружении("CPDB_SQL_RESTORE_SHRINK_LOG");
	
	Команда.Опция("pd db-path", , "путь к каталогу файлов данных базы после восстановления")
	       .ТСтрока()
	       .Обязательный()
	       .ВОкружении("CPDB_SQL_RESTORE_DATA_PATH");
	
	Команда.Опция("pl db-logpath", , "путь к каталогу файлов журнала после восстановления")
	       .ТСтрока()
	       .Обязательный()
	       .ВОкружении("CPDB_SQL_RESTORE_LOG_PATH");
	
	Команда.Опция("r db-recovery", "SIMPLE", "установить модель восстановления (RECOVERY MODEL),
	                                   |возможные значения ""FULL"", ""SIMPLE"",""BULK_LOGGED""")
	       .ТСтрока()
	       .ВОкружении("CPDB_SQL_RESTORE_RECOVERY_MODEL");
	
	Команда.Опция("cn db-changelfn", Ложь, "изменить логические имена файлов (LFN) базы, в соответствии с именем базы")
	       .Флаговый()
	       .ВОкружении("CPDB_SQL_RESTORE_CHANGE_LFN");
	
	Команда.Опция("ds delsrc", Ложь, "удалить файл резервной копии после восстановления")
	       .Флаговый()
	       .ВОкружении("CPDB_SQL_RESTORE_DELSRC");
	
КонецПроцедуры // ОписаниеКоманды()

// Процедура - запускает выполнение команды устанавливает описание команды
//
// Параметры:
//  Команда    - КомандаПриложения     - объект  описание команды
//
Процедура ВыполнитьКоманду(Знач Команда) Экспорт

	ВыводОтладочнойИнформации = Команда.ЗначениеОпции("verbose");

	ПараметрыПриложения.УстановитьРежимОтладки(ВыводОтладочнойИнформации);

	Если НЕ ПараметрыПриложения.ОбязательныеПараметрыЗаполнены(Команда) Тогда
		Команда.ВывестиСправку();
		Возврат;
	КонецЕсли;

	ПараметрыПодключения = Новый Структура("Сервер, Пользователь, ПарольПользователя");
	ПараметрыПодключения.Сервер               = Команда.ЗначениеОпцииКомандыРодителя("sql-srvr");
	ПараметрыПодключения.Пользователь         = Команда.ЗначениеОпцииКомандыРодителя("sql-user");
	ПараметрыПодключения.ПарольПользователя   = Команда.ЗначениеОпцииКомандыРодителя("sql-pwd");

	База                 = Команда.ЗначениеОпции("sql-db");
	ПутьКРезервнойКопии  = Команда.ЗначениеОпции("bak-path");
	СоздаватьБазу        = Команда.ЗначениеОпции("create-db");
	ВладелецБазы         = Команда.ЗначениеОпции("db-owner");
	ВключитьКомпрессию   = Команда.ЗначениеОпции("compress-db");
	СжатьБазу            = Команда.ЗначениеОпции("shrink-db");
	СжатьФайлЛог         = Команда.ЗначениеОпции("shrink-log");
	ПутьКФайлуДанных     = Команда.ЗначениеОпции("db-path");
	ПутьКФайлуЖурнала    = Команда.ЗначениеОпции("db-logpath");
	МодельВосстановления = Команда.ЗначениеОпции("db-recovery");
	ИзменитьЛИФ          = Команда.ЗначениеОпции("db-changelfn");
	УдалитьИсточник      = Команда.ЗначениеОпции("delsrc");

	ПодключениеКСУБД = Новый ИнструментыСУБД(ПараметрыПодключения.Сервер,
	                                         ПараметрыПодключения.Пользователь,
	                                         ПараметрыПодключения.ПарольПользователя);
	
	ВыполнитьВосстановление(ПодключениеКСУБД,
	                        База,
	                        ПутьКРезервнойКопии,
	                        ПутьКФайлуДанных,
	                        ПутьКФайлуЖурнала,
	                        СоздаватьБазу);

	Если УдалитьИсточник Тогда
		УдалитьИсточник(ПутьКРезервнойКопии);
	КонецЕсли;
	
	Если ЗначениеЗаполнено(ВладелецБазы) Тогда
		ИзменитьВладельца(ПодключениеКСУБД, База, ВладелецБазы);
	КонецЕсли;
	
	Если ЗначениеЗаполнено(МодельВосстановления) Тогда
		ИзменитьМодельВосстановления(ПодключениеКСУБД, База, МодельВосстановления);
	КонецЕсли;
	
	Если ИзменитьЛИФ Тогда
		ИзменитьЛогическиеИменаФайлов(ПодключениеКСУБД, База);
	КонецЕсли;
	
	КомандаКомпрессии = Новый КомандаВыполнитьКомпрессиюСтраниц();

	Если ВключитьКомпрессию Тогда
		КомандаКомпрессии.ВключитьКомпрессию(ПодключениеКСУБД, База);
	КонецЕсли;
	
	Если СжатьБазу Тогда
		КомандаКомпрессии.СжатьБазу(ПодключениеКСУБД, База);
	КонецЕсли;
	
	Если СжатьФайлЛог Тогда
		КомандаКомпрессии.СжатьФайлЛог(ПодключениеКСУБД, База);
	КонецЕсли;
	
КонецПроцедуры // ВыполнитьКоманду()

#КонецОбласти // СлужебныйПрограммныйИнтерфейс

#Область СлужебныеПроцедурыИФункции

// Удаляет файл-источник резервной копии
//   
// Параметры:
//   ПодключениеКСУБД        - ИнструментыСУБД    - объект подключения к СУБД
//   База                    - Строка             - имя базы
//   ПутьКРезервнойКопии     - Строка             - путь к файлу резервной копии
//   ПутьКФайлуДанных        - Строка             - путь к файлу данных базы
//   ПутьКФайлуЖурнала       - Строка             - путь к файлу журнала транзакций базы
//   СоздаватьБазу           - Булево             - Истина - создать базу в случае отсутствия
//
Процедура ВыполнитьВосстановление(ПодключениеКСУБД,
                                  База,
                                  ПутьКРезервнойКопии,
                                  ПутьКФайлуДанных,
                                  ПутьКФайлуЖурнала,
                                  СоздаватьБазу)

	Лог.Информация("Начало восстановления базы ""%1\%2"" из резервной копии ""%3""",
	               ПодключениеКСУБД.Сервер(),
	               База,
	               ПутьКРезервнойКопии);

	Попытка
	
		ОписаниеРезультата = "";

		Результат = ПодключениеКСУБД.ВосстановитьИзРезервнойКопии(База,
		                                                          ПутьКРезервнойКопии,
		                                                          ПутьКФайлуДанных,
		                                                          ПутьКФайлуЖурнала,
		                                                          СоздаватьБазу,
		                                                          ОписаниеРезультата);

		Если Результат Тогда
			Лог.Информация("Выполнено восстановление базы ""%1"" из резервной копии ""%2"": %3",
			               База,
			               ПутьКРезервнойКопии,
			               ОписаниеРезультата);
		Иначе
			ТекстОшибки = СтрШаблон("Ошибка восстановления базы ""%1"" из резервной копии ""%2"": %3",
			                        База,
			                        ПутьКРезервнойКопии,
			                        ОписаниеРезультата); 
			ВызватьИсключение ТекстОшибки;
		КонецЕсли;

	Исключение
		ТекстОшибки = СтрШаблон("Ошибка восстановления базы ""%1"" из резервной копии ""%2"": %3",
		                        База,
		                        ПутьКРезервнойКопии,
		                        ОписаниеОшибки());
		ВызватьИсключение ТекстОшибки;
	КонецПопытки;

КонецПроцедуры // ВыполнитьВосстановление()

// Удаляет файл-источник резервной копии
//   
// Параметры:
//   ПутьКРезервнойКопии     - Строка   - путь к файлу резервной копии
//
Процедура УдалитьИсточник(ПутьКРезервнойКопии)

	Попытка
		УдалитьФайлы(ПутьКРезервнойКопии);
		Лог.Информация("Исходный файл %1 удален", ПутьКРезервнойКопии);
	Исключение
		ТекстОшибки = СтрШаблон("Ошибка удаления файла %1: %2",
		                        ПутьКРезервнойКопии,
		                        ПодробноеПредставлениеОшибки(ИнформацияОбОшибке()));
		ВызватьИсключение ТекстОшибки;
	КонецПопытки;

КонецПроцедуры // УдалитьИсточник()

// Устанавливает нового владельца базы
//   
// Параметры:
//   ПодключениеКСУБД    - ИнструментыСУБД    - объект подключения к СУБД
//   База                - Строка             - имя базы
//   ВладелецБазы        - Строка             - новый владелец базы
//
Процедура ИзменитьВладельца(ПодключениеКСУБД, База, ВладелецБазы)

	Попытка
		Результат = ПодключениеКСУБД.УстановитьВладельцаБазы(База, ВладелецБазы);

		Если НЕ Результат Тогда
			ТекстОшибки = СтрШаблон("Ошибка смены владельца базы ""%1"" на ""%2""",
			                        База,
			                        ВладелецБазы);
			ВызватьИсключение ТекстОшибки;
		КонецЕсли;

		Лог.Информация("Для базы ""%1"" установлен новый владелец ""%2""",
		               База,
		               ВладелецБазы);
	Исключение
		ТекстОшибки = СтрШаблон("Ошибка смены владельца базы ""%1"" на ""%2"": %3",
		                        База,
		                        ВладелецБазы,
		                        ПодробноеПредставлениеОшибки(ИнформацияОбОшибке()));
		ВызватьИсключение ТекстОшибки;
	КонецПопытки;

КонецПроцедуры // ИзменитьВладельца()

// Устанавливает нового владельца базы
//   
// Параметры:
//   ПодключениеКСУБД       - ИнструментыСУБД    - объект подключения к СУБД
//   База                   - Строка             - имя базы
//   МодельВосстановления   - Строка             - новая модель восстановления (FULL, SIMPLE, BULK_LOGGED)
//
Процедура ИзменитьМодельВосстановления(ПодключениеКСУБД, База, МодельВосстановления)

	Попытка
		Результат = ПодключениеКСУБД.УстановитьМодельВосстановления(База, МодельВосстановления);

		Если НЕ Результат Тогда
			ТекстОшибки = СтрШаблон("Ошибка смены модели восстановления базы ""%1"" на ""%2""",
			                        База,
			                        МодельВосстановления);
			ВызватьИсключение ТекстОшибки;
		КонецЕсли;

		Лог.Информация("Для базы ""%1"" установлена модель восстановления ""%2""",
		               База,
		               МодельВосстановления);
	Исключение
		ТекстОшибки = СтрШаблон("Ошибка смены модели восстановления базы ""%1"" на ""%2"": %3",
		                        База,
		                        МодельВосстановления,
		                        ПодробноеПредставлениеОшибки(ИнформацияОбОшибке()));
		ВызватьИсключение ТекстОшибки;
	КонецПопытки;

КонецПроцедуры // ИзменитьМодельВосстановления()

// Устанавливает логические имена файлов базы в соответствии с именем базы
//   
// Параметры:
//   ПодключениеКСУБД    - ИнструментыСУБД    - объект подключения к СУБД
//   База                - Строка             - имя базы
//
Процедура ИзменитьЛогическиеИменаФайлов(ПодключениеКСУБД, База)

	Попытка
		ЛИФ = ПодключениеКСУБД.ПолучитьЛогическоеИмяФайлаВБазе(База, "ROWS");
		НовоеЛИФ = База;
		Результат = ПодключениеКСУБД.ИзменитьЛогическоеИмяФайлаБазы(База, ЛИФ, НовоеЛИФ);

		Если НЕ Результат Тогда
			ТекстОшибки = СтрШаблон("Ошибка изменения логического имени файла данных ""%1"" в базе ""%2""",
			                        ЛИФ,
			                        База);
			ВызватьИсключение ТекстОшибки;
		КонецЕсли;

		Лог.Информация("Для базы ""%1"" изменено логическое имя файла данных ""%2"" на ""%3""",
		               База,
		               ЛИФ,
		               НовоеЛИФ);
	Исключение
		ТекстОшибки = СтрШаблон("Ошибка изменения логического имени файла данных ""%1"" в базе ""%2"": %3",
		                        ЛИФ,
		                        База,
		                        ПодробноеПредставлениеОшибки(ИнформацияОбОшибке()));
		ВызватьИсключение ТекстОшибки;
	КонецПопытки;
	
	Попытка
		ЛИФ = ПодключениеКСУБД.ПолучитьЛогическоеИмяФайлаВБазе(База, "LOG");
		НовоеЛИФ = База + "_log";
		Результат = ПодключениеКСУБД.ИзменитьЛогическоеИмяФайлаБазы(База, ЛИФ, НовоеЛИФ);

		Если НЕ Результат Тогда
			ТекстОшибки = СтрШаблон("Ошибка изменения логического имени файла журнала ""%1"" в базе ""%2""",
			                        ЛИФ,
			                        База);
			ВызватьИсключение ТекстОшибки;
		КонецЕсли;

		Лог.Информация("Для базы ""%1"" изменено логическое имя файла журнала ""%2"" на ""%3""",
		               База,
		               ЛИФ,
		               НовоеЛИФ);
	Исключение
		ТекстОшибки = СтрШаблон("Ошибка изменения логического имени файла журнала ""%1"" в базе ""%2"": %3",
		                        ЛИФ,
		                        База,
		                        ПодробноеПредставлениеОшибки(ИнформацияОбОшибке()));
		ВызватьИсключение ТекстОшибки;
	КонецПопытки;

КонецПроцедуры // ИзменитьЛогическиеИменаФайлов()

#КонецОбласти // СлужебныеПроцедурыИФункции

#Область ОбработчикиСобытий

// Процедура - обработчик события "ПриСозданииОбъекта"
//
// BSLLS:UnusedLocalMethod-off
Процедура ПриСозданииОбъекта()

	Лог = ПараметрыПриложения.Лог();

КонецПроцедуры // ПриСозданииОбъекта()
// BSLLS:UnusedLocalMethod-on

#КонецОбласти // ОбработчикиСобытий
