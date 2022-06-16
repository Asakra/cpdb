﻿#Использовать fs
#Использовать deflator
#Использовать "../src/core"

Перем ПодключениеКСУБД;          //    - объект подключения к СУБД
Перем РаботаССУБД;               //    - объект работы с СУБД
Перем ИмяСервера;                //    - имя сервера MS SQL
Перем ПрефиксИмениБД;            //    - префикс имен тестовых баз
Перем ФайлКопииБазы;             //    - путь к файлу копии базы для тестов
Перем КаталогВременныхДанных;    //    - путь к каталогу временных данных
Перем Лог;                       //    - логгер

// Процедура выполняется после запуска теста
//
Процедура ПередЗапускомТеста() Экспорт
	
	КаталогВременныхДанных = ОбъединитьПути(ТекущийСценарий().Каталог, "..", "build", "tmpdata");
	КаталогВременныхДанных = ФС.ПолныйПуть(КаталогВременныхДанных);

	ФС.ОбеспечитьКаталог(КаталогВременныхДанных);

	ИмяСервера = ПолучитьПеременнуюСреды("CPDB_SQL_SRVR");
	ИмяПользователя = ПолучитьПеременнуюСреды("CPDB_SQL_USER");
	ПарольПользователя = ПолучитьПеременнуюСреды("CPDB_SQL_PWD");

	ПрефиксИмениБД = "cpdb_test_db";
	ФайлКопииБазы = ОбъединитьПути(ТекущийСценарий().Каталог, "fixtures", "cpdb_test_db.bak");

	ПодключениеКСУБД = Новый ПодключениеMSSQL(ИмяСервера, ИмяПользователя, ПарольПользователя);

	РаботаССУБД = Новый РаботаССУБД(ПодключениеКСУБД);

	Лог = ПараметрыСистемы.Лог();

КонецПроцедуры // ПередЗапускомТеста()

// Процедура выполняется после запуска теста
//
Процедура ПослеЗапускаТеста() Экспорт

КонецПроцедуры // ПослеЗапускаТеста()

&Тест
Процедура ТестДолжен_ПодготовитьТестовуюБазу() Экспорт

	Лог.Информация("Перед тестами: Подготовка тестовой базы данных");

	Для й = 1 По 3 Цикл
		ИмяБазы = СтрШаблон("%1_%2", ПрефиксИмениБД, й);

		Если НЕ РаботаССУБД.БазаСуществует(ИмяБазы) Тогда
			Продолжить;
		КонецЕсли;

		РаботаССУБД.УдалитьБазуДанных(ИмяБазы);
	КонецЦикла;

	ИмяБД = СтрШаблон("%1_%2", ПрефиксИмениБД, 1);

	РаботаССУБД.СоздатьБазуДанных(ИмяБД, , КаталогВременныхДанных);

	ТекстОшибки = СтрШаблон("Ошибка создания базы данных ""%1""", ИмяБД);

	Утверждения.ПроверитьИстину(РаботаССУБД.БазаСуществует(ИмяБД), ТекстОшибки);

	РаботаССУБД.ВыполнитьВосстановление(ИмяБД,
	                                    ФайлКопииБазы,
	                                    КаталогВременныхДанных,
	                                    КаталогВременныхДанных,
	                                    Истина);
	
	ТекстОшибки = СтрШаблон("Ошибка восстановления базы ""%1"" из резервной копии ""%2""", ИмяБД, ФайлКопииБазы);

	Утверждения.ПроверитьИстину(РаботаССУБД.БазаСуществует(ИмяБД), ТекстОшибки);

КонецПроцедуры // ТестДолжен_ПодготовитьТестовуюБазу()

&Тест
Процедура ТестДолжен_ПроверитьЧтоБазаЯвляетсяБазой1С() Экспорт

	Лог.Информация("Тест: Проверка, что база является базой ""1С:Предприятие 8""");

	ИмяБД = СтрШаблон("%1_%2", ПрефиксИмениБД, 1);

	ТекстОшибки = СтрШаблон("Не найдена тестовая база ""%1""", ИмяБД);

	Утверждения.ПроверитьИстину(РаботаССУБД.БазаСуществует(ИмяБД), ТекстОшибки);

	СтруктураХраненияИБ = Новый СтруктураХраненияИБ(ПодключениеКСУБД, ИмяБД);

	ЭтоБаза1С = СтруктураХраненияИБ.ЭтоБаза1С(ИмяБД);

	ТекстОшибки = СтрШаблон("Ошибка проверки, что база ""%1"" является базой ""1С:Предприятие 8""", ИмяБД);

	Утверждения.ПроверитьИстину(ЭтоБаза1С, ТекстОшибки);

КонецПроцедуры // ТестДолжен_ПроверитьЧтоБазаЯвляетсяБазой1С()

&Тест
Процедура ТестДолжен_ПолучитьВерсиюФорматаКонфигурации() Экспорт

	Лог.Информация("Тест: Получение версии формата конфигурации");

	ИмяБД = СтрШаблон("%1_%2", ПрефиксИмениБД, 1);

	ТекстОшибки = СтрШаблон("Не найдена тестовая база ""%1""", ИмяБД);

	Утверждения.ПроверитьИстину(РаботаССУБД.БазаСуществует(ИмяБД), ТекстОшибки);

	СтруктураХраненияИБ = Новый СтруктураХраненияИБ(ПодключениеКСУБД, ИмяБД);

	ОписаниеВерсии = СтруктураХраненияИБ.ВерсияФорматаКонфигурации();

	ТекстОшибки = СтрШаблон("Ошибка получения версии формата базы ""%1""", ИмяБД);

	Утверждения.ПроверитьРавенство(ОписаниеВерсии.ТребуемаяВерсияПлатформы, "80313", ТекстОшибки);

КонецПроцедуры // ТестДолжен_ПолучитьВерсиюФорматаКонфигурации()

&Тест
Процедура ТестДолжен_ПолучитьОписаниеКонфигурации() Экспорт

	Лог.Информация("Тест: Получение описания конфигурации");

	ИмяБД = СтрШаблон("%1_%2", ПрефиксИмениБД, 1);

	ТекстОшибки = СтрШаблон("Не найдена тестовая база ""%1""", ИмяБД);

	Утверждения.ПроверитьИстину(РаботаССУБД.БазаСуществует(ИмяБД), ТекстОшибки);

	СтруктураХраненияИБ = Новый СтруктураХраненияИБ(ПодключениеКСУБД, ИмяБД);

	ОписаниеКонфигурации = СтруктураХраненияИБ.ОписаниеКонфигурации();

	ТекстОшибки = СтрШаблон("Ошибка получения описания конфигурации 1С базы ""%1""", ИмяБД);

	Утверждения.ПроверитьРавенство(ОписаниеКонфигурации.Имя, "CPDB_TEST", ТекстОшибки);

КонецПроцедуры // ТестДолжен_ПолучитьОписаниеКонфигурации()

&Тест
Процедура ТестДолжен_ПолучитьОписаниеОбъектаМетаданных1СПоИмениТаблицы() Экспорт

	Лог.Информация("Тест: Получение описания объекта метаданных 1С по имени таблицы БД");

	ИмяБД = СтрШаблон("%1_%2", ПрефиксИмениБД, 1);

	ТекстОшибки = СтрШаблон("Не найдена тестовая база ""%1""", ИмяБД);

	Утверждения.ПроверитьИстину(РаботаССУБД.БазаСуществует(ИмяБД), ТекстОшибки);

	СтруктураХраненияИБ = Новый СтруктураХраненияИБ(ПодключениеКСУБД, ИмяБД);

	ИмяОбъектаБД = "Reference34";
	ИмяОбъектаМетаданных = "Справочник.Справочник1";

	ОписаниеОбъектаМетаданных = СтруктураХраненияИБ.ОписаниеМетаданныхОбъектаБД1С(ИмяОбъектаБД);

	ТекстОшибки = СтрШаблон("Ошибка получения описания объекта метаданных 1С для объекта БД ""%1""", ИмяОбъектаБД);

	Утверждения.ПроверитьРавенство(ОписаниеОбъектаМетаданных.ПолноеИмяМетаданных, ИмяОбъектаМетаданных, ТекстОшибки);

КонецПроцедуры // ТестДолжен_ПолучитьОписаниеОбъектаМетаданных1СПоИмениТаблицы()

&Тест
Процедура ТестДолжен_ПолучитьОписаниеТабличнойЧастиОбъектаМетаданных1СПоИмениТаблицы() Экспорт

	Лог.Информация("Тест: Получение описания табличной части объекта метаданных 1С по имени таблицы БД");

	ИмяБД = СтрШаблон("%1_%2", ПрефиксИмениБД, 1);

	ТекстОшибки = СтрШаблон("Не найдена тестовая база ""%1""", ИмяБД);

	Утверждения.ПроверитьИстину(РаботаССУБД.БазаСуществует(ИмяБД), ТекстОшибки);

	СтруктураХраненияИБ = Новый СтруктураХраненияИБ(ПодключениеКСУБД, ИмяБД);

	ИмяОбъектаБД = "_Reference34_VT36";
	ИмяТабличнойЧасти = "Справочник.Справочник1.ТабличнаяЧасть1";

	ОписаниеОбъектаМетаданных = СтруктураХраненияИБ.ОписаниеМетаданныхОбъектаБД1С(ИмяОбъектаБД);

	ТекстОшибки = СтрШаблон("Ошибка получения описания табличной части
	                        | объекта метаданных 1С для объекта БД ""%1""",
	                        ИмяОбъектаБД);

	Утверждения.ПроверитьРавенство(ОписаниеОбъектаМетаданных.ПолноеИмяМетаданных, ИмяТабличнойЧасти, ТекстОшибки);

КонецПроцедуры // ТестДолжен_ПолучитьОписаниеТабличнойЧастиОбъектаМетаданных1СПоИмениТаблицы()

&Тест
Процедура ТестДолжен_ПолучитьОписаниеРеквизитаОбъектаМетаданных1СПоИмениКолонки() Экспорт

	Лог.Информация("Тест: Получение описания реквизита объекта метаданных 1С по имени таблицы БД");

	ИмяБД = СтрШаблон("%1_%2", ПрефиксИмениБД, 1);

	ТекстОшибки = СтрШаблон("Не найдена тестовая база ""%1""", ИмяБД);

	Утверждения.ПроверитьИстину(РаботаССУБД.БазаСуществует(ИмяБД), ТекстОшибки);

	СтруктураХраненияИБ = Новый СтруктураХраненияИБ(ПодключениеКСУБД, ИмяБД);

	ИмяОбъектаБД = "_Fld35";
	ИмяРеквизита = "Справочник.Справочник1.Реквизит1";

	ОписаниеОбъектаМетаданных = СтруктураХраненияИБ.ОписаниеМетаданныхОбъектаБД1С(ИмяОбъектаБД);

	ТекстОшибки = СтрШаблон("Ошибка получения описания реквизита
	                        | объекта метаданных 1С для объекта БД ""%1""",
	                        ИмяОбъектаБД);

	Утверждения.ПроверитьРавенство(ОписаниеОбъектаМетаданных.ПолноеИмяМетаданных, ИмяРеквизита, ТекстОшибки);

КонецПроцедуры // ТестДолжен_ПолучитьОписаниеРеквизитаОбъектаМетаданных1СПоИмениКолонки()

&Тест
Процедура ТестДолжен_ПолучитьОписаниеРеквизитаТабличнойЧасти1СПоИмениКолонки() Экспорт

	Лог.Информация("Тест: Получение описания реквизита табличной части объекта метаданных 1С по имени таблицы БД");

	ИмяБД = СтрШаблон("%1_%2", ПрефиксИмениБД, 1);

	ТекстОшибки = СтрШаблон("Не найдена тестовая база ""%1""", ИмяБД);

	Утверждения.ПроверитьИстину(РаботаССУБД.БазаСуществует(ИмяБД), ТекстОшибки);

	СтруктураХраненияИБ = Новый СтруктураХраненияИБ(ПодключениеКСУБД, ИмяБД);

	ИмяОбъектаБД = "_Fld38";
	ИмяРеквизита = "Справочник.Справочник1.ТабличнаяЧасть1.Реквизит1";

	ОписаниеОбъектаМетаданных = СтруктураХраненияИБ.ОписаниеМетаданныхОбъектаБД1С(ИмяОбъектаБД);

	ТекстОшибки = СтрШаблон("Ошибка получения описания реквизита табличной части
	                        | объекта метаданных 1С для объекта БД ""%1""",
	                        ИмяОбъектаБД);

	Утверждения.ПроверитьРавенство(ОписаниеОбъектаМетаданных.ПолноеИмяМетаданных, ИмяРеквизита, ТекстОшибки);

КонецПроцедуры // ТестДолжен_ПолучитьОписаниеРеквизитаТабличнойЧасти1СПоИмениКолонки()

&Тест
Процедура ТестДолжен_ПолучитьОписаниеСтруктурыХраненияБД1С() Экспорт

	Лог.Информация("Тест: Получение описания структуры хранения базы данных 1С");

	ИмяБД = СтрШаблон("%1_%2", ПрефиксИмениБД, 1);

	ТекстОшибки = СтрШаблон("Не найдена тестовая база ""%1""", ИмяБД);

	Утверждения.ПроверитьИстину(РаботаССУБД.БазаСуществует(ИмяБД), ТекстОшибки);

	ИмяОбъектаБДСправочника = "Reference34";
	ИмяОбъектаБДТабличнойЧасти = "Reference34_VT36";
	ИмяОбъектаБДТабличнойЧастиСокр = "VT36";

	ИмяСправочника = "Справочник.Справочник1";
	ИмяТабличнойЧасти = "Справочник.Справочник1.ТабличнаяЧасть1";

	СтруктураХраненияИБ = Новый СтруктураХраненияИБ(ПодключениеКСУБД, ИмяБД);

	ОписаниеОбъектовМетаданных = СтруктураХраненияИБ.ОписаниеМетаданныхОбъектовБД1С();

	ТекстОшибки = СтрШаблон("Ошибка получения описания объектов метаданных 1С,
	                        | не найдено описание для объекта БД ""%1"" справочника", 
	                        ИмяОбъектаБДСправочника);

	Утверждения.ПроверитьРавенство(ОписаниеОбъектовМетаданных[ИмяОбъектаБДСправочника].ПолноеИмяМетаданных,
	                               ИмяСправочника,
	                               ТекстОшибки);

	ТекстОшибки = СтрШаблон("Ошибка получения описания объектов метаданных 1С,
	                        | не найдено описание для объекта БД ""%1"" табличной части по полному имени", 
	                        ИмяОбъектаБДТабличнойЧасти);

	Утверждения.ПроверитьРавенство(ОписаниеОбъектовМетаданных[ИмяОбъектаБДТабличнойЧасти].ПолноеИмяМетаданных,
	                               ИмяТабличнойЧасти,
	                               ТекстОшибки);

	ТекстОшибки = СтрШаблон("Ошибка получения описания объектов метаданных 1С,
	                        | не найдено описание для объекта БД ""%1"" табличной части по сокращенному имени", 
	                        ИмяОбъектаБДТабличнойЧастиСокр);

	Утверждения.ПроверитьРавенство(ОписаниеОбъектовМетаданных[ИмяОбъектаБДТабличнойЧастиСокр].ПолноеИмяМетаданных,
	                               ИмяТабличнойЧасти,
	                               ТекстОшибки);

	ТекстОшибки = СтрШаблон("Ошибка получения описания объектов метаданных 1С,
	                        | не найдено описание для объекта метаданных ""%1"" справочника", 
	                        ИмяСправочника);

	Утверждения.ПроверитьРавенство(ОписаниеОбъектовМетаданных[ИмяСправочника].Имя,
	                               ИмяОбъектаБДСправочника,
	                               ТекстОшибки);

	ТекстОшибки = СтрШаблон("Ошибка получения описания объектов метаданных 1С,
	                        | не найдено описание для объекта метаданных ""%1"" табличной части", 
	                        ИмяТабличнойЧасти);

	Утверждения.ПроверитьРавенство(ОписаниеОбъектовМетаданных[ИмяТабличнойЧасти].Имя,
	                               ИмяОбъектаБДТабличнойЧастиСокр,
	                               ТекстОшибки);

КонецПроцедуры // ТестДолжен_ПолучитьОписаниеСтруктурыХраненияБД1С()

&Тест
Процедура ТестДолжен_ПолучитьОписаниеСтруктурыХраненияБД1ССПолями() Экспорт

	Лог.Информация("Тест: Получение описания структуры хранения базы данных 1С с полями");

	ИмяБД = СтрШаблон("%1_%2", ПрефиксИмениБД, 1);

	ТекстОшибки = СтрШаблон("Не найдена тестовая база ""%1""", ИмяБД);

	Утверждения.ПроверитьИстину(РаботаССУБД.БазаСуществует(ИмяБД), ТекстОшибки);

	ИмяОбъектаБДПоля = "Fld35";
	ИмяРеквизита = "Справочник.Справочник1.Реквизит1";

	СтруктураХраненияИБ = Новый СтруктураХраненияИБ(ПодключениеКСУБД, ИмяБД);

	ОписаниеОбъектовМетаданных = СтруктураХраненияИБ.ОписаниеМетаданныхОбъектовБД1С(Истина);

	ТекстОшибки = СтрШаблон("Ошибка получения описания объектов метаданных 1С,
	                        | не найдено описание для объекта БД ""%1"" реквизита", 
	                        ИмяОбъектаБДПоля);

	Утверждения.ПроверитьРавенство(ОписаниеОбъектовМетаданных[ИмяОбъектаБДПоля].ПолноеИмяМетаданных,
	                               ИмяРеквизита,
	                               ТекстОшибки);

	ТекстОшибки = СтрШаблон("Ошибка получения описания объектов метаданных 1С,
	                        | не найдено описание для объекта метаданных ""%1""", 
	                        ИмяРеквизита);

	Утверждения.ПроверитьРавенство(ОписаниеОбъектовМетаданных[ИмяРеквизита].Имя,
	                               ИмяОбъектаБДПоля,
	                               ТекстОшибки);

КонецПроцедуры // ТестДолжен_ПолучитьОписаниеСтруктурыХраненияБД1ССПолями()

&Тест
Процедура ТестДолжен_ПолучитьЗанимаемоеБазойМесто() Экспорт

	Лог.Информация("Тест: Получение объема места занимаемого базой данных");

	ИмяБД = СтрШаблон("%1_%2", ПрефиксИмениБД, 1);

	ТекстОшибки = СтрШаблон("Не найдена тестовая база ""%1""", ИмяБД);

	Утверждения.ПроверитьИстину(РаботаССУБД.БазаСуществует(ИмяБД), ТекстОшибки);

	СтруктураХраненияИБ = Новый СтруктураХраненияИБ(ПодключениеКСУБД, ИмяБД);

	ЗанимаемоеМесто = СтруктураХраненияИБ.ЗанимаемоеМесто();

	ТекстОшибки = СтрШаблон("Ошибка получения занимаемое базой ""%1"" место", ИмяБД);

	Утверждения.ПроверитьБольше(ЗанимаемоеМесто.РазмерБазы, 0, ТекстОшибки);

КонецПроцедуры // ТестДолжен_ПолучитьЗанимаемоеБазойМесто()

&Тест
Процедура ТестДолжен_ПолучитьПоказателиИспользованияТаблицБазы() Экспорт

	Лог.Информация("Тест: Получение показателей использования таблиц базы данных");

	ИмяБД = СтрШаблон("%1_%2", ПрефиксИмениБД, 1);

	ТекстОшибки = СтрШаблон("Не найдена тестовая база ""%1""", ИмяБД);

	Утверждения.ПроверитьИстину(РаботаССУБД.БазаСуществует(ИмяБД), ТекстОшибки);

	СтруктураХраненияИБ = Новый СтруктураХраненияИБ(ПодключениеКСУБД, ИмяБД);

	ТаблицыБазы = СтруктураХраненияИБ.ПоказателиИспользованияТаблицБазы();

	ТестоваяТаблица = "Config";

	ТекстОшибки = СтрШаблон("Ошибка получения таблиц базы ""%1""", ИмяБД);

	Утверждения.ПроверитьРавенство(ТаблицыБазы.Количество(), 48, ТекстОшибки);

	ТекстОшибки = СтрШаблон("Ошибка получения таблиц базы ""%1"", не найдена таблица ""%2""", ИмяБД, ТестоваяТаблица);

	ЕстьТаблица = Ложь;
	Для Каждого ТекТаблица Из ТаблицыБазы Цикл
		Если ТекТаблица.Таблица = ТестоваяТаблица Тогда
			ЕстьТаблица = Истина;
			Прервать;
		КонецЕсли;
	КонецЦикла;

	Утверждения.ПроверитьИстину(ЕстьТаблица, ТекстОшибки);

	ТекстОшибки = СтрШаблон("Ошибка получения таблиц базы ""%1"",
	                        | не удалось получить размер таблицы ""%2""",
	                        ИмяБД,
	                        ТестоваяТаблица);

	Утверждения.ПроверитьБольше(ТекТаблица.ВсегоЗанято, 0, ТекстОшибки);

КонецПроцедуры // ТестДолжен_ПолучитьПоказателиИспользованияТаблицБазы()

&Тест
Процедура ТестДолжен_УдалитьТестовуюБазу() Экспорт

	Лог.Информация("После тестов: Удаление временной базы");

	Для й = 1 По 3 Цикл
		ИмяБазы = СтрШаблон("%1_%2", ПрефиксИмениБД, й);

		Если НЕ РаботаССУБД.БазаСуществует(ИмяБазы) Тогда
			Продолжить;
		КонецЕсли;

		РаботаССУБД.УдалитьБазуДанных(ИмяБазы);
	КонецЦикла;

КонецПроцедуры // ТестДолжен_УдалитьТестовуюБазу()
