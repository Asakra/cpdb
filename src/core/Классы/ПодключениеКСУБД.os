// ----------------------------------------------------------
// This Source Code Form is subject to the terms of the
// Mozilla Public License, v.2.0. If a copy of the MPL
// was not distributed with this file, You can obtain one
// at http://mozilla.org/MPL/2.0/.
// ----------------------------------------------------------
// Codebase: https://github.com/ArKuznetsov/cpdb/
// ----------------------------------------------------------

#Использовать 1commands
#Использовать fs

Перем Лог;           // - Объект    - объект записи лога приложения
Перем Сервер;        // - Строка    - адрес сервера СУБД
Перем Пользователь;  // - Строка    - Пользователь сервера СУБД
Перем Пароль;        // - Строка    - Пароль пользователя сервера СУБД

#Область ПрограммныйИнтерфейс

Функция Сервер() Экспорт

	Возврат Сервер;

КонецФункции // Сервер()

Процедура УстановитьСервер(Знач НовоеЗначение) Экспорт

	Сервер = НовоеЗначение;

КонецПроцедуры // УстановитьСервер()

Функция Пользователь() Экспорт

	Возврат Пользователь;

КонецФункции // Пользователь()

Процедура УстановитьПользователь(Знач НовоеЗначение) Экспорт

	Пользователь = НовоеЗначение;

КонецПроцедуры // УстановитьПользователь()

Процедура УстановитьПароль(Знач НовоеЗначение) Экспорт

	Пароль = НовоеЗначение;

КонецПроцедуры // УстановитьПароль()

////////////////////////////////////////////////////////////////////////////////
// Работа с СУБД

// Функция проверяет существование базу на сервере СУБД
//
// Параметры:
//   База                              - Строка    - имя базы данных
//   ВариантСообщенияОСуществовании    - Строка    - в каких случаях выводить сообщение о существании БД
//
// Возвращаемое значение:
//   Булево       - Истина - база существует на сервере СУБД
//
Функция БазаСуществует(База, ВариантСообщенияОСуществовании = Неопределено) Экспорт

	ТекстЗапроса = СтрШаблон("""SET NOCOUNT ON;
	                         |SELECT
	                         |	COUNT(name)
	                         |FROM
	                         |	sysdatabases
	                         |WHERE
	                         |	name = '%1';
	                         |
	                         |SET NOCOUNT OFF""",
	                         База);
	
	РезультатЗапроса = "";
	КодВозврата = ВыполнитьЗапросСУБД(ТекстЗапроса, РезультатЗапроса);

	Если КодВозврата = 0 Тогда
		РезультатЗапроса = СокрЛП(СтрЗаменить(РезультатЗапроса, "-", ""));
		Результат = РезультатЗапроса = "1";
	Иначе
		Результат = Ложь;
	КонецЕсли;

	ВариантыСообщения = ВариантыСообщенияОСуществованииБД();

	Если НЕ ЗначениеЗаполнено(ВариантСообщенияОСуществовании) Тогда
		ВариантСообщенияОСуществовании = ВариантыСообщения.НеСообщать;
	КонецЕсли;

	Если ВариантСообщенияОСуществовании = ВариантыСообщения.СообщатьОСуществовании
	   И Результат Тогда
		Лог.Предупреждение("База ""%1"" уже существует!", База);
	ИначеЕсли ВариантСообщенияОСуществовании = ВариантыСообщения.СообщатьОбОтсутствии
	        И НЕ Результат Тогда
		Лог.Предупреждение("База ""%1"" не существует!", База);
	ИначеЕсли Результат Тогда
		Лог.Отладка("База ""%1"" существует!", База);
	Иначе
		Лог.Отладка("База ""%1"" не существует!", База);
	КонецЕсли;

	Возврат Результат;

КонецФункции // БазаСуществует()

// Функция выполняет команду создания базы на сервере СУБД
//
// Параметры:
//   База                    - Строка    - имя базы данных
//   МодельВосстановления    - Строка    - новая модель восстановления (FULL, SIMPLE, BULK_LOGGED)
//   ПутьККаталогу           - Строка    - путь к каталогу для размещения файлов базы данных
//                                         если не указан, то файлы размещаются в каталоге по умолчанию SQL Server
//   ОписаниеРезультата      - Строка    - результат выполнения команды
//
// Возвращаемое значение:
//   Булево      - Истина - команда выполнена успешно
//
Функция СоздатьБазу(База,
	                Знач МодельВосстановления = Неопределено,
	                Знач ПутьККаталогу = "",
	                ОписаниеРезультата = "") Экспорт

	Если БазаСуществует(База, ВариантыСообщенияОСуществованииБД().СообщатьОСуществовании) Тогда
		Возврат Ложь;
	КонецЕсли;

	Если НЕ ЗначениеЗаполнено(МодельВосстановления) Тогда
		МодельВосстановления = МоделиВосстановленияБД().Полная;
	КонецЕсли;

	ПутьККаталогу = ФС.ПолныйПуть(ПутьККаталогу);

	Если ЗначениеЗаполнено(ПутьККаталогу) Тогда
		ТекстЗапроса = СтрШаблон("""USE [master];
	                         |
	                         |CREATE DATABASE [%1]
	                         |ON
	                         |( NAME = %1,
	                         |  FILENAME = '%2\%1.mdf')
	                         |LOG ON
	                         |( NAME = %1_log,
	                         |  FILENAME = '%2\%1_log.ldf');
	                         |
	                         |ALTER DATABASE [%1]
	                         |SET RECOVERY %3""",
	                         База,
	                         ПутьККаталогу,
	                         МодельВосстановления);
	Иначе
		ТекстЗапроса = СтрШаблон("""USE [master];
	                         |
	                         |CREATE DATABASE [%1];
	                         |
	                         |ALTER DATABASE [%1]
	                         |SET RECOVERY %2""",
	                         База,
	                         МодельВосстановления);
	КонецЕсли;

	КодВозврата = ВыполнитьЗапросСУБД(ТекстЗапроса, ОписаниеРезультата);
	
	Возврат КодВозврата = 0;
	
КонецФункции // СоздатьБазу()

// Функция выполняет команду удаления базы на сервере СУБД
//
// Параметры:
//    База                    - Строка    - имя базы данных
//    ОписаниеРезультата      - Строка    - результат выполнения команды
//
// Возвращаемое значение:
//    Булево      - Истина - команда выполнена успешно
//
Функция УдалитьБазу(База, ОписаниеРезультата = "") Экспорт

	Если НЕ БазаСуществует(База, ВариантыСообщенияОСуществованииБД().СообщатьОбОтсутствии) Тогда
		Возврат Ложь;
	КонецЕсли;

	ТекстЗапроса = СтрШаблон("""USE [master];
	                         |
	                         |DROP DATABASE [%1]""",
	                         База);
	
	КодВозврата = ВыполнитьЗапросСУБД(ТекстЗапроса, ОписаниеРезультата);
	
	Возврат КодВозврата = 0;
	
КонецФункции // УдалитьБазу()

// Функция получает модель восстановления базы
//
// Параметры:
//    База                   - Строка    - имя базы данных
//
// Возвращаемое значение:
//    Строка       - модель восстановления (FULL, SIMPLE, BULK_LOGGED)
//
Функция ПолучитьМодельВосстановления(База) Экспорт

	Если НЕ БазаСуществует(База, ВариантыСообщенияОСуществованииБД().СообщатьОбОтсутствии) Тогда
		Возврат Неопределено;
	КонецЕсли;

	ТекстЗапроса = СтрШаблон("""SET NOCOUNT ON;
	                         |
	                         |SELECT
	                         |  [recovery_model_desc] AS Recovery_model
	                         |FROM sys.databases
	                         |
	                         |WHERE name = '%1';
	                         |
	                         |SET NOCOUNT OFF;""",
	                         База);
	
	РезультатЗапроса = "";

	КодВозврата = ВыполнитьЗапросСУБД(ТекстЗапроса, РезультатЗапроса);
	
	Если КодВозврата = 0 Тогда
		Разделитель = "---";
		Поз = СтрНайти(РезультатЗапроса, Разделитель, НаправлениеПоиска.FromEnd);
		РезультатЗапроса = ВРег(СокрЛП(Сред(РезультатЗапроса, Поз + СтрДлина(Разделитель))));
	Иначе
		РезультатЗапроса = Неопределено;
	КонецЕсли;

	Возврат РезультатЗапроса;
	
КонецФункции // ПолучитьМодельВосстановления()

// Функция устанавливает модель восстановления базы
//
// Параметры:
//    База                   - Строка    - имя базы данных
//    МодельВосстановления   - Строка    - новая модель восстановления (FULL, SIMPLE, BULK_LOGGED)
//    ОписаниеРезультата     - Строка    - результат выполнения команды
//
// Возвращаемое значение:
//    Булево       - Истина - команда выполнена успешно
//
Функция УстановитьМодельВосстановления(База, МодельВосстановления = Неопределено, ОписаниеРезультата = "") Экспорт

	Если Найти("FULL,SIMPLE,BULK_LOGGED", ВРег(МодельВосстановления)) = 0 Тогда
		Лог.Предупреждение("Указана некорректная модель восстановления ""%1""
		                   | (возможные значения: ""FULL"", ""SIMPLE"", ""BULK_LOGGED"")!",
		                   МодельВосстановления);
		Возврат Ложь;
	КонецЕсли;

	Если НЕ БазаСуществует(База, ВариантыСообщенияОСуществованииБД().СообщатьОбОтсутствии) Тогда
		Возврат Ложь;
	КонецЕсли;

	ТекстЗапроса = СтрШаблон("""USE [master];
	                         |
	                         |ALTER DATABASE %1
	                         |SET RECOVERY %2""",
	                         База,
	                         ВРег(МодельВосстановления));
	
	КодВозврата = ВыполнитьЗапросСУБД(ТекстЗапроса, ОписаниеРезультата);
	
	Возврат КодВозврата = 0;
	
КонецФункции // УстановитьМодельВосстановления()

// Функция изменяет владельца базы
//
// Параметры:
//   База    - Строка    - имя базы данных
//
// Возвращаемое значение:
//   Строка    - имя текущего владельца базы
//
Функция ПолучитьВладельцаБазы(База) Экспорт

	Если НЕ БазаСуществует(База, ВариантыСообщенияОСуществованииБД().СообщатьОбОтсутствии) Тогда
		Возврат Ложь;
	КонецЕсли;

	ТекстЗапроса = СтрШаблон("""SET NOCOUNT ON;
	                         |
	                         |SELECT
	                         |  logins.name AS login
	                         |
                             |FROM sys.databases AS databases
                             |LEFT JOIN sys.syslogins AS logins
                             |ON databases.owner_sid = logins.sid
	                         |
                             |WHERE databases.name = '%1'
                             |
                             |SET NOCOUNT OFF;""",
                             База);
	
	РезультатЗапроса = "";

	КодВозврата = ВыполнитьЗапросСУБД(ТекстЗапроса, РезультатЗапроса);
	
	Если КодВозврата = 0 Тогда
		Разделитель = "---";
		Поз = СтрНайти(РезультатЗапроса, Разделитель, НаправлениеПоиска.FromEnd);
		РезультатЗапроса = СокрЛП(Сред(РезультатЗапроса, Поз + СтрДлина(Разделитель)));
	Иначе
		РезультатЗапроса = Неопределено;
	КонецЕсли;

	Возврат РезультатЗапроса;
	
КонецФункции // ПолучитьВладельцаБазы()

// Функция изменяет владельца базы
//
// Параметры:
//    База                 - Строка    - имя базы данных
//    НовыйВладелец        - Строка    - новый владелец базы
//    ОписаниеРезультата   - Строка    - результат выполнения команды
//
// Возвращаемое значение:
//    Булево    - Истина - команда выполнена успешно
//
Функция УстановитьВладельцаБазы(База, НовыйВладелец, ОписаниеРезультата = "") Экспорт

	Если НЕ БазаСуществует(База, ВариантыСообщенияОСуществованииБД().СообщатьОбОтсутствии) Тогда
		Возврат Ложь;
	КонецЕсли;

	ТекстЗапроса = СтрШаблон("""ALTER AUTHORIZATION ON DATABASE::%1 TO %2""", База, НовыйВладелец);
	
	КодВозврата = ВыполнитьЗапросСУБД(ТекстЗапроса, ОписаниеРезультата);
	
	Возврат КодВозврата = 0;
	
КонецФункции // УстановитьВладельцаБазы()

// Функция выполняет сжатие базы (shrink)
//
// Параметры:
//    База                 - Строка    - имя базы данных
//    ОписаниеРезультата   - Строка    - результат выполнения команды
//
// Возвращаемое значение:
//    Булево    - Истина - команда выполнена успешно
//
Функция СжатьБазу(База, ОписаниеРезультата = "") Экспорт

	Если НЕ БазаСуществует(База, ВариантыСообщенияОСуществованииБД().СообщатьОбОтсутствии) Тогда
		Возврат Ложь;
	КонецЕсли;

	ТекстЗапроса = СтрШаблон("""DBCC SHRINKDATABASE(N'%1', 0)""", База);
	
	КодВозврата = ВыполнитьЗапросСУБД(ТекстЗапроса, ОписаниеРезультата);
	
	Возврат КодВозврата = 0;
	
КонецФункции // СжатьБазу()

// Функция выполняет сжатие файла лог (shrink)
//
// Параметры:
//    База                - Строка - Имя базы данных
//    ОписаниеРезультата  - Строка - результат выполнения команды
//
// Возвращаемое значение:
//    Булево    - Истина - команда выполнена успешно
//
Функция СжатьФайлЖурналаТранзакций(База, ОписаниеРезультата = "") Экспорт

	Если НЕ БазаСуществует(База, ВариантыСообщенияОСуществованииБД().СообщатьОбОтсутствии) Тогда
		Возврат Ложь;
	КонецЕсли;
	
	ЛогическоеИмяФайлаЖурнала = ПолучитьЛогическоеИмяФайлаВБазе(База, "L");

	ТекстЗапроса = СтрШаблон("""USE [%1];
	                         |
	                         |DBCC SHRINKFILE(N'%2', 0, TRUNCATEONLY); """,
	                         База,
	                         ЛогическоеИмяФайлаЖурнала);
	
	КодВозврата = ВыполнитьЗапросСУБД(ТекстЗапроса, ОписаниеРезультата);
	
	Возврат КодВозврата = 0;
	
КонецФункции // СжатьФайлЖурналаТранзакций()

// Функция выполняет выполняет компрессию базы и индексов на уровне страниц (DATA_COMPRESSION = PAGE)
//
// Параметры:
//    База                 - Строка    - имя базы данных
//    КомпрессияТаблиц     - Булево    - Истина - будет выполнена компрессия таблиц базы
//    КомпрессияИндексов   - Булево    - Истина - будет выполнена компрессия индексов базы
//    ОписаниеРезультата   - Строка    - результат выполнения команды
//
// Возвращаемое значение:
//    Булево    - Истина - команда выполнена успешно
//
Функция ВключитьКомпрессиюСтраниц(База,
                                  КомпрессияТаблиц = Истина,
                                  КомпрессияИндексов = Истина,
                                  ОписаниеРезультата = "") Экспорт

	ОписаниеВерсии = ПолучитьВерсиюСУБД();

	Если НЕ ДоступностьФункционалаСУБД("Компрессия", ОписаниеВерсии) Тогда
		Лог.Предупреждение("Для данной версии СУБД ""MS SQL Server %1 %2""
		                   |не доступна функциональность компресии страниц!",
		                   ОписаниеВерсии.Версия,
		                   ОписаниеВерсии.Редакция);
		Возврат Истина;
	КонецЕсли;

	Если НЕ (КомпрессияТаблиц ИЛИ КомпрессияИндексов) Тогда
		Лог.Предупреждение("Не указан флаг включения компрессии страниц для индексов или таблиц!");
		Возврат Истина;
	КонецЕсли;

	Если НЕ БазаСуществует(База, ВариантыСообщенияОСуществованииБД().СообщатьОбОтсутствии) Тогда
		Возврат Ложь;
	КонецЕсли;

	ТекстЗапроса = СтрШаблон("""USE [%1];", База);
	Если КомпрессияТаблиц Тогда
		ТекстЗапроса = СтрШаблон("%1%2EXEC sp_MSforeachtable 'ALTER TABLE ? REBUILD WITH (DATA_COMPRESSION = PAGE)'",
		                         ТекстЗапроса,
		                         Символы.ПС);
	КонецЕсли;

	Если КомпрессияИндексов Тогда
		ТекстЗапроса = СтрШаблон("%1%2EXEC sp_MSforeachtable 'ALTER INDEX ALL ON ? REBUILD WITH (DATA_COMPRESSION = PAGE)'",
		                         ТекстЗапроса,
		                         Символы.ПС);
	КонецЕсли;

	ТекстЗапроса = СтрШаблон("%1""", ТекстЗапроса);
	
	КодВозврата = ВыполнитьЗапросСУБД(ТекстЗапроса, ОписаниеРезультата);
	
	Возврат КодВозврата = 0;
	
КонецФункции // ВключитьКомпрессиюСтраниц()

// Функция создает файл резервной копии базы
//
// Параметры:
//    База                 - Строка    - имя базы данных
//    ПутьКРезервнойКопии  - Строка    - путь к файлу резервной копии
//    ОписаниеРезультата   - Строка    - результат выполнения команды
//
// Возвращаемое значение:
//    Булево    - Истина - команда выполнена успешно
//
Функция СоздатьРезервнуюКопию(База, Знач ПутьКРезервнойКопии, ОписаниеРезультата = "") Экспорт
	
	Если НЕ БазаСуществует(База, ВариантыСообщенияОСуществованииБД().СообщатьОбОтсутствии) Тогда
		Возврат Ложь;
	КонецЕсли;

	ПутьКРезервнойКопии = ФС.ПолныйПуть(ПутьКРезервнойКопии);

	ТекстЗапроса = СтрШаблон("""BACKUP DATABASE [%1] TO DISK = N'%2'
	                         |WITH NOFORMAT, INIT, NAME = N'%1 FULL Backup',
	                         |SKIP,
	                         |NOREWIND,
	                         |NOUNLOAD,
	                         |COMPRESSION,
	                         |STATS = 10""",
	                         База,
	                         ПутьКРезервнойКопии);
	
	КодВозврата = ВыполнитьЗапросСУБД(ТекстЗапроса, ОписаниеРезультата);

	Возврат КодВозврата = 0;
	
КонецФункции // СоздатьРезервнуюКопию()

// Функция выполняет восстановление базы из файла с резервной копией
//
// Параметры:
//    База                 - Строка    - имя базы данных
//    ПутьКРезервнойКопии  - Строка    - путь к файлу резервной копии
//    ПутьКФайлуДанных     - Строка    - путь к файлу базы
//    ПутьКФайлуЖурнала    - Строка    - путь к файлу журнала (transaction log) базы
//    СоздаватьБазу        - Булево    - Истина - будет создана новая база в случае отсутствия
//    ОписаниеРезультата   - Строка    - результат выполнения команды
//
// Возвращаемое значение:
//    Булево    - Истина - команда выполнена успешно
//
Функция ВосстановитьИзРезервнойКопии(База,
                                     Знач ПутьКРезервнойКопии,
                                     Знач ПутьКФайлуДанных = "",
                                     Знач ПутьКФайлуЖурнала = "",
                                     СоздаватьБазу = Ложь,
                                     ОписаниеРезультата = "") Экспорт
	
	Если НЕ БазаСуществует(База, ВариантыСообщенияОСуществованииБД().СообщатьОбОтсутствии) Тогда
		Если НЕ СоздаватьБазу Тогда
			Возврат Ложь;
		Иначе
			Если НЕ СоздатьБазу(База, МоделиВосстановленияБД().Простая, ОписаниеРезультата) Тогда
				Возврат Ложь;
			КонецЕсли;
		КонецЕсли;
	КонецЕсли;

	ПутьКРезервнойКопии = ФС.ПолныйПуть(ПутьКРезервнойКопии);

	Если ЗначениеЗаполнено(ПутьКФайлуДанных) Тогда
		ПутьКФайлуДанных = ФС.ПолныйПуть(ПутьКФайлуДанных);
	Иначе
		ПутьКФайлуДанных = РасположениеФайловБазПоУмолчанию("D");
	КонецЕсли;

	Если ЗначениеЗаполнено(ПутьКФайлуЖурнала) Тогда
		ПутьКФайлуЖурнала = ФС.ПолныйПуть(ПутьКФайлуЖурнала);
	Иначе
		ПутьКФайлуЖурнала = РасположениеФайловБазПоУмолчанию("L");
	КонецЕсли;
	
	ЛогическоеИмяФайлаДанных = ПолучитьЛогическоеИмяФайлаВРезервнойКопии(ПутьКРезервнойКопии, "D");
	ЛогическоеИмяФайлаЖурнала = ПолучитьЛогическоеИмяФайлаВРезервнойКопии(ПутьКРезервнойКопии, "L");

	ТекстЗапроса = СтрШаблон("""USE [master];
	                         |
	                         |ALTER DATABASE [%1] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
	                         |
	                         |RESTORE DATABASE [%1] FROM  DISK = N'%2' WITH  FILE = 1,
	                         |MOVE N'%3' TO N'%4\%1.mdf',
	                         |MOVE N'%5' TO N'%6\%1_log.ldf',
	                         |NOUNLOAD,  REPLACE,  STATS = 10;
	                         |
	                         |ALTER DATABASE [%1] SET MULTI_USER""",
	                         База,
	                         ПутьКРезервнойКопии,
	                         ЛогическоеИмяФайлаДанных,
	                         ПутьКФайлуДанных,
	                         ЛогическоеИмяФайлаЖурнала,
	                         ПутьКФайлуЖурнала);
	
	КодВозврата = ВыполнитьЗапросСУБД(ТекстЗапроса, ОписаниеРезультата);

	Возврат КодВозврата = 0;

КонецФункции // ВосстановитьИзРезервнойКопии()

// Функция возвращает логическое имя файла в резервной копии
//
// Параметры:
//    ПутьКРезервнойКопии    - Строка    - путь к файлу резервной копии
//    ТипФайла               - Строка    - D - файл данных; L - файл журнала транзакций
//
// Возвращаемое значение:
//    Строка    - логическое имя файла базы в файле резервной копии
//
Функция ПолучитьЛогическоеИмяФайлаВРезервнойКопии(Знач ПутьКРезервнойКопии, Знач ТипФайла = Неопределено) Экспорт
	
	ТипыФайлов = ТипыФайловБД();
	ТипыФайловСокр = ТипыФайловБД(Истина);

	Если НЕ ЗначениеЗаполнено(ТипФайла) Тогда
		ТипФайла = ТипыФайловСокр.Данные;
	КонецЕсли;

	Если ТипФайла = ТипыФайлов.Данные ИЛИ ТипФайла = ТипыФайловСокр.Данные Тогда
		ТипФайла = ТипыФайловСокр.Данные;
	ИначеЕсли ТипФайла = ТипыФайлов.Журнал ИЛИ ТипФайла = ТипыФайловСокр.Журнал Тогда
		ТипФайла = ТипыФайловСокр.Журнал;
	Иначе
		Возврат Неопределено;
	КонецЕсли;
	
	ПутьКРезервнойКопии = ФС.ПолныйПуть(ПутьКРезервнойКопии);

	ТекстЗапроса = СтрШаблон("""SET NOCOUNT ON;
	                         |
	                         |DECLARE @T1CTmp TABLE (%1);
	                         |
	                         |INSERT INTO @T1CTmp EXECUTE('RESTORE FILELISTONLY FROM DISK = N''%2''');
	                         |
	                         |SELECT
	                         |	[LogicalName]
	                         |FROM
	                         |	@T1CTmp
	                         |WHERE
	                         |	[Type] = '%3';
	                         |
	                         |SET NOCOUNT OFF;""",
	                         ПолучитьСписокПолейТаблицыФайловРезервнойКопии(),
	                         ПутьКРезервнойКопии,
	                         ВРег(ТипФайла));
	
	РезультатЗапроса = "";
	КодВозврата = ВыполнитьЗапросСУБД(ТекстЗапроса, РезультатЗапроса);

	Если КодВозврата = 0 Тогда
		Разделитель = "---";
		Поз = СтрНайти(РезультатЗапроса, Разделитель, НаправлениеПоиска.FromEnd);
		РезультатЗапроса = СокрЛП(Сред(РезультатЗапроса, Поз + СтрДлина(Разделитель)));
	КонецЕсли;

	Возврат РезультатЗапроса;

КонецФункции // ПолучитьЛогическоеИмяФайлаВРезервнойКопии()
	
// Функция возвращает логическое имя файла в базе
//
// Параметры:
//   База        - Строка    - имя базы данных
//   ТипФайла    - Строка    - ROWS - файл базы; LOG - файл журнала транзакций
//
// Возвращаемое значение:
//   Строка     - логическое имя файла базы
//
Функция ПолучитьЛогическоеИмяФайлаВБазе(База, Знач ТипФайла = Неопределено) Экспорт
	
	ТипыФайлов = ТипыФайловБД();
	ТипыФайловСокр = ТипыФайловБД(Истина);

	Если НЕ ЗначениеЗаполнено(ТипФайла) Тогда
		ТипФайла = ТипыФайлов.Данные;
	КонецЕсли;

	Если ТипФайла = ТипыФайлов.Данные ИЛИ ТипФайла = ТипыФайловСокр.Данные Тогда
		ТипФайла = ТипыФайлов.Данные;
	ИначеЕсли ТипФайла = ТипыФайлов.Журнал ИЛИ ТипФайла = ТипыФайловСокр.Журнал Тогда
		ТипФайла = ТипыФайлов.Журнал;
	Иначе
		Возврат Неопределено;
	КонецЕсли;
	
	Если НЕ БазаСуществует(База, ВариантыСообщенияОСуществованииБД().СообщатьОбОтсутствии) Тогда
		Возврат Неопределено;
	КонецЕсли;

	ТекстЗапроса = СтрШаблон("""SET NOCOUNT ON;
	                         |
	                         |SELECT
	                         |	[name]
	                         |FROM
	                         |	sys.master_files
	                         |WHERE
	                         |	[database_id]=db_id('%1')
	                         |		AND type_desc='%2';
	                         |
	                         |SET NOCOUNT OFF;""",
	                         База,
	                         ТипФайла);
	
	РезультатЗапроса = "";
	КодВозврата = ВыполнитьЗапросСУБД(ТекстЗапроса, РезультатЗапроса);

	Если КодВозврата = 0 Тогда
		Разделитель = "---";
		Поз = СтрНайти(РезультатЗапроса, Разделитель, НаправлениеПоиска.FromEnd);
		РезультатЗапроса = СокрЛП(Сред(РезультатЗапроса, Поз + СтрДлина(Разделитель)));
	Иначе
		РезультатЗапроса = Неопределено;
	КонецЕсли;

	Возврат РезультатЗапроса;

КонецФункции // ПолучитьЛогическоеИмяФайлаВБазе()

// Функция изменяет логическое имя файла базы
//
// Параметры:
//   База                  - Строка    - имя базы данных
//   Имя                   - Строка    - логическое имя изменяемого файла
//   НовоеИмя              - Строка    - новое логическое имя
//   ОписаниеРезультата    - Строка    - результат выполнения команды
//
// Возвращаемое значение:
//   Булево    - Истина - команда выполнена успешно
//
Функция ИзменитьЛогическоеИмяФайлаВБазе(База, Имя, НовоеИмя, ОписаниеРезультата = "") Экспорт

	Если Имя = НовоеИмя Тогда
		Лог.Предупреждение("Новое логическое имя ""%1"" совпадает со старым ""%2""!", Имя, НовоеИмя);
		Возврат Истина;
	КонецЕсли;

	Если НЕ БазаСуществует(База, ВариантыСообщенияОСуществованииБД().СообщатьОбОтсутствии) Тогда
		Возврат Ложь;
	КонецЕсли;

	ТекстЗапроса = СтрШаблон("""USE [master];
	                         |
	                         |ALTER DATABASE [%1]
	                         |MODIFY FILE (NAME = N'%2', NEWNAME = N'%3');""",
	                         База,
	                         Имя,
	                         НовоеИмя);

	КодВозврата = ВыполнитьЗапросСУБД(ТекстЗапроса, ОписаниеРезультата);

	Возврат КодВозврата = 0;

КонецФункции // ИзменитьЛогическоеИмяФайлаВБазе()

// Функция возвращает логическое имя файла в базе
//
// Параметры:
//   ТипФайла    - Строка    - ROWS - файл базы; LOG - файл журнала транзакций
//
// Возвращаемое значение:
//   Строка     - логическое имя файла базы
//
Функция РасположениеФайловБазПоУмолчанию(Знач ТипФайла = Неопределено) Экспорт
	
	ТипыФайлов = ТипыФайловБД();
	ТипыФайловСокр = ТипыФайловБД(Истина);

	Если НЕ ЗначениеЗаполнено(ТипФайла) Тогда
		ТипФайла = ТипыФайлов.Данные;
	КонецЕсли;

	Если ТипФайла = ТипыФайлов.Данные ИЛИ ТипФайла = ТипыФайловСокр.Данные Тогда
		ТипФайла = ТипыФайлов.Данные;
	ИначеЕсли ТипФайла = ТипыФайлов.Журнал ИЛИ ТипФайла = ТипыФайловСокр.Журнал Тогда
		ТипФайла = ТипыФайлов.Журнал;
	Иначе
		Возврат Неопределено;
	КонецЕсли;
	

	ТекстЗапроса = СтрШаблон("""SET NOCOUNT ON;
	                         |
	                         |SELECT
	                         |	[physical_name]
	                         |FROM
	                         |	sys.master_files
	                         |WHERE
	                         |	[database_id]=4
	                         |		AND type_desc='%1';
	                         |
	                         |SET NOCOUNT OFF;""",
	                         ТипФайла);
	
	РезультатЗапроса = "";
	КодВозврата = ВыполнитьЗапросСУБД(ТекстЗапроса, РезультатЗапроса);

	Если КодВозврата = 0 Тогда
		Разделитель = "---";
		Поз = СтрНайти(РезультатЗапроса, Разделитель, НаправлениеПоиска.FromEnd);
		РезультатЗапроса = СокрЛП(Сред(РезультатЗапроса, Поз + СтрДлина(Разделитель)));

		ФайлБазы = Новый Файл(РезультатЗапроса);
		РезультатЗапроса = Сред(ФайлБазы.Путь, 1, СтрДлина(ФайлБазы.Путь) - 1);

	Иначе
		РезультатЗапроса = Неопределено;
	КонецЕсли;

	Возврат РезультатЗапроса;

КонецФункции // РасположениеФайловБазПоУмолчанию()

// Функция возвращает описание установленной версии SQL Server
//
// Возвращаемое значение:
//	Структура            - описание версии SQL Server
//       ИмяСервера            - имя сервера
//       ИмяЭкземпляраСУБД     - имя экземпляра СУБД на сервере
//       Редакция              - номер редакции
//       Версия                - номер версии
//       Уровень               - уровень продукта
//       ВерсияМакс            - старший номер версии (2000 - 2000 (8)), 2005 - 9,
//                                                     2008 - 10, 2012 - 11, 2014 - 12, 2016 - 13)
//       Корп                  - признак Enterprise версии
//
Функция ПолучитьВерсиюСУБД() Экспорт
	
	ТекстЗапроса = """SET NOCOUNT ON;
	               |
	               |SELECT
	               |  SERVERPROPERTY('MachineName') AS ComputerName,
	               |  SERVERPROPERTY('ServerName') AS InstanceName,
	               |  SERVERPROPERTY('Edition') AS Edition,
	               |  SERVERPROPERTY('ProductVersion') AS ProductVersion,
	               |  SERVERPROPERTY('ProductLevel') AS ProductLevel,
				   |  @@VERSION AS FullVersion""";

	ОписаниеРезультата = "";
	КодВозврата = ВыполнитьЗапросСУБД(ТекстЗапроса, ОписаниеРезультата, "|", Истина);

	СтрокаОписанияВерсии = 3;
	ИмяСервера           = 0;
	ИмяЭкземпляраСУБД    = 1;
	Редакция             = 2;
	Версия               = 3;
	Уровень              = 4;
	Представление        = 5;
	
	// 2000 - 2000 (8)), 2005 - 9, 2008 - 10, 2012 - 11, 2014 - 12, 2016 - 13, 2017 - 14, 2019 - 15
	МассивВерсий = СтрРазделить("2000-8,9,10,11,12,13,14,15", ",");

	СоответствиеВерсий = Новый Соответствие();

	Для Каждого ТекВерсия Из МассивВерсий Цикл
		ЧастиВерсии = СтрРазделить(ТекВерсия, "-");

		КоличествоЧастей = ЧастиВерсии.Количество();
		Если КоличествоЧастей = 1 Тогда
			СоответствиеВерсий.Вставить(ЧастиВерсии[0], Число(ЧастиВерсии[0]));
		ИначеЕсли КоличествоЧастей > 1 Тогда
			СоответствиеВерсий.Вставить(ЧастиВерсии[0], Число(ЧастиВерсии[1]));
		Иначе
			Возврат Неопределено;
		КонецЕсли;	
	КонецЦикла;
	
	Если КодВозврата = 0 Тогда
		СтруктураРезультата = Новый Структура();

		Текст = Новый ТекстовыйДокумент();
		Текст.УстановитьТекст(ОписаниеРезультата);
		
		МассивЗначений = СтрРазделить(Текст.ПолучитьСтроку(СтрокаОписанияВерсии), "|");

		СтруктураРезультата.Вставить("ИмяСервера"       , МассивЗначений[ИмяСервера]);
		СтруктураРезультата.Вставить("ИмяЭкземпляраСУБД", МассивЗначений[ИмяЭкземпляраСУБД]);
		СтруктураРезультата.Вставить("Редакция"         , МассивЗначений[Редакция]);
		СтруктураРезультата.Вставить("Версия"           , МассивЗначений[Версия]);
		СтруктураРезультата.Вставить("Уровень"          , МассивЗначений[Уровень]);
		СтруктураРезультата.Вставить("Представление"    , МассивЗначений[Представление]);
		
		МассивВерсии = СтрРазделить(СтруктураРезультата["Версия"], ".");
		СтруктураРезультата.Вставить("ВерсияМакс"       , СоответствиеВерсий[МассивВерсии[0]]);

		СтруктураРезультата.Вставить("Корп"             , СтрНайти(ВРег(СтруктураРезультата["Редакция"]), "ENTERPRISE") > 0);

		Возврат СтруктураРезультата;
	Иначе
		Возврат Неопределено;
	КонецЕсли;

КонецФункции // ПолучитьВерсиюСУБД()

// Функция возвращает признак доступности функционала SQL Server
//
// Параметры:
//	Функционал        - Строка            - наименование проверяемого функционала
//	ОписаниеВерсии    - Соответствие      - наименование проверяемого функционала
//
// Возвращаемое значение:
//	Булево            - Истина - функционал доступен
//
Функция ДоступностьФункционалаСУБД(Знач Функционал, ОписаниеВерсии = Неопределено) Экспорт

	МинВерсияАвторизации = 10;
	МинВерсияКомпрессии = 13;

	СтруктураФункционала = Новый Структура("Компрессия, ИзменениеАвторизации", Ложь, Ложь);

	Если НЕ ТипЗнч(ОписаниеВерсии) = Тип("Соответствие") Тогда
		ОписаниеВерсии = ПолучитьВерсиюСУБД();
	КонецЕсли;

	Если ОписаниеВерсии = Неопределено Тогда
		Возврат Ложь;
	КонецЕсли;

	Если ОписаниеВерсии.ВерсияМакс >= МинВерсияАвторизации Тогда
		СтруктураФункционала.ИзменениеАвторизации = Истина;
	КонецЕсли;

	Если ОписаниеВерсии.ВерсияМакс >= МинВерсияКомпрессии ИЛИ ОписаниеВерсии.Корп Тогда
		СтруктураФункционала.Компрессия = Истина;
	КонецЕсли;

	Если НЕ СтруктураФункционала.Свойство(Функционал) Тогда
		Возврат Ложь;
	КонецЕсли;

	Возврат СтруктураФункционала[Функционал];

КонецФункции // ДоступностьФункционалаСУБД()

#КонецОбласти // ПрограммныйИнтерфейс

#Область СлужебныеПроцедурыИФункции

// Функция выполняет запрос к СУБД (используется консольная утилита sqlcmd)
//
// Параметры:
//    ТекстЗапроса           - Строка       - текст исполняемого запроса
//    ОписаниеРезультата     - Строка       - результат выполнения команду
//    Разделитель            - Строка       - символ - разделитель колонок результата
//    УбратьПробелы          - Булево       - Истина - будут убраны выравнивающие пробелы из результата
//
// Возвращаемое значение:
//	Булево       - Истина - команда выполнена успешно
//
Функция ВыполнитьЗапросСУБД(ТекстЗапроса, ОписаниеРезультата = "", Разделитель = "", УбратьПробелы = Ложь)

	Лог.Отладка("Текст запроса: %1", ТекстЗапроса);
	
	КомандаРК = Новый Команда;
	
	КомандаРК.УстановитьКоманду("sqlcmd");
	КомандаРК.ДобавитьПараметр("-S " + Сервер);
	Если ЗначениеЗаполнено(Пользователь) Тогда
		КомандаРК.ДобавитьПараметр("-U " + Пользователь);
		Если ЗначениеЗаполнено(пароль) Тогда
			КомандаРК.ДобавитьПараметр("-P " + Пароль);
		КонецЕсли;
	КонецЕсли;
	КомандаРК.ДобавитьПараметр("-Q " + ТекстЗапроса);
	КомандаРК.ДобавитьПараметр("-b");

	Если ЗначениеЗаполнено(Разделитель) Тогда
		КомандаРК.ДобавитьПараметр(СтрШаблон("-s ""%1""", Разделитель));
	КонецЕсли;

	Если УбратьПробелы Тогда
		КомандаРК.ДобавитьПараметр("-W");
	КонецЕсли;

	КомандаРК.УстановитьИсполнениеЧерезКомандыСистемы( Ложь );
	КомандаРК.ПоказыватьВыводНемедленно( Ложь );
	
	КодВозврата = КомандаРК.Исполнить();

	ОписаниеРезультата = КомандаРК.ПолучитьВывод();

	Возврат КодВозврата;

КонецФункции // ВыполнитьЗапросСУБД()

// Функция выполняет запрос к СУБД, выполняя текст из файлов скриптов (используется консольная утилита sqlcmd)
//
// Параметры:
//    МассивСкриптов       - Массив из Строка - массив с путями к файлам скриптов
//    МассивПеременных     - Массив из Строка - массив со значениями переменных вида "<Имя>=<Значение>"
//    ОписаниеРезультата   - Строка - результат выполнения команды
//
// Возвращаемое значение:
//    Булево       - Истина - команда выполнена успешно
//
Функция ВыполнитьСкриптыЗапросСУБД(МассивСкриптов, МассивПеременных = Неопределено, ОписаниеРезультата = "") Экспорт
	
	КомандаРК = Новый Команда;
	
	КомандаРК.УстановитьКоманду("sqlcmd");
	КомандаРК.ДобавитьПараметр("-S " + Сервер);
	Если ЗначениеЗаполнено(Пользователь) Тогда
		КомандаРК.ДобавитьПараметр("-U " + Пользователь);
		Если ЗначениеЗаполнено(пароль) Тогда
			КомандаРК.ДобавитьПараметр("-P " + Пароль);
		КонецЕсли;
	КонецЕсли;

	Для каждого Файл Из МассивСкриптов Цикл
		Лог.Отладка("Добавлен файл скрипта: %1", Файл);

		КомандаРК.ДобавитьПараметр(СтрШаблон("-i %1", Файл));		
	КонецЦикла;
	
	Если ТипЗнч(МассивПеременных) = Тип("Массив") Тогда
		Для каждого Переменная Из МассивПеременных Цикл
			Лог.Отладка("Добавлено значение переменной: %1", Переменная);
			
			КомандаРК.ДобавитьПараметр(СтрШаблон("-v %1", Переменная));		
		КонецЦикла;
	КонецЕсли;

	КомандаРК.ДобавитьПараметр("-b");

	КомандаРК.УстановитьИсполнениеЧерезКомандыСистемы( Ложь );
	КомандаРК.ПоказыватьВыводНемедленно( Ложь );
	
	КодВозврата = КомандаРК.Исполнить();

	ОписаниеРезультата = КомандаРК.ПолучитьВывод();

	Возврат КодВозврата;

КонецФункции // ВыполнитьСкриптыЗапросСУБД()

// Функция возвращает список полей таблицы информации о резервной копии
//
// Возвращаемое значение:
//    Строка    - список полей таблицы с информацией о резервной копии (разделенный ",")
//
Функция ПолучитьСписокПолейТаблицыФайловРезервнойКопии()

	ОписаниеПолей = "[LogicalName] nvarchar(128),
	                |[PhysicalName] nvarchar(260),
	                |[Type] char(1),
	                |[FileGroupName] nvarchar(128),
	                |[Size] numeric(20,0),
	                |[MaxSize] numeric(20,0),
	                |[FileID] bigint,
	                |[CreateLSN] numeric(25,0),
	                |[DropLSN] numeric(25,0) NULL,
	                |[UniqueID] uniqueidentifier,
	                |[ReadOnlyLSN] numeric(25,0) NULL,
	                |[ReadWriteLSN] numeric(25,0) NULL,
	                |[BackupSizeInBytes] bigint,
	                |[SourceBlockSize] int,
	                |[FileGroupID] int,
	                |[LogGroupGUID] uniqueidentifier NULL,
	                |[DifferentialBaseLSN] numeric(25,0) NULL,
	                |[DifferentialBaseGUID] uniqueidentifier,
	                |[IsReadOnly] bit,
	                |[IsPresent] bit,
	                |[TDEThumbprint] varbinary(32)";

	ОписаниеВерсии = ПолучитьВерсиюСУБД();
	
	Версия2016 = 13;

	Если ОписаниеВерсии.ВерсияМакс >= Версия2016 Тогда
		ОписаниеПолей = СтрШаблон("%1,
		                          |[SnapshotUrl] nvarchar(360)",
		                          ОписаниеПолей);
	КонецЕсли;
	
	Возврат ОписаниеПолей;

КонецФункции // ПолучитьСписокПолейТаблицыФайловРезервнойКопии()

// Функция возвращает список возможных типов файлов базы данных или таблиц резервной копии
//
// Параметры:
//    Сокращенные    - Булево    - Истина - возвращать список сокращенных обозначений
//                                 типов баз (для файлов в файлах резервных копий);
//                                 Ложь - список полных обозначений (для файлов баз данных)
//
// Возвращаемое значение:
//    ФиксированнаяСтруктура    - список возможных типов файлов базы данных или таблиц резервной копии
//
Функция ТипыФайловБД(Сокращенные = Ложь)

	ТипыФайлов = Новый Структура();
	ТипыФайлов.Вставить("Данные"    , "ROWS");
	ТипыФайлов.Вставить("Журнал"    , "LOG");

	ТипыФайловСокр = Новый Структура();
	ТипыФайловСокр.Вставить("Данные", "D");
	ТипыФайловСокр.Вставить("Журнал", "L");

	Возврат Новый ФиксированнаяСтруктура(?(Сокращенные, ТипыФайловСокр, ТипыФайлов));

КонецФункции // ТипыФайловБД()

// Функция возвращает список вариантов сообщения о существовании базы данных при проверке
//
// Возвращаемое значение:
//    ФиксированнаяСтруктура    - варианты сообщения о существовании базы данных при проверке
//
Функция ВариантыСообщенияОСуществованииБД()

	ВариантыСообщения = Новый Структура();
	ВариантыСообщения.Вставить("НеСообщать"            , "НЕСООБЩАТЬ");
	ВариантыСообщения.Вставить("СообщатьОСуществовании", "СООБЩАТЬОСУЩЕСТВОВАНИИ");
	ВариантыСообщения.Вставить("СообщатьОбОтсутствии"  , "СООБЩАТЬОБОТСУТСТВИИ");

	Возврат Новый ФиксированнаяСтруктура(ВариантыСообщения);

КонецФункции // ВариантыСообщенияОСуществованииБД()

// Функция возвращает список возможных моделей восстановления базы данных
//
// Возвращаемое значение:
//    ФиксированнаяСтруктура    - возможные модели восстановления базы данных
//
Функция МоделиВосстановленияБД()

	МоделиВосстановления = Новый Структура();
	МоделиВосстановления.Вставить("Простая"                    , "SIMPLE");
	МоделиВосстановления.Вставить("Полная"                     , "FULL");
	МоделиВосстановления.Вставить("МинимальноеПротоколирование", "BULK_LOGGED");

	Возврат Новый ФиксированнаяСтруктура(МоделиВосстановления);

КонецФункции // ВариантыСообщенияОСуществованииБД()

#КонецОбласти // СлужебныеПроцедурыИФункции

#Область ОбработчикиСобытий

// Процедура - обработчик события "ПриСозданииОбъекта"
//
// Параметры:
//    _Сервер          - Строка    - адрес сервера СУБД
//    _Пользователь    - Строка    - пользователь сервера СУБД
//    _Пароль          - Строка    - пароль пользователя сервера СУБД
//
Процедура ПриСозданииОбъекта(Знач _Сервер, Знач _Пользователь, Знач _Пароль) Экспорт
	
	Сервер       = _Сервер;
	Пользователь = _Пользователь;
	Пароль       = _Пароль;
	
	Лог = ПараметрыСистемы.Лог();

КонецПроцедуры // ПриСозданииОбъекта()

#КонецОбласти // ОбработчикиСобытий
