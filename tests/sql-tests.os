﻿#Использовать fs
#Использовать "../src/core"

Перем ИмяСервера;         //    - имя сервера MS SQL
Перем ПодключениеКСУБД;   //    - объект подключения к СУБД
Перем РаботаССУБД;        //    - объект работы с СУБД
Перем ПрефиксИмениБД;     //    - префикс имен тестовых баз

Перем Лог;                //    - логгер

// Процедура выполняется после запуска теста
//
Процедура ПередЗапускомТеста() Экспорт
	
	ИмяСервера = ПолучитьПеременнуюСреды("CPDB_SQL_SERVER");
	ИмяПользователя = ПолучитьПеременнуюСреды("CPDB_SQL_USER");
	ПарольПользователя = ПолучитьПеременнуюСреды("CPDB_SQL_PWD");

	ПрефиксИмениБД = "cpdb_test_db";

	ПодключениеКСУБД = Новый ПодключениеКСУБД(ИмяСервера, ИмяПользователя, ПарольПользователя);
	
	РаботаССУБД = Новый РаботаССУБД(ПодключениеКСУБД);

	Лог = ПараметрыСистемы.Лог();
	Лог.УстановитьУровень(УровниЛога.Отладка);

	Для й = 1 По 10 Цикл
		ИмяБазы = СтрШаблон("%1%2", ПрефиксИмениБД, й);

		Если НЕ РаботаССУБД.БазаСуществует(ИмяБазы) Тогда
			Продолжить;
		КонецЕсли;

		РаботаССУБД.УдалитьБазуДанных(ИмяБазы);
	КонецЦикла;

КонецПроцедуры // ПередЗапускомТеста()

// Процедура выполняется после запуска теста
//
Процедура ПослеЗапускаТеста() Экспорт

КонецПроцедуры // ПослеЗапускаТеста()

&Тест
Процедура ТестДолжен_ПолучитьВерсиюSQLServer() Экспорт

	Результат = ПодключениеКСУБД.ПолучитьВерсиюСУБД();

	ТекстОшибки = СтрШаблон("Ошибка получения версии MS SQL Server");

	Утверждения.ПроверитьРавенство(ВРег(Результат.ИмяСервера), ВРег(ИмяСервера), ТекстОшибки);

КонецПроцедуры // ТестДолжен_ПолучитьВерсиюSQLServer()

&Тест
Процедура ТестДолжен_ПолучитьДоступностьФункционалаSQLServer() Экспорт

	Результат = ПодключениеКСУБД.ДоступностьФункционалаСУБД("Компрессия");

	ТекстОшибки = СтрШаблон("Ошибка получения доступности функционала MS SQL Server");

	Утверждения.ПроверитьИстину(Результат, ТекстОшибки);

КонецПроцедуры // ТестДолжен_ПолучитьДоступностьФункционалаSQLServer()

&Тест
Процедура ТестДолжен_ВыполнитьСценарийSQLИзФайла() Экспорт

	ВремКаталог = ОбъединитьПути(ТекущийСценарий().Каталог, "..", "testdata");
	ФС.ОбеспечитьКаталог(ВремКаталог);
	ПутьКСкрипту = ОбъединитьПути(ВремКаталог, "test.sql");
	Скрипт = Новый ТекстовыйДокумент();
	Скрипт.ДобавитьСтроку("SELECT @@VERSION");
	Скрипт.Записать(ПутьКСкрипту);

	Результат = РаботаССУБД.ВыполнитьСкрипты(ПутьКСкрипту);

	ТекстОшибки = СтрШаблон("Ошибка выполнения сценария MS SQL Server");

	Утверждения.ПроверитьБольше(СтрНайти(Результат, "Microsoft SQL Server"), 0, ТекстОшибки);

	УдалитьФайлы(ВремКаталог);

КонецПроцедуры // ТестДолжен_ВыполнитьСценарийSQLИзФайла()

&Тест
Процедура ТестДолжен_СоздатьБазуДанных() Экспорт

	ИмяБД = СтрШаблон("%1%2", ПрефиксИмениБД, 1);
	МодельВосстановления = "SIMPLE";

	РаботаССУБД.СоздатьБазуДанных(ИмяБД, МодельВосстановления);

	ТекстОшибки = СтрШаблон("Ошибка создания базы данных ""%1""", ИмяБД);

	Утверждения.ПроверитьИстину(РаботаССУБД.БазаСуществует(ИмяБД), ТекстОшибки);

	РаботаССУБД.УдалитьБазуДанных(ИмяБД);

КонецПроцедуры // ТестДолжен_СоздатьБазуДанных()

&Тест
Процедура ТестДолжен_ПроверитьОшибкуСозданияБазыДанных() Экспорт

	ИмяБД = СтрШаблон("%1%2", ПрефиксИмениБД, 1);
	МодельВосстановления = "SIMPLE";

	РаботаССУБД.СоздатьБазуДанных(ИмяБД, МодельВосстановления);

	ТекстОшибки = СтрШаблон("Ошибка создания базы данных ""%1""", ИмяБД);

	Утверждения.ПроверитьИстину(РаботаССУБД.БазаСуществует(ИмяБД), ТекстОшибки);

	ВозниклаОшибка = Истина;

	Попытка
		ВозниклаОшибка = НЕ РаботаССУБД.СоздатьБазуДанных(ИмяБД, МодельВосстановления);
	Исключение
		ВозниклаОшибка = Истина;
	КонецПопытки;

	ТекстОшибки = СтрШаблон("Ожидалась ошибка создания существующей базы данных ""%1""", ИмяБД);

	Утверждения.ПроверитьИстину(ВозниклаОшибка, ТекстОшибки);

	РаботаССУБД.УдалитьБазуДанных(ИмяБД);

	МодельВосстановления = "WRONGMODEL";

	ВозниклаОшибка = Неопределено;

	Попытка
		ВозниклаОшибка = НЕ РаботаССУБД.СоздатьБазуДанных(ИмяБД, МодельВосстановления);
	Исключение
		ВозниклаОшибка = Истина;
	КонецПопытки;

	ТекстОшибки = СтрШаблон("Ожидалась ошибка создания базы данных ""%1""
	                        |с некоhректной моделью восстановления ""%2""",
	                        ИмяБД,
	                        МодельВосстановления);

	Утверждения.ПроверитьИстину(ВозниклаОшибка, ТекстОшибки);

КонецПроцедуры // ТестДолжен_ПроверитьОшибкуСозданияБазыДанных()

&Тест
Процедура ТестДолжен_УдалитьБазуДанных() Экспорт

	ИмяБД = СтрШаблон("%1%2", ПрефиксИмениБД, 2);
	МодельВосстановления = "SIMPLE";

	РаботаССУБД.СоздатьБазуДанных(ИмяБД, МодельВосстановления);

	ТекстОшибки = СтрШаблон("Ошибка создания базы данных ""%1""", ИмяБД);

	Утверждения.ПроверитьИстину(РаботаССУБД.БазаСуществует(ИмяБД), ТекстОшибки);

	РаботаССУБД.УдалитьБазуДанных(ИмяБД);

	ТекстОшибки = СтрШаблон("Ошибка удаления базы данных ""%1""", ИмяБД);

	Утверждения.ПроверитьЛожь(РаботаССУБД.БазаСуществует(ИмяБД), ТекстОшибки);

КонецПроцедуры // ТестДолжен_УдалитьБазуДанных()

&Тест
Процедура ТестДолжен_ПроверитьОшибкуУдаленияБазыДанных() Экспорт

	ИмяБД = СтрШаблон("%1%2", ПрефиксИмениБД, 1);

	ВозниклаОшибка = Неопределено;

	Попытка
		ВозниклаОшибка = НЕ РаботаССУБД.УдалитьБазуДанных(ИмяБД);
	Исключение
		ВозниклаОшибка = Истина;
	КонецПопытки;

	ТекстОшибки = СтрШаблон("Ожидалась ошибка удаления отсутствующей базы данных ""%1""", ИмяБД);

	Утверждения.ПроверитьИстину(ВозниклаОшибка, ТекстОшибки);

КонецПроцедуры // ТестДолжен_ПроверитьОшибкуУдаленияБазыДанных()

&Тест
Процедура ТестДолжен_ПолучитьЛогическоеИмяФайлаВБазе() Экспорт

	ИмяБД = СтрШаблон("%1%2", ПрефиксИмениБД, 3);
	МодельВосстановления = "SIMPLE";

	РаботаССУБД.СоздатьБазуДанных(ИмяБД, МодельВосстановления);

	ТекстОшибки = СтрШаблон("Ошибка создания базы данных ""%1""", ИмяБД);

	Утверждения.ПроверитьИстину(РаботаССУБД.БазаСуществует(ИмяБД), ТекстОшибки);

	ЛогическоеИмя = ПодключениеКСУБД.ПолучитьЛогическоеИмяФайлаВБазе(ИмяБД, "D");

	ТекстОшибки = СтрШаблон("Ошибка получения логического имени файла данных базы ""%1""", ИмяБД);

	Утверждения.ПроверитьРавенство(ЛогическоеИмя, ИмяБД, ТекстОшибки);

	ЛогическоеИмя = ПодключениеКСУБД.ПолучитьЛогическоеИмяФайлаВБазе(ИмяБД, "L");

	ТекстОшибки = СтрШаблон("Ошибка получения логического имени файла журнала базы ""%1""", ИмяБД);

	Утверждения.ПроверитьРавенство(ЛогическоеИмя, СтрШаблон("%1_log", ИмяБД), ТекстОшибки);

	РаботаССУБД.УдалитьБазуДанных(ИмяБД);

КонецПроцедуры // ТестДолжен_ПолучитьЛогическоеИмяФайлаВБазе()

&Тест
Процедура ТестДолжен_СоздатьРезервнуюКопиюБазы() Экспорт

	ИмяБД = СтрШаблон("%1%2", ПрефиксИмениБД, 3);
	МодельВосстановления = "SIMPLE";

	РаботаССУБД.СоздатьБазуДанных(ИмяБД, МодельВосстановления);

	ТекстОшибки = СтрШаблон("Ошибка создания базы данных ""%1""", ИмяБД);

	Утверждения.ПроверитьИстину(РаботаССУБД.БазаСуществует(ИмяБД), ТекстОшибки);

	ВремКаталог = ОбъединитьПути(ТекущийСценарий().Каталог, "..", "testdata");
	ФС.ОбеспечитьКаталог(ВремКаталог);
	ПутьКРезервнойКопии = ОбъединитьПути(ВремКаталог, СтрШаблон("%1.bak", ИмяБД));

	РаботаССУБД.ВыполнитьРезервноеКопирование(ИмяБД, ПутьКРезервнойКопии);

	ВремФайл = Новый Файл(ПутьКРезервнойКопии);

	ТекстОшибки = СтрШаблон("Ошибка резервного копирования базы ""%1"" в файл ""%2""", ИмяБД, ПутьКРезервнойКопии);

	Утверждения.ПроверитьИстину(ВремФайл.Существует(), ТекстОшибки);

	РаботаССУБД.УдалитьБазуДанных(ИмяБД);

	УдалитьФайлы(ВремКаталог);

КонецПроцедуры // ТестДолжен_СоздатьРезервнуюКопиюБазы()

&Тест
Процедура ТестДолжен_ПолучитьОшибкуСозданияРезервнойКопииБазы() Экспорт

	ИмяБД = СтрШаблон("%1%2", ПрефиксИмениБД, 3);

	ВремКаталог = ОбъединитьПути(ТекущийСценарий().Каталог, "..", "testdata");
	ПутьКРезервнойКопии = ОбъединитьПути(ВремКаталог, СтрШаблон("%1.bak", ИмяБД));

	ВозниклаОшибка = Неопределено;

	Попытка
		ВозниклаОшибка = НЕ РаботаССУБД.ВыполнитьРезервноеКопирование(ИмяБД, ПутьКРезервнойКопии);
	Исключение
		ВозниклаОшибка = Истина;
	КонецПопытки;

	ТекстОшибки = СтрШаблон("Ожидалась ошибка резервного копирования базы ""%1"" в файл ""%2""", ИмяБД, ПутьКРезервнойКопии);

	Утверждения.ПроверитьИстину(ВозниклаОшибка, ТекстОшибки);

КонецПроцедуры // ТестДолжен_ПолучитьОшибкуСозданияРезервнойКопииБазы()

&Тест
Процедура ТестДолжен_ВосстановитьБазуИзРезервнойКопии() Экспорт

	ИмяБД = СтрШаблон("%1%2", ПрефиксИмениБД, 4);
	МодельВосстановления = "SIMPLE";

	РаботаССУБД.СоздатьБазуДанных(ИмяБД, МодельВосстановления);

	ТекстОшибки = СтрШаблон("Ошибка создания базы данных ""%1""", ИмяБД);

	Утверждения.ПроверитьИстину(РаботаССУБД.БазаСуществует(ИмяБД), ТекстОшибки);

	ВремКаталог = ОбъединитьПути(ТекущийСценарий().Каталог, "..", "testdata");
	ФС.ОбеспечитьКаталог(ВремКаталог);
	ПутьКРезервнойКопии = ОбъединитьПути(ВремКаталог, СтрШаблон("%1.bak", ИмяБД));

	РаботаССУБД.ВыполнитьРезервноеКопирование(ИмяБД, ПутьКРезервнойКопии);

	ВремФайл = Новый Файл(ПутьКРезервнойКопии);

	ТекстОшибки = СтрШаблон("Ошибка резервного копирования базы ""%1"" в файл ""%2""", ИмяБД, ПутьКРезервнойКопии);

	Утверждения.ПроверитьИстину(ВремФайл.Существует(), ТекстОшибки);

	РаботаССУБД.УдалитьБазуДанных(ИмяБД);

	ИмяБД = СтрШаблон("%1%2", ПрефиксИмениБД, 5);

	РаботаССУБД.ВыполнитьВосстановление(ИмяБД,
	                                    ПутьКРезервнойКопии,
	                                    ВремКаталог,
	                                    ВремКаталог,
	                                    Истина);
	
	ТекстОшибки = СтрШаблон("Ошибка восстановления базы ""%1"" из резервной копии ""%2""", ИмяБД, ПутьКРезервнойКопии);

	Утверждения.ПроверитьИстину(РаботаССУБД.БазаСуществует(ИмяБД), ТекстОшибки);

	РаботаССУБД.УдалитьБазуДанных(ИмяБД);

	РаботаССУБД.УдалитьИсточник(ПутьКРезервнойКопии);

	УдалитьФайлы(ВремКаталог);

КонецПроцедуры // ТестДолжен_ВосстановитьБазуИзРезервнойКопии()

&Тест
Процедура ТестДолжен_ПолучитьОшибкуВосстановленияБазыИзРезервнойКопии() Экспорт

	ИмяБД = СтрШаблон("%1%2", ПрефиксИмениБД, 4);

	ВремКаталог = ОбъединитьПути(ТекущийСценарий().Каталог, "..", "testdata");
	ПутьКРезервнойКопии = ОбъединитьПути(ВремКаталог, СтрШаблон("%1.bak", ИмяБД));

	ИмяБД = СтрШаблон("%1%2", ПрефиксИмениБД, 5);

	ВозниклаОшибка = Неопределено;

	Попытка
		ВозниклаОшибка = НЕ РаботаССУБД.ВыполнитьВосстановление(ИмяБД,
	                                                            ПутьКРезервнойКопии,
	                                                            ВремКаталог,
	                                                            ВремКаталог,
	                                                            Истина);
	Исключение
		ВозниклаОшибка = Истина;
	КонецПопытки;

	ТекстОшибки = СтрШаблон("Ожидалась ошибка восстановления ""%1"" из файла ""%2""", ИмяБД, ПутьКРезервнойКопии);
	
	Утверждения.ПроверитьИстину(ВозниклаОшибка, ТекстОшибки);

КонецПроцедуры // ТестДолжен_ПолучитьОшибкуВосстановленияБазыИзРезервнойКопии()

&Тест
Процедура ТестДолжен_ИзменитьМодельВосстановленияБазы() Экспорт

	ИмяБД = СтрШаблон("%1%2", ПрефиксИмениБД, 6);
	МодельВосстановленияДо = "SIMPLE";
	МодельВосстановленияПосле = "FULL";

	РаботаССУБД.СоздатьБазуДанных(ИмяБД, МодельВосстановленияДо);

	МодельВосстановления = ПодключениеКСУБД.ПолучитьМодельВосстановления(ИмяБД);

	ТекстОшибки = СтрШаблон("Ошибка проверки модели восстановления базы ""%1""", ИмяБД);

	Утверждения.ПроверитьРавенство(МодельВосстановления, МодельВосстановленияДо, ТекстОшибки);

	ПодключениеКСУБД.УстановитьМодельВосстановления(ИмяБД, МодельВосстановленияПосле);

	МодельВосстановления = ПодключениеКСУБД.ПолучитьМодельВосстановления(ИмяБД);

	ТекстОшибки = СтрШаблон("Ошибка установки модели восстановления ""%1"" базы ""%2""", МодельВосстановленияПосле, ИмяБД);

	Утверждения.ПроверитьРавенство(МодельВосстановления, МодельВосстановленияПосле, ТекстОшибки);

	РаботаССУБД.УдалитьБазуДанных(ИмяБД);

КонецПроцедуры // ТестДолжен_ИзменитьМодельВосстановленияБазы()

&Тест
Процедура ТестДолжен_ПолучитьОшибкуИзмененияМоделиВосстановленияБазы() Экспорт

	ИмяБД = СтрШаблон("%1%2", ПрефиксИмениБД, 6);
	МодельВосстановленияПосле = "WRONGMODEL";

	РаботаССУБД.СоздатьБазуДанных(ИмяБД);

	ВозниклаОшибка = Неопределено;

	Попытка
		ВозниклаОшибка = НЕ ПодключениеКСУБД.УстановитьМодельВосстановления(ИмяБД, МодельВосстановленияПосле);
	Исключение
		ВозниклаОшибка = Истина;
	КонецПопытки;

	ТекстОшибки = СтрШаблон("Ожидалась ошибка установки модели восстановления ""%1"" базы ""%2""",
	                        МодельВосстановленияПосле,
	                        ИмяБД);

	Утверждения.ПроверитьИстину(ВозниклаОшибка, ТекстОшибки);

	РаботаССУБД.УдалитьБазуДанных(ИмяБД);

КонецПроцедуры // ТестДолжен_ПолучитьОшибкуИзмененияМоделиВосстановленияБазы()

