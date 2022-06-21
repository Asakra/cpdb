// ----------------------------------------------------------
// This Source Code Form is subject to the terms of the
// Mozilla Public License, v.2.0. If a copy of the MPL
// was not distributed with this file, You can obtain one
// at http://mozilla.org/MPL/2.0/.
// ----------------------------------------------------------
// Codebase: https://github.com/ArKuznetsov/cpdb/
// ----------------------------------------------------------

#Использовать "../../core"

Перем Лог;       // - Объект      - объект записи лога приложения

#Область СлужебныйПрограммныйИнтерфейс

// Процедура - устанавливает описание команды
//
// Параметры:
//  Команда    - КомандаПриложения     - объект описание команды
//
Процедура ОписаниеКоманды(Команда) Экспорт
	
	Команда.Опция("pp params", "", "Файлы JSON содержащие значения параметров,
	                               | могут быть указаны несколько файлов разделенные "";""")
	       .ТСтрока()
	       .ВОкружении("CPDB_PARAMS");

	Команда.Опция("is ib-srvr", "", "адрес кластера серверов 1С ([<протокол>://]<адрес>[:<порт>])")
	       .ТСтрока()
	       .Обязательный()
	       .ВОкружении("CPDB_IB_SRVR");
	
	Команда.Опция("ir ib-ref", "", "имя базы в кластере 1С")
	       .ТСтрока()
	       .Обязательный()
	       .ВОкружении("CPDB_IB_REF");
	
	Команда.Опция("ee err-if-exist errifexist", Ложь, "сообщить об ошибке если ИБ в кластере 1С существует")
	       .Флаговый()
	       .ВОкружении("CPDB_IB_ERROR_IF_EXIST");
	
	Команда.Опция("db dbms",
	              "MSSQLServer",
	              "тип сервера СУБД (MSSQLServer <по умолчанию>; PostgreSQL; IBMDB2; OracleDatabase)")
	       .ТСтрока()
	       .Обязательный()
	       .ВОкружении("CPDB_IB_DBMS");
	
	Команда.Опция("ds db-srvr", "", "адрес сервера СУБД")
	       .ТСтрока()
	       .Обязательный()
	       .ВОкружении("CPDB_IB_DB_SRVR");
	
	Команда.Опция("du db-user", "", "пользователь сервера СУБД")
	       .ТСтрока()
	       .Обязательный()
	       .ВОкружении("CPDB_IB_DB_USER");
	
	Команда.Опция("dp db-pwd", "", "пароль пользователя сервера СУБД")
	       .ТСтрока()
	       .Обязательный()
	       .ВОкружении("CPDB_IB_DB_PWD");
	
	Команда.Опция("dn db-name", "", "имя базы на сервере СУБД (если не указано, используется имя базы 1С)")
	       .ТСтрока()
	       .ВОкружении("CPDB_IB_DB_NAME");
	
	Команда.Опция("so sql-offs", "2000", "смещение дат на сервере MS SQL (0; 2000 <по умолчанию>)")
	       .ТСтрока()
	       .ВОкружении("CPDB_IB_SQL_OFFSET");
	
	Команда.Опция("cd create-db createdb", Ложь, "создавать базу данных в случае отсутствия")
	       .Флаговый()
	       .ВОкружении("CPDB_IB_CREATE_DB");
	
	Команда.Опция("aj allow-sch-job allowschjob", Ложь, "разрешить регламентные задания")
	       .Флаговый()
	       .ВОкружении("CPDB_IB_SCHEDULED_JOBS");
	
	Команда.Опция("al allow-lic-dstr allowlicdstr", Ложь, "разрешить выдачу лицензий сервером 1С")
	       .Флаговый()
	       .ВОкружении("CPDB_IB_LIC_DISTRIBUTION");
	
	Команда.Опция("ca cadm-user", "", "имя администратора кластера")
	       .ТСтрока()
	       .ВОкружении("CPDB_IB_CLUSTER_ADMIN");
	
	Команда.Опция("cp cadm-pwd", "", "пароль администратора кластера")
	       .ТСтрока()
	       .ВОкружении("CPDB_IB_CLUSTER_PWD");
	
	Команда.Опция("nl name-in-list nameinlist", "", "имя в списке баз пользователя (если не задано, то ИБ в список не добавляется)")
	       .ТСтрока()
	       .ВОкружении("CPDB_IB_NAME_IN_LIST");
	
	Команда.Опция("tp tmplt-path", "", "путь к шаблону для создания информационной базы (*.cf; *.dt).
	                                   |Если шаблон не указан, то будет создана пустая ИБ")
	       .ТСтрока()
	       .ВОкружении("CPDB_IB_TEMPLATE_PATH");
	
КонецПроцедуры // ОписаниеКоманды()

// Процедура - запускает выполнение команды устанавливает описание команды
//
// Параметры:
//  Команда    - КомандаПриложения     - объект  описание команды
//
Процедура ВыполнитьКоманду(Знач Команда) Экспорт

	ЧтениеОпций = Новый ЧтениеОпцийКоманды(Команда);

	ВыводОтладочнойИнформации = ЧтениеОпций.ЗначениеОпции("verbose");

	ПараметрыСистемы.УстановитьРежимОтладки(ВыводОтладочнойИнформации);

	Параметры1С          = Новый Структура();
	ПараметрыСУБД        = Новый Структура();
	АвторизацияВКластере = Новый Структура();

	Параметры1С.Вставить("Сервер1С"               , ЧтениеОпций.ЗначениеОпции("ib-srvr"));
	Параметры1С.Вставить("ИмяИБ"                  , ЧтениеОпций.ЗначениеОпции("ib-ref"));
	Параметры1С.Вставить("РазрешитьВыдачуЛицензий", ЧтениеОпций.ЗначениеОпции("allowlicdstr"));
	Параметры1С.Вставить("РазрешитьРегЗадания"    , ЧтениеОпций.ЗначениеОпции("allowschjob"));

	ПараметрыСУБД.Вставить("ТипСУБД"         , ЧтениеОпций.ЗначениеОпции("dbms"));
	ПараметрыСУБД.Вставить("СерверСУБД"      , ЧтениеОпций.ЗначениеОпции("db-srvr"));
	ПараметрыСУБД.Вставить("ПользовательСУБД", ЧтениеОпций.ЗначениеОпции("db-user"));
	ПараметрыСУБД.Вставить("ПарольСУБД"      , ЧтениеОпций.ЗначениеОпции("db-pwd"));
	
	ПараметрыСУБД.Вставить("ИмяБД"           , ЧтениеОпций.ЗначениеОпции("db-name"));
	Если НЕ ЗначениеЗаполнено(ПараметрыСУБД.ИмяБД) Тогда
		ПараметрыСУБД.ИмяБД = Параметры1С.ИмяИБ;
	КонецЕсли;

	ПараметрыСУБД.Вставить("СмещениеДат"     , ЧтениеОпций.ЗначениеОпции("sql-offs"));
	ПараметрыСУБД.Вставить("СоздаватьБД"     , ЧтениеОпций.ЗначениеОпции("create-db"));
	
	АвторизацияВКластере.Вставить("Имя"   , ЧтениеОпций.ЗначениеОпции("cadm-user"));
	АвторизацияВКластере.Вставить("Пароль", ЧтениеОпций.ЗначениеОпции("cadm-pwd"));
	
	ИмяВСпискеБаз        = ЧтениеОпций.ЗначениеОпции("nameinlist");
	ПутьКШаблону         = ЧтениеОпций.ЗначениеОпции("tmplt-path");
	ОшибкаЕслиСуществует = ЧтениеОпций.ЗначениеОпции("errifexist");
	
	ИспользуемаяВерсияПлатформы = ЧтениеОпций.ЗначениеОпции("v8version", Истина);
	
	РаботаСИБ.СоздатьСервернуюБазу(Параметры1С,
	                               ПараметрыСУБД,
	                               АвторизацияВКластере,
	                               ИспользуемаяВерсияПлатформы,
	                               ОшибкаЕслиСуществует,
	                               ПутьКШаблону,
	                               ИмяВСпискеБаз);

КонецПроцедуры // ВыполнитьКоманду()

#КонецОбласти // СлужебныйПрограммныйИнтерфейс

#Область ОбработчикиСобытий

// Процедура - обработчик события "ПриСозданииОбъекта"
//
// BSLLS:UnusedLocalMethod-off
Процедура ПриСозданииОбъекта()

	Лог = ПараметрыСистемы.Лог();

КонецПроцедуры // ПриСозданииОбъекта()
// BSLLS:UnusedLocalMethod-on

#КонецОбласти // ОбработчикиСобытий
