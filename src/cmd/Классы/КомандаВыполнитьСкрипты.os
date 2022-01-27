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
	
	Команда.Опция("f sql-files", "", "файлы, содержащие текст скрипта, 
	                                 |могут быть указаны несколько файлов, разделённые "";""")
	       .ТСтрока()
	       .Обязательный()
	       .ВОкружении("CPDB_SQL_SCRIPT_FILES");
	
	Команда.Опция("v sql-vars", "", "переменные для скриптов SQL,
	                                |имя переменной и значение разделены ""="", переменные разделены "";""")
	       .ТСтрока()
	       .ВОкружении("CPDB_SQL_SCRIPT_VARIABLES");
	
КонецПроцедуры // ОписаниеКоманды()

// Процедура - запускает выполнение команды устанавливает описание команды
//
// Параметры:
//  Команда    - КомандаПриложения     - объект  описание команды
//
Процедура ВыполнитьКоманду(Знач Команда) Экспорт

	ВыводОтладочнойИнформации = Команда.ЗначениеОпции("verbose");

	ПараметрыПриложения.УстановитьРежимОтладки(ВыводОтладочнойИнформации);

	Сервер             = Команда.ЗначениеОпцииКомандыРодителя("sql-srvr");
	Пользователь       = Команда.ЗначениеОпцииКомандыРодителя("sql-user");
	ПарольПользователя = Команда.ЗначениеОпцииКомандыРодителя("sql-pwd");
	СкриптыВыполнения  = Команда.ЗначениеОпции("sql-files");
	СтрокаПеременных   = Команда.ЗначениеОпции("sql-vars");

	ПодключениеКСУБД = Новый ПодключениеКСУБД(Сервер, Пользователь, ПарольПользователя);
	
	ОписаниеРезультата = "";
	
	Попытка
		Результат = ПодключениеКСУБД.ВыполнитьСкрипты(СкриптыВыполнения, СтрокаПеременных, ОписаниеРезультата);

		Если НЕ ПустаяСтрока(ОписаниеРезультата) Тогда
			Лог.Информация(ОписаниеРезультата);
		КонецЕсли;
		
		Если НЕ Результат Тогда
			ТекстОшибки = СтрШаблон("Ошибка выполнения скриптов ""%1"" для значений переменных ""%2"" на сервере ""%3"".",
			                        СкриптыВыполнения,
			                        СтрокаПеременных,
			                        Сервер); 
			ВызватьИсключение ТекстОшибки;
		КонецЕсли;
	Исключение
		ТекстОшибки = СтрШаблон("Ошибка выполнения скриптов ""%1"" для значений переменных ""%2"" на сервере ""%3"": %4%5",
		                        СкриптыВыполнения,
		                        СтрокаПеременных,
		                        Сервер,
		                        Символы.ПС,
		                        ПодробноеПредставлениеОшибки(ИнформацияОбОшибке()));
		ВызватьИсключение ТекстОшибки;
	КонецПопытки;

КонецПроцедуры // ВыполнитьКоманду()

#КонецОбласти // СлужебныйПрограммныйИнтерфейс

#Область ОбработчикиСобытий

// Процедура - обработчик события "ПриСозданииОбъекта"
//
// BSLLS:UnusedLocalMethod-off
Процедура ПриСозданииОбъекта()

	Лог = ПараметрыПриложения.Лог();

КонецПроцедуры // ПриСозданииОбъекта()
// BSLLS:UnusedLocalMethod-on

#КонецОбласти // ОбработчикиСобытий
