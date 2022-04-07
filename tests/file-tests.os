﻿#Использовать fs
#Использовать "../src/core"
#Использовать "../src/cmd"

Перем ШаблонБазы;                //    - путь к файлу шаблона базы для тестов
Перем КаталогВременныхДанных;    //    - путь к каталогу временных данных
Перем Лог;                       //    - логгер

// Процедура выполняется после запуска теста
//
Процедура ПередЗапускомТеста() Экспорт
	
	КаталогВременныхДанных = ОбъединитьПути(ТекущийСценарий().Каталог, "..", "build", "tmpdata");

	ШаблонБазы = ОбъединитьПути(ТекущийСценарий().Каталог, "fixtures", "cpdb_test_db.dt");

	Лог = ПараметрыСистемы.Лог();
	Лог.УстановитьУровень(УровниЛога.Информация);

КонецПроцедуры // ПередЗапускомТеста()

// Процедура выполняется после запуска теста
//
Процедура ПослеЗапускаТеста() Экспорт

КонецПроцедуры // ПослеЗапускаТеста()

&Тест
Процедура ТестДолжен_СоздатьПапкуВNextCloud() Экспорт

	АдресСервиса = ПолучитьПеременнуюСреды("NC_ADDRESS");
	АдминИмя = ПолучитьПеременнуюСреды("NC_ADMIN_NAME");
	АдминПароль = ПолучитьПеременнуюСреды("NC_ADMIN_PWD");

	Сервис = Новый ПодключениеNextCloud(АдресСервиса, АдминИмя, АдминПароль);

	ИмяКаталога = "testFolder1";

	РаботаСФайлами.СоздатьПапкуВNextCloud(Сервис, ИмяКаталога);

	ТекстОшибки = СтрШаблон("Ошибка создания каталога ""%1"" в сервисе ""%2"", для пользователя ""%3""",
	                        ИмяКаталога,
	                        АдресСервиса,
	                        АдминИмя);

	Утверждения.ПроверитьИстину(Сервис.Файлы().Существует(ИмяКаталога), ТекстОшибки);

	Сервис.Файлы().Удалить(ИмяКаталога);

КонецПроцедуры // ТестДолжен_СоздатьПапкуВNextCloud()

&Тест
Процедура ТестДолжен_ОтправитьФайлВNextCloud() Экспорт

	АдресСервиса = ПолучитьПеременнуюСреды("NC_ADDRESS");
	АдминИмя = ПолучитьПеременнуюСреды("NC_ADMIN_NAME");
	АдминПароль = ПолучитьПеременнуюСреды("NC_ADMIN_PWD");

	Сервис = Новый ПодключениеNextCloud(АдресСервиса, АдминИмя, АдминПароль);

	ИмяКаталога = "testFolder1";

	ТестовыйФайл = Новый Файл(ШаблонБазы);

	РаботаСФайлами.СоздатьПапкуВNextCloud(Сервис, ИмяКаталога);

	ТекстОшибки = СтрШаблон("Ошибка создания каталога ""%1"" в сервисе ""%2"", для пользователя ""%3""",
	                        ИмяКаталога,
	                        АдресСервиса,
	                        АдминИмя);

	Утверждения.ПроверитьИстину(Сервис.Файлы().Существует(ИмяКаталога), ТекстОшибки);

	РаботаСФайлами.ОтправитьФайлВNextCloud(Сервис, ТестовыйФайл.ПолноеИмя, ИмяКаталога);

	ТекстОшибки = СтрШаблон("Ошибка отправки файла ""%1"" в сервис ""%2"", для пользователя ""%3""",
	                        ТестовыйФайл.ПолноеИмя,
	                        АдресСервиса,
	                        АдминИмя);

	Утверждения.ПроверитьИстину(Сервис.Файлы().Существует(ОбъединитьПути(ИмяКаталога, ТестовыйФайл.Имя)), ТекстОшибки);

	Сервис.Файлы().Удалить(ОбъединитьПути(ИмяКаталога, ТестовыйФайл.Имя));

	Сервис.Файлы().Удалить(ИмяКаталога);

КонецПроцедуры // ТестДолжен_ОтправитьФайлВNextCloud()

&Тест
Процедура ТестДолжен_ПолучитьФайлИзNextCloud() Экспорт

	АдресСервиса = ПолучитьПеременнуюСреды("NC_ADDRESS");
	АдминИмя = ПолучитьПеременнуюСреды("NC_ADMIN_NAME");
	АдминПароль = ПолучитьПеременнуюСреды("NC_ADMIN_PWD");

	Сервис = Новый ПодключениеNextCloud(АдресСервиса, АдминИмя, АдминПароль);

	ИмяКаталога = "testFolder1";

	ТестовыйФайл = Новый Файл(ШаблонБазы);

	РаботаСФайлами.СоздатьПапкуВNextCloud(Сервис, ИмяКаталога);

	ТекстОшибки = СтрШаблон("Ошибка создания каталога ""%1"" в сервисе ""%2"", для пользователя ""%3""",
	                        ИмяКаталога,
	                        АдресСервиса,
	                        АдминИмя);

	Утверждения.ПроверитьИстину(Сервис.Файлы().Существует(ИмяКаталога), ТекстОшибки);

	РаботаСФайлами.ОтправитьФайлВNextCloud(Сервис, ТестовыйФайл.ПолноеИмя, ИмяКаталога);

	ТекстОшибки = СтрШаблон("Ошибка отправки файла ""%1"" в сервис ""%2"", для пользователя ""%3""",
	                        ТестовыйФайл.ПолноеИмя,
	                        АдресСервиса,
	                        АдминИмя);

	Утверждения.ПроверитьИстину(Сервис.Файлы().Существует(ОбъединитьПути(ИмяКаталога, ТестовыйФайл.Имя)), ТекстОшибки);

	ФС.ОбеспечитьКаталог(КаталогВременныхДанных);
	
	ПутьКЗагруженномуФайлу = РаботаСФайлами.ПолучитьФайлИзNextCloud(Сервис, ОбъединитьПути(ИмяКаталога, ТестовыйФайл.Имя), КаталогВременныхДанных);

	ТекстОшибки = СтрШаблон("Ошибка получения файла ""%1"" из сервиса ""%2"", для пользователя ""%3""",
	                        ОбъединитьПути(ИмяКаталога, ТестовыйФайл.Имя),
	                        АдресСервиса,
	                        АдминИмя);

	Утверждения.ПроверитьИстину(ТестовыйФайл.Существует(), ТекстОшибки);

	Сервис.Файлы().Удалить(ОбъединитьПути(ИмяКаталога, ТестовыйФайл.Имя));

	Сервис.Файлы().Удалить(ИмяКаталога);

	УдалитьФайлы(КаталогВременныхДанных);

КонецПроцедуры // ТестДолжен_ПолучитьФайлИзNextCloud()
