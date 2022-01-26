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
	
	Команда.Опция("s src", "", "файл источник")
	       .ТСтрока()
	       .Обязательный()
	       .ВОкружении("CPDB_FILE_COPY_SRC");
	
	Команда.Опция("d dst", "", "файл/каталог приемник")
	       .ТСтрока()
	       .Обязательный()
	       .ВОкружении("CPDB_FILE_COPY_DST");
	
	Команда.Опция("r replace", Ложь, "перезаписывать существующие файлы")
	       .Флаговый()
	       .ВОкружении("CPDB_FILE_COPY_REPLACE");
	
	Команда.Опция("m move delsrc", Ложь, "выполнить перемещение файлов (удалить источник после копирования)")
	       .Флаговый()
	       .ВОкружении("CPDB_FILE_COPY_MOVE");
	
	Команда.Опция("l lastonly", Ложь, "копирование файлов, измененных не ранее текущей даты (параметр /D для xcopy)")
	       .Флаговый()
	       .ВОкружении("CPDB_FILE_COPY_LAST_ONLY");

КонецПроцедуры // ОписаниеКоманды()

// Процедура - запускает выполнение команды устанавливает описание команды
//
// Параметры:
//  Команда    - КомандаПриложения     - объект  описание команды
//
Процедура ВыполнитьКоманду(Знач Команда) Экспорт

	ВыводОтладочнойИнформации = Команда.ЗначениеОпции("verbose");

	ПараметрыПриложения.УстановитьРежимОтладки(ВыводОтладочнойИнформации);

	Источник        = Команда.ЗначениеОпции("src");
	Приемник        = Команда.ЗначениеОпции("dst");
	Перезаписывать  = Команда.ЗначениеОпции("replace");
	Перемещение     = Команда.ЗначениеОпции("move");
	ТолькоСегодня   = Команда.ЗначениеОпции("lastonly");

	Попытка
		ОписаниеРезультата = "";
		
		КомандаКопироватьФайл(Источник,
		                      Приемник,
		                      Перезаписывать,
		                      Перемещение,
		                      ТолькоСегодня);
	Исключение
		ТекстОшибки = СтрШаблон("Ошибка копирования файла ""%1"" -> ""%2"": %3%4",
		                        Источник,
		                        Приемник,
		                        Символы.ПС,
		                        ПодробноеПредставлениеОшибки(ИнформацияОбОшибке()));
		ВызватьИсключение ТекстОшибки;
	КонецПопытки;

КонецПроцедуры // ВыполнитьКоманду()

#КонецОбласти // СлужебныйПрограммныйИнтерфейс

#Область СлужебныеПроцедурыИФункции

// Функция, выполняет копирование/перемещение указанных файлов
//   
// Параметры:
//   Источник           - Строка       - копируемые файлы
//   Приемник           - Строка       - назначение копирования, каталог или файл
//   Перезаписывать     - Булево       - перезаписывать существующие файлы
//   Перемещение        - Булево       - выполнить перемещение файлов (удалить источник после копирования)
//   ТолькоСегодня      - Булево       - копирование файлов, измененных не ранее текущей даты (параметр /D для xcopy)
//
Процедура КомандаКопироватьФайл(Источник,
                                Приемник,
                                Перезаписывать = Истина,
                                Перемещение = Ложь,
                                ТолькоСегодня = Ложь)

	КомандаРК = Новый Команда;
	
	КомандаРК.УстановитьКоманду("xcopy");
	КомандаРК.ДобавитьПараметр(Источник);
	КомандаРК.ДобавитьПараметр(Приемник);
	Если Перезаписывать Тогда
		КомандаРК.ДобавитьПараметр("/Y");
	КонецЕсли;
	КомандаРК.ДобавитьПараметр("/Z");
	КомандаРК.ДобавитьПараметр("/V");
	КомандаРК.ДобавитьПараметр("/J");
	Если ТолькоСегодня Тогда
		лТекДата = ТекущаяДата();
		лФорматированнаяДата = Строка(Формат(лТекДата, "ДФ=MM-dd-yyyy"));
		КомандаРК.ДобавитьПараметр("/D:" + лФорматированнаяДата);
	КонецЕсли;

	КомандаРК.УстановитьИсполнениеЧерезКомандыСистемы(Ложь);
	КомандаРК.ПоказыватьВыводНемедленно(Ложь);
	
	КодВозврата = КомандаРК.Исполнить();

	ОписаниеРезультата = КомандаРК.ПолучитьВывод();
	
	Если Не ПустаяСтрока(ОписаниеРезультата) Тогда
		Лог.Информация("Вывод команды копирования: " + ОписаниеРезультата);
	КонецЕсли;
	
	Если НЕ КодВозврата = 0 Тогда
		ТекстОшибки = СтрШаблон("Ошибка копирования файла ""%1"" -> ""%2"", код возврата: %3",
		                        Источник,
		                        Приемник,
		                        КодВозврата);
		ВызватьИсключение ТекстОшибки;
	КонецЕсли;

	Если Перемещение Тогда
		КомандаУдалитьФайл(Источник);
	КонецЕсли;
	
КонецПроцедуры // КомандаКопироватьФайл()

// Функция, выполняет удаление указанных файлов
//   
// Параметры:
//   ПутьКФайлу         - Строка         - путь к удаляемому файлы
//
Процедура КомандаУдалитьФайл(ПутьКФайлу)

	КомандаРК = Новый Команда;
	
	КомандаРК.УстановитьКоманду("del");
	КомандаРК.ДобавитьПараметр("/F ");
	КомандаРК.ДобавитьПараметр("/Q ");
	КомандаРК.ДобавитьПараметр(ПутьКФайлу);

	КомандаРК.УстановитьИсполнениеЧерезКомандыСистемы( Ложь );
	КомандаРК.ПоказыватьВыводНемедленно( Ложь );
	
	КодВозврата = КомандаРК.Исполнить();

	ОписаниеРезультата = КомандаРК.ПолучитьВывод();
	
	Если Не ПустаяСтрока(ОписаниеРезультата) Тогда
		Лог.Информация("Вывод команды удаления: " + ОписаниеРезультата);
	КонецЕсли;

	Если НЕ КодВозврата = 0 Тогда
		ТекстОшибки = СтрШаблон("Ошибка удаления файла ""%1"", код возврата: %2",
		                        ПутьКФайлу,
		                        КодВозврата);
		ВызватьИсключение ТекстОшибки;
	КонецЕсли;

КонецПроцедуры // КомандаУдалитьФайл()

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
